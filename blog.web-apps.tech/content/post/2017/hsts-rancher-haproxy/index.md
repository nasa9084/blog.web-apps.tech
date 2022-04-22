---
author: nasa9084
categories:
- rancher
- haproxy
- hsts
- reverse proxy
- load balancer
date: "2017-09-02T16:49:12Z"
description: ""
draft: false
cover:
  image: images/rancher.png
slug: hsts-rancher-haproxy
summary: |-
  HSTSはHTTP Strict Transport Securityの略で、HTTPでの接続を強制的にHTTPSへと変更するようウェブブラウザへ伝達するセキュリティ機構です。
  Rancher-HAProxyでロードバランシングしている場合にもHSTSを使えるように設定してみました。
tags:
- rancher
- haproxy
- hsts
- reverse proxy
- load balancer
title: Rancher-HAProxyでHSTSを設定する
---


HSTSはHTTP Strict Transport Securityの略で、HTTPでの接続を強制的にHTTPSへと変更するようウェブブラウザへ伝達するセキュリティ機構です。

最近ではウェブサービスはHTTPS化して当然という流れになってきています。
このブログは現在Rancher上で管理されています。フロントエンドのHTTP/HTTPSロードバランサとしてRancher-HAProxyを使用しており、HSTSを設定するのに難儀したのでメモを残しておきます。

HSTSを設定するには、HTTPレスポンスヘッダに以下を含めます。

```
Strict-Transport-Security:max-age=有効期間秒数;
```

`max-age`で指定された期間の間、ブラウザは必ずHTTPSで通信するようになります。

扨、これを実際にRancher-HAProxyに設定するには、Rancher-HAProxyの設定ページで、`Custom haproxy.cfg`の欄に以下のように記述します。

```
backend 80
http-response set-header Strict-Transport-Security max-age=16000000;
```

改行も必要なようです。[HSTS on HAProxy · Issue #4443 · rancher/rancher · GitHub](https://github.com/rancher/rancher/issues/4443)には改行なしで書かれていたので、ハマりました。

