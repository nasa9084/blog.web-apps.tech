---
author: nasa9084
categories:
- golang
- design pattern
- functional option pattern
date: "2017-09-26T01:44:53Z"
description: ""
draft: false
cover:
  image: images/gopher-3.png
  relative: true
slug: go-functional-option-pattern
tags:
- golang
- design pattern
- functional option pattern
title: Functional Option Pattern
---


Fuctional Option PatternはGo言語において構造体の初期化時にオプション引数を与えるためのデザインパターンで、元ネタはRob Pike氏の[Self-referential functions and the design of options](https://commandcenter.blogspot.jp/2014/01/self-referential-functions-and-design.html)、Dave Cheney氏の[Functional options for frendly APIS](https://dave.cheney.net/2014/10/17/functional-options-for-friendly-apis)です。

Go言語には他の言語でオプション引数やキーワード引数と呼ばれる、省略可能な引数が存在しません。
通常は大きな問題は無いのですが、しかし、構造体の初期化時には、省略可能引数がほしくなる場合もあります。

Dave Cheney氏の記事にもある例を見てみましょう。

## 例

``` go
type Server struct {
    listener net.Listener
}

func NewServer(addr string) (*Server, error) {
    l, err := net.Listen("tcp", addr)
    if err != nil {
        return nil, err
    }
    srv := Server{listener: l}
    go srv.run
    return &srv, nil
}
```

よくある構造体の初期化関数です。
初期化が上手くいけば、ポインタと`nil`を、上手くいかなければ`nil`とエラーを返す形になっています。

ここで、`Server`になにがしかの拡張を加えることを考えます。たとえばタイムアウトや、TLS対応等です。
しかしこれらは指定する必要が無い場合もあります。
Go言語を用いたアプローチですぐに思いつくのは、オプションの組み合わせの数だけ初期化関数を作成することですね。(たとえば、`With...`というサフィックスを使って)

しかしこれは、オプションの数が増えると、作成しなければならない関数の数が膨大になっていきます。
保守の観点から見てもこれは余りうれしくありません。

## Config構造体を用いる

そこでよく用いられるのが、設定を保持する構造体を用いる方法です。
例としては、以下の様にします。

``` go
type Config struct {
    Timeout time.Duration
    Cert *tls.Cert
}

func NewServer(addr string, config Config) {
    // ...
}
```

これも良く用いられているパターンです。
しかし、オプションを一切与えない場合のパターンを考えてみましょう。

``` go
func main() {
    srv, err := NewServer("localhost", Config{})
    // ...
}
```

むむ・・・オプションを与える必要が無いときでもConfig構造体を与えなければいけないのが余り美しくないですね。
勿論、引数をConfigのポインタにするという選択肢もあります。

``` go
func NewServer(addr string, config *Config) {
    // ...
}
```

この場合、オプションを与える必要が無い場合は`nil`を与えることができます。
しかし次の様な場合の動作はどうなるでしょうか。

``` go
func main() {
    config := Config{Port: 9000}
    srv, err := NewServer("localhost", &config)
    // error handling
    
    config.Port = 9001
    // ...
}
```

勿論、この場合の動作は**実装次第**です。
ドキュメントなどで説明文を読むか、ソースコードを読み解かなければ、実際にどのように動作するのかがわかりません。
ですから、ポインタを与えるという選択肢は保守の観点からは愚策と言えるでしょう。

## 可変長引数を導入する

Go言語には可変長引数があります。これを用いれば0個(=引数を与えない)が実現できると考えるかもしれません。

``` go
func NewServer(addr string, config ...Config) (*Server, error) {
    // ...
}
```

確かにこの方法なら、オプションを与えることも、与えないことも可能です。
なるほど、素晴らしいように思えます。

しかしまだ問題はあります。
可変長引数は0 or 1個の引数をとるわけではないのです。
Configを複数与えられた場合の挙動はどうなるのでしょうか。
これは大きな問題でしょう。

## Functional Options

扨、ここまで見てきた、「オプションの引数をどうするか」を解決するのが**Functional Option Pattern**と呼ばれるパターンです。

Go言語の関数は[第一級関数](https://ja.wikipedia.org/wiki/第一級関数)です。
これを利用して、オプションを**ポインタを引数にとる関数**とします。

例を見てみましょう。
先ほどの初期化関数を以下の様にします。

``` go
func NewServer(addr string, options ...func(*Server)) (*Server, error) {
    l, err := net.Listen("tcp", addr)
    if err != nil {
        return nil, err
    }
    
    srv := Server{listener: l}
    // ここまでは同じ
    
    for _, option := range options {
        option(&srv)
    }
    return &srv, nil
}
```

実際に使用する際は以下の様にします。Option関数を返すような関数を作成しています。

``` go
func Timeout(t int) func(*Server) {
    return func(s *Server) {
        s.Timeout = time.Duration(t) * time.Second
    }
}
func main() {
    srv, err := NewServer("localhost", Timeout(30))
}
```

どうでしょうか。
この形にすることで、

- オプションがない場合の対応(可変長引数のため)
- 組み合わせの自由(順番も自由)
- 拡張性(関数の追加でオプションが追加できる)
- 自己説明性(関数名でパラメータを明示)
- 安全性(ポインタじゃないので)
- `nil`や空値を使用する必要がない

と、多くの問題を解決できます。

関数を第一級オブジェクトとして扱うのは慣れも必要ですが、覚えておいて損はありません。

