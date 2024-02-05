---
author: nasa9084
date: "2017-08-17T02:06:00Z"
description: ""
draft: false
cover:
  image: images/docker.png
  relative: true
slug: docker-multi-stage-builds
tags:
  - docker
  - dockerfile
title: Docker multi-stage builds
---


Docker 17.05から、新機能として[**multi-stage builds**](https://docs.docker.com/engine/userguide/eng-image/multistage-build/)というものが導入されました。
これは、コンテナイメージをより最適化するために有用な機能で、Dockerfileからコンテナイメージをビルドする際にビルド依存のライブラリ/環境とランタイム依存のライブラリ/環境を切り分けることができる機能です。

具体例を見てみましょう。
Go言語で書かれた何らかのアプリケーションをコンテナ上で動かすことを考えます。
以前までであれば、以下のような二つのDockerfileを用いて作成します。

まずはビルド用Dockerfileです

``` dockerfile
FROM golang:1.7.3
WORKDIR /go/src/github.com/someone/foo/
COPY app.go .
RUN GOOS=linux go build -a -o app .
```

つぎに、実行用のDockerfileです。

``` dockerfile
FROM busybox:latest
WORKDIR /root/
COPY app .
CMD ["./app"]
```

このようにすることで、ビルド時にはGo言語のビルド環境が入ったコンテナを、実行時は(Go言語環境は不要なので)busyboxコンテナを使用することで、実行イメージを小さく抑えることができます。
しかし、このように二つのDockerfileを使用する場合、コンテナイメージのビルド手順が煩雑になる、複数ファイルのため管理しにくいなどの問題がありました。

multi-stage buildsを実装されたことで、以下のようにDockerfileを一つにまとめることができます。

``` dockerfile
FROM golang:1.7.3 AS build
WORKDIR /go/src/github.com/someone/foo/
COPY app.go .
RUN GOOS=linux go build -a -o app .

FROM busybox:latest
WORKDIR /root/
COPY --from=build /go/src/github.com/someone/foo/app .
CMD ["./app"]
```

一行目の`AS build`、九行目の`--from=build`がポイントです。

`AS hoge`を使用することで、ビルドステージに名前をつけることができます。
加えて、`COPY`に`--from=hoge`の形で名称を指定することで、ビルドステージから直接ファイルをコピーしてくることができます。
これまでは一旦ホストにファイルを取り出してから再度コピーするという形だったので、かなり手間が省けると言えるでしょう。

golangイメージの中でも小さい、`golang:alpine`と`busybox`イメージでは、イメージサイズが200倍以上違うため、これは重要なアップデートと考えられます。

