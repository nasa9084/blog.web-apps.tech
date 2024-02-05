---
author: nasa9084
date: "2017-07-26T01:24:00Z"
description: ""
cover:
  image: images/gopher-1.png
  relative: true
slug: go1-9rc1_is_released
tags:
  - golang
  - release
title: Go1.9rc1 is released!
---


Go1.9rc1がリリースされました！
そこで、Go1.9のリリースノートをさらっと見てみようと思います。
(まだrc1なので、今後変更される場合があります。ご注意を)

全部見ていくと、結構な量になりそうなので、すぐに影響のありそうな部分だけ、軽く見ていきましょう。

# type alias
Go1.9ではType Aliasというものが導入されます。
これはその名の通り、型に別名をつけられるというもの。
言葉で説明するより、コードを見た方が早いと思いますので、コードを用意しました。

``` go
package main

import (
	"fmt"
	"log"
)

type T1 struct {
	ID   string
	Name string
}

type T2 = T1

func main() {
	t := T1{
		ID:   "id",
		Name: "Taro",
	}
	log.Println("call t1.Call()")
	fmt.Println(t.Call())

	log.Println("call t2.Call2()")
	fmt.Println(t.Call2())

	return 0
}

func (t *T1) Call() string {
	return "hello, " + t.Name
}

func (t *T2) Call2() string {
	return "hi, " + t.ID
}
```

go1.8以前ではsyntax errorになるこのコードですが、go1.9では正常に動作し、以下のような出力をします。

``` bash
$ go1.9rc1 run main.go
2017/07/26 09:38:27 call t1.Call()
hello, Taro
2017/07/26 09:38:27 call t1.Call2()
hi, id
```

`t`はT1型であり、`Call2()`が定義されているのはT2型ですが、T1型とT2型は同じものと見なされるので、T1型である`t`から`Call2()`を呼び出すことができます。(ややこしい)
この、Type Aliasが導入される背景などを説明した提案は[proposa/18130-type-alias.md](https://github.com/golang/proposal/blob/master/design/18130-type-alias.md)にあります。

ここで注意が必要なのは、C言語の`typedef`のように、
``` go
type sp = *string
```
のようにすることはできないので注意が必要です(実際には上のコード自体は動作しますが、この型名を使おうとすると上手くいかないことが多いので、使用しない方が良いでしょう)

# Vendor matching with ./...
以前より、`./...`とすることで、カレントディレクトリ以下を再帰的に探索してテストなどを行うことができました。
しかしここで問題となるのが、`vendor`ディレクトリ内のパッケージで、テストの際はここを避けたい、といった要望も多かったようです。
実際、glide等では`glide nv`コマンドなどにより、`vendor`ディレクトリ以外を列挙するようなことができるようになっていました。

1.9からは、`./...`には`vendor`ディレクトリが含まれなくなりました。

# go test -list
`go test`コマンドに`-list`フラグが追加されました。これは、引数として正規表現を与えることで、マッチするテストやベンチマークを(テストを実行せずに)列挙することができるオプションです。

# Transparent Monotonic Time support 
`time`パッケージがモノトニック時刻をサポートするようになりました。

# New bit manipulation package
`math/bits`パッケージが新たに追加されました。
bitをカウントしたり、操作したりする関数群が含まれています。

# Test Helper Functions
`testing`パッケージに、`(*T).Helper()`および`(*B).Helper()`が追加されました。
これは、呼び出された関数をヘルパー関数だとマークし、テストコードやその行数を出力するような場合にヘルパー関数をスキップする様になります。

# そのほか、標準パッケージの変更
## crypto/rand
Linux環境で、`getrandom`が十分なランダム性を用意できない場合、ブロックするようになりました。
もしブロックされた場合、goは`/dev/urandom`から乱数を取得します。

## database/sql
`database/sql`パッケージでは、`Tx.Stmt()`が呼ばれた際、キャッシュされた`Stmt`オブジェクトがあればそれを利用するようになりました。

# その他
実際には、もっと多くの変更があります。
詳しく知りたいかたは[release note](https://tip.golang.org/doc/go1.9)をご覧になって下さい！！！

