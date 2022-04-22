---
author: nasa9084
categories:
- golang
- net/http
date: "2019-11-01T05:48:19Z"
description: ""
draft: false
cover:
  image: images/gG9QcK.jpg
slug: hook-on-http-client
tags:
- golang
- net/http
title: net/http.ClientにHookをかける
---


昨日のこと。[jszwedko/go-circleci](https://github.com/jszwedko/go-circleci)というパッケージを使用してCircleCI EnterprizeのAPIを叩くという処理を実装していたのですが、どうにもうまくいかない。正直に言ってこのパッケージはドキュメントがしっかりしている、という訳ではないし、エラーメッセージを見ても何がだめなのか(そもそも現在使用しているCircleCI Enterpriseで使用できるかもよくわかっていなかった)わからない。

しかしまぁ、自分でHTTP requestを作ったりしてあれやこれややるのもまぁ面倒であるので、なんとかデバッグしたいと思ったのですが、外部のパッケージをフォークして変更を加えてデバッグする・・・という様なことはもちろんやりたくないわけです。

このパッケージは[`*http.Client`](https://golang.org/pkg/net/http/#Client)を指定できます。`*http.Client`はインターフェースではなく構造体なので、別の実装に置き換えるということはできません。が、その実装はほぼほぼ後述する`http.RoundTripper`なため、`http.RoundTripper`をラップして、HTTP requestとHTTP responseをログに吐けばまぁ、何が問題かわかるだろう、と考えました。
そんなモノは誰かがすでに書いているだろう、というのはさておき、`http.RoundTripper`を実際にいじってみるということはやったことがなかったので、勉強がてら[nasa9084/go-logtransport](https://github.com/nasa9084/go-logtransport)なるものを書きました。
書いていく途中で、考えたことなど、記録に残しておくのも良さそうと思ったため、本記事とします。

## http.Clientとhttp.RoundTripper

Go言語でHTTPのリクエストを発行するには基本として[`*http.Client`](https://golang.org/pkg/net/http/#Client)というものを使用します。簡便のため、[GET](https://golang.org/pkg/net/http/#Get)、[POST](https://golang.org/pkg/net/http/#Post)、[Head](https://golang.org/pkg/net/http/#Head)についてはパッケージグローバルの関数も用意されてはいるのですが、これらも内部的にはパッケージグローバルで宣言された[`DefaultClient`](https://golang.org/pkg/net/http/#DefaultClient)という[`*http.Client`](https://golang.org/pkg/net/http/#Client)が使用されています。

`*http.Client`はゼロ値で使用できるようにまとめられた構造体で、[DefaultClient](https://golang.org/pkg/net/http/#DefaultClient)は`*http.Client{}`と宣言されています。

普段はこの`*http.Client`を使用してHTTPの通信を行うわけですが、実は`*http.Client`はそれほど多くの機能は持っていません。実際、持っているフィールドはたったの4つ(Go1.13時点)しかないのです。`*http.Client`はリダイレクトやクッキーなどの一部の処理だけを受け持っていて、実際のHTTP通信のほとんどはフィールドとして保持している`http.RoudTripper`が行います。

`http.RoundTripper`はインターフェースとして定義されていて、自由に差し替えをすることができます。特に指定していない場合は`*http.Transport`がデフォルトの実装として使用されます。
Goの他の標準パッケージの例に漏れず、`http.RoundTripper`は非常にシンプルなインターフェースで、次の様に定義されています。

``` go
type RoundTripper interface {
    RoundTrip(*Request) (*Response, error)
}
```

`RoundTrip()`がHTTP requestを受け取り、HTTP responseを返します。つまり、requestのログをとり、子`RoundTripper`の`RoundTrip()`を実行し、`Response`のログをとってそのまま返す、という様なラッパーを書けば良さそうです。

``` go
func (t *Transport) RoundTrip(r *http.Request) (*http.Response, error) {
    // Requestのログをとる
    
    resp, _ := t.Transport.RoundTrip(r)
    
    // responseのログをとる
    
    return resp, nil
}
```

実際にrequestとresponseのログをとるには、`net/http/httputil`パッケージの`Dump`系関数が使用できます。今回はクライアント側の実装なので、`httputil.DumpRequestOut`と`httputil.DumpResponse`を使用します。

## テスト

実装の詳細はそれほど難しい内容ではないのでさておき、テストをどう書くか、という話をしましょう。
HTTPに関連したテストを書くとき、Go言語では`net/http/httptest`を使用すると便利です。
テストを書くにあたり、最初は子`RoundTripper`をモックして、適当にResponseを返すモノをつくればよいか、と思ったのですが、いい感じにテスト用のResponseを作成するのは面倒そうでした。

<blockquote class="twitter-tweet"><p lang="ja" dir="ltr">そういえば今日、http.Transportにロガーを仕込むの書いてみて、テストを書くのにRequestとResponse生成したいな・・・って考えてhttptestにないか見て、なんでないんや！って一瞬おこだったけどhttptest.Server使えばええんや、とすぐに思い直したのでアレがそれでそんな感じでした(とりとめが無い</p>&mdash; nasa9084@某某某某(0x1a) (@nasa9084) <a href="https://twitter.com/nasa9084/status/1189912403841929217?ref_src=twsrc%5Etfw">October 31, 2019</a></blockquote>
<script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

しかし素直に`httptest.Server`を使えば、クライアント側では一切テスト用に特殊な実装を使用することなく、普通にリクエストをしてレスポンスを受けることができます(`httptest.Server`は日常的に使っているのに、なぜ忘れていたのか・・・)。

これを使用して、シュッと適当なハンドラをサーブしてことなきをえました。

## interface or struct

さて、今回得た教訓として、別に必ずしもすべてをinterfaceで定義する必要は無いと言うことです。
HTTPでいえば`http.Client`は構造体として定義されていますが、これを使う側はいちいちinterfaceにして隠蔽せずとも、そのコアである`Transport`が`RoundTripper` interfaceとして定義されているため、実装を差し替えることができます。

例えば、OAuthを使用した認証をしたい場合、`golang.org/x/oauth2`を使用するのが簡単ですが、これも`http.Client.Transport`に認証の設定を加えることで、`http.Client`を使用するコードが意識することなく認証ができるように実装されています。

`sql.DB`なども、実際にデータベースに接続するドライバ部のみがinterfaceとして定義されています。

とりとめが無くなってきたのでこの辺で。



