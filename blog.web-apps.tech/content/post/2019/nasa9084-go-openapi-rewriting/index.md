---
author: nasa9084
date: "2019-12-20T08:15:39Z"
description: ""
draft: false
cover:
  image: images/gopher.png
  relative: true
slug: nasa9084-go-openapi-rewriting
tags:
  - golang
  - openapi
  - advent  calendar
  - "2019"
title: go-openapi を書き直しています
---


本記事は[Go2 Advent Calendar](https://qiita.com/advent-calendar/2019/go2)の20日目の記事です。昨日はyaegashiさんによる、[jsonx.go](https://l0w.dev/posts/jsonex.go/)でした。

皆さんは[OpenAPI Specification](https://github.com/OAI/OpenAPI-Specification)というモノをご存じでしょうか。OpenAPI SpecificationはJSONまたはYAMLでREST APIを表現するための仕様で、現在[バージョン3.0.2](https://github.com/OAI/OpenAPI-Specification/blob/master/versions/3.0.2.md)が最新です。いわゆる[Swagger](https://swagger.io/)の後継で、バージョン1系、2系がSwagger、3系以降がOpenAPI、ということになっています(Swaggerなら聞いたことがある/使っているという人も多いのではないでしょうか)。

OpenAPI Specificationは人間にも機械にも(比較的)読みやすい仕様書として、コード生成や、ドキュメントページの生成に使用することが可能です。

個人的には専らコード生成に使用しており、Go言語向けの実装として[github.com/nasa9084/go-openapi](https://github.com/nasa9084/go-openapi)(以下go-openapi)を実装・公開しています。
go-openapiは2017年ごろから細々と実装を続けており、(多分)二番目か三番目には古いと思われるOpenAPIのGo実装です。

基本的にはただひたすらOpenAPIのオブジェクトをGoの構造体として定義、値のバリデーション関数を用意しているといったもので、特別な機能はほとんどありません。
YAMLのパーサも、[go-yaml/yaml](https://github.com/go-yaml/yaml)を使用しており、自前では実装していません。

そんな中、[@goccy](https://twitter.com/goccy54)さんが、encoding/jsonとコンパチなインターフェースを持ったYAMLパーサを開発した、という話を耳にし、これを機に、とgo-openapiの実装を一から書き直し始めました。
もともと、パースは完全にgo-yaml/yamlに依存しており、Unmarshal系のメソッドも実装していなかった(途中から全部書くのはつらかったので・・・)ため、一部バリデーションに必要な関数を埋め込んだりもできなかったので、書き直したいとは思っていたのです。

現時点ではまだ[マージしておらず](https://github.com/nasa9084/go-openapi/pull/3)、書いている途中なのですが、大きな変更点として次の様なものがあります。

* もともとパブリックだったフィールドをすべてプライベートに変更し、ゲッターをはやした
* 各構造体に対応する`UnmarshalYAML()`メソッドをすべてコード生成するようにした
* YAMLパーサは[github.com/goccy/go-yaml](https://github.com/goccy/go-yaml)に乗り換えた
* rootオブジェクトを各構造体に埋め込むことで、バリデーションをとりやすくした

今後はよりコード生成に便利なメソッドを追加していきたいと思っています。

時間の都合で今日はここまで。技術的な話が全然無い記事になってしまった・・・



