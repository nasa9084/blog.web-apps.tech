---
author: nasa9084
date: "2018-06-06T02:52:04Z"
description: ""
cover:
  image: images/eks_logo.png
  relative: true
slug: amazon-eks-is-now-ga
tags:
  - aws
  - kubernetes
  - eks
title: Amazon EKSがGAだと言うので触ってみた
---


AWSのmanaged Kubernetesで、これまでプライベートベータだった[Elastic Container Service for Kubernetes](https://console.aws.amazon.com/eks)が[GAになった](https://aws.amazon.com/jp/about-aws/whats-new/2018/06/amazon-elastic-container-service-for-kubernetes-eks-now-ga/)ということなので、さくっとクラスタを作成してみました。[^ga]

参考にしたのはAWS公式、[EKSのGetting Started Guide](https://docs.aws.amazon.com/eks/latest/userguide/getting-started.html)です。

まずはEKSのページを見てみようとしたところ・・・
![eks_top_ja](images/eks_top_ja.png)
ぶっ壊れてますね！これはなんかアレですね。
gettext的なのが上手くいっていないように見えるので、画面下から英語にしてみます。

![eks_top_en](images/eks_top_en.png)
無事、正しいと思われるページが表示されました。
なんか、How it worksの説明の図がちょっとぼやけて見えるのは環境のせいでしょうか。

扨、ここからGetting Startedしていきます。

![create_iam](images/create_iam.png)
まずはEKS用のIAMロールを作っていきます。
IAMロール作成画面のサービスリストにEKSが追加されていますので、これを選択します。

![eks_usecase](images/eks_usecase.png)
ユースケースは一つしかなく、選択済みになっています。

![eks_permission](images/eks_permission.png)
フムー。

![iam_created](images/iam_created.png)
IAMロールが出来ました。

![cf_template](images/cf_template.png)
CloudFormationでクラスタを組んでいきます。
今のところ、EKSが使えるリージョンはUS West(Oregon) (us-west-2)とUS East(N.Virginia) (us-east-1)の二カ所です。今回はUS Eastでやっていきます。

CloudFormationでCreate Stackをやっていきましょう。
S3 template URLが用意されていますので、これを入力します。
template URLは`https://amazon-eks.s3-us-west-2.amazonaws.com/1.10.3/2018-06-05/amazon-eks-vpc-sample.yaml`です。

![cf_template_view](images/cf_template_view.png)
Viewしてみるとこんな感じです。なるほど。

細かい設定的なところは全くいじらず、さくさく進めていきます。Stack nameは`GettingStarted`にしました。

![cf_stack_complete](images/cf_stack_complete.png)
できた。

![cf_stack_output-1](images/cf_stack_output-1.png)
Outputのタグを選択して、SecurityGroupsとVpcIdとSubnetIdsを(一応)メモっておきます。[^note]

次にkubectlの設定をしておきます。
最新のkubectl(1.10以降)をインストールしておいてください。まだインストールしていない場合はEKS側でも配信しているようなのでそれを使ってもOKです。

EKSでは認証にheptio-authenticator-awsを使用するようなので、こちらもドキュメントに従い導入します。
私はいろいろ考えるのが面倒だったため、`go get`しました。

``` shell
$ go get -u -v github.com/heptio/authenticator/cmd/heptio-authenticator-aws
```

ヘルプを表示して、正常に導入出来たかざっくり確認します。

``` shell
$ heptio-authenticator-aws help
```

ここで注意なのですが、ガイドでは**Download and Install the Latest AWS CLI**のところに**Optional**ってついてるんですが、これはほぼ必須です。
AWS CLIがないとクラスタに接続出来ないので、AWS CLIをインストールしておきます。

ではいよいよ、EKSでクラスタを作っていきます。
ここで私は若干手間取ったのですが、EKSでクラスタを作るのはルートクレデンシャルでログインしている状態ではだめで、IAMユーザを作る必要がありました。
普段からAWSをごりごり使っている人はアレですが、私みたいにほとんど使ってない人は注意が必要です。

![account_menu](images/account_menu.png)
![account](images/account.png)
アカウントの詳細画面を開いて、アカウントIDをメモります。

![add_user](images/add_user.png)
![user_permission](images/user_permission.png)
ざっくりIAMユーザを作ります。今回は適当にeks-userとしました。
権限も、何が必要なのかよくわからなかったのでAdministrator Accessとしておきました。
本番ではちゃんとやらなきゃだめですね。

![user_created](images/user_created.png)
はい。

![login_with_iam](images/login_with_iam.png)
一旦ログアウトし、IAMユーザを使ってログインします。

![create_eks](images/create_eks.png)
EKSのトップページでクラスタ名を入れます。今回はgetting-startedとしました。

![eks_configure_1](images/eks_configure_1.png)
いろいろな情報を入れていきます。
これらはCloudFormationで作った奴ですね。

![error_subnet_region](images/error_subnet_region.png)
エラーが出ました。ガイドを見ると、どうしたら良いか書いてあります。

> **Important**
>
>You may receive an error that one of the Availability Zones in your request does not have sufficient capacity to create an Amazon EKS cluster. If this happens, the error output contains the Availability Zones that can support a new cluster. Retry creating your cluster with at least two subnets that are located in the supported Availability Zones for your account.

サブネットのアベイラビリティゾーン(AZ)がたりないよ、と。ふむ。

![create_subnet](images/create_subnet.png)
VPCのページに行き、さくっとサブネットを作ってきます。
最低二つ、EKSが使えるAZが有ればOKとのことなので、一個足しておきます。

![eks_configure_2](images/eks_configure_2.png)
作ったサブネットを入れて再挑戦。

![cluster_success](images/cluster_success.png)
今度は上手くいきました。

![cluster_creating_detail](images/cluster_creating_detail.png)
CREATINGで結構時間がかかるので、API server endpointとCertificate authorityの値をメモっておきます。

あと、このタイミングでAWS CLIに認証情報を設定しておきます。今回で言うと、eks-userの認証情報を`aws configure`で突っ込んでおきます。

加えて、kubectlの設定をしていきます。
`~/.kube/config-getting-started`として次の内容で設定ファイルを作ります(getting-startedは適宜クラスタ名にする)。
``` yaml
apiVersion: v1
clusters:
- cluster:
    server: <endpoint-url>
    certificate-authority-data: <base64-encoded-ca-cert>
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: aws
  name: aws
current-context: aws
kind: Config
preferences: {}
users:
- name: aws
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1alpha1
      command: heptio-authenticator-aws
      args:
        - "token"
        - "-i"
        - "<cluster-name>"
```

ここで、`<endpoint-url>`と`<base64-encoded-ca-cert>`はそれぞれさっきメモをしたAPI server endpointとCertificate authorityで、`<cluster-name>`はクラスタ名(今回だとgetting-started)で置き換えます。

shellで`export KUBECONFIG=$KUBECONFIG:~/.kube/config-getting-started`として、設定ファイルを読み込みます。

![cluster_active](images/cluster_active.png)
そうこうしている間にクラスタがActiveになったりならなかったり(意外と時間がかかるので)するので、Activeになったら、次のコマンドで設定の確認をします。

``` shell
$ kubectl get all
NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
service/kubernetes   ClusterIP   10.100.0.1   <none>        443/TCP   23m
```

私はここで、kubectlのバージョンが古く、かつAWS CLIの設定をしていなかったがために結構困りました。
ユーザ名とパスワードを聞かれたり、答えてもForbiddenだったり、`error: You must be logged in to the server (Unauthorized)`とか言われたり。
これらはまだ良いのですが、`error: the server doesn't have a resource type "cronjobs"`とかって訳のわからんエラーが出たりして大変困りました。
kubectlのバージョンとAWS CLIの設定に要注意です。

上手くいったら、ワーカーノードを立てていきます。
ワーカーノードの作成もCloudFormationでさくっとやりましょう。

![cf_worker_template](images/cf_worker_template.png)
先ほどと同じく、S3 template URLが用意されています。`https://amazon-eks.s3-us-west-2.amazonaws.com/1.10.3/2018-06-05/amazon-eks-nodegroup.yaml`を入力しましょう。

![configure_worker_stack](images/configure_worker_stack.png)
Stack名はgetting-started-worker-nodesとしました。
ClusterNameにはそのままクラスタ名(getting-started)を入力。
NodeGroupNameは適当につけておきます。
MinSizeとMazSizeはそのまま、NodeInstanceTypeは`t2.small`にしました(今回は検証なので)。
NodeImageIdなんですが、これはリージョンによって違います。

| Region | AMI ID |
|:-------|:-------|
|US West |ami-73a6e20b|
|US East |ami-dea4d5a1|

今回はUS Eastなので`ami-dea4d5a1`と入力しました。
KeyNameにはキーペアを選択して入れます。EC2インスタンスに直接SSHする予定がなくても、選択しないと、作成中に失敗しますので、入れておきます。
VpcIdとSubnetsはクラスタに使ったものを入れておきます。

![node_created](images/node_created.png)
できました。Outputのタブを選択して、NodeInstanceRoleをメモっておきます。

コマンドラインで、ノードをクラスタに追加します。

``` shell
$ curl -O https://amazon-eks.s3-us-west-2.amazonaws.com/1.10.3/2018-06-05/aws-auth-cm.yaml
```

設定ファイルをダウンロードしてきて、`<ARN of instance role (not instance profile>`の部分に先ほどのNodeInstanceRoleを書き込みます。

``` yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: <ARN of instance role (not instance profile)>
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
```

で、applyします。

``` shell
$ kubectl apply -f aws-auth-cm.yaml
```

ざっくりノードが追加されたことを確認します。

``` shell
$ kubectl get nodes
NAME                              STATUS    ROLES     AGE       VERSION
ip-192-168-132-251.ec2.internal   Ready     <none>    2m        v1.10.3
ip-192-168-229-157.ec2.internal   Ready     <none>    2m        v1.10.3
```

問題なさそうですね。

一応、guest bookアプリもやっておきます。


``` shell
$ kubectl apply -f https://raw.githubusercontent.com/kubernetes/kubernetes/v1.10.3/examples/guestbook-go/redis-master-controller.json
replicationcontroller "redis-master" created
$ kubectl apply -f https://raw.githubusercontent.com/kubernetes/kubernetes/v1.10.3/examples/guestbook-go/redis-master-service.json
service "redis-master" created
$ kubectl apply -f https://raw.githubusercontent.com/kubernetes/kubernetes/v1.10.3/examples/guestbook-go/redis-slave-controller.json
replicationcontroller "redis-slave" created
$ kubectl apply -f https://raw.githubusercontent.com/kubernetes/kubernetes/v1.10.3/examples/guestbook-go/redis-slave-service.json
service "redis-slave" created
$ kubectl apply -f https://raw.githubusercontent.com/kubernetes/kubernetes/v1.10.3/examples/guestbook-go/guestbook-controller.json
replicationcontroller "guestbook" created
$ kubectl apply -f https://raw.githubusercontent.com/kubernetes/kubernetes/v1.10.3/examples/guestbook-go/guestbook-service.json
service "guestbook" created
$ kubectl get services -o wide
NAME           TYPE           CLUSTER-IP       EXTERNAL-IP                                                             PORT(S)          AGE       SELECTOR
guestbook      LoadBalancer   10.100.178.116   ad0f4fcee692d11e88ee612f8cc97e4d-88389123.us-east-1.elb.amazonaws.com   3000:32656/TCP   5m        app=guestbook
kubernetes     ClusterIP      10.100.0.1       <none>                                                                  443/TCP          47m       <none>
redis-master   ClusterIP      10.100.24.130    <none>                                                                  6379/TCP         6m        app=redis,role=master
redis-slave    ClusterIP      10.100.195.26    <none>                                                                  6379/TCP         5m        app=redis,role=slave
```

出来ました。
ブラウザからアクセスしてみます。

![guestbook](images/guestbook.png)
よさそうですね。

動作確認が出来たらもういらないのでguestbookは消してしまいます。

``` shell
$ kubectl delete rc/redis-master rc/redis-slave rc/guestbook svc/redis-master svc/redis-slave svc/guestbook
replicationcontroller "redis-master" deleted
replicationcontroller "redis-slave" deleted
replicationcontroller "guestbook" deleted
service "redis-master" deleted
service "redis-slave" deleted
service "guestbook" deleted
```

はい。
なかなか手数は多いですが、難しいことはあまりありませんでした。
AWS CLIが暗黙的に使われてて、**Optional**とか書かれてたのがちょっとくせ者ですね。


[^ga]: GA: Generally Availableの略。一般にProduction Readyと同じような意味合いで取られることが多い。
[^note]: だいたいは選択出来るUIなので、判別出来るならいらないですが

