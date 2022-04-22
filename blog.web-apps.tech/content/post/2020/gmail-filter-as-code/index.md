---
author: nasa9084
categories:
- automation
- ci
date: "2020-05-08T01:00:00Z"
description: ""
draft: false
cover:
  image: images/gmail.png
slug: gmail-filter-as-code
tags:
- automation
- ci
title: Gmail Filter as Code
---


[@yamamoto_febc](https://twitter.com/yamamoto_febc)さんの[ブログ記事](https://febc-yamamoto.hatenablog.jp/entry/2020/04/26/182608)で、[jessfraz/gmailfilters](https://github.com/jessfraz/gmailfilters)というツールを知りました。なんでも、GmailのフィルタをTOMLで管理するツール、とのこと(実際の使用例などは[kakakakakkuさんの記事](https://kakakakakku.hatenablog.com/entry/2020/04/22/090002)で紹介されています)。
それは素敵っぽい、ということで触ってみたところ、実際良い物っぽい感じはあったものの、TOMLというのが(個人的に)つらいし、releasedなバージョンではexportができない(機能自体はmasterにあるものの、一年前に機能開発されてからリリースが打たれていない、という点がちょっと不安)という二点が気になりました。
特にTOMLはどうにも好きになれず、やはりYAMLで書きたい、という気持ちが強かった+GWの自由研究が決まらなかったので自前で書き直し、これをGmail as Code (今はfilterしか管理できないけど、他の設定も管理できるようにしたい)から[gmac](https://github.com/nasa9084/gmac)と名付けました。

<blockquote class="twitter-tweet"><p lang="ja" dir="ltr">YAMLで設定したい</p>&mdash; nasa9084@某某某某(0x1b) (@nasa9084) <a href="https://twitter.com/nasa9084/status/1254720750264541184?ref_src=twsrc%5Etfw">April 27, 2020</a></blockquote>
<script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

## GMaC - Gmail as Code

大枠の挙動としては、jessfraz/gmailfiltersとそれほど変わりません。Gmail APIを[google.golang.org/api/gmail/v1](https://pkg.go.dev/google.golang.org/api/gmail/v1)を使用して叩いているのも同じです。
jessfraz/gmailfiltersと比較して、違う点として次の様なものがあります:

* TOMLではなくYAMLで設定を記述する
* Gmail Web UIに比較的近い設定項目
    * jessfraz/gmailfiltersも実装しているArchiveやDeleteなどはもちろん実装
    * 条件/アクションを個別に設定する形にした
        * jessfraz/gmailfiltersみたいに全部まとまってるとわかりにくくない？
    * `larger_than`や`subject`、`has_attachment`といった条件も追加
    * `star`や`important`、`category`(私は使ってないけど)といったアクションも追加
* OAuthの際に認証/認可ページを自動で開き、OAuth callbackも受ける
    * jessfraz/gmailfiltersはURLと、OAuth tokenをコピペする必要がある
* `credentials.json`および`token.json` (OAuthの認証ファイル)を特定の場所に置き、そこから読み込む
    * jessfraz/gmailfiltersは毎回ファイルパスを指定する必要がある
* kubectl-likeなサブコマンド配置
    * get/applyが個別に行え、(k8sに慣れている人は)比較的なじみやすいはず
    * jessfraz/gmailfiltersはオプションフラグで挙動を変える方針っぽい
* CIで使いやすい(と思う)
    * `credentials.json`を標準入力から読める
    * OAuth refresh tokenを環境変数で指定できる
    * jessfraz/gmailfiltersはファイルからのみ
* (そこそこ)ちゃんとテストを書いている
    * 全部とはいえないけど・・・
    * jessfraz/gmailfiltersはほとんどテストがなくてちょっと怖い
* (そこそこ)ドキュメントを整備してある
    * README.mdを頑張って書いた

逆にjessfraz/gmailfiltersがサポートしている、`queryOr`や`archiveUnlessToMe`は実装していません。ORとか普通に書けばよかろう。



### Manage with CI

実際に、GitHub Actionsを使用して自分のGmail Filterを管理するように設定しました。管理用のプライベートリポジトリに`filters.yml`としてフィルタの設定ファイル(これ自体も `gmac get filters -o yaml > filters.yml` として出力したもの)と、次のGitHub Actions設定ファイルをおいてpushごとに適用するように構成しました。

```yaml
---
name: Apply
on: push

jobs:
  apply:
    name: Apply Filters
    runs-on: ubuntu-latest
    if: "! contains(toJSON(github.event.commits.*.message), '[skip ci]')"
    steps:
      - name: Setup Golang
        uses: actions/setup-go@v2
        with:
          go-version: 1.14
      - name: Checkout code
        uses: actions/checkout@v2
      - name: Install GMaC
        run: go get -u github.com/nasa9084/gmac@v0.0.3
        env:
          GO111MODULE: 'on'
      - name: Apply
        run: echo "${GMAC_CREDENTIALS_JSON}" | gmac apply -f filters.yml -c-
        env:
          GMAC_CREDENTIALS_JSON: ${{ secrets.CREDENTIALS_JSON }}
          GMAC_REFRESH_TOKEN: ${{ secrets.REFRESH_TOKEN }}
```

`CREDENTIALS_JSON`と`REFRESH_TOKEN`はsecretとして設定してあります。

GitHub Actionを作ってみたい気持ちもあります。

### 設定ファイルの例

以下の設定は今の私の設定を抜粋した物です。

```yaml
kind: Filter
filters:
- criteria:
    from: 自分
  action:
    archive: true
    add_label: 自己
- criteria:
    from: facebookmail.com
  action:
    archive: true
    add_label: Services/facebook
    never_mark_as_spam: true
- criteria:
    from: slack.com
  action:
    archive: true
    add_label: Services/slack
    never_mark_as_spam: true
- criteria:
    from: feedly
  action:
    archive: true
    add_label: Services
    never_mark_as_spam: true
- criteria:
    from: YouTube
  action:
    archive: true
    add_label: Services
    never_mark_as_spam: true
- criteria:
    from: ASUS
  action:
    archive: true
    add_label: Services
    never_mark_as_spam: true
- criteria:
    from: Evernote
  action:
    archive: true
    add_label: Services
    never_mark_as_spam: true
- criteria:
    from: connpass
  action:
    archive: true
    add_label: Services/connpass
    never_mark_as_spam: true
- criteria:
    from: Kickstarter
  action:
    archive: true
    add_label: Services/Kickstarter
    never_mark_as_spam: true
- criteria:
    from: Amazon.co.jp
  action:
    archive: true
    add_label: Amazon
- criteria:
    to: osc-do@list.ospn.jp
  action:
    archive: true
    add_label: OSC/hokkaido
    never_mark_as_spam: true
- criteria:
    to: osc-member@list.ospn.jp
  action:
    archive: true
    add_label: OSC
- criteria:
    to: members@local.or.jp
  action:
    archive: true
    add_label: LOCAL
- criteria:
    from: mg.gitlab.com
  action:
    archive: true
    add_label: gitlab
- criteria:
    to: kubernetes-dev@googlegroups.com
  action:
    archive: true
    add_label: kubernetes-dev
- criteria:
    from: banking@sonybank.net
  action:
    archive: true
    add_label: Sony銀行
- criteria:
    from: peatix.com
  action:
    archive: true
    add_label: Services/Peatix
    never_mark_as_spam: true
- criteria:
    from: google.com
  action:
    archive: true
    add_label: Services/Google
    never_mark_as_spam: true
- criteria:
    from: Kubernetes Prow Robot
  action:
    archive: true
    mark_as_read: true
    add_label: k8s/Prow
```



