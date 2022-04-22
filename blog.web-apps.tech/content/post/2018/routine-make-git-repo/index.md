---
author: nasa9084
categories:
- git
- github
date: "2018-12-07T03:19:52Z"
description: ""
draft: false
cover:
  image: images/git.png
slug: routine-make-git-repo
tags:
- git
- github
title: git repositoryの初期化ルーチン
---


おそらくみなさんもgit repositoryを作る時、毎回だいたい同じような手順で初期化をするのではないでしょうか。
メモがてら、自分の初期化ルーチンをまとめておきます

## tools

使用しているツールは以下の通り:

* [`hub`](https://github.com/github/hub) : [`.zshrc`](https://github.com/nasa9084/dotfiles/blob/master/.zshrc#L152)で`git`コマンドにエイリアスを張ってます
* [gitignore.io](https://gitignore.io) : [先日記事を書いたように](/gitignore-from-cli/)、`git ignore`コマンドとして使ってます
* [git-license](https://github.com/nasa9084/git-license) : 自作のサブコマンドです

## routine

``` shell
# 新しいリポジトリ用のディレクトリを作成
$ mkdir new-repository
$ cd new-repository
$ git init
# GitHub上にnasa9084/new-repositoryリポジトリを作成
# hubコマンドの機能
$ git create
# まずは空の状態で初回コミット
$ git commit -m 'initial commit' --allow-empty
# .gitignoreを作成(今回はgo言語プロジェクト向け)
$ git ignore emacs,macos,go > .gitignore
$ git add .gitignore
$ git commit -m 'add .gitignore for emacs,macos,go'
# LICENSEを作成
$ git license -u nasa9084 mit > LICENSE
$ git add LICENSE
$ git commit -m 'add MIT License'
$ git push -u origin master
```

ここまでがルーチンで、ここから`Makefile`を作ったり開発したりします。



