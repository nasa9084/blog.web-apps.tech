---
author: nasa9084
date: "2020-04-08T04:17:35Z"
cover:
  image: images/gopher-1.png
  relative: true
slug: context-withtimeout-with-zero
tags:
  - golang
  - context
  - time
title: context.WithTimeoutに0を与えるとどうなるのか
---


当然と言えば当然なんですけど、特に `panic` とかそういうことはなく、一瞬でタイムアウトします。まぁ、どうと言うことは無いですが、設定ファイルとかで未定義時に0が来るような実装になっている場合はなんか処理する(0の時は処理をしない、というのは多分あんまりなさそうですし)必要がありますね。

``` go
ctx, cancel := context.WithTimeout(context.Background(), time.Duration(0))
defer cancel()

<-ctx.Done()
log.Print("timeout")
```

https://play.golang.org/p/63DkfIEImjv

## もうちょっと細かい話

さすがに短すぎるので、もう少し細かい実装の話。

`context.WithTimeout`は内部的には特別な実装は無くて、`context.WithDeadline`を`time.Now.Add(timeout)`に対して呼んでいます。

で、`context.WithDeadline`は返値を返す前に`time.Until`を使って現在時刻とデッドラインまでの差分をチェックしていて、これが0以下なら[その場でキャンセル関数を呼んで](https://github.com/golang/go/blob/go1.14.1/src/context/context.go#L437-L439)います。

まぁそんなわけで、余分な待ち時間が発生することもなく、`time.WithTimeout`を呼んだ時点でちゃんとタイムアウトされる、ということでした。ちゃんちゃん。



