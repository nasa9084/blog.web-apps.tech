---
author: nasa9084
categories:
- openstack
- kolla
- ansible
- ocata
date: "2017-10-04T06:12:37Z"
description: ""
draft: false
cover:
  image: images/OpenStack_logo.png
slug: kolla-ansible-ocata
summary: |-
  OpenStack Kollaを用いると、比較的簡単にOpenStack on Docker環境を構築することができます。
  今回はKolla-Ansibleを使用してall-in-one構成で4.0.0(Ocata)環境を構築してみます。
tags:
- openstack
- kolla
- ansible
- ocata
title: Kolla-AnsibleでOpenStack Ocata環境を構築する
---


OpenStack Kollaを用いると、比較的簡単にOpenStack on Docker環境を構築することができます。
今回はKolla-Ansibleを使用してall-in-one構成で4.0.0(Ocata)環境を構築してみます。
基本的な手順は[公式ドキュメント](https://docs.openstack.org/kolla-ansible/latest/user/quickstart.html)に沿っています。

## VMを用意する

まず、VMを一台用意します。勿論物理マシンでもかまいません。
要件は以下の様になっています。

* 2 Network Interfaces
* 8GB or more RAM
* 40GB or more free Disk Space

今回はvmware vSphere上にCentOS 7の仮想マシンを作製しました。
2つのNetwork Interfaceのうち、片方はIPを持っている状態(Activated)、片方はIPを持っていない状態(Deactivated)にします。
CentOS 7の場合、`nmtui`等を使用すると簡単にActivate/Deactivateできます。

今回はActivatedされているNetwork Interfaceの名前を`ens160`でIPを`192.168.1.10/24`、Deactivateされている方の名前を`ens192`とします。

予め、`ip a`コマンドでどちらのインターフェースも状態がUPになっていることを確認しておきます。
(DOWNになっている場合は`ip link set ens192 up`などとしてUPにする)

また、今回は簡単のため、firewalldを無効化しておきます。

```
$ sudo systemctl stop firewalld
$ sudo systemctl disable firewalld
```

## 依存するライブラリ等を導入する

Kolla-Ansibleの実行に必要なライブラリ・ソフトウェアを導入していきます。

### pipの導入

[Ansible](https://www.ansible.com/)はPythonで書かれたソフトウェアです。Ansibleをインストールするため、Pythonのパッケージ管理ツールであるpipを導入します。
CentOSの場合、以下の手順で導入可能です(諸般の事情により、Pythonが2系であることには目を瞑ります)。

```
# yum install epel-release
# yum install python-pip
# pip install -U pip        # pipを最新版にアップグレード
```

また、pipでパッケージをビルドするのに必要ないくつかの依存ライブラリを導入しておきます。

```
# yum install python-devel libffi-devel gcc openssl-devel libselinux-python
```

### Ansibleのインストール

Ansibleをインストールします。
Kolla-AnsibleでOcata環境を構築するために必要な最小バージョンのAnsibleは`2.0.0`であり、[Kolla-ansible precheckで発生するエラーの対処](/kolla-ansible-precheck-error)に記載のあるように最新バージョンのAnsibleではエラーが発生します。
エラーを回避するため、以下の様にAnsibleをインストールします。

```
# pip install ansible==2.2
```

上記コマンドにより、Ansible 2.2系がインストールされます。

### Dockerのインストール

```
# curl -sSL https://get.docker.io | bash
```

を実行します。
実行後、正常にインストールができたか確認するには、

```
# docker --version
```

を実行して、最新のDockerがインストールされていることを確認します。

#### dockerの設定

以下のコマンドで設定を追加します。

```
# mkdir -p /etc/systemd/system/docker.service.d

# tee /etc/systemd/system/docker.service.d/kolla.conf <<-'EOF'
[Service]
MountFlags=shared
EOF

# systemctl daemon-reload

# systemctl restart docker
```

#### docker pythonライブラリのインストール

pythonからdockerを操作するため、ライブラリをインストールします

```
# pip install -U docker
```

### NTPの導入

OpenStackはRabbitMQとCephが正常に動作するために、正確な時間の同期が必要です。
そのため、NTP導入します。

```
# yum install ntp
# systemctl enable ntpd.service
# systemctl start ntpd.service
```

### libvirtdを停止する

libvirtdが動作している場合、以下のコマンドで停止します。

```
# systemctl stop libvirtd.service
# systemctl disable libvirtd.service
```

## Kolla-Ansibleをインストールする

ようやくKolla-Ansibleそのものの導入に移ります。
Kolla-Ansibleはpipでインストールできますので、以下のコマンドでインストールします。
現時点[^1]で、5.0.0(Pike)のインストールは正常に行うことができませんので、4.0.0(Ocata)のインストールを行います。

```
# pip install kolla-ansible==4.0.0
```

インストールが完了すると、コンフィグ例もインストールされていますので、コンフィグを置くべきディレクトリにコピーします。

```
cp -r /usr/share/kolla-ansible/etc_examples/kolla /etc/kolla/
cp /usr/share/kolla-ansible/ansible/inventory/* .
```

### Kolla-Ansibleの設定を行う

Kolla-Ansibleの設定を行います。
お好みのエディタで`/etc/kolla/globals.yml`を開き、次の部分を編集します。

* `kolla_internal_vip_address`: 値を`192.168.1.10`とする
* `network_interface`: コメントアウトを外し、値を`ens160`とする
* `neutron_external_interface`: コメントアウトを外し、値を`ens192`とする
* `Kolla options`のすぐ下に`enable_haproxy: "no"`を追記する

編集が完了したら、次のコマンドでパスワードを生成します。

```
# kolla-genpwd
```

### novaの設定を行う

以下のコマンドでハードウェアアクセラレーションが使用できるかどうかを確認します。

```
# egrep -c '(vmx|svm)' /proc/cpuinfo
```

一般に、多重化仮想環境では0が返ることが多いと思います。
0が返ってきた場合、以下のコマンドでnovaの設定を追記します。

```
# mkdir -p /etc/kolla/config/nova
# cat << EOF > /etc/kolla/config/nova/nova-compute.conf
[libvirt]
virt_type = qemu
cpu_mode = none
EOF
```

## ImageをPullする

OpenStackのコンポーネントイメージをPullします。
Kolla-Ansibleでこれらも自動化されているため、以下のコマンドを実行すればPullできます。

```
# kolla-ansible pull -i all-in-one
```

`all-in-one`はインベントリファイルで、コンフィグ例のコピー時にカレントディレクトリにコピーされているはずです。

## Kolla-Ansibleをデプロイする

いよいよ、Kolla-Ansibleのデプロイの時間です。
まずは正常に設定できているか、プリチェックを行います。

```
# kolla-ansible prechecks -i all-in-one
```

これが通ってもデプロイが成功するとは限りませんが(悲しい)、これが通らないと確実にデプロイが失敗します。
プリチェックが問題なく成功したら、以下のコマンドでデプロイを行います！

```
# kolla-ansible deploy -i all-in-one
```

## デプロイ後の処理を行う

デプロイが成功したら、以下のコマンドで後設定を行います。

```
# kolla-ansible post-deploy
```

このコマンドで`admin-openrc.sh`が生成されるハズです。
デプロイが成功したかどうか確認するために、以下のコマンドでネットワークを初期化します。

```
# . /etc/kolla/admin-openrc.sh
# cd /usr/share/kolla-ansible
# ./init-runonce
```

### パブリックネットワークの設定を行う

以下のコマンドで、パブリックネットワークを設定します。

```
# ip addr add 10.0.2.1/24 dev br-ex
# ip link set br-ex up
# ip route add 10.0.2.0/24 dev br-ex
```

## Dashboardにアクセスする

デプロイは以上でおわりです。
Webからダッシュボードにアクセスしてみましょう。
以下のコマンドでログインパスワードを確認することができます。

```
# env | grep OS_PASSWORD
```

ブラウザから、`192.168.1.10`にアクセスし、`admin`ユーザ、上記コマンドで表示されたパスワードでログインします。

以上で、Kolla-Ansibleを使用したOpenStack Ocataのデプロイは終了です！


[^1]: 2017年10月4日現在

