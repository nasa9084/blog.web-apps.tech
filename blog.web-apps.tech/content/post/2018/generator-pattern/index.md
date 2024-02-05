---
author: nasa9084
date: "2018-11-21T08:09:23Z"
description: ""
draft: false
cover:
  image: images/gopher-1.png
  relative: true
slug: generator-pattern
tags:
  - golang
  - design pattern
  - goroutine
  - generator pattern
title: Generator Pattern
---


Generator PatternはGo言語における並列処理パターンの一つで、goroutine-safeな値列の生成などに使用することができます。

コードを見た方が早いと思いますので、コードを掲載しましょう。
次の例は複数のgoroutineから共通の連番を採番したいときに利用することができます。

``` go
func GenInt(ctx context.Context, max int) <-chan int {
    ch := make(chan int)
    go func() {
        defer close(ch)
        for i := 0; i < max; i++ {
            select {
            case <-ctx.Done():
                return
            case ch <- i:
        }
    }
    return ch
}
```

返された`<-chan int`から`int`の値を取得するようにすることで、重複のない連番を取得することができます。
Go言語において、`chan`は複数箇所から値の取り出しを行うことができますが、`chan`に入力された一つの値はどこか一箇所からしか取り出すことができません。そのため、lock等を使用しなくとも、必ず重複無く連番を取得することができます。
lockを使用した場合、若干動作が遅いため、可能であればlockを使用しないで、`chan`を使用して実装できるとより高速な、Goらしいコードとすることができます。





