---
author: nasa9084
categories:
- kubernetes
- security
- best practices
date: "2018-04-19T05:18:30Z"
description: ""
draft: false
cover:
  image: images/kubernetes.png
slug: k8s-security-best-practices-by-ianlewis
tags:
- kubernetes
- security
- best practices
title: Kubernetesのセキュリティのベストプラクティス by Ian Lewis
---


[Japan Container Days v18.04](https://containerdays.jp/)で表題のセッションを聞いたので、まとめました。

## スライド資料

[Kubernetesのセキュリティのベストプラクティス(SpeakerDeck)](https://speakerdeck.com/ianlewis/kubernetesfalsesekiyuriteifalsebesutopurakuteisu)

## APIサーバへの攻撃を防ぐ

### RBACでPodに付与される権限を絞る

Podにはシークレットが自動でマウントされるため、不正アクセスにより読み込まれてしまうと危ない

### FirewallでAPIサーバへのアクセスについてIP制限を付与する

いざ、シークレットが漏れた場合でも、APIサーバにアクセスされてしまわないように、ファイアウォールでIP制限をかけておくと良い

### NetworkPolicyでDBへの接続が許可されるPodを制限する

大体の場合、重要なデータはDBに有るため、DBへのアクセスを絞ることで安全性を上げる

#### example:

``` yaml
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:    
  name: redis
spec:
  podSelector:    
    matchLabels:
      name: redis
  ingress:
  - from:
    - podSelector: 
      matchLabels:    
        name: guestBook
```

## ホストへの攻撃を防ぐ

次の三つを併用すると良い

### non-rootユーザでPodを実行する

#### example:

``` yaml
kind: Pod
apiVersion: v1
metadata:    
  name: security-context-demo
spec:
  securityContext:
    runAsUser: 1000
```

### 読み込み専用ファイルシステムを使用する

#### example:

``` yaml
kind: Pod
apiVersion: v1
metadata:
  name: security-context-demo
spec:
  securityContext:
    readOnlyRootFilesystem: true
```

### no_new_privs

forkしたプロセスが強い権限を持てないようにする

#### example:

``` yaml
kind: Pod
apiVersion: v1
metadata:
  name: security-context-demo
spec:
  securityContext:
    allowPrivilegeEscalation: false
```

## seccomp/AppArmor/SELinux

コンテナ自体若干のセキュリティ性能はあるが、ほぼないので、seccompとAppArmor/SELinuxを使用することで、壁を増やす

### seccomp

seccomp: Linuxでプロセスのシステムコールの発行を制限する機能

dockerではseccompはデフォルトになってが、kubernetesではまだデフォルトになっていないため、dockerのポリシーを流用する

まだアルファだが、使った方が良い

#### example:

``` yaml
kind: Pod
apiVersion: v1
metadata:
  name: myPod
  annotations:
    seccomp.security.alpha.kubernetes.io/pod: runtime/default
```

### AppArmor

AppArmor: Linux Security Modulesの一つで、ネットワークアクセス、Raw socket アクセス、ファイルへの読み書き実行などの機能を制限する機能

#### example:

``` yaml
kind: Pod
apiVersion: v1
metadata:
  name: myPod
  annotations:
    container.apparmor.security.beta.kubernetes.io/hello: runtime/default
```

### SELinux

#### example:

``` yaml
kind: Pod
apiVersion: v1
metadata:
  name: myPod
spec:
  securityContext:
    seLinuxOptions:
      level: "s0:c123,c456"
```

## kubeletの権限を制限する

* RBACを設定する
    * `--authorization-mode=RBAC,Node`
    * `--admission-control=...,NodeRestriction`
* kubeletの証明書をローテートする
    * `--rotate-certificates`

## トラフィックの傍受を防ぐ

* Istioを導入する
    * サービス間のプロキシ
    * 暗号化
    * 証明書の自動更新
    * ポリシーの中央管理

