---
author: nasa9084
categories:
- golang
- net/smtp
date: "2020-04-06T10:13:42Z"
description: ""
draft: false
cover:
  image: images/gopher.png
slug: go-smtp-sendmail-without-mailserver
tags:
- golang
- net/smtp
title: Goで(メールサーバを用意せずに)メールを送る
---


単純な興味というか、特にこれで何かを作るというわけではないのだけれど、ふと思い立って調べてみたら意外と情報が無かったのでメモを残しておきます。

Goでメールを送りたい、と思ったとき、Googleで検索してみると、[net/smtp](https://pkg.go.dev/net/smtp)パッケージを使ってgmailのSMTPサーバを使用する、とかSendGridを使用する、とかそういった例ばかりが目につきました。これらはもちろん便利であることは疑いようもない(自前でメールサーバの管理とかやってられないし)んですけど、こういったSMTPサーバやらsendmail/postfixやらを使わなくても、本来SMTPではメールを簡単に送れるはず(なんと言っても「Simple Mail Transfer Protocol」ですから)、と思いました。
とはいえじゃぁどうしたら良いのか、と思ったとき、Goを用いた例というのはぱっと見当たらないのです。仕方ないのでtelnetを使用した例を見ながら、telnetでどうやれば自分のgmail宛てにメールが送れるのか、というのを試しました。

具体的な手順というのは、次の様なものです。なお、以下の手順では(macにtelnetが入っておらずインストールして環境がごちゃごちゃするのも面倒だったので)centos:7のDockerコンテナを使用しています。

```
# nslookup -type=mx gmail.com
Server:         192.168.65.1
Address:        192.168.65.1#53

Non-authoritative answer:
gmail.com       mail exchanger = 20 alt2.gmail-smtp-in.l.google.com.
gmail.com       mail exchanger = 10 alt1.gmail-smtp-in.l.google.com.
gmail.com       mail exchanger = 40 alt4.gmail-smtp-in.l.google.com.
gmail.com       mail exchanger = 5 gmail-smtp-in.l.google.com.
gmail.com       mail exchanger = 30 alt3.gmail-smtp-in.l.google.com.

Authoritative answers can be found from:

# telnet gmail-smtp-in.l.google.com 25
Trying 74.125.204.26...
Connected to gmail-smtp-in.l.google.com.
Escape character is '^]'.
220 mx.google.com ESMTP 6si12301456pjb.7 - gsmtp
HELO smtp.gmail.com
250 mx.google.com at your service
MAIL FROM:<nasa9084@example.com>
250 2.1.0 OK 6si12301456pjb.7 - gsmtp
RCPT TO:<XXXXXXXXXX@gmail.com>
250 2.1.5 OK 6si12301456pjb.7 - gsmtp
DATA
354  Go ahead 6si12301456pjb.7 - gsmtp
Subject: Test via telnet
From: nasa9084
To: nasa9084.gmail

Hello, world
.
250 2.0.0 OK  1586166529 6si12301456pjb.7 - gsmtp
QUIT
221 2.0.0 closing connection 6si12301456pjb.7 - gsmtp
Connection closed by foreign host.
```

無事自分のgmailアカウントにメールが届きました。この手順をGoでやってみます。

```
const body = `From: nasa9084@example.com
To: XXXXXXXXXX@gmail.com

test mail
`

func main() {
	mxs, err := net.LookupMX("gmail.com")
	if err != nil {
		log.Fatal(err)
	}
	c, err := smtp.Dial(fmt.Sprintf("%s:25", mxs[0].Host))
	if err != nil {
		log.Fatal(err)
	}
	if err := c.Mail("nasa9084@example.com"); err != nil {
		log.Fatal(err)
	}
	if err := c.Rcpt("XXXXXXXXXX@gmail.com"); err != nil {
		log.Fatal(err)
	}
	wc, err := c.Data()
	if err != nil {
		log.Fatal(err)
	}
	if _, err = fmt.Fprintf(wc, body); err != nil {
		log.Fatal(err)
	}
	if err := wc.Close(); err != nil {
		log.Fatal(err)
	}
	if err := c.Quit(); err != nil {
		log.Fatal(err)
	}
}
```

これで無事送ることができました。

最初Goでnet/smtpでやれるじゃん！って思ってやり始めたときは送れなかったんですけど、telnetでやってみてわかったのは、`smtp.Dial()`はMXレコードの解決等を行ってくれないので予め自分で解決しておく必要がある、というところが個人的はまりポイントでした。

まぁ、わかってみたら特に難しいことはないですね。



