---
author: nasa9084
categories:
- golang
- signal
- syscall
- net/http
date: "2018-03-10T15:42:54Z"
description: ""
draft: false
cover:
  image: images/gopher-3.png
  relative: true
slug: graceful-shutdown-with-syg
tags:
- golang
- signal
- syscall
- net/http
title: sygを使用したgraceful shutdown serverパターン
---


[`github.com/nasa9084/syg`](https://github.com/nasa9084/syg)を使用すると、手軽にシグナルとコールバック関数のマッピングを行うことができます[^syg-article]

これを使用し、SIGINTを受けてgraceful shutdownできるHTTPサーバを実装してみます。

``` go
package app

import (
    "context"
    "net/http"
    "os"
    "time"
    
    "github.com/nasa9084/syg"
)

type Server struct {
    server *http.Server
    closed chan struct{}
}

func NewServer() *Server {
    http.HandleFunc("/", longlongHandler)
    return &Server{
        server: &http.Server{
            Addr: ":8080",
        },
        closed: make(chan struct{}),
    }
}

func (s *Server) Run() error {
    // os.Interrupt　= syscall.SIGINT
    cancel := syg.Listen(s.shutdown, os.Interrupt)
    defer cancel()

    err := s.server.ListenAndServe()
    <-s.closed
    return err
}

func (s *Server) shutdown(os.Signal) {
    s.Shutdown(context.Background())
    close(s.closed)
}

func longlongHandler(w http.ResponseWriter, r *http.Request) {
    // なんか長い処理のつもり
    time.Sleep(10 * time.Second)
    w.Write([]byte("hello"))
}
```

mainからは以下の様に呼びます。

``` go
package main

import (
    "log"
    
    "foo/bar/app"  // 上記のappが$GOPATH/foo/bar以下にあると仮定
)

func main() {
    s := app.NewServer()
    if err := s.Run(); err != http.ErrServerClosed {
        log.Print(err)
    }
}
```

上手く動作しているか試してみます。

まずはサーバを起動します。

``` shell
$ go build main.go
$ ./main

```

次に、Terminalをもう一つ起動して、リクエストを投げてみます。

``` shell
$ curl localhost:8080
hello
```

10秒待つとレスポンスが返ってきます。

もう一度リクエストを送信し、レスポンスが返ってくる前に一つ目のTerminalで`Ctrl-C`(SIGINT)を叩きます。
すると、サーバはすぐには終了せず、レスポンスを返し終わるのを待ってからサーバが終了します。

無事、mainからはgoroutineやチャンネルを意識したコードを書かずともgraceful shutdownできるサーバを実装することができました。

[^syg-article]: [前回の記事](/go-signal-more-simply/)を参照

