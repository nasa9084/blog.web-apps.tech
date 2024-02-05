---
author: nasa9084
date: "2018-09-02T03:04:50Z"
cover:
  image: images/eks_logo.png
  relative: true
slug: eks-internal-lb
tags:
  - kubernetes
  - aws
  - eks
  - load balancer
  - service
  - ec2
title: EC2インスタンスからEKS上のアプリケーションにアクセスしたい
---


## TR;DR

* Kubernetesの`Service`で、Internal LoadBalancerってのがあるので、それを使うと良い

## Internal LoadBalancer

皆さんはEKS、もう使ってますか？私は使っています。業務システムをリプレースで新規開発する的な案件で、新システムの基盤がEKSという感じです。EKSはネットワークが素敵に気持ち悪い感じになっており、普通はKubernetesのクラスタ内部っていうのは、外側と別のサブネットを作る訳なんですが、なんとEKSが所属するVPCと同じサブネットで接続できるようになっています。

そんなわけで、同一VPCに存在したり、VPC PeeringしたりなんかしちゃってるEC2インスタンスとEKS上の`Pod`はIPアドレスベースでは普通に接続がとれちゃったりするんです。
EKS上のアプリケーションから、EC2インスタンスへアクセスしたいときは、普通にEC2インスタンスのIPアドレスやら内部エンドポイントへアクセスすれば良いですね。EC2インスタンスが動きっぱなしならまぁさほどIPも変わらんでしょう(雑)。

しかし逆は問題です。`Pod`のIPは勿論割り振られてはいますけれど、これは`Pod`が再生成されると勿論変わってしまいます。アプリケーションは動きっぱなしだから変わらない、なんて言うこともできないです。EC2インスタンスはインスタンス上でアプリケーションの更新なんかもしちゃうかもしれないですけど、EKS上の`Pod`に乗ったアプリケーションの更新は普通、`Pod`の再作成が伴います。`Pod`の再作成が起きると、勿論IPが変わります。

そうすると、やはり考えるのは`Service`をつくることですね。外部からアクセスするためにはそうしますから、同じように考えるのが普通です。
しかし、ここで問題が発生します。普通に外部向けに公開するのと同じように`Service`を作成すると、グローバルIPが当たってしまい、プライベートIPベースで接続できる状況では接続ができないのです。困った。

まぁドキュメントちゃんと読めよって話なんですが、[Kubernetesのドキュメント](https://kubernetes.io/docs/concepts/services-networking/service/)を読むと、Internal LoadBalancerってのがちゃんと書いてあります。AWSの方のドキュメントには無かったのでちょっと盲点でした。annotationで次の様に指定します。

``` yaml
# ...
metadata:
    name: my-service
    annotations:
        service.beta.kubernetes.io/aws-load-balancer-internal: 0.0.0.0/0
# ...
```

これだけで、`type: LoadBalancer`で作成されるELBが内部向けのものになります。internal-なんちゃらみたいなエンドポイントです。IPアドレスもしっかりプライベートIPです。最高。後ろの`0.0.0.0/0`のところで、アクセスできるIPレンジ制限できるのかなーなんて希望的観測を持ちましたが、全然関係ありませんでした。
ちょっと気持ち悪いのは、普通にパブリックDNSで名前引きができてしまうことですかね。全然関係ない外部のネットワークとかでも(パブリックDNSに名前があるので)名前解決ができてしまって、かつプライベートのアドレスが帰って来るという不思議な体験をすることができます。

``` shell
$ nslookup internal-xxxxx.us-west-2.elb.amazonaws.com 1.1.1.1
Server:		1.1.1.1
Address:	1.1.1.1#53

Non-authoritative answer:
Name:	internal-xxxxx.us-west-2.elb.amazonaws.com
Address: 192.168.187.214
Name:	internal-xxxxx.us-west-2.elb.amazonaws.com
Address: 192.168.222.128
Name:	internal-xxxxx.us-west-2.elb.amazonaws.com
Address: 192.168.109.84
```

うーん、まぁ実害は無いんでしょうけど。

