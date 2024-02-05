---
author: nasa9084
date: "2017-11-21T04:21:58Z"
description: ""
draft: false
cover:
  image: images/gopher-1.png
  relative: true
slug: package-specified-context
tags:
  - golang
  - context
  - stdlib
  - net/http
title: Application Specific Context
---


元ネタは[@lestrrat](https://twitter.com/lestrrat)さんの「[Abusing type aliases to augment context.Context](https://medium.com/@lestrrat/abusing-type-aliases-to-augment-context-context-a08a85692fa8)」。

 golangを用いてHTTPサーバを作る場合、ルーティングを定義するのに以下の様な関数を用います。
 
 ``` go
 http.HandleFunc(path string, handler func(w http.ResponseWriter, r *http.Request)
 ```
 
 もちろん、`http.Handle`を用いる場合もありますし、[gorilla/mux](https://github.com/gorilla/mux)などのライブラリを用いることもあると思います。
 ここで重要なのは、`func(w http.ResponseWriter, r *http.Request)`という引数の方です。
 
 多くの場合、アプリケーションのハンドラ内ではデータベースなどの外部アプリケーション・ミドルウェアを用いることになります。
 しかし、golangのHTTPアプリケーションでは、ハンドラ関数の形式が`func (w http.ResponseWriter, r *http.Request)`と決まっています。引数の追加はできないため、引数以外の方法でDB接続情報などを渡す必要があります。
 
 これまで、golangでWebアプリケーション開発を行う場合によく用いられていたデータベースコネクションの保持方法は、`db`パッケージを作成し、そこにパッケージ変数として持つ方法かと思います。が、[グローバルな変数はできるだけ持ちたくない](https://dave.cheney.net/2017/06/11/go-without-package-scoped-variables)ですよね。
 
 そこで、Go 1.8から追加された[`context`](https://golang.org/pkg/context)を使うことができます。[`http.Request`](https://golang.org/pkg/net/http#Reqeuest)には`context.Context`が入っていて、[`Request.Context()`](https://golang.org/pkg/net/http#Request.Context)でget、[`Request.WithContext()`](https://golang.org/pkg/net/http#Request.WithContext)でsetできます。
 
 `context.Context`に値を持たせる方法で最初に思いつくのは[`Context.WithValue()`](https://golang.org/pkg/context#Context.WithValue)を用いる方法ですが、これは値を取得する度にtype assertionをする必要があり、あまり[よくありません](https://medium.com/@lestrrat/alternative-to-using-context-value-f2efe6bd2788)。
 これを解消するため、自分で型を定義するのがよいでしょう。
 
 ``` go
 package context // internal context subpackage
 
 import (
     "context"
     "errors"
 )
 
 type  withSomethingContext struct {
     context.Context
     something *Something
 }
 
 func WithSomething(ctx context.Context, something *Something) context.Context {
     return &withSomethingContext{
         Context: ctx,
         something: something,
     }
 }
 
 func Something(ctx context.Context) (*Something, error) {
     if sctx, ok := ctx.(*withSomethingContext); ok {
         if sctx.something != nil {
             return sctx.something, nil
         }
     }
     return nil, errors.New(`no asscosiated something`)
 }
 ```
 
 このように定義をすることで、毎回type assertionをする必要もなくなり、すっきりします。
 
 扨、このパッケージと`context`パッケージを両方読み込むためには、どちらかの読み込み名称を変更する必要があります。
 たとえば、以下の様な具合です。
 
 ``` go
 import (
     "context"
     mycontext "github.com/hoge/fuga/context"
 ```
 
 また、ソースコード中でも`context`と`mycontext`を使い分ける必要があり、煩雑です。
 この問題は、Go 1.9で導入された[Type Alias](https://golang.org/doc/go1.9#language)を使うときれいに書くことができます。
 
 ``` go
 import "context"
 
 type Context = context.Context
 ```
 
 このように書くと、標準パッケージの`context.Context`と、このアプリケーションにおける`context.Context`が同一のものとして扱われます。
 そのため、一つのパッケージのインポートだけで良くなります。
 
 最終的な`context`サブパッケージのコードは以下の様になるでしょう。
 
 ``` go
 package context // internal context subpackage
 
 import (
     "context"
     "errors"
 )
 
 type Context = context.Context
 /*
 ** some more definition
 */
 
 type  withSomethingContext struct {
     Context
     something *Something
 }
 
 func WithSomething(ctx Context, something *Something) Context {
     return &withSomethingContext{
         Context: ctx,
         something: something,
     }
 }
 
 func Something(ctx Context) (*Something, error) {
     if sctx, ok := ctx.(*withSomethingContext); ok {
         if sctx.something != nil {
             return sctx.something, nil
         }
     }
     return nil, errors.New(`no asscosiated something`)
 }
 ```
 
 実際には、標準パッケージの`context`と同等に使用するにはその他の定義の再定義や、複数の`withXXXContext`を定義した場合には再帰的に値を読み出す処理が必要になりますが、基本的にはこの形を使用すると便利です。
 このように`context`を定義しておき、以下の様に使用します。
 
 ``` go
 func withSomethingMiddleware(h http.Handler) http.Handler {
     return http.Handler(func(w http.ResponseWriter, r *http.Request) {
         something := &Something{}
         r = r.WithContext(context.WithSomething(r.Context(), something))
         h.ServeHTTP(w, r)
     })
 }
 ```
 
 `http.Handler`のmiddlewareについてはまたの機会に。

