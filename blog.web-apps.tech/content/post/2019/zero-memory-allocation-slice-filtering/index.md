---
author: nasa9084
date: "2019-02-04T07:30:29Z"
description: ""
draft: false
cover:
  image: images/gopher.png
  relative: true
slug: zero-memory-allocation-slice-filtering
tags:
  - golang
  - slice
title: zero memory allocation slice filtering
---


次のように、あるスライスをフィルタリングする関数を書くことがあると思います。

``` go
func FilterFoo(arr []string) []string {
    b := []string{}
    for _, e := range arr {
        if IsFoo(e) {
            b = append(b, e)
        }
    }
    return b
}
```

簡単なベンチマークを書くとわかるように、この関数は返値となるスライスの長さ+1回のメモリアロケーションを行います。一般に、メモリアロケーションの回数は少ない方がパフォーマンスがよく、可能ならばアロケーション回数0を目指したいものです。

今回の場合、次のように書くとメモリアロケーション回数0回の関数を書くことができます。

<ins datetime=2019-02-05>*追記*
`b := arr[:0]`とすると、基底配列に影響が出るので一概に比較できない、とご指摘を受けました。実際に使用する際は副作用に注意しましょう。

<blockquote class="twitter-tweet"><p lang="ja" dir="ltr">このやりかたって引数に副作用あるので、わかってないで使うと危ないような…<a href="https://t.co/iKXrXHUD3N">https://t.co/iKXrXHUD3N</a> <a href="https://t.co/CMrAYGJrdA">https://t.co/CMrAYGJrdA</a></p>&mdash; Yoichiro Shimizu (@budougumi0617) <a href="https://twitter.com/budougumi0617/status/1092566248242569216?ref_src=twsrc%5Etfw">February 4, 2019</a></blockquote>
<script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

<blockquote class="twitter-tweet"><p lang="ja" dir="ltr">append は引数を弄ってしまうので動作が異なりますね。 / “zero memory allocation slice filtering” <a href="https://t.co/JFFDJlfIQA">https://t.co/JFFDJlfIQA</a></p>&mdash; mattn (@mattn_jp) <a href="https://twitter.com/mattn_jp/status/1092581160339726336?ref_src=twsrc%5Etfw">February 5, 2019</a></blockquote>
<script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

*追記終わり*</ins>

``` go
func FilterFoo(arr []string) []string {
    b := arr[:0]
    for _, e := range arr {
        if IsFoo(e) {
            b = append(b, e)
        }
    }
    return b
}
```

違うのは一行目だけですが、ベンチマークを取ってみると、速度面では大きな違いがあります。次のようなベンチマークを実行してみます。

``` go
package benchmark_test

import (
	"strings"
	"testing"
)

var a = []string{"Hello", "foo.go", "hoge", "bar.go", "baz.go", "fuga"}

func IsGoFilename(filename string) bool {
	return strings.HasSuffix(filename, ".go")
}

func naive(arr []string) []string {
	var b []string
	for _, x := range arr {
		if IsGoFilename(x) {
			b = append(b, x)
		}
	}
	return b
}

func BenchmarkNaive(b *testing.B) {
	for i := 0; i < b.N; i++ {
		naive(a)
	}
}

func woAlloc(arr []string) []string {
	b := arr[:0]
	for _, x := range arr {
		if IsGoFilename(x) {
			b = append(b, x)
		}
	}
	return b
}

func BenchmarkWithoutAlloc(b *testing.B) {
	for i := 0; i < b.N; i++ {
		woAlloc(a)
	}
}
```

結果は次のようになります。

``` shell
$ go test -bench . -benchmem
goos: darwin
goarch: amd64
pkg: practice/go-filtering-without-allocating
BenchmarkNaive-8                 5000000               252 ns/op             240 B/op          4 allocs/op
BenchmarkWithoutAlloc-8         50000000                34.3 ns/op             0 B/op          0 allocs/op
PASS
ok      practice/go-filtering-without-allocating        3.269s
```



