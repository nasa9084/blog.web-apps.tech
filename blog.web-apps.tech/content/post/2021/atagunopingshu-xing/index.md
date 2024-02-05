---
author: nasa9084
date: "2021-08-02T14:55:54Z"
cover:
  image: images/---------1.png
  relative: true
slug: atagunopingshu-xing
title: aタグのping属性
---


私は基本的に業務・趣味の両方でGoを書いていると言うこともあり、ソースコードの管理はGOPATH方式で管理しています。しかしGOPATH方式で管理していると、ライブラリの挙動確認やらなんやらで使う書き捨てのコードをどこに置くか、という問題がある。 `src/github.com/nasa9084/...` に置くというのも一つの手ではあるものの、社内のGitリポジトリやらGitHubやらにアップするつもりもないコードを他の、GitHubやらなんやらで管理されているリポジトリと同じ場所に置くと一覧性や検索性が下がるし、やりたくはないので、普段はそういった直ぐにいらなくなるコードは `src/practice` というディレクトリに配置しています。

毎回書き殴った後に削除をする、というまめな性格はしていないので、結果として二度と日の目を見ないことがほとんどなコード片が貯まっていくので定期的にクリーンアップを行っています。書き殴りのコードとはいえ、何かヒントが残っているかもしれないので、削除前にチラチラと内容を確認しながら削除していくのですけれど、そういえばそんなの調べたな、なんて思うコード片がたまに見つかったりする訳です。

今回発見したのはタイトルにもあるとおり、`a`タグの`ping`属性です。W3C発行(発行、という表現が正しいのかどうかもよく分かっていないですけど)のHTML仕様が廃止となり、WHATWGのHTML仕様、HTML Living Standardに置き換えられる、との話を6月頃に見て、なるほどなーなんてちょろっと調べて、HTML Living Standardでは`a`タグの`ping`属性ってのがある、という情報にたどり着き、そして実際どんな挙動なのか、とコードを書いた、という経緯だったと思います。

実際のコード片がこちら:
index.html:
``` html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8"/>
    <title>Document</title>
  </head>
  <body>
    first page
    <a href="second.html" ping="http://localhost:8080/ping">second</a>
  </body>
</html>
```

second.html:
``` html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8"/>
    <title>Document</title>
  </head>
  <body>
    second page
  </body>
</html>
```

main.go:
``` go
package main

import (
	"log"
	"net/http"
)

func main() {
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		b, _ := httputil.DumpRequest(r, true)
		log.Printf("%s", b)
	})

	http.ListenAndServe(":8080", nil)
}
```

要するに、`index.html`をブラウザで開いて、`second.html`へのリンクをクリックすると`main.go`が待ち受けている8080番ポートにリクエストが飛び、次の様なログが出力されます:

```
2021/08/02 23:50:32 POST /ping HTTP/1.1
Host: localhost:8080
Connection: keep-alive
Content-Length: 4
Content-Type: text/ping
Ping-To: file:///Users/nasa/src/practice/a-ping/second.html
Sec-Fetch-Dest: empty
Sec-Fetch-Mode: no-cors
Sec-Fetch-Site: cross-site
User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:90.0) Gecko/20100101 Firefox/90.0

PING
```

これはFirefoxでのもので、Google Chromeだと次の様なログです:

```
2021/08/02 23:52:32 POST /ping HTTP/1.1
Host: localhost:8080
Accept: */*
Accept-Encoding: gzip, deflate, br
Accept-Language: ja-JP,ja;q=0.9,en-US;q=0.8,en;q=0.7
Cache-Control: max-age=0
Connection: keep-alive
Content-Length: 5
Content-Type: text/ping
Origin: null
Ping-To: file:///Users/nasa/src/practice/a-ping/second.html
Sec-Ch-Ua: "Chromium";v="92", " Not A;Brand";v="99", "Google Chrome";v="92"
Sec-Ch-Ua-Mobile: ?0
Sec-Fetch-Dest: empty
Sec-Fetch-Mode: no-cors
Sec-Fetch-Site: cross-site
User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/92.0.4515.107 Safari/537.36

PING
```

Chromeの方が情報量が多いですね。また、Chromeでは特に設定等をしなくてもpingが送出されましたが、Firefoxでは`about:config`を開いて`browser.send_pings`を`true`に設定しないとpingが送出されませんでした。

まぁ特に仕事で使っているわけでもないし、なんという事も無いんですが、供養がてらメモとしておいておきます。
以上です。



