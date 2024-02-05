---
author: nasa9084
date: "2018-09-16T17:06:14Z"
cover:
  image: images/nginx.png
  relative: true
slug: configure-ingress-nginx
tags:
  - ingress-nginx
  - nginx
  - kubernetes
  - Ingress
title: ingress-nginxで諸々設定する
---


[ingress-nginx](https://github.com/kubernetes/ingress-nginx)を使用している際に、nginxに何か設定をしたいと思ったとき。
例えば、nginxは初期状態では、アップロードできるファイルの上限は1MBなのですが、これをもっと大きくしたいとき、nginxでは次のように設定します。

``` conf
client-max-body-size    5m;
```

これをingress-nginxでも設定したいと思ったとき、どうしたら良いか。

まぁ、簡単な話で、[annotation](https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/)で設定値を与えてあげれば良いです。
この場合だと、次のようにします。

``` yaml
metadata:
  annotations:
    nginx.ingress.kubernetes.io/proxy-body-size: 5m
```

設定できる値は[ingress-nginxのドキュメント](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations/)に記載されています。
`client-max-body-size`を指定するのに`proxy-body-size`と設定することに注意です。



