---
author: nasa9084
date: "2017-11-30T09:04:06Z"
cover:
  image: images/kubernetes.png
  relative: true
slug: deploy-k8s-cluster-using-kubespray
tags:
  - kubernetes
  - docker
  - kubespray
  - ansible
  - cluster
title: kubesprayを使用してkubernetes clusterを構築する
---


**注意: 情報が古くなっています。[新しい情報にあわせて記事を書いた](/deploy-k8s-with-kubespray-2/)ので、そちらをご覧ください。**

[kubespray](https://github.com/kubernetes-incubator/kubespray)はproduction readyなkubernetes(k8s)クラスタを構成できるツールです。
[Ansible](https://www.ansible.com/)をベースに作られているため、任意のサーバでk8sクラスタを構成できます。

今回は、3台のVMを用意してクラスタを構成してみます[^vsphere]。

## 検証環境

今回用意したVMは以下の構成です。
- 2Core
- 8GB RAM
- 80GB HDD
- CentOS 7

IPアドレスは以下の様になっているものとします。
- 192.168.1.11
- 192.168.1.12
- 192.168.1.13

また、kubesprayを実行するローカルの環境はmacOS Sierraです。
各ホストのrootユーザに対してSSH鍵は配置済み、firewalldは無効化されているとします。

## requirements

実行する環境に、[Ansible](https://www.ansible.com/)が必要なため、`pip`でインストールします。[^py2][^venv]

``` shell
$ pip install ansible
```

## install kubespray-cli

kubespray自体も`pip`でインストールします。

``` shell
$ pip install kubespray
```

## prepare

設定ファイルを生成するため、`kubespray prepare`を使用します。

``` shell
$ kubespray prepare --nodes node1[ansible_ssh_host=192.168.1.11] node2[ansible_ssh_host=192.168.1.12] node3[ansible_ssh_host=192.168.1.13]
```

## deploy

以下のコマンドでk8sクラスタをデプロイします。

``` shell
$ kubespray deploy -u root -n flannel
```

今回は[`flannel`](https://github.com/coreos/flannel)ネットワークプラグインで構成しました。
kubesprayは、次のネットワークプラグインを使用してクラスタを構成することができます。

- [flannel](https://github.com/coreos/flannel)[^flannel]
- [calico](https://www.projectcalico.org/)[^calico]
- [canal](https://github.com/projectcalico/canal)
- [contiv](http://contiv.github.io/)[^contiv]
- [weave](https://www.weave.works/)[^weave]

あとは構成が終了するのを待つだけです。

[^vsphere]: [vmware vSphere](https://www.vmware.com/jp/products/vsphere.html)上に作成しました
[^py2]: 最初、Python 3でkubesprayを実行しようとしたところ、`raw_input`を使っているようで、上手くいきませんでした。Python 2で実行します
[^venv]: 私は一応`venv`を挟みました
[^flannel]: https://github.com/kubernetes-incubator/kubespray/blob/master/docs/flannel.md
[^calico]: https://github.com/kubernetes-incubator/kubespray/blob/master/docs/calico.md
[^contiv]: https://github.com/kubernetes-incubator/kubespray/blob/master/docs/contiv.md
[^weave]: https://github.com/kubernetes-incubator/kubespray/blob/master/docs/weave.md

