---
author: nasa9084
categories:
- golang
- net/http
date: "2019-01-08T07:31:50Z"
description: ""
draft: false
cover:
  image: images/gopher.png
slug: net-http-for-valid
tags:
- golang
- net/http
title: きちんとやるnet/http
---


皆さん、`net/http`パッケージは使っていますか？
Go言語の標準パッケージである`net/http`はPythonなどの標準HTTPパッケージに比べ、人間にとっても取り扱いがしやすいため、そのまま使用している方が多いかと思います。
しかし、この`net/http`パッケージ、簡単に使えるように見えて結構落とし穴が多いのです。

## 1. Response Bodyはクローズする必要がある

次のコードを見てみましょう。

``` go
resp, err := http.Get("https://example.com/api")
if err != nil {
    return nil, err
}
var t T
if err := json.NewDecoder(resp.Body).Decode(&t); err != nil {
    return nil, err
}
return &t, nil
```

クライアントライブラリなどでよく書きそうな処理ですね。何も問題ないと思いましたか？
[公式ドキュメント](https://golang.org/pkg/net/http/#Response.Body)を見てみましょう。

> It is the caller's responsibility to close Body.

Bodyをクローズするのは関数を呼んだ人の責任、とあります。そうです。`Response.Body`は `Close()`しなければならないのです。ちゃんとクローズされていない場合、次のリクエストでkeepaliveコネクションの再利用がされず、パフォーマンスの悪化やコネクションリークを起こす可能性があります。

## 2. Response Bodyを最後まで読む

Response Bodyをきちんとクローズするように修正したコードが次のようなコードです。

``` go
resp, err := http.Get("https://example.com/api")
if err != nil {
    return nil, err
}
defer resp.Body.Close()
var t T
if err := json.NewDecoder(resp.Body).Decode(&t); err != nil {
    return nil, err
}
return &t, nil
```

`defer`を使うことできちんとクローズできているはずです。
さて、問題はないでしょうか？いいえ、これだけだとまだkeepaliveコネクションの再利用がされない恐れがあります。

>  The default HTTP client's Transport may not reuse HTTP/1.x "keep-alive" TCP connections if the Body is not read to completion and closed.

Response Bodyが最後まで読まれていない場合ですね。jsonのデコードの最中にエラーが発生した場合など、最後まで読み込まれていない可能性があります。最後まで読み込む処理を入れましょう。

## 3. Response Codeをチェックする

Response Bodyを最後まで読み込む処理を加えたのが次のコードです。

``` go
resp, err := http.Get("https://example.com/api")
if err != nil {
    return nil, err
}
defer func() {
    defer resp.Body.Close()
    io.Copy(ioutil.Discard, resp.Body)
}
var t T
if err := json.NewDecoder(resp.Body).Decode(&t); err != nil {
    return nil, err
}
return &t, nil
```

問題はありますか？はい、きちんとResponse Codeをチェックしましょう。リクエスト時に返ってくるエラーはあくまでリクエスト時のエラーであり、HTTPのステータスコードの確認まではしません。
APIによっては、正常時は200で返すがエラー時(例えば404のとき)は普通にwebページが返ってきてしまう、というAPIもあり得ます。
そんな場合にjsonのDecodeがpanicを起こさないよう、きちんとハンドリングしておきましょう。
また、`Response.StatusCode`は単なるintとして定義されています。場合によっては0などのおかしな値が入っていることもあるので、そういった意味でも確認が必要でしょう。

## 最終コード

最終的には次のようなコードになります。

``` go
resp, err := http.Get("https://example.com/api")
if err != nil {
    return nil, err
}
defer func() {
    defer resp.Body.Close()
    io.Copy(ioutil.Discard, resp.Body)
}
if resp.StatusCode < 200 || 299 < resp.StatusCode {
    return nil, errors.New("something error message...")
}
var t T
if err := json.NewDecoder(resp.Body).Decode(&t); err != nil {
    return nil, err
}
return &t, nil
```

最初はシンプルなように見えましたが、少し肥大化してしまいました。思っていたよりも注意すべき点があったようです。これに加え、場合によっては`context.Context`を使ってタイムアウトの指定をしたい、などより複雑になる可能性もあります。
一見単純なリクエストですが、きちんと気を遣っていきたいですね。



