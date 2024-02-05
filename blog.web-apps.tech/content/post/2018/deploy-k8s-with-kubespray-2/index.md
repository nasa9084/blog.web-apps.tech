---
author: nasa9084
date: "2018-02-23T14:45:49Z"
description: ""
draft: false
cover:
  image: images/kubernetes.png
  relative: true
slug: deploy-k8s-with-kubespray-2
tags:
  - kubernetes
  - kubespray
  - docker
  - ansible
  - cluster
title: kubesprayを使用してkubernetes clusterを構築する(2)
---


3ヶ月ほど前に、[kubesprayを使用してkubernetes clusterを構築する](/deploy-k8s-cluster-using-kubespray/)という、[kubespray](https://kubespray.io/)とkubespray-cliを使用してKubernetesクラスタを構築する記事を書きました。
しかし、kubespray-cliはすでに[deprecatedだということなので](https://github.com/kubernetes-incubator/kubespray/commit/1869aa39859bff4d27bf1337c1352fd383e980a5)、kubespray-cliを使用せずにkubesprayでクラスタを構築する手順をまとめておきます。

## 要件

kubesprayを使用してkubernetesクラスタを構築するための要件は以下のようになっています。

* ansible 2.4以降とpython-netaddr (python-netaddrを忘れがちなので注意)
    * `pip install ansible netaddr`
* Jinja 2.9以降(ansibleの依存でインストールされると思います)
* 構築先サーバがインターネットに接続できること
* 構築先サーバでswapが無効化されていること
* 構築先サーバでIPv4 forwardingが有効になっていること
    * `sysctl -w net.ipv4.ip_forward=1`する(再起動するまで)
    * `/etc/sysctl.conf`に`net.ipv4.ip_forward = 1`と記入する(再起動後)
* Ansibleを実行するマシンから構築先サーバにSSH鍵が渡されていること
* ファイアウォールが無効化されていること
    * ファイアウォールの設定をしっかりできる人は有効でも

また、kubesprayには(kubespray-cliのような)inventory生成ツールが付属されており、これを利用する場合はpython3系である必要が有ります。

## 構成

前回の記事同様、以下のIPを持った三台のサーバを対象として構築してみます。

* 192.168.1.11
* 192.168.1.12
* 192.168.1.13

それぞれ、IPv4 forwardingが有効化され、firewalldを無効化し、Python 3をインストール済みのCentOS 7のサーバとします。また、kubesprayを実行するローカルマシンから、各サーバのrootユーザにSSH鍵を配置[^ssh-copy-id]済みとします。

## 手順

### 準備

まず、kubesprayをダウンロードします。

``` shell
$ git clone https://github.com/kubernetes-incubator/kubespray
$ cd kubespray
```

リポジトリのクローンが完了したら、ansibleなどの依存モジュールを導入します[^pip-sudo]。

``` shell
kubespray$ pip install -r requirements.txt
```

次に、ansible用のインベントリを作成します。

``` shell
kubespray$ cp -rfp inventory/sample inventory/mycluster
kubespray$ declare -a IPS=(192.168.1.11 192.168.1.12 192.168.1.13)
CONFIG_FILE=inventory/mycluster/hosts.ini python3 contrib/inventory_builder/inventory.py ${IPS[@]}
```

IPSは対象サーバのIPに合わせて定義をします。
また、環境によっては、`python3`コマンドではなく、`python`コマンドでPython 3が実行される場合も有ります。適宜読み替えてください。

最後に、構成するkubernetesクラスタの設定をします。`inventory/mycluster/group_vars`ディレクトリにある、`all.yml`と`k8s-cluster.yml`を適宜変更します。
特に、`k8s-cluster.yml`に含まれる、以下の項目は確認しておく必要があるでしょう。

* kube_version
    * kubernetesのバージョンを指定します。
* kube_network_plugin
    * kubernetesのnetwork pluginを指定します。初期値はcalicoですが、flannelが一般的です。[^contiv]
* kube_service_addresses, kube_pods_subnet
    * kubernetes内部で使用するIPの範囲をCIDR形式で指定します。LAN内のネットワークとかぶらないよう注意しましょう。
* dashboard_enabled
    * kubernetes dashboardを用意するかどうかの真偽値です。初期値はtrueです。trueの場合、RBACが有効になっている必要があります。
* helm_enabled, istio_enabled, registry_enabled
    * それぞれ、kubernetes Helm、Istio、Docker registryをデプロイするかどうかの真偽値です。インストールする予定ならここでtrueにしておくと楽です。

設定が完了したら、準備は終了です。

### デプロイする

準備ができたら、デプロイしましょう！
とはいっても、ココまで来たら後は普通にansible playbookを流し込むだけです。
次のコマンドを実行します。

``` shell
kubespray$ ansible-playbook -i inventory/mycluster/hosts.ini cluster.yml
```

エラーを出さずに終了したら、kubernetesのデプロイは完了です！

## kubernetesを操作する

デプロイできたら、kubernetesを操作してみましょう。
一番前に指定したサーバにSSHで接続し、`kubectl`を使って操作します。

``` shell
$ kubectl get nodes
NAME      STATUS    ROLES         AGE       VERSION
node1     Ready     master,node   10d       v1.9.2+coreos.0
node2     Ready     master,node   10d       v1.9.2+coreos.0
node3     Ready     node          10d       v1.9.2+coreos.0
```

また、LAN内の他のマシンから操作できるように、管理者アカウントを追加してみましょう。

``` shell
$ kubectl create serviceaccount nasa
serviceaccount "nasa" created
$ kubectl create clusterrolebinding nasa --clusterrole cluster-admin --serviceaccount=default:nasa
clusterrolebinding "nasa" created
```

追加できたら、トークンを確認します。

``` shell
$ kubectl describe serviceaccount nasa
Name:                nasa
Namespace:           default
Labels:              <none>
Annotations:         <none>
Image pull secrets:  <none>
Mountable secrets:   nasa-token-pcn8j
Tokens:              nasa-token-pcn8j
Events:              <none>
$ kubectl describe secret nasa-token-pcn8j
Name:         nasa-token-pcn8j
Namespace:    default
Labels:       <none>
Annotations:  kubernetes.io/service-account.name=nasa
              kubernetes.io/service-account.uid=8916621a-1010-11e8-8bf3-0200c0a80130

Type:  kubernetes.io/service-account-token

Data
====
ca.crt:     1090 bytes
namespace:  7 bytes
token:      eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJkZWZhdWx0Iiwaa3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZWNyZXQubmFtZSI6Im5yc2EtdG9rZW4tcGNuOGoiLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlcnZpY2UtYWNjb3VudC5uYW1lIjoibmFzYSIsImt1YmVybmV0ZXMuaW8dc2VydmljZWFjY291bnQvc2VydmljZS1hY2NvdW50LnVpZCI6Ijg5MTY2MjFhLTEwMTAtMTFlOC04YmYzLTAyMDBjMGE4MDEfMCIsInN1YiI6InN5c3RlbTpzZXJ2aWNlYWNjb3VudDgkZWZhdWx0Om5hc2FifQ.D1o3Jvko91dX6pk2qG505dd2zaXW468GGc9RT6eSzJlrjEG7UEtjF9vlhy7c3BegjPddpPpHsc_ouMx5BAmFdWh74v-PvxnX0IKsCVt_9dlSAcxbbk2PSOloqiwMxTs5q-j6y0Tx64zKzq5e520cNBQrkjJV96-f_riRHHXCrLXQKh2vroh_kpVDViQPqM-e4UKLU4zINGHnraouc7T95ib5wIMcVHEejgsZvF-hLgItxiMAhu4NQXzJ2gM4tMhXupgQZLL1-N_oqoTCNFssPQcoE9Ziyj9_RBkUoodhizpxGOKMFogUgG07DRae4OkEjywoR5xDAuQSJMPihTPqzw
```

`kubectl`コマンドをインストールした、別のマシンにトークンを設定します。

``` shell
$ kubectl config set-cluster mycluster --server=https://192.168.1.11:6443 --insecure-skip-tls-verify=true
$ kubectl config set-credentials mycluster --token=eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJkZWZhdWx0Iiwaa3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZWNyZXQubmFtZSI6Im5yc2EtdG9rZW4tcGNuOGoiLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlcnZpY2UtYWNjb3VudC5uYW1lIjoibmFzYSIsImt1YmVybmV0ZXMuaW8dc2VydmljZWFjY291bnQvc2VydmljZS1hY2NvdW50LnVpZCI6Ijg5MTY2MjFhLTEwMTAtMTFlOC04YmYzLTAyMDBjMGE4MDEfMCIsInN1YiI6InN5c3RlbTpzZXJ2aWNlYWNjb3VudDgkZWZhdWx0Om5hc2FifQ.D1o3Jvko91dX6pk2qG505dd2zaXW468GGc9RT6eSzJlrjEG7UEtjF9vlhy7c3BegjPddpPpHsc_ouMx5BAmFdWh74v-PvxnX0IKsCVt_9dlSAcxbbk2PSOloqiwMxTs5q-j6y0Tx64zKzq5e520cNBQrkjJV96-f_riRHHXCrLXQKh2vroh_kpVDViQPqM-e4UKLU4zINGHnraouc7T95ib5wIMcVHEejgsZvF-hLgItxiMAhu4NQXzJ2gM4tMhXupgQZLL1-N_oqoTCNFssPQcoE9Ziyj9_RBkUoodhizpxGOKMFogUgG07DRae4OkEjywoR5xDAuQSJMPihTPqzw
$ kubectl config set-context mycluster --cluster=mycluster --user=mycluster
$ kubectl config use-context mycluster
$ kubectl get nodes
NAME      STATUS    ROLES         AGE       VERSION
node1     Ready     master,node   10d       v1.9.2+coreos.0
node2     Ready     master,node   10d       v1.9.2+coreos.0
node3     Ready     node          10d       v1.9.2+coreos.0
```

無事、アクセスすることができました！
今回はclusterの設定で`--insecure-skip-tls-verify=true`とし、TLSの確認を省略しましたが、マスターノードの`/etc/kubernetes/ssl/apiserver.pem`をコピーしてきて、`kubectl config set-cluster`の`--certificate-authority=`に指定することで、TLSを確認した上で使用することができます。

楽しいkubernetesライフを送りましょう！

[^ssh-copy-id]: `ssh-copy-id`コマンドを利用すると便利です。
[^pip-sudo]: 環境によってはsudoが必要かもしれません。
[^contiv]: 個人的にはcontivで構成しています。深い意味はありませんが、Web UIがついているのが気に入っています。

