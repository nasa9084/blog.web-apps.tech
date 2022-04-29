---
author: nasa9084
categories:
- golang
- crypto/sha512
- encoding/hex
- bytes
- array
- slice
- stdlib
date: "2018-03-16T02:19:13Z"
description: ""
draft: false
cover:
  image: images/gopher-4.png
  relative: true
slug: golang-array-to-slice
tags:
- golang
- crypto/sha512
- encoding/hex
- bytes
- array
- slice
- stdlib
title: 'Golang: 配列からスライスに変換する'
---


* TL;DR: `slice := array[:]`で変換できる

Go言語にはリストの様なものが二つあります。配列(固定長)とスライス(可変長)です。
一般に、Go言語で配列を扱うことは多くないでしょう。
実際、多くのパッケージ(標準パッケージを含む)が要求するのはスライスです。

とは言っても一部のパッケージでは配列を取り扱っているものがあります。
例えば、[`crypto/sha512`を見てみる](https://golang.org/pkg/crypto/sha512/)と、以下の様な関数が存在します。

``` go
func Sum512(data []byte) [Size]byte
```

ここで、`Size`は同パッケージ内で宣言されている定数で、値は64です。
つまり、この関数は64バイトの長さを持った配列を返します。

この関数は与えられたデータからSHA512チェックサムを計算するものです。
勿論、返ってきた値をそのまま使用することもあるとは思いますが、そのままの値は人間可読な値では無いため、hexdigestを得たいと思うでしょう。

Go言語にはもちろんのことながら、`encoding/hex`パッケージが存在し、簡単に16進文字列を得ることができます。
16進表記の文字列を得るためには、次の関数を使用します。

``` go
func EncodeToString(src []byte) string
```

引数に注目します。
要求されているのは`byte`のスライスです。

Goでは、配列とスライスは基本的に別物ですから、以下の様に書くことはできません。

``` go
h := sha512.Sum512("foobar")

// 型エラーが発生する
EncodeToString(h)
```

そうは言っても、配列とスライスは非常に似ています。
次のように書きたくなりますね。

``` go
h := sha512.Sum512("foobar")
EncodeToString([]byte(h)) // 配列をスライスに変換したい
```

しかし、次のようなエラーを生じます。

```
cannot convert sha512.Sum512("foobar") (type [64]byte) to type []byte
```

型変換はできないようです。
どうしたら良いのでしょうか。

Go言語では、配列の範囲インデックスを使った場合、返される値はスライスとなります。

``` go
a := [3]string{"foo", "bar", "baz"}
s := a[0:2] // sはスライス
```

また、インデックスを省略することもできます。
開始値を省略すれば、0を与えたものと見なされますし、終了値を省略すれば、配列の最後までを切り取ります。

``` go
a := [3]string{"foo", "bar", "baz"}
s1 := a[:2]  // a[0:2]と等しい
s2 := a[0:]  // a[0:3]と等しい
```

では、両方省略するとどうなるでしょうか。
両方省略すると、**もとの配列と同じ内容のスライス**が返されます。

つまり、配列をスライスに変換したい場合は、次のように書くことができます。

``` go
a := [3]string{"foo", "bar", "baz"}
s := array[:]
```

さきほどの例に戻ってみましょう。
`sha512.Sum512()`は配列を返し、`hex.EncodeToString()`はスライスを要求するのでした。
この場合、次のように書くことができます。

``` go
h := sha512.Sum512([]byte("foobar"))
hex.EncodeToString(h[:])
```

これで無事、配列とスライスの変換をして、SHA512チェックサムの16進表現を得ることができました。

