---
author: nasa9084
date: "2018-01-29T07:13:10Z"
description: ""
draft: false
cover:
  image: images/gopher.png
  relative: true
slug: output-columned-text
tags:
  - golang
  - stdlib
  - text/tabwriter
  - string
title: テキストを列ごとにそろえて出力する
---


TL;DR: 標準パッケージ[`text/tabwriter`](https://golang.org/pkg/text/tabwriter/)を使用する

コマンドラインツールで標準出力を良い感じにそろえて出力したい場合があります。
例えば、[docker](https://www.docker.com)では、以下の様に出力されます。

``` shell
$ docker container ls
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                    NAMES
8caad461b4a4        redis               "docker-entrypoint.s…"   5 days ago          Up 5 days           0.0.0.0:6379->6379/tcp   redis-svr
329c9f9be035        mysql               "docker-entrypoint.s…"   5 days ago          Up 5 days           0.0.0.0:3306->3306/tcp   mysql-svr
```

このような **map、あるいは構造体の配列** の様なものを、きれいに表形式の様に列をそろえて出力したい場合に便利なのが標準パッケージの[`text/tabwriter`](https://golang.org/pkg/text/tabwriter/)です。
その名の通り、タブ区切りの文字列を良い感じに出力してくれるパッケージです。

`text/tabwriter`で定義されているのは[いくつかの設定用定数](https://golang.org/pkg/text/tabwriter/#pkg-constants)と、[`Writer`構造体](https://golang.org/pkg/text/tabwriter#Writer)のみです。
`Writer`は(勿論)[`io.Writer`インターフェース](https://golang.org/pkg/io/#Writer)を実装しています。

使用方法は通常の`io.Writer`とはすこし変わっていて、最初に[`Writer.Init()`](https://golang.org/pkg/text/tabwriter#Writer.Init)で初期化し、任意回数[`Writer.Write()`](https://golang.org/pkg/text/tabwriter#Writer.Write)で書き込みをした後、[`Writer.Flush()`](https://golang.org/pkg/text/tabwriter#Writer.Flush)で整形した文字列を出力します。
[`NewWriter()`](https://golang.org/pkg/text/tabwriter#NewWriter)関数は`Writer`構造体を`new()`した後`Init()`するのと同等です。

`Writer.Init()`関数及び`NewWriter()`関数に与える引数は以下の様になっています。

| 名前 | 型 | 内容 |
|:---:|:---:|:---:|
| `output` | `io.Writer` | `Flush()`したときの出力先 |
| `minwidth` | `int` | 1セルあたりの最小幅(パディングを含む) |
| `tabwidth` | `int` | タブ文字の幅(スペースの個数と等しい) |
| `padding` | `int` | パディング[^padding] |
| `padchar` | `byte` | パディング文字[^padchar_ascii] |
| `flags` | `int` | 調整用フラグ |

最後の引数である、調整用フラグには`0`(標準状態)を与えるか、[パッケージ定数](https://golang.org/pkg/text/tabwriter/#pkg-constants)の論理和を用いて設定を与えます。

[フラグ用定数](https://golang.org/pkg/text/tabwriter/#pkg-constants)は以下のものが定義されています。

| 定数名 | 意味 |
|:---:|:---:|
| `FilterHTML` | HTMLタグや **'&'** で始まる特殊文字を1文字としてカウントする |
| `StripEscape` | エスケープ文字を取り除く |
| `AlignRight` | 右寄せにする |
| `DiscardEmptyColumns` | 最初の空列を無視する |
| `TabIndent` | `padchar`の値に関係なく、インデントにTAB文字を使用する |
| `Debug` | 列同士の間に縦棒`|`を入れて表示する |

### example

#### source
``` go
w := tabwriter.NewWriter(os.Stdout, 0, 1, 1, ' ', tabwriter.AlignRight|tabwriter.Debug)
w.Write([]byte("alpha\tbeta\tgamma\t\n"))
for i := 0; i < 5; i++ {
    w.Write([]byte("foo\tbar\tbaz\t\n"))
}
w.Flush()
```

#### 出力
```
 alpha| beta| gamma|
   foo|  bar|   baz|
   foo|  bar|   baz|
   foo|  bar|   baz|
   foo|  bar|   baz|
   foo|  bar|   baz|
```


[^padding]: 文字列の幅に加えられる
[^padchar_ascii]: ASCII文字で指定する

