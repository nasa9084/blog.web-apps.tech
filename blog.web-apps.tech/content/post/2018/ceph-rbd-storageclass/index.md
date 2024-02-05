---
author: nasa9084
date: "2018-10-23T07:08:35Z"
description: ""
cover:
  image: images/ceph_logo.png
  relative: true
slug: ceph-rbd-storageclass
tags:
  - kubernetes
  - ceph rbd
  - ceph
  - storageclass
  - persistent volume
  - cluster
title: Ceph RBDをKubernetesのStorageClassとして登録する
---


Kubernetesで何らかの永続データを保存する場合、通常PersistentVolumeと呼ばれる永続ストレージを使用します。Persistent VolumeはNFSなどのネットワークストレージを直接指定することもできますが、ボリュームを手動で用意する必要があり、非常に面倒です。
そのため、ブロックストレージサービスをバックエンドとしてdynamic provisioningと呼ばれる、自動でボリュームを作成する機能も用意されています。

dynamic provisioningを使用する場合、バックエンドのprovisionerをStorageClassと呼ばれるリソースに登録しておきます。クラウドでKubernetesを使用している場合はAWS EBSなどを使用するでしょう。

オンプレミスや自宅でKubernetesを使用している場合、GlusterFSやCeph RBDを使用することができます。今回はCephを使用してPersistentVolumeを作成するまでの流れを説明しましょう。

## 下準備

今回はOpenNebula上にCentOS 7のVM(2GB RAM/1Core CPU)を3台用意し、構築を行いました。バージョンはmimicです。`/dev/vdb`にCeph用のディスクがあるとします。
それぞれ、Chronyで時刻同期の設定、firewalld無効化、SELinux無効化状態で構成しました(本番ではちゃんと設定してくださいね！)。
また、`ceph-1` `ceph-2` `ceph-3`という名称でアクセスできるよう、hostsファイルを書いて、SSHの鍵もコピーしました。

## インストール

まずは[公式サイト](http://docs.ceph.com/docs/mimic/install/get-packages/)を参考に各サーバへリポジトリの追加をします。

``` shell
/root@ceph-N# rpm --import 'https://download.ceph.com/keys/release.asc'
/root@ceph-N# cat < EOF > /etc/repos.d/ceph.repo
[ceph]
name=Ceph packages for $basearch
baseurl=https://download.ceph.com/rpm-mimic/el7/$basearch
enabled=1
priority=2
gpgcheck=1
gpgkey=https://download.ceph.com/keys/release.asc

[ceph-noarch]
name=Ceph noarch packages
baseurl=https://download.ceph.com/rpm-mimic/el7/noarch
enabled=1
priority=2
gpgcheck=1
gpgkey=https://download.ceph.com/keys/release.asc

[ceph-source]
name=Ceph source packages
baseurl=https://download.ceph.com/rpm-mimic/el7/SRPMS
enabled=0
priority=2
gpgcheck=1
gpgkey=https://download.ceph.com/keys/release.asc
EOF
```

リポジトリの追加ができたら、各サーバへ`ceph-deploy`をインストールします。

``` shell
/root@ceph-N# mkdir ceph
/root@ceph-N# cd ceph
/root/ceph@ceph-N# yum install -y ceph-deploy
```

ここまではすべてのサーバに対し実行します。ansibleなどを使っても良いでしょう。
そして、ここからは`ceph-1`のみで実施します。

各サーバをOSDノードとして登録します。

``` shell
/root/ceph@ceph-1# ceph-deploy new ceph-1 ceph-2 ceph-3
```

ネットワークに関する記述を設定ファイルに追記します。ネットワークに合わせて各自サブネットは変更してください。

``` shell
/root/ceph@ceph-1# echo "public network = 192.168.1.0/24" >> ceph.conf
```

いよいよインストールです！

```shell
/root/ceph@ceph-1# ceph-deploy install --release mimic ceph-1 ceph-2 ceph-3
```

途中で止まらず実行できたらインストール完了です。

## インストール後処理

インストール後にやっておく処理がいくつかあるのでやっておきます。

``` shell
/root/ceph@ceph-1# ceph-deploy mon create-initial
/root/ceph@ceph-1# ceph-deploy admin ceph-1 ceph-2 ceph-3
/root/ceph@ceph-1# ceph-deploy osd create ceph-1 --data /dev/vdb && \
ceph-deploy osd create ceph-2 --data /dev/vdb && \
ceph-deploy osd create ceph-3 --data /dev/vdb
/root/ceph@ceph-1# mkdir /var/lib/ceph/mgr/ceph-admin
/root/ceph@ceph-1# touch /var/lib/ceph/mgr/ceph-admin/keyring
/root/ceph@ceph-1# ceph --cluster ceph auth get-or-create mgr.admin mon 'allow profile mgr' osd 'allow *' mds 'allow *' >> /var/lib/ceph/mgr/ceph-admin/keyring
/root/ceph@ceph-1# ceph-mgr -i admin
```

以上でCephクラスタの構築は完了です！

## StorageClassとして設定

続いて、StorageClassとして設定します。まずはノードの設定からです。CephをPersistentVolumeとして使うには、各ノードにCephのドライバが入っている必要があります。インストールの節を参考にリポジトリを追加したあと、次のようにします。

``` shell
/root@kube-node-N# yum install -y ceph-common
```

CephにKubernetes用のpoolを作成します。

``` shell
/root@ceph-1# ceph osd pool create kube 1024
/root@ceph-1# ceph auth get-or-create client.kube mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=kube' -o ceph.client.kube.keyring
```

認証情報を取得します。

``` shell
/root@ceph-1# ceph auth get-key client.admin | base64
/root@ceph-1# ceph auth get-key client.kube | base64
```

取得した認証情報を使用して次のようなSecretを作成します。

``` yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: ceph-admin-secret
  namespace: kube-system
data:
  key: < insert your client.admin key >
type: kubernetes.io/rbd
---
apiVersion: v1
kind: Secret
metadata:
  name: ceph-kube-secret
  namespace: kube-system
data:
  key: < insert your client.kube key >
type: kubernetes.io/rbd
```

``` shell
/root@kube-node-1# kubectl apply -f ceph-secret.yml
```

最後に、StorageClassを作成します(YAML中の`192.168.1.x:6789`はそれぞれ`ceph-1`、`ceph-2`、 `ceph-3`のIPアドレス)。

```yaml
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ceph-rbd
provisioner: kubernetes.io/rbd
allowVolumeExpansion: true
parameters:
  monitors: 192.168.1.40:6789,192.168.1.43:6789,192.168.1.42:6789
  adminId: admin
  adminSecretName: ceph-admin-secret
  adminSecretNamespace: kube-system
  pool: kube
  userId: kube
  userSecretName: ceph-kube-secret
  userSecretNamespace: kube-system
```

``` shell
/root@kube-node-1# kubectl apply ceph-storageclass.yml
```

PersistentVolumeClaimを作成し、動作を確認します。

以上です。



