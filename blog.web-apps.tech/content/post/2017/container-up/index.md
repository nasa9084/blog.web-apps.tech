---
author: nasa9084
categories:
- golang
- docker
date: "2017-12-22T04:23:39Z"
description: ""
draft: false
cover:
  image: images/container-up.png
slug: container-up
tags:
- golang
- docker
title: container-upというツールを書いた
---


[container-up](https://github.com/nasa9084/container-up)というツールを書いたのでご紹介。

## 背景

このブログは[ghost](https://ghost.org/)というブログエンジンで動いています。動作環境として[Docker](https://www.docker.com/)を使用していて、Ghostの[公式イメージ](https://hub.docker.com/_/ghost/)を使用しています。
過去の経緯から、単体のDockerコンテナで動作させており、永続データはDockerボリュームとしてマウントしている形です。

扨、Docker ComposeやKubernetesなどのオーケストレーションツールを使っている場合、コンテナのバージョンアップは比較的簡単に行うことができます。
たとえば、Docker Composeを使用している場合、`docker-compose up`で、新しいイメージで作成したコンテナに差し替えることができます。

しかし、Dockerを単体で使っている場合、基本的には手作業で差し替えを行う必要があります。
Ghostコンテナの更新時は手作業でBlue-Greenアップグレードを行ってきたのですが、Ghostはかなりアップデートのペースが速く、毎度コンテナを差し替えるのが面倒になってきました。
それを楽にするため、**container-up**を作りました。

## インストール

### Go環境がある人

Go言語の環境がすでにある人は、以下のコマンドで使用できるようになります。

``` shell
$ go get github.com/nasa9084/container-up
```

### それ以外の人

Go言語の環境がない人は、[Releases](https://github.com/nasa9084/container-up/releases)ページから自分のOSに併せてバイナリをダウンロード、パスを通してください。
windows, linux, macos向け、それぞれamd64版のバイナリを用意してあります。
動作確認はmacos、linux(CentOS 7)のみ行っています。

これら以外の環境の人は、予め[dep](https://github.com/golang/dep)をインストールした上で以下のコマンドでコンパイルしてください。

``` shell
$ git clonse https://github.com/nasa9084/container-up.git
$ cd container-up
$ dep ensure
$ go build -o container-up main.go
```

コンパイルしたら、任意の場所にバイナリを移動し、パスを通してください。

## 使い方

基本的な使い方は、引数にコンテナ名またはコンテナIDを渡すだけです。

``` shell
$ container-up CONTAINER_NAME
```

与えられたコンテナと同じ名称のイメージを使用して、ボリュームやネットワークなどの設定はそのままに新しいコンテナを作成し、差し替えます。
`:latest`なイメージを使用している場合、`docker pull`した後にこのコマンドを実行することで、最新のイメージから作られたコンテナに差し替わるということです。

もとのコンテナは`--rm`オプションをつけて起動していた場合を除いて、`_oldContainer`というサフィックスが付いた状態でstopします。
なにか問題があった場合は、このコンテナに戻すと良いでしょう。

もし、元のコンテナが必要ない場合は、`--rm`オプションをつけると、差し替え時に削除します。

``` shell
$ container-up --rm CONTAINER_NAME
```

`:latest`ではないような、バージョンタグが付いたイメージを使用していて、新しいバージョンのイメージを使いたい場合などのため、新しいイメージ名を指定して実行することもできます。

``` shell
$ container-up -i IMAGE_NAME CONTAINER_NAME
```

この場合、差し替えるコンテナは指定されたイメージで作成されます。

これらのコマンドでは、ボリュームのマウント設定は引き継ぎますが、それ以外のファイルはすべて新しいイメージに差し替わります。
もし、ボリュームマウントしているところ以外に引き継ぎたいファイルなどがある場合[^copy-file]、`-f`オプションにファイルパスを指定することで新しいコンテナにコピーすることができます。

``` shell
$ container-up -f /path/to/file.ex CONTAINER_NAME
```

`-f`オプションは複数指定することができますので、複数のファイルをコピーしたい場合には複数回指定してください。

``` shell
$ container-up -f /path/to/file1 -f /path/to/file2 CONTAINER_NAME
```

現状実装されている機能は以上です。
ヘルプは`-h`オプションをつけることで見られます。

[^copy-file]: たとえば設定ファイルなど

