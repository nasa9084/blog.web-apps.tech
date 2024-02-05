---
author: nasa9084
date: "2018-11-06T05:01:49Z"
description: ""
draft: false
cover:
  image: images/gopher.png
  relative: true
slug: subcommand-using-jessevdk-go-flags
tags:
  - golang
  - command-line
  - flag
title: jessevdk/go-flagsでサブコマンドを実装する
---


Go言語を用いてコマンドラインツールを開発する際、皆さんはフラグのパースやサブコマンドの実装にどんなパッケージを使用していますか？標準の`flag`パッケージのほか、、[`spf13/cobra`](https://github.com/spf13/cobra)、[`alecthomas/kingpin`](https://github.com/alecthomas/kingpin)などもよく使われているようです。
私は専ら、[`jessevdk/go-flags`](https://github.com/jessevdk/go-flags)(以下`go-flags`)を使用しています。
`go-flags`はその名の通り、基本的にはオプション/フラグの解析用パッケージで、[ドキュメント](https://godoc.org/github.com/jessevdk/go-flags)もフラグ解析に関するものがほとんどです。
しかし、`go-flags`では、サブコマンドの実装も可能です。今回はこれに焦点を当ててご紹介していきます。

`go-flags`では、親コマンドにサブコマンドを登録する、という形でサブコマンドを実装していきます。サブコマンドは構造体として実装し、それぞれがオプションを格納する構造体を兼ねる形となります。
終端の、実際に何かの動作をするコマンドは `Commander` interfaceを実装している必要がありますが、中間のサブコマンド(`docker container`のような、グルーピングのためのサブコマンド)はこれを実装していなくても構いません。
`Commander` interfaceの定義は次のようになっています。

``` go
type Commander interface {
    Execute(args []string) error
}
```

非常に単純ですね。`args`にはコマンドでパースされなかったあまりの引数が渡されます。
実際の実装例を見てみましょう。


``` go
type subcommand struct {
    verbose bool `short:"v" long:"verbose"`
}

func (cmd *subcommand) Execute(args []string) error {
    // some exec
    return nil
}
```

サブコマンドを実装したら、親のコマンドにサブコマンドとして登録します。
ドキュメントを見ると、`Command`構造体に登録する関数があること、`Parser`構造体は`Command`構造体が埋め込まれていること、がわかります。
通常、`go-flags`パッケージを使用する場合はパッケージグローバルの`Parse`関数を使用することが多いと思うのですが、サブコマンドを実装する場合はトップレベルのパーサーを自分で作る必要があります。

``` go
type options struct {
    // ...
}

var opts options // global option
var parser = flags.NewParser(&opts, flags.Default)
var subcmd subcommand

func init() {
    parser.AddCommand("subcmd",
        "subcommand",
        "",
        &subcmd,
    )
}

func main() {
    if _, err := parser.Parse(); err != nil {
        if fe, ok := err.(*flags.Error); ok && fe.Type == flags.ErrHelp {
            os.Exit(0)
        }
        log.Print(err)
        os.Exit(1)
    }
}
```

このように登録することで、`subcmd`という名前のサブコマンドが使用できるようになりました。`go run main.go subcmd`などとすると、`subcommand.Execute`関数が実行されます。
実際には`Parser.AddSubCommand`のエラーをハンドリングしたりなど、もう少しやらなければならないことはあると思いますが、基本的には以上です。



