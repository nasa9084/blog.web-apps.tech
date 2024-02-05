---
author: nasa9084
date: "2018-07-04T15:33:02Z"
description: ""
draft: false
cover:
  image: images/gopher.png
  relative: true
slug: future-pattern
tags:
  - golang
  - goroutine
  - design pattern
  - future pattern
title: Future Pattern
---


Future Patternは非同期処理パターンの一つで、ある処理を別のスレッドなどで実行し、結果を後で(=未来で)受け取るような処理に用いられるデザインパターンです。
特徴としては、外側に見えている関数などの処理を実行するオブジェクトは、処理を別スレッドに委譲し、後で結果を得ることの出来るFutureと呼ばれるオブジェクトを即座にメインロジックへと返却することです。

言葉で書いても、何だかよくわからないので、コードを見てみましょう。

``` go
/* package, import part */

func main() {
    in := make(chan int)
    out := Double(in)  // この時点では結果は得られない
    go func() {
        for i := 0; i < 10; i++ {
            in <- i
        }
        close(in)
    }()
    for d := range out {
        fmt.Println(d)  // ここで結果を得る
    }
}

func Double(in <-chan int) <-chan int {
    out := make(chan int)
    
    go func() {
        for i := range in {
            out <- 2 * i
        }
        close(out)
    }
    
    return out  // Futureオブジェクト
}
```

`main`関数から呼び出された`Double`関数は、与えられた数を二倍する関数ですが、二倍する処理は呼び出された時点では実行せず、即座にchannelを返します。この、変数名`out`のchannelが**Futureオブジェクト**です。
そのため、数を二倍した結果は、Double関数を呼び出した時点では得られず、後で`out`channelから得ることとなります。

以下に示す、パイプラインのような関数実行パターンにも使用しやすいデザインパターンです。

``` go
/* package, import part */

func main() {
    ar := []int{1, 2, 3, 4, 5}
    a2c := Array2Chan(ar)
    x2 := Double(a2c)
    xx := Square(x2)
    for i := range xx {
        fmt.Println(i)
        // Output:
        // 4
        // 16
        // 36
        // 64
        // 100
    }
}

func Array2Chan(ar []int) <-chan int {
    out := make(chan int)
    go func() {
        for _, i := range ar {
            out <- i
        }
        close(out)
    }()
    return out
}

func Double(in <-chan int) <-chan int {
    out := make(chan int)
    go func() {
        for i := range in {
            out <- 2 * i
        }
        close(out)
    }()
    return out
}

func Square(in <-chan int) <-chan int {
    out := make(chan int)
    go func() {
        for i := range in {
            out <- i * i
        }
        close(out)
    }()
    return out
}
```

