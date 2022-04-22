---
author: nasa9084
categories:
- git
- github
- security
date: "2019-08-24T04:36:12Z"
description: ""
draft: false
cover:
  image: images/git.png
slug: gitconfig-secret
tags:
- git
- github
- security
title: 社用Gitサーバでは社用のメールをつかう.gitconfig 〜社内ドメインを外に漏らさない編〜
---


GitHubのコミットログ、コミットした人のアイコンが出ていてとてもわかりやすいですよね。
コミットとアカウントの紐付けにはどうやら、コミットに紐付けられたメールアドレスが使用されているようです。そうなると、コミットに紐付ける(`git config user.email=...`とかやるアレです)メールアドレスはアカウントに登録してあるメールアドレスにしたいものです。

しかし、会社ではGitHub Enterprise(GHE)、私用では[github.com](https://github.com)を使用している、と言った場合はどうでしょうか。コミットに紐付けたいメールアドレスがリポジトリによって変わる、ということになってしまいます。

調べてみると、そういった場合、次の様に`.gitconfig`に`IncludeIf`のブロックを設定することでうまく回避ができそうということがわかり、しばらく設定していました

``` ini
[IncludeIf "gitdir:~/src/GHE_DOMAIN"]
path = "~/.gitconfig.ghe"
```

`~.gitconfig.ghe`には次の様に書かれています。

``` ini
[user]
email = 社用メールアドレス
```
私はGo言語をよく書くのと、[ghq](https://github.com/motemen/ghq)を使っている都合上、gitのリポジトリを配置するパスが`$(GOPATH)/src/GIT_DOMAIN/USERNAME/REPOSITORY`という形式になっているため、リモートリポジトリのドメインを指定することでうまいこと社用GHEの時だけ設定を上書きすることができていたのでした。

そしてこれは、どのPCでも使用できるように、[dotfilesリポジトリ](https://github.com/nasa9084/dotfiles)として[github.com](https://github.com)にpushしていました。

その結果、会社の人から、「社内のサービスのURL(この場合はGHEのURL)はセキュリティ的な理由から外に出さないようにしてほしい」と連絡を受けました。すぐさま該当のブロックは消したのですが、そうするとメールの設定が自動でされなくなってしまい不便です。リポジトリのパスを変更するというのも、せっかくの統一的な操作に違いが出てしまい、不便です。

そこで思いついたのが、こういったセンシティブな情報を別のプライベートリポジトリに分け、[Makefile](https://github.com/nasa9084/dotfiles/blob/master/Makefile)でインストールを自動化するという方法です。

パブリックな[dotfilesリポジトリ](https://github.com/nasa9084/dotfiles)にある[`.gitconfig`](https://github.com/nasa9084/dotfiles/blob/master/.gitconfig)には次の様に書いてあります。

```
[include]
path = ~/.gitconfig.secret
```

`.gitconfig.secret`はその名の通り、秘匿情報を含んだ`.gitconfig`で、プライベート化されたdotfiles-secretリポジトリにおいてあります。dotfiles-secretリポジトリは`make install`としたときに`git clone`され、さらにそのディレクトリ内の`Makefile`により配置されます。`dotfiles-secret/.gitconfig.secret`には先ほどの`IncludeIf`ブロックが書かれており、同リポジトリ内の`.gitconfig.secret.ghe`(名前を少し変えました)を読み込みます。

これで、全体の使い勝手をほとんど損なうことなくどのマシンでも(dotfilesが配備済みなら)同様に設定することができました。

`Makefile`は特にdotfilesのリストを持たないよう記述しているため、新しいdotfileが増えても、特に`Makefile`の変更をする必要も無く安心です。



