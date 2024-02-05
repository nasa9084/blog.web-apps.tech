---
author: nasa9084
date: "2019-08-22T10:30:00Z"
description: ""
draft: false
cover:
  image: images/github.jpg
slug: hub-with-github-enterprise
tags:
  - git
  - github
  - tool
title: hubコマンドにGitHub Enterprise環境を追加する
---


[`hub`](https://github.com/github/hub)コマンドをご存じでしょうか。インストールして`alias git=hub`と設定するだけで、`git`コマンドからGitHubの操作ができるようになる優れものです。特に個人的には`git create`とするだけでGitHub上にリポジトリが作成される、というのが非常に便利だと思っています。

さて、皆さんの会社ではgitサーバはどのように構築されているでしょうか。いろいろな選択肢がありますが、それなりの規模だとGitHub Enterprise(以下GHE)を利用している、という会社も多いと思います。
実際、現職ではGHEを使っています。

そのような場合、趣味/個人の開発ではgithub.com、会社ではGHEと使い分けることとなりますが、GHEで`hub`が使えないとすると非常に不便です。そう考えて調べてみると、Web上では、`hub`をGHE環境で使うには環境変数を使うとする設定例が散見されます。

しかし実は、`hub`は複数環境での使用をサポートしているんです。
設定方法は至って簡単で、`$HOME/.config/hub`に設定を書き足すだけです。実際に見てみましょう。

すでに`hub`を使っている場合、`cat $HOME/.config/hub`で設定を見ることができます。私の場合、次のようになっていました(`oauth_token`は潰してありますが、実際にはトークンが入っています)。

``` yaml
github.com:
- user: nasa9084
  oauth_token: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
  protocol: https
```

どんな項目かは明らかですね。ここに会社のGHEの環境に関する情報を追記します。
まず、自社のGHEのアドレス以下`/settings/tokens`を開きます。**Generate new token**ボタンをクリックし、新規でPersonal access tokenを発行します。名称はわかりやすい物を任意で付けてください。`hub`はリポジトリを操作するコマンドですから、scopeは**repo**を与えれば十分でしょう。画面下部の**Generate token**ボタンをクリックすると、トークンが発行されますので、これをコピーしておきます。

手元のエディタ(お好みの物を使用してください)で`$HOME/.config/hub`を開き、設定を追加します。

``` yaml
YOUR_GHE_DOMAIN:
- user: YOUR_USERNAME
  oauth_token: YOUR_TOKEN
  protocol: https
```

オブジェクトのキーとしてGHEのドメインを、`user`はGHEでログインに使用するユーザ名を使用します。`oauth_token`に先ほど生成したPersonal access tokenを設定し、保存します。保存できたら、`hub`でGHEにアクセスができるようになっているはずです。

実際に使うと、次の様にどのホストを使用するか聞かれ、好きな方を選べるようになっています。

``` shell
$ git create
Select host:
 1. github.com
 2. YOUR_GHE_DOMAIN
> 1
Updating origin
https://github.com/nasa9084/REPOSITORY_NAME
```



