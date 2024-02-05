---
author: nasa9084
date: "2017-12-12T15:00:00Z"
description: ""
cover:
  image: images/parcel.png
  relative: true
slug: parcel-riot-js
tags:
  - javascript
  - package bundler
title: Parcel + Riot.js
---


この記事は [Riot.js Advent Calendar 2017](https://qiita.com/advent-calendar/2017/riot) 13日目の記事です。
昨日は[@supple](https://qiita.com/supple)さんによる[Riot+ElectronでMarkdownエディタを作る](https://qiita.com/supple/items/2cc58ee5c9bc11832596)でした。

## tl;dr
* [Parcel](https://parceljs.org/)というJavaScriptのモジュールバンドラを触ってみた
* webpackなどと比べて設定ファイルなどもいらずとても簡単
* ホットリロードな開発サーバを簡単に実行できる
* Riotと組み合わせるのもそれほど難しくない

## Parcel + Riot.js
[Parcel](https://parceljs.org/)というJavaScriptのモジュールバンドラが話題なのでさわってみました。
国内で話題になっている元の記事は「[webpack時代の終わりとparcel時代のはじまり](https://qiita.com/bitrinjani/items/b08876e0a2618745f54a)」。
[React](https://reactjs.org/)との組み合わせで記事を書かれています。

個人的には[Riot.js](http://riotjs.com/ja/)が好みなので、Riot.jsとの組み合わせで触ってみました。
尚、webpackは挫折したため比較できません。

## Parcel/Riot.jsのインストール

npmを使ってインストールします。

``` shell
$ npm install -g parcel-bundler riot
```

## source code

### ディレクトリ構造

以下の様なディレクトリ構造だとします。
なお、練習用のため、動作確認に関係ない部分は適当に削っています。

```
src/
|- index.html
|- index.js
|- package.json
|- app/
|  |- App.tag
```

### index.html

``` html
<!doctype html>
<html lang="ja">
  <head></head>
  <body>
    <App></App>
    <script src="index.js"></script>
  </body>
</html>
```

### index.js

``` javascript
import riot from 'riot'
import './app/tags'

riot.mount('App')
```

### App.tag

``` html
<App>
  <h1>Hello, parcel world!</h1>

  <script>
  import riot from 'riot' 
  </script>
</App>
```

### package.json

`package.json`は`npm init -y`で作成しました。

## compile/bundle & run

``` shell
$ riot app/ app/tags.js
$ parcel index.html
```

上記のコマンドで `http://localhost:1234` でホットリロードのサーバが動作します。
最終的な成果物を作る場合は `parcel build index.html`とすれば良いようです。

しかし、riot.jsのコンパイルはparcelの前段で別途行っているため、tagファイルの変更はwatchされません。riotコマンドに`-w`オプションをつけることでウォッチできますが、そのままだと二つのコマンドを別々の端末で開くなどする必要があり、若干面倒です。
`package.json`の`scripts`に以下の三つのコマンドを追加します。

``` json 
{
"watch": "npm run watch:riot & npm run watch:parcel",
"watch:riot": "riot -w app/ app/tags.js",
"watch:parcel": "parcel index.html"
}
```

追加したら、以下のコマンドを実行します。

``` shell
$ npm run watch
```

これでコマンド一つでホットリロードの開発サーバを動作させることができます。

