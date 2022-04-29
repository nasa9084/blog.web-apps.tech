---
author: nasa9084
categories:
- kubernetes
- load balancer
- service
- Ingress
- ingress-nginx
- letsencrypt
- tls
- reverse proxy
- kubespray
- nginx
date: "2018-08-06T05:37:02Z"
description: ""
draft: false
cover:
  image: images/kubernetes_logo-1.png
  relative: true
slug: ingress-nginx-on-prem
tags:
- kubernetes
- load balancer
- service
- Ingress
- ingress-nginx
- letsencrypt
- tls
- reverse proxy
- kubespray
- nginx
title: ingress-nginxを使用してオンプレでもIngressを使用する
---


## TL;DR

* ingress-nginxを使用するとオンプレでも`Ingress`を使用出来る
* MetalLBと組み合わせる

## Ingress

Ingressは[Kubernetes](https://k8s.io)の機能の一つで、L7 LoadBalancerの機能を持ちます。[先日紹介した](/type-loadbalancer_by_metallb/)`type LoadBalancer`は、L4 LoadBalancerで、クラスタ内のDNSで名前解決をし、IP制限などをすることが出来ます。それに対し、`Ingress`では、HTTPSの終端となることが出来、ホスト名ベース・パスベースのルーティングを行うことが出来ます。

通常、オンプレでKubernetesを構築した場合、Ingress Controllerと呼ばれる、Ingressを作成する機能が無いために`Ingress`を使用することが出来ません。
しかし、折角Kubernetesを使用しているのに、ホスト名ベースのルーティングをクラスタ外のロードバランサーに設定するのは面倒です。
どうせなら`Ingress`、使いたいですね？

そこで使用できるのが[ingress-nginx](https://kubernetes.github.io/ingress-nginx/)(GitHub: [kubernetes/ingress-nginx](https://github.com/kubernetes/ingress-nginx))です。ingress-nginxはその名のとおり、nginxを使用したIngress Controllerです。`Ingress`リソースの作成時に、nginxの設定を`ConfigMap`として保存することで`Ingress`の作成を実現します。

## Install

[MetalLBをインストール](/type-loadbalancer_by_metallb/)している場合、次の二つのコマンドを実行することでインストールできます。

``` shell
$ kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/mandatory.yaml
$ kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/provider/cloud-generic.yaml
```

二行目のコマンドは[ドキュメント上では](https://kubernetes.github.io/ingress-nginx/deploy/)docker for macのコマンドとして記載されていますが、`type: LoadBalancer`が使用できるクラスタ一般で使用できます。

インストールが完了したら、ingress-nginxのサービスにIPアドレスが割当たります。

``` shell
$ kubectl get svc -n ingress-nginx
NAME                   TYPE           CLUSTER-IP      EXTERNAL-IP     PORT(S)                      AGE
default-http-backend   ClusterIP      10.233.50.56    <none>          80/TCP                       2d
ingress-nginx          LoadBalancer   10.233.47.246   192.168.1.100   80:30431/TCP,443:30017/TCP   2d
```

実際にブラウザでingress-nginxのIPアドレスにアクセスしてみて、**default backend - 404**と表示されれば正常に動作しています。

ルーターからKubernetes上のサービスに直通で問題ない(`Ingress`でHTTPS終端なども行う)場合、ルーターのNAT/NAPT設定で、80/443番ポートの行き先をこのIPアドレスとします。

クラスタ外のLAN内に別のサービスも存在し、別途ロードバランサーなどで振り分けを行っている場合、ワイルドカードを使用してこのIPアドレスへ振り分けるのがお勧めです(nginxでは、ワイルドカードより、正確にマッチした方のルールを優先するため、設定されていない場合にKubernetesへトラフィックが流れることとなります)。

弊宅では、ルーターから80/443でアクセスされるnginxに次の様に設定しています。

```
server {
	listen	80;
	server_name	*.web-apps.tech;

	location / {
		return 301 https://$host$request_uri;
	}
}

server {
	listen 443;
	server_name	*.web-apps.tech;

	ssl on;
	ssl_certificate /etc/letsencrypt/live/web-apps.tech/fullchain.pem;
	ssl_certificate_key /etc/letsencrypt/live/web-apps.tech/privkey.pem;
	ssl_protocols TLSv1 TLSv1.1 TLSv1.2;

	location / {
		proxy_pass	http://192.168.1.100;
		proxy_set_header Upgrade $http_upgrade;
		proxy_set_header Connection "upgrade";
		proxy_set_header host $host;
		proxy_set_header X-Forwarded-Host $host;
		proxy_set_header X-Forwarded-Proto $scheme;

		# HSTS config
		add_header Strict-Transport-Security 'max-age=31536000; includeSubDomains';
	}
}
```

DNSは[Cloudflare](https://www.cloudflare.com/ja-jp/)を使用しており、Let's Encryptのワイルドカード証明書を取得して適用しています。
ワイルドカード証明書を使用することで、ingress-nginxでHTTPS終端をしていませんが、`Ingress`を作成した時点から証明書の設定などをすること無く、常にHTTPSで通信をすることが出来ています。

