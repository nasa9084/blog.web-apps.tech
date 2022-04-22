---
author: nasa9084
categories:
- docker
- docker-machine
- rancher
- rancheros
date: "2017-08-24T02:14:41Z"
description: ""
draft: false
cover:
  image: images/rancheros.png
slug: docker-machine-with-rancheros
tags:
- docker
- docker-machine
- rancher
- rancheros
title: docker-machineでRancherOSを使う
---


# docker-machineとそのメリット

[docker-machine](https://docs.docker.com/machine/)は仮想マシン上に[Docker Engine](https://docs.docker.com/engine/)をインストールするツールです。
`docker-machine`コマンドを使用することで、Dockerホストを作成・管理することが可能です。
docker-machineを使用してDockerホストを作成すると、

``` bash
$ docker-machine env <MACHINE_NAME>
```

でシェル評価可能なDocker接続情報を得ることができ、

``` bash
$ eval $(docker-machine env <MACHINE_NAME>)
```

とすることにより、そのセッション内ではあたかもローカル環境のDockerの様にコンテナを操作することが可能となります。

# docker-machineで使用するOS

扨、通常docker-machineでDockerホストを作成すると、インストールされるOSは[Boot2Docker](http://boot2docker.io/)ですが、docker-machineでは、ホスト作成時のコマンドラインオプションでisoイメージやシェルスクリプトを指定することでOSやDocker Engineのバージョンを変更することができます。

## RancherOS

Boot2Dockerに類似したOSとして、[RancherOS](http://rancher.com/rancher-os/)があり、`ros`コマンドを使用することでインストール後でもDockerのバージョンを簡単に切り替えることができます。

RancherOSは以前、仮想マシン環境のサポートとして、[Vagrant](https://github.com/rancher/os-vagrant)用の環境を提供していましたが、現在(2017年8月)では、すでにサポートが終了しており、docker-machineを使用するようにというアナウンスが出ています。

そこで、今回はdocker-machineを使用してRancherOSを立ちあげてみようと思います。

# docker-machineでRancherOSを立ちあげる

[公式ドキュメント](http://rancher.com/docs/os/v1.0/en/running-rancheros/workstation/docker-machine/)上に示されたコマンドをそのまま使用しても、途中でエラーが出てしまい(エラーが出ること自体は記述されていますが)、docker-machineをの大きなメリットである、`docker-machine env`が使用できません。

エラーを回避するためには、[Rancherのリポジトリ上にあるインストールスクリプト](https://github.com/rancher/install-docker)を指定します。

``` bash
$ docker-machine create -d virtualbox --virtualbox-boot2docker-url https://releases.rancher.com/os/latest/rancheros.iso --engine-install-url https://raw.githubusercontent.com/rancher/install-docker/master/17.06.sh
```

インストールが完了したら、`docker-machine ls`コマンドで実行中のDockerホストの一覧を表示することができます。

``` bash
$ docker-machine ls
NAME   ACTIVE   DRIVER       STATE     URL                         SWARM   DOCKER        ERRORS
ros    -        virtualbox   Running   tcp://192.168.99.100:2376           v17.06.0-ce
```

# Docker Engineのバージョンを切り替える

せっかくRancherOSを使用しているので、Docker Engineのバージョンを切り替えてみましょう。
Docker Engineのバージョンを切り替えるにはRancherOS上で`ros`コマンドを使用するのでした。

RancherOSはdocker-machineで作成されたVM上で動作していますので、以下のコマンドを用いてログインします。

``` bash
$ docker-machine ssh <RANCHEROS_VM_NAME>
```

Vagrantを使用したことがある方はなじみやすいかもしれません。
SSHログインできたら、以下のコマンドで使用可能なDocker Engineのリストを表示します。

``` bash
$ sudo ros engine list
disabled docker-1.10.3
disabled docker-1.11.2
disabled docker-1.12.6
disabled docker-1.13.1
disabled docker-17.03.1-ce
disabled docker-17.04.0-ce
disabled docker-17.05.0-ce
current  docker-17.06.0-ce
```

`disabled`と表示されているものが使用可能なDockerのバージョン、`current`と表示されているものが現在使用中のDockerのバージョンです。
今回は、1.12.6に変更してみましょう([Kubernetes](https://kubernetes.io/)がサポートしているバージョンです))
Dockerのバージョンを切り替えるには、以下のコマンドを使用します。

``` bash
$ sudo ros engine switch <DOCKER_VERSION>
```

今回は1.12.6に変更したいため、以下の様にします。

``` bash
$ sudo ros engine switch docker-1.12.6
```

実行し終わり、`docker version`コマンドでバージョンが変更されたことを確認されたら、`CTRL-d`でログアウトし、`docker-machine ls`でもバージョンを見てみましょう。

``` bash
$ docker-machine ls
NAME   ACTIVE   DRIVER       STATE     URL                         SWARM   DOCKER    ERRORS
ros    -        virtualbox   Running   tcp://192.168.99.100:2376           v1.12.6
```

docker-machineから見えているバージョンもきちんと変更されていることがわかりました。

# まとめ
docker-machineを使用することで、ローカル環境に簡単に複数のDockerホストを作成することができます。docker-machineにはドライバを選択するオプションもあり、[Virtualbox](https://www.virtualbox.org/)以外にも[vmware fusion](https://www.vmware.com/jp/products/fusion.html)、[xhyve](https://github.com/mist64/xhyve)/[hyperkit](https://github.com/moby/hyperkit)などのローカル仮想マシン環境、[Amazon Web Service](https://aws.amazon.com/jp/ec2/)や[Microsoft Azure](https://azure.microsoft.com/ja-jp/)、[Google Cloud Platform](https://cloud.google.com/?hl=ja)などのクラウド環境にDockerホストを構築することも可能です。

