---
author: nasa9084
categories:
- golang
- assets
- package bundler
date: "2019-01-17T07:47:13Z"
description: ""
draft: false
cover:
  image: images/gopher-1.png
slug: jessevdk-go-assets
tags:
- golang
- assets
- package bundler
title: jessevdk/go-assetsでファイルを埋め込む
---


Go言語の素敵なところの一つとして、最終的な成果物を1バイナリに収めることができる、という点にあると思う。結果として、非常に簡単にコマンドラインツールなどを配布することができる。
しかし、例えばコード生成を行うようなツールでテンプレートファイルを別途持っているような場合や、アプリケーション中で使う画像などを含む場合など、Goのソースコード以外のファイルを必要とする場合、全てを1ファイルで、とはいかない。

そのような場合に便利なのが[jessevdk/go-assets](https://github.com/jessevdk/go-assets)である。以前は多くの人がgo-bindataを使用していたと思われるが、作者がやめてしまったため、使えなくなってしまった。代替としてこれが便利。
jessevdk/go-assetsを使用するには、まず[jessevdk/go-assets-builder](https://gibhut.com/jessevdk/go-assets-builder)を使用する。これは、指定したファイルをGoのソースコードに埋め込んで、それらを扱うための`Assets`というオブジェクトを作成してくれるツールである。

インストールは簡単で、`go get`するだけ。

``` shell
$ go get github.com/jessevdk/go-assets-builder
```

インストールできたら、次のように使う。

``` shell
$ ls assets/
foo.html.tmpl bar.png
$ go-assets-builder assets -o assets.go
```
すると、`assets`ディレクトリの内容が埋め込まれた`assets.go`が生成される。今回は特にパッケージ名を指定していないのて、`package main`として作成された。必要なら`-p`オプションでパッケージ名を指定することもできる。
生成されたあとは、実際に使いたいソースコード内で次のように使う。

``` go
f, _ := Assets.Open("/assets/foo.html.tmpl")
// in production, need to handle error
defer f.Close()
// Do something with f
```

ここで作成された`f`は`os.File`と同じインターフェースを備えている。要するに、`os.Open`を使用したときと同じように操作することができる。

また、`Assets`という変数を別に使いたいときは、go-assets-builderでパッキングするときに`-v`オプションで変数名を指定することもできる。ディレクトリ全体ではなく、個別のファイルを指定することもできる。







