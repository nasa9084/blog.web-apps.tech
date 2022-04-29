---
author: nasa9084
categories:
- Alertmanager
- Prometheus
- kubernetes
- Secret
- confd
- security
- tool
- dockerfile
- initContainer
date: "2018-08-20T08:06:47Z"
description: ""
draft: false
cover:
  image: images/prometheus.png
  relative: true
slug: alertmanager-config-to-secret-with-confd
tags:
- Alertmanager
- Prometheus
- kubernetes
- Secret
- confd
- security
- tool
- dockerfile
- initContainer
title: confd + initContainerでAlertmanagerの設定をSecretに逃がす
---


## TL;DR

* Alertmanagerの設定には一部Secretが含まれる
    * バージョン管理システムに入れたくない
* initContainerでconfdを使って設定ファイルを生成する
    * Alertmanagerの設定の一部をSecretに格納できる

## confd

[kelseyhightower/confd](https://github.com/kelseyhightower/confd)は非常に軽量な設定ファイル管理ツールです。基本的にはテンプレートエンジンですが、多くのバックエンドデータストアからデータを持ってきて、設定ファイルに書き出すことが出来ます。
また、事前処理や事後処理を行うことが出来るので、例えば設定ファイルを書き換えたあと、リロードする、というところまで`confd`で行うことが出来ます。

### Install

Go言語で書かれているため、インストールは非常に簡単で、バイナリをダウンロードしてきて実行権限を与え、パスの通ったところに置くだけです。バイナリは[リリースページ](https://github.com/kelseyhightower/confd/releases)からダウンロードすることが出来ます。

### 使用方法

`confd`を使用するためには、三つのものを用意する必要があります。

* テンプレートリソース
* テンプレート
* データストア

#### テンプレートリソース

テンプレートリソースには、どのテンプレートを使用して、どんなキーでデータストアからデータを取り出し、完成した設定ファイルをどこに置くのか、事前処理・事後処理はどんなものかを記述します。書式はTOMLで、慣れ親しんだ(慣れ親しんでない？)iniファイルの様に気軽に書くことが出来ます。`/etc/confd/conf.d`以下に配置します。

#### テンプレート

テンプレートはその名の通り、設定ファイルのテンプレートです。ここに、データストアから取り出したデータを合わせて設定ファイルを作成します。書式はGo言語の[`text/template`](https://golang.org/pkg/text/template/#pkg-overview)に準じます。`/etc/confd/templates`以下に配置します。

#### データストア

そして、データストアにデータを入れる必要があります。

`confd`は、データストアとして、次のものをサポートしています(2018/08/20現在)

* [etcd](https://coreos.com/etcd/) (GitHub: [coreos/etcd](https://github.com/coreos/etcd))
* [consul](https://www.consul.io/) (GitHub: [hashicorp/consul](https://github.com/hashicorp/consul))
* [dynamodb](https://aws.amazon.com/jp/dynamodb/)
* [redis](https://redis.io) (GitHub: [antirez/redis](https://github.com/antirez/redis))
* [vault](https://www.vaultproject.io/) (GitHub: [hashicorp/vault](https://github.com/hashicorp/vault))
* [zookeeper](https://zookeeper.apache.org/) (GitHub: [apache/zookeeper](https://github.com/apache/zookeeper))
* [rancher](https://rancher.com/) [metadata-service](https://github.com/rancher/metadata) (GitHub: [rancher/rancher](https://github.com/rancher/rancher), [rancher/metadata](https://github.com/rancher/metadata))
* [AWS Systems Manager パラメータストア](https://aws.amazon.com/jp/systems-manager/)
* 環境変数
* ファイル

## Alertmanager

[Alertmanager](https://github.com/prometheus/alertmanager)は[Prometheus](https://github.com/prometheus/prometheus)からのアラートを受け取り、適切にハンドルするためのアプリケーションです。Alertmanagerの設定はYAMLで記述するのですが、SMTPのパスワードや[Slack](https://slack.com)の[Incoming Webhook URL](https://api.slack.com/incoming-webhooks)等、平文でバージョン管理システムに入れるのは躊躇われるデータを含みます。しかし、環境変数などから設定をすることも出来ないため、平文で記述するか、何らかの方法で設定ファイルを編集してから使う必要があります。
特に、Prometheus/Alertmanagerは[Kubernetes](https://k8s.io)と併せて使用されることが多いため、出来ればKubernetesのSecret機能を使用したいところです。
そこで`confd`をinitContainerで使用して、設定ファイルを生成します。

まず、テンプレートを作成します。Alertmanagerの設定ファイルを用意し、後から挿入したい部分をテンプレート文字列で置換しておきます。

``` yaml
global:
  slack_api_url: {{getenv "ALERTMANAGER_SLACK_URL"}}

route:
  receiver: slack

receivers:
  - name: slack
    slack_configs:
      - channel: "#alert"
```

今回は例なので、細かい設定の一切を省いた形にしました。上記の内容で、`alertmanager.yml.tmpl`として保存しました。

次に、テンプレートリソースを作成します。

``` toml
[template]
src = "alertmanager.yml.tmpl"

dest = "/etc/alertmanager/alertmanager.yml"

keys = [
    "ALERTMANAGER_SLACK_URL",
]
```

こちらも、上記内容で`confd.toml`として保存しました。

最後に、データストアにデータを投入します。今回の想定はKubernetesでSecretを使用する、ということなので、KubernetesのSecretを作成します。

``` shell
$ echo 'https://hooks.slack.com/services/XXXXXXXXX/XXXXXXXXX/XXXXXXXXXXXXXXXXXXXXXXXX' > alertmanager_slack_url
$ kubectl create secret general alertmanager-slack-url --from-file ./alertmanager_slack_url
```

Alertmanagerの起動前に設定ファイルを生成するため、[initContainer](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/)を使用します。initContainerはPod内のアプリケーションコンテナが起動する前に、初期化処理を行うことが出来るコンテナです。今回は、[`nasa9084/confd`](https://hub.docker.com/r/nasa9084/confd)を使用して設定ファイルを生成します。

`nasa9084/confd`のDockerfileは次の様になっています(ラベル省略)。

``` Dockerfile
FROM busybox:latest

RUN wget https://github.com/kelseyhightower/confd/releases/download/v0.16.0/confd-0.16.0-linux-amd64 -O confd &&\
    chmod +x confd &&\
    mv confd /bin/confd

ENTRYPOINT ["confd"]
```

これをinitContainerで起動します。Kubernetesのマニフェストは次の様に記述します。

``` yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: alertmanager
spec:
  selector:
    matchLabels:
      app: alertmanager
  template:
    metadata:
      labels:
        app: alertmanager
    spec:
      containers:
        - name: alertmanager
          image: prom/alertmanager:v0.15.2
          ports:
            - containerPort: 9093
          args: ["--config.file=/etc/alertmanager/alertmanager.yml"]
          volumeMounts:
            - name: alertmanager-config
              mountPath: /etc/alertmanager
      initContainers:
        - name: init-alertmanager-config
          image: nasa9084/confd:v0.16.0
          args: ["-onetime", "-backend", "env"]
          volumeMounts:
            - name: alertmanager-config
              mountPath: /etc/alertmanager
            - name: alertmanager-config-template
              mountPath: /etc/confd/templates
            - name: alertmanager-confd-toml
              mountPath: /etc/confd/conf.d
          env:
            - name: ALERTMANAGER_SLACK_URL
              valueFrom:
                secretKeyRef:
                  name: alertmanager-slack-url
                  key: alertmanager_slack_url
      volumes:
        - name: alertmanager-config-template
          configMap:
            name: alertmanager-config-template
        - name: alertmanager-confd-toml
          configMap:
            name: alertmanager-confd-toml
        - name: alertmanager-config
          emptyDir: {}
```

`.template.spec.initContainers`で設定ファイル生成用のコンテナを定義しています。テンプレートリソース、テンプレートをそれぞれconfigMapに格納し、適切なディレクトリにマウントしています。`alertmanager-config`が設定ファイル格納用のボリュームです。Podの起動時に設定ファイルが生成されるため、永続化する必要はありませんが、initContainerとAlertmanagerのコンテナ間でデータを受け渡す必要があるため、`emptyDir`として作成しました。また、先ほど作成したSlack Incoming webhook URLのSecretを環境変数としてマウントしています。
`confd`は通常、デーモンとして動作します。今回は一度設定ファイルを生成すれば十分なため、`-onetime`オプションをつけています。
最後に、生成した設定ファイルをボリュームとしてAlertmanagerのコンテナにマウントしてあります。

`confd`をinitContainerで起動する方法はAlertmanager以外にも応用が利きそうです。

