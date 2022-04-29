---
author: nasa9084
categories:
- kubernetes
- MetalLB
- cluster
- load balancer
- service
date: "2018-08-05T15:02:11Z"
description: ""
draft: false
cover:
  image: images/kubernetes.png
  relative: true
slug: type-loadbalancer_by_metallb
tags:
- kubernetes
- MetalLB
- cluster
- load balancer
- service
title: 'MetalLBを使用してオンプレでもtype: LoadBalancerを使用する'
---


## TL;DR

MetalLBを使用することでオンプレ(not on OpenStack)に構築したk8sでも`type: LoadBalancer`を使用できる

## type: LoadBalancer

[kubespray](https://github.com/kubernetes-incubator/kubespray)等を使用して、[Kubernetes](https://k8s.io)をオンプレ(on OpenStackを除く)で構築した場合、通常、[type: LoadBalancer](https://k8s.io/docs/concepts/services-networking/service/#loadbalancer)を使用することができません。これは、`type: LoadBalancer`は通常CloudProviderにより管理されており、オンプレ(on OpenStackを除く)でk8sを構築した場合にはCloudProvider連携が無いためです。

しかし、k8sを使用するからには`type: LoadBalancer`も使用したいですよね？NodePortなどで代用するにも、ポートがバラバラになってしまって面倒です。
そこで使用できるのが[MetalLB](https://metallb.universe.tf/)(GitHub: [google/metallb](https://github.com/google/metallb))です。
MetalLBを使用すると、`type LoadBalancer`の作成をフックしてアドレス割り当てとアドレスの広報を行ってくれます。

## Layer 2 mode

MetalLBにはLayer 2 mode(以下L2 mode)とBGP modeがあります。これらのモードはアドレス広報の仕方が違い、L2 modeではARP/NDPで、BGP modeではその名の通りBGPでアドレスの広報を行います。通常、自宅を含むオンプレ環境ではBGPを使用していないと思いますので、L2 modeについて解説します。

L2 modeでは、特定のノードへアクセスを集中させ、kube-proxyによって各サービスへトラフィックを分配します。そのため、実態としてはロードバランサーが実装されている訳ではないことに注意が必要です。単体ノードにアクセスが集中するため、これがボトルネックとなり得ますし、アクセスが集中することになるノードが何らかの理由でアクセスできなくなった場合、フェイルオーバーに10秒程度かかる可能性があります。

### requirements & installation

導入は非常に簡単ですが、以下の要件を満たしている必要があります。

* 他にネットワークロードバランシングの機能が無いKubernetes 1.9.0以降
* [MetalLB対応表](https://metallb.universe.tf/installation/network-addons/)に記載のあるネットワークで設定されていること

これに加え、MetalLBで使用することのできるIPv4アドレスを用意しておく必要があります。
私の環境ではk8sのノードが`192.168.1.0/24`にあるため、`192.168.1.100`から`192.168.1.159`までの60個のアドレスをMetalLB用としました。

要件を満たしていることが確認できたら、MetalLBのインストールを行います。
MetalLBをインストールするには、次のコマンドを実行します。

``` shell
$ kubectl apply -f https://raw.githubusercontent.com/google/metallb/v0.7.2/manifests/metallb.yaml
```

[Helm](https://helm.sh/)を使用してインストールすることもできますが、Chartが最新版ではないので注意しましょう。

次に、次のようなConfigMapを作成します。

``` yaml
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
    - name: default
      protocol: layer2
      addresses:
      - 192.168.1.100-192.168.1.159
```

これでMetalLBのセットアップは完了です。パブリッククラウドで使用するように、`type: LoadBalancer`を作成するとアドレスプールからIPアドレスが割り当てられ、アクセスできるようになります。
アドレスプールは複数用意することができ、特定のアドレスプールからIPを割り当てたい場合は`type: LoadBalancer`のアノテーションに`metallb.universe.tf/address-pool: <ADDRESS_POOL_NAME>`を追加します。

