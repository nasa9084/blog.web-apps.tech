---
title: Exa to Eza
author: nasa9084
date: 2023-09-18T21:26:50+09:00
draft: false
categories:
- zsh
- bash
tags:
- zsh
- bash
slug: exa-to-eza
---

[2020年に`exa`をインストールして](/replacing-ls-with-exa/)から、3年半弱`ls`の代わりとして`exa`を使用してきました。
設定としては以下のような感じで、`exa`に何やらオプションを足した奴を`ls`のエイリアスとして、追加で`ll`、`la`、`lla`を設定している感じです:

``` shell
alias ls="exa -Fgh --git --time-style=long-iso"
alias la="ls -a"
alias ll="ls -l"
alias lla="ls -la"
```

で、不定期でやってるローカルのツール更新というか、`brew update && brew outdated`をしたところ、`exa`のバージョンが(なんかよく分からない感じで)上がっていたので更新内容をチェックしに行ったところ、[exa is unmaintained, please use the active fork eza instead](https://github.com/ogham/exa/commit/fb05c421ae98e076989eb6e8b1bcf42c07c1d0fe)というコミットが打たれていて、[eza](https://github.com/eza-community/eza)を見に行ったら実際活発に開発されていて、7月末からすでに10回のリリースが行われているようでした。
個人的には`exa`で困ってはいなかったモノの、2年以上リリースが打たれていないのも事実ですし、`eza`のリリースノートを見る限りセキュリティフィックスなどもあるようなので、置き換えをしました。

## 手順

1. `brew install eza`
2. `sed -ie 's/exa/eza/' .zshrc`
3. `brew uninstall exa`

今のところ特に使用感は変わった感じはしないですが、一つだけ気づいたのは[symlinkのサイズ表示が変わった](https://github.com/eza-community/eza/pull/42)くらいですかね。
