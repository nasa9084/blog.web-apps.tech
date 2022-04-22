---
author: nasa9084
categories:
- github
- git
date: "2022-03-20T14:14:15Z"
description: ""
draft: false
cover:
  image: images/git.png
slug: github-disabled-git-protocol
tags:
- github
- git
title: GitHubがgit://を無効にした件
---


## TL;DR
GitHubからgitプロトコル(`git://github.com`で始まるURL)でgit cloneする設定になっている人が居たらSSHプロトコル(`git@github.com`で始まるURL)を使うように設定変更しましょう

---

wez/weztermという端末エミュレータを知って、使ってみようかと思い、ドキュメントに従って`brew tap`したときのことでした。次の様なエラーが発生して、tapできません。

```
$ brew tap wez/wezterm
==> Tapping wez/wezterm
Cloning into '/opt/homebrew/Library/Taps/wez/homebrew-wezterm'...
fatal: remote error: 
  The unauthenticated git protocol on port 9418 is no longer supported.
Please see https://github.blog/2021-09-01-improving-git-protocol-security-github/ for more information.
Error: Failure while executing; `git clone https://github.com/wez/homebrew-wezterm /opt/homebrew/Library/Taps/wez/homebrew-wezterm --origin=origin --template=` exited with 128.
```

[指定された記事](https://github.blog/2021-09-01-improving-git-protocol-security-github/)を見てみると、`git://`で始まるURLでのアクセス==gitプロトコルでのアクセスを無効化したようです。
[自分の`.gitconfig`を見てみると](https://github.com/nasa9084/dotfiles/blob/2aa844041a6ec45ae08d73ba850ecedb68e0eb89/.gitconfig)、確かに https://github.com の代わりに git://github.com を使うという設定がされています。

```
[url "git@github.com:"]
	pushInsteadOf = git://github.com/
	pushInsteadOf = https://github.com/

[url "git://github.com/"]
	insteadOf = https://github.com/
```

GitHubによるとこれまでもgitプロトコルでのアクセスは読み取り専用だったようですが、ご丁寧にpushInsteadOfで git@github.com を使用するという設定まで書かれているので、これまで問題無く使えてしまっていたようです。自分でもなぜこういう設定にしたのか記憶にないのですが、これは単にSSHプロトコルを使用すれば良いだけ、ということのようでしたので[修正しました](https://github.com/nasa9084/dotfiles/blob/a55ab8c0d44bbda1d9fff398ac3e3a69a79be274/.gitconfig)。

```
[url "git@github.com:"]
	insteadOf = https://github.com/
```

GitHubの想定としてもどうせread-onlyだから使っている人なんてほとんどいないだろう、ということで引っかかる人も居ないでしょうが、メモとして残しておきます。



