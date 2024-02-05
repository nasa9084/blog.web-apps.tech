---
author: nasa9084
date: "2019-02-06T07:52:05Z"
cover:
  image: images/nats-server.png
  relative: true
slug: messaging-system-nats
tags:
  - cncf
  - nats
  - cloud-native
  - messaging
title: NATSを触ってみた
---


[NATS](https://nats.io/)は[CNCF](https://www.cncf.io)(Cloud Native Computing Foundation)によってホスティングされているメッセージングシステムです。軽量で高パフォーマンスかつスケーラブルなのが特徴だそうです。オランダのSynadia社が中心となって開発を行っていますが、オープンソースソフトウェアなので[GitHub](https://github.com/nats-io)上で今トリビュートすることもできます。
Go、NodeJS、Ruby、Java、C、C#、Nginx用のクライアントライブラリはSynadiaによってサポートされており、そのほかにもPythonやElixir用のクライアントなどが存在します。
NATSのサーバ自体(gnatsd)は[Goで書かれている](https://github.com/nats-io/gnatsd)ため、バイナリ一つで起動できるほか、、[公式Dockerコンテナイメージ](https://hub.docker.com/_/nats)や[Kubernetes用のOperator](https://github.com/nats-io/nats-operator)も用意されているため、簡単に構築・運用することができます。
本記事でも、Dockerで起動したサーバを使用しています。

NATSでは3種類のメッセージングモデルを利用することができます。

* Publish/Subscribe
* Request/Reply
* Queueing

今回はPub/SubとRequest/Replyを試してみます。

## サーバを立ち上げる

実験に先駆けて、まずはサーバを立ち上げます。今回はmacOS High Sierra環境のため、docker for macで起動してみます。

```shell
$ docker run --rm -d --name nats -p 4222:4222 -p 6222:6222 -p 8222:8222 nats:1.4.0-linux
```

`nats:1.4.0-linux`は執筆時点(2019-02-06)で`nats:latest`です。
ここで三つのポートを空けていますが、それぞれ用途は次の通りです。

* `:4222`: client port
* `:6222`: route port
* `:8222`: http port

それぞれの詳細な説明は割愛しますが、本記事ではクライアントからの接続だけを試してみますので、4222番ポートだけの開放でも問題ありません。

## Publish/Subscribe

まずは標準的なPub/Subモデルから試してみます。NATSのPub/SubはRedisなどと同様、[Wikipedia](https://ja.wikipedia.org/wiki/%E5%87%BA%E7%89%88-%E8%B3%BC%E8%AA%AD%E5%9E%8B%E3%83%A2%E3%83%87%E3%83%AB)でいうところの「トピックベース」なPub/Subです。NATSではトピックのことを**Subject**とよびます。
NATSのSubjectは階層構造をとることができ、`.`(ドット)で区切って表現します。Subscriberはこの階層構造の一部にワイルドカードとして`*`(アスタリスク)を使用することができます。また、`>`を使用して下の階層すべて、を表現することもできます。
例えば、Subscriberが`foo.bar.*`を購読している場合、`foo.bar.baz`や`foo.bar.qux`などのメッセージを受け取ることができますが、`foo.bar.baz.qux`は受け取ることができません。一方、`foo.bar.>`を購読している場合、`foo.bar.baz.qux`も受け取ることができます。

サンプルコードとして、次のようなものを書いてみました。

### Publisher

``` go
package main

import (
	"log"

	nats "github.com/nats-io/go-nats"
)

func main() {
	nc, err := nats.Connect("localhost:4222")
	if err != nil {
		log.Fatal(err)
	}
	defer nc.Close()

	if err := nc.Publish("subjectFoo", []byte("bodyBar")); err != nil {
		log.Fatal(err)
	}
}
```

### Subscriber

``` go
package main

import (
	"log"

	nats "github.com/nats-io/go-nats"
)

func main() {
	nc, err := nats.Connect("localhost:4222")
	if err != nil {
		log.Fatal(err)
	}
	defer nc.Close()

	sub, err := nc.Subscribe("subjectFoo", callback)
	if err != nil {
		log.Fatal(err)
	}
	log.Printf("Subject: %s", sub.Subject)
	log.Printf("Queue: %s", sub.Queue)
	ch := make(chan struct{})
	<-ch
}

func callback(message *nats.Msg) {
	log.Print(string(message.Data))
}
```

それぞれ、適当なファイルに保存し、`go run`で起動します。あらかじめSubscriber側を起動しておくことで、Publisherを起動した際にメッセージ(今回は"bodyBar")が(Subscriber側で)Printされるはずです。
ポイントは`*nats.Conn.Subscribe`が非同期な関数で、メッセージを受け取った際にcallback関数が呼ばれる、というところです。
今回のサンプル中では`<-ch`としてブロックしていますが、何らかの方法でブロックしないと、受け取る前にmainが終わってしまうので注意が必要です。
同期処理したい場合には、`*nats.Conn.SubscribeSync`を使用することで次のように書き換えられます。

``` go
package main

import (
	"log"

	nats "github.com/nats-io/go-nats"
)

func main() {
	nc, err := nats.Connect("localhost:4222")
	if err != nil {
		log.Fatal(err)
	}
	defer nc.Close()

	log.Printf("Subject: %s", sub.Subject)
	log.Printf("Queue: %s", sub.Queue)
    
    sub, err := nc.Subscribe("subjectFoo", callback)
	if err != nil {
		log.Fatal(err)
	}
    
    for {
        msg, err := sub.NextMsgWithContext(context.Background())
        if err != nil {
            log.Fatal(err)
        }
        callback(msg)
    }
}

func callback(message *nats.Msg) {
	log.Print(string(message.Data))
}
```

Pub/Subモデルは単純な、一方通行のモデルなため、Subscriber側からのレスポンスが必要な場合は次のRequest/Replyモデルを使用します。

## Request/Reply

Request/ReplyモデルはほとんどPub/Subモデルですが、Subscriber側からの返事を期待する、という点が違います。メッセージ送信の際に一緒に渡されるSubjectに対してSubscriberが返事を送信するという形で実装します。
Goクライアントの場合、Subscriber側はcallback関数内で返信を返すように実装するという他は大きな違いはありません。
一方Publisher側は返信を待つため、`*nats.Conn.Request`関数を使用します。

次にサンプルコードを示します。

### Request

``` go
package main

import (
	"log"
	"time"

	nats "github.com/nats-io/go-nats"
)

func main() {
	nc, err := nats.Connect("localhost:4222")
	if err != nil {
		log.Fatal(err)
	}
	defer nc.Close()

	msg, err := nc.Request("subjectFoo", []byte("bodyBar"), 10*time.Second)
	if err != nil {
		log.Fatal(err)
	}
	log.Print(string(msg.Data))
}
```

### Reply

``` go
package main

import (
	"log"

	nats "github.com/nats-io/go-nats"
)

func main() {
	nc, err := nats.Connect("localhost:4222")
	if err != nil {
		log.Fatal(err)
	}
	defer nc.Close()

	if _, err := nc.Subscribe("subjectFoo", callback); err != nil {
		log.Fatal(err)
	}
	ch := make(chan struct{})
	<-ch
}

func callback(message *nats.Msg) {
	log.Print(string(message.Data))
	nc, err := nats.Connect("localhost:4222")
	if err != nil {
		log.Fatal(err)
	}
	defer nc.Close()
	nc.Publish(message.Reply, []byte("ReplyBaz"))
}
```

Pub/Subモデル同様、受け取り側をあらかじめ起動してから送信側を起動します。
受信側で送信されたメッセージ("bodyBar")が、送信側で返信("ReplyBaz")が表示されるはずです。

この実装では、複数のクライアントがいる場合は最初に届いた返信のみが採用されます。
複数のクライアントからの返信すべてに対応したい場合は、次のように`*nats.Conn.NewRespInbox`を使用します。

* Request(for multiple client)

``` go
package main

import (
	"log"

	nats "github.com/nats-io/go-nats"
)

func main() {
	nc, err := nats.Connect("localhost:4222")
	if err != nil {
		log.Fatal(err)
	}
	defer nc.Close()

	inbox := nc.NewRespInbox()
	if err := nc.PublishRequest("subjectFoo", inbox, []byte("bodyBar")); err != nil {
		log.Fatal(err)
	}
	if _, err := nc.Subscribe(inbox, callback); err != nil {
		log.Fatal(err)
	}
	ch := make(chan struct{})
	<-ch
}

func callback(message *nats.Msg) {
	log.Print(string(message.Data))
}
```

`*nats.Conn.NewRespInbox`は返信用に使用できるSubjectを生成して返します。これを`*nats.Conn.PublishRequest`に渡して返信を待ち受けます。

## お片付け

``` shell
$ docker stop nats
```



