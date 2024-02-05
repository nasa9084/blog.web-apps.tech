---
author: nasa9084
date: "2018-06-26T08:30:22Z"
cover:
  image: images/gopher.png
  relative: true
slug: benchmark_in_func
tags:
  - golang
  - array
  - slice
  - string
  - benchmark
title: array/sliceに対する存在確認関数のベンチマーク
---


Pythonでいうところの、次の様な条件式を実現する関数を書きたかった。

``` python
ls = ["foo", "bar", "baz"]
s = "baz"

if s in ls:
    print("FOOBAR!")
```

対象がリストの時、普段なら普通にfor文を回すのですが、今回やりたかったのは定数値の一覧にあるかどうか、だったのと、定数の数も少なかったので、とりあえずで以下の様に実装していました。


``` go
func something(s string) error {
    if s != "foo" && s != "bar" && s != "baz" {
        return errors.New("value invalid")
    }
}
```

流石に雑すぎるので、リファクタリングしよう、と思ったのですが、「はて、for文挟んだら遅くなったりしないだろうか」などと考えてしまったのでベンチマークを取りました。

### TL; DR

素直にfor文を回しても大して問題はなさそう

### result

今回取ったベンチマークは6種類です。

* for-range文を回す
* for文を回す
* `map[string]struct{}`を集合として取り扱ってみる
* `&&`, `||`でつなぐ
* switch文を使う
* `sort.SearchStrings()`を使う

6番目の`sort.SearchStrings()`を使う方法は[stackoverflow](https://stackoverflow.com/questions/15323767/does-golang-have-if-x-in-construct-similar-to-python)に書いてあった方法で、二分探索をしてくれるというのでやってみました。

結果は次の通り。

```
BenchmarkInByForRange-4            	200000000	         9.34 ns/op	       0 B/op	       0 allocs/op
BenchmarkInByFor-4                 	100000000	        10.1 ns/op	       0 B/op	       0 allocs/op
BenchmarkInByMap-4                 	200000000	         7.79 ns/op	       0 B/op	       0 allocs/op
BenchmarkInByAnd-4                 	1000000000	         2.85 ns/op	       0 B/op	       0 allocs/op
BenchmarkInBySwitch-4              	2000000000	         1.39 ns/op	       0 B/op	       0 allocs/op
BenchmarkInBySortSearchStrings-4   	10000000	       179 ns/op	      32 B/op	       1 allocs/op
```

まぁ予想通りではあるものの、`sort.SearchStrings()`を使う方法は遅いですね。これはこの関数の「事前にリストがソート済みであること」という条件のために関数内でソートをしてるからだと思われます。(実際、ソート済みのリストを使って、関数内でソートをしないようにすると1/4くらいにはなる)

一番速かったのはswitch文を使ったやつで、これも予想通り(Go言語のswitchさん、すごく速いのは知っていた)。

とはいえ、(`sort.SearchString()`は除いて)せいぜい一桁ナノ秒の三倍程度しか違わないので、よほどのことが無ければ普通にfor文を回す方法でも問題ないかな、という程度の速度差でした。

