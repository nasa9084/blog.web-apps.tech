---
author: nasa9084
date: "2017-09-01T07:03:07Z"
description: ""
cover:
  image: images/gopher.png
  relative: true
slug: how-to-use-sync-waitgroup
tags:
  - golang
  - goroutine
  - sync
  - stdlib
title: sync.WaitGroup
---


Goroutineを使用して複数の処理を並列で実行、すべてが終わったら次の処理に進みたいという場合があると思います。
Goroutineでデータのリストを作るという処理を考えます。
データの順番は関係なく、すべてのGoroutineでのデータがそろったら次の処理をしたいという設定です。
この場合、単純に考えると以下のようなコードになりますが、以下のコードではデータがそろう前に次の処理が行われます。

``` go
datalist := []string{}
for i := 0; i < 10; i++ {
    go func() {
        // something w/datalist
    }
}
fmt.Println("next step")
```

このような場合に、`sync.WaitGroup`を使用します。
`sync.WaitGroup`は基本的にはただのカウンタですが、カウンタがゼロになるまで処理を待つことができます。
言葉で説明してもわかりにくいと思いますので、ソースコードを見てみましょう。

``` go
datalist := []string{}
wg := sync.WaitGroup{}

for i := 0; i < 10; i++ {
    wg.Add(1) // Goroutineの数だけカウンタを増やす
    go func() {
        // something w/datalist
        wg.Done() // カウンタを減らす
    }
}
wg.Wait() // カウンタが0になるまでブロックする
fmt.Println("next step")
```

上記の様にすることで、for文の部分ではGoroutineで並列に実行しつつ、次の処理は並列実行部分が終わってからという動作をさせることができます。

ポイントはカウンタを増やす部分です。
Goroutine内ではなく、外側で`Add(1)`します。
Goroutine内で`Add(1)`してしまうと、`wg.Wait()`に到達した時点でGoroutineがまだどれも実行されておらず、次の処理に進んでしまう可能性があるので、必ずGoroutineの外側で実行することが肝要です。

