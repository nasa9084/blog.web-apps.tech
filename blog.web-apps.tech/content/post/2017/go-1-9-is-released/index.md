---
author: nasa9084
date: "2017-08-28T01:41:47Z"
cover:
  image: images/gopher-3.png
  relative: true
slug: go-1-9-is-released
tags:
  - golang
  - release
title: Go 1.9 is released
---


先日2017年8月24日にGo 1.9がリリースされました。
[ダウンロードページ](https://golang.org/dl/)からダウンロード可能です。

最大の変更点は[Go1.9rc1 is released!](../go1-9rc1_is_released)でもお伝えしたように、[**Type Alias**](https://golang.org/doc/go1.9#language)でしょう。
型名に対して別名をつけることができる機能です。

また、そのほかにも多くの変更が加えられています。
リリースノートは[こちら](https://golang.org/doc/go1.9)です。

以下では、いくつか変更点を見ていきます。

## Ports
Go 1.9から新しく2つのOSと1つのプロセッサアーキテクチャがサポートされています。

### POWER8
IBMのPOWER8プロセッサがサポートされています。
`GOARCH=ppc64`または`GOARCH=ppc64le`で使用することができます。

### FreeBSD
FreeBSD 9.3で動作します。。。が、すでにFreeBSDはサポート切れです。(なんでや・・・・)
Go 1.10からはFreeBSD 10.3+で動作する様になる予定です。

### OpenBSD 6.0
OpenBSD 6.0がサポートされました。
かわりに、Go 1.9ではOpenBSD5.9をサポートしていません。

## Parallel Compilation
パッケージの関数を並列コンパイルできるようになりました。
並列コンパイルはデフォルトでONになっており、無効化するには環境変数で`GO19CONCURRENTCOMPILATION`を`0`に設定します。

## Vendor matching with ./...
これまで、`./...`というディレクトリ表現はvendorディレクトリも含んでいました。しかし、`go test`の場合などvendorディレクトリは含まれない方がうれしい場合も多く、実際`glide nv`などでvendorディレクトリを含まないディレクトリマッチングが実装されていました。
go1.9からは`./...`にはvendorディレクトリが含まれないようになり、vendorディレクトリにマッチさせたい場合は`./vendor/...`と書く必要があります。

## Moved GOROOT
Go 1.9から、GOROOTが移動となりました。
起動されたパスから自動でGOROOTを探索します。
これにより、Goのインストールパスが違う場所に移動しても、Goのツール類は継続して使える用になりました。

## Compiler Toolchain
* 複素数の割り算がC99準拠となりました。

## Doc
長い引数リストは省略されます。
これは`go doc`で生成されるコードの可読性向上のためです。
また、構造体フィールドのドキュメンテーションがサポートされました。`go doc http.Client.Jar`などでどうなったのか確認することができます。

## env
`go env -json`フラグによりJSON出力することができるようになりました。

## Test
`go test`コマンドに`-list`フラグが追加されました。
これに正規表現で引数を与えることで、テスト名・ベンチマーク名・Exampleテスト名を調べることができます。

## Vet
`vet`コマンドがより強化されました。

## GC
ガベージコレクションがより効率化されました。

## ライブラリ
### Transparent Monotonic Times
モノトニック時間がサポートされました。

### math/bits
ビット操作のためのライブラリとして`math/bits`が追加されました。

### Helper method
`(\*testings.T).Helper`と`(\*testings.B).Helperという二つのメソッドが追加されました。
ファイルや行番号を表示する際にスキップする関数を用意できます。
これにより便利なテストヘルパー関数を書いて、且つユーザに対してはわかりやすい行番号を表示することができます。

### 標準ライブラリ
syncパッケージに`Map`という構造体が追加されているほか、多くの標準ライブラリに対して細かい変更が加わっています。

