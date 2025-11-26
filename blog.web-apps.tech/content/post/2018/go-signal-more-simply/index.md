---
author: nasa9084
date: "2018-03-06T14:32:00Z"
cover:
  image: images/gopher-2.png
  relative: true
slug: go-signal-more-simply
tags:
  - golang
title: 'Golang: 手軽にシグナルをListenしてcallback関数を呼ぶ'
---


Go言語でシグナルを取り扱いたい場合、`os`パッケージおよび`os/signal`パッケージ、`syscall`パッケージを使用します。

具体的には、以下のようにします。

``` go
func main() {
    sigCh := make(chan os.Signal, 1)
    doneCh := make(chan struct{})
    
    signal.Notify(sigCh, syscall.SIGINT)
    
    go func() {
        sig := <-sigCh
        fmt.Println(sig) // (1)
        close(doneCh)
    }()
    <-done
}
```

実際には、(1)の様に受け取ったシグナルを出力するだけではなく、何らかの処理を行うことになるでしょうし、goroutineのリークを避けるためにシグナルの待受をキャンセルする必要が有りますから、`context`を使用してfor-selectループを書くことにもなるでしょう。

例として、HTTPサーバをシャットダウンするような処理を考えます。

``` go
func main() {
    sigCh := make(chan os.Signal, 1)
    doneCh := make(chan struct{})
    ctx, cancel := context.WithCancel(context.Background())
    
    signal.Notify(sigCh, syscall.SIGINT)
    
    s := &http.Server{
        Addr: ":8080",
        Handler: http.DefaultServeMux,
    }
    
    go func() {
        for {
            select {
            case sig := <-sigCh:
                sig := <-sigCh
                s.Shutdown(context.Background())
                close(doneCh)
            case <-ctx.Done():
                return
            }
        }
    }()
    
    if err := s.ListenAndServe(); err != http.ErrServerClosed {
        log.Println(err)
        cancel()
        return
    }
    <-doneCh
}
```

シグナルを受け取って、関数の呼び出し(ここでは`s.Shutdown()`)をしたいだけなのに、チャンネルを作って、goroutineを立ち上げて、となんとも大仰です。
goroutineで呼び出す関数の中でfor-selectループを使っているため、行数も長くなってしまっています。

できれば、これらの処理を、もっと気軽に取り扱いたいですよね。

そこで、[`syg`](https://github.com/nasa9084/syg)というパッケージを作成しました。

## [`github.com/nasa9084/syg`](https//github.com/nasa9084/syg)

`syg`パッケージに用意されているのは関数二つだけです。
`Listen`と`ListenContext`だけです。
察しの良い方はお気づきかもしれませんが、`Listen`は内部で`context.Background`を使って`ListenContext`を呼び出します。
`database/sql`パッケージの`*DB.Query`と`*DB.QueryContext`などの関係と同じです。
つまり、処理的には実質一つの関数のみしかありません。

これらの関数はコールバック関数とシグナル(可変長)をとり、`CancelFunc`を返します。
名前の通り、シグナルをListenして、シグナルを受け取ったら所定のコールバック関数を呼ぶ、というものです。
`CancelFunc`はgoroutineを停止するキャンセル用の関数のため、`defer`で呼び出すことでgoroutineのリークも防げます。

先程のHTTPサーバのシャットダウンの例を、`syg`を使用して書き換えてみます。

``` go
func main() {
    doneCh := make(chan struct{})

    s := &http.Server{
        Addr: ":8080",
        Handler: http.DefaultServeMux,
    }
    
    cancel := syg.Listen(func(os.Signal) { 
        s.Shutdown(context.Background())
        close(doneCh)
    })
    defer cancel()
    
    if err := s.ListenAndServe(); err != http.ErrServerClosed {
        log.Println(err)
        return
    }
    <-doneCh
}
```

goroutineの立ち上げや、シグナルを受け渡すチャンネルの処理、for-selectループなくなり、スッキリしました。

`syg`は数十行程度の小さなパッケージですが、是非使ってみてください！
バグや改善点が有りましたら、issue、PRもお待ちしています！

