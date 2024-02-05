---
author: nasa9084
date: "2018-02-24T03:22:28Z"
description: ""
cover:
  image: images/gopher.png
  relative: true
slug: go-cmdline-option-jessevdk-go-flags
tags:
  - golang
  - command-line
title: Goでコマンドラインオプションを処理する
---


## TL;DR

* `github.com/jessevdk/go-flags`が便利

## flagパッケージ

コマンドライン・ツールを作ろうと考えたとき、避けては通れないのがコマンドラインオプションを如何に処理するか、ということです。

Go言語では、標準パッケージに`flag`というパッケージが存在し、これを用いることでコマンドラインオプションをパースすることが出来ます。
しかし、`flag`パッケージでは、ロングオプションとショートオプションを一度に定義することが出来ず、また、ロングオプションであろうとショートオプションであろうと`-XXX`という、ハイフンが一つつく形式のオプションとなります。
これはあまり一般的ではなく[^one-hyphen]、便利とも言いにくいでしょう。

そこで便利なのが、[`jessevdk/go-flags`](https://github.com/jessevdk/go-flags)パッケージです。

## go-flagsパッケージ

[`jessevdk/go-flags`](https://github.com/jessevdk/go-flags)パッケージは、その名の通り、コマンドラインオプションを取り扱うパッケージです。
ショートオプション、ロングオプションはもちろんのこと、ショートオプションをまとめて指定する、同じオプションを違う引数で複数回指定する、環境変数からの読み込み、デフォルト値の指定などに対応していて、一般的なオプションの処理に幅広く対応出来ます。
オプションは構造体として定義出来るため、パースした後の処理で取り回すのも簡単です。

簡単な例を見てみましょう。

``` go
type options struct {
    Name string `short:"n" long:"name" description:"listen address"`
}

func main() {
    var opts options
    if _, err := flags.Parse(&opts); err != nil {
        // some error handling
        return
    }
    fmt.Printf("Hello, %s\n", opts.name)
}
```

パッケージ宣言やインポートの節は省略していますが、上記をmain.goとして実行すると、以下の様に出力されます。

``` shell
$ go run main.go -h
Usage:
  main [OPTIONS]

Application Options:
  -n, --name= listen address

Help Options:
  -h, --help  Show this help message

$ go run main.go -n Foo
Hello, Foo
```

## フィールドの設定

`jessevdk/go-flags`パッケージでは、オプションを定義するために構造体を作ります。
構造体の各フィールドがオプション一つ一つに当たります。
そのため、細かい設定はタグで行うことになります。
以下で、このパッケージで使用できる、主なタグを紹介します。

* `short`
    * ショートオプションの名前を決定します。ショートオプションですので、一文字をしていします。
* `long`
    * ロングオプションを指定します。
* `description`
    * ヘルプで表示される、オプションの説明文を指定します。
* `no-flag`
    * フィールドをオプションとして扱わないときに指定します。値は空値以外とします。
* `env`
    * 読み込む環境変数を指定します。環境変数から読み込まれた値は、オプションの規定値となります。(オプションで指定されたものが優先されます)
* `env-delim`
    * sliceやmapのオプションに環境変数から値を読み込む場合、このタグで指定した値で分割されます。
* `default`
    * 規定値を設定します。mapやsliceの値の場合は複数回指定することもできます。
* `default-mask`
    * ヘルプで規定値の欄に表示される値を指定します。指定しなかった場合は`default`の値が表示されますが、このタグを指定すると表示を上書きできます。`-`を指定すると、規定値を表示しない設定となります。
* `choice`
    * オプションに指定可能な値を定義できます。複数の選択肢を定義する場合は複数回指定します。
* `required`
    * オプションが必須な場合に指定します。値は空値以外とします。このタグが指定されたオプションが実行時に与えられなかった場合、ErrRequiredを返します。
* `positional-args`
    * 構造体に対してこのタグを指定することで、位置引数を定義できます。

このほか、オプショングループ、オプションの名前空間、サブコマンドの定義などに対応しています。

[^one-hyphen]: javaのオプションなど、全く見ないわけではありませんが

