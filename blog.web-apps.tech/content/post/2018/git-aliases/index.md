---
author: nasa9084
date: "2018-12-12T06:16:37Z"
description: ""
cover:
  image: images/git-1.png
  relative: true
slug: git-aliases
tags:
  - git
  - alias
  - advent calendar
  - "2018"
title: gitにもaliasの指定ができる件
---


## tl;dr

* `.gitconfig`にもaliasの登録ができる
    * `[alias]`ブロックにaliasを登録する
* `tags`で単数・複数の悩みを解消する
* `discard`で変更を取り消す
* `unstage`でaddを取り消す
* `uncommit`でcommitを取り消す
* `ignore`で`.gitignore`を生成する

## git aliases

この記事は[今すぐalias登録すべきワンライナー by ゆめみ① Advent Calendar 2018](https://qiita.com/advent-calendar/2018/yumemi01_one-liner)の6日目の穴埋め記事です。
こちらのアドベントカレンダーは今すぐalias登録べきワンライナーということで、みなさん`.bashrc`や`.zshrc`のaliasについて記事を書いてらっしゃいますが、実は`.gitconfig`という、`git`コマンドの設定を書いておくファイルにもaliasの指定ができます。
誰もshellのaliasとは言ってない！(・・・はず)ので、いくつか`.gitconfig`用に便利なaliasを紹介していきましょう

### aliasの登録方法

`.gitconfig`は基本的にiniファイルです。そのため、次のように登録します。

``` ini
[alias]
aliasname1 = some command 1st
aliasname2 = some command 2nd
```

簡単ですね？ `[alias]`というブロックを作成し、alias名=コマンドの形で記述します。
このときコマンドは`git xxx`の形で実行される、`xxx`の部分のみを指定します。

例えば、

``` ini
[alias]
stat = git status
```

と指定すると実際の実行時には`git git status`という形で実行されてしまいエラーになるので注意しましょう。
`git`のつかないコマンドを実行したい場合は頭に`!`をつけます。

``` ini
[alias]
ls = !ls
```

このように記載すると、`git ls`で`ls`が実行されます。

### `git tags`

`git tag`というコマンドがありまして。まぁみなさんご存知でしょうが、tagの一覧を出したり、新しいtagを作ったりするコマンドです。これ単体では特に問題がないのですが、リモートリポジトリと合わせて使うと、ちょっと悩みが発生します。
`git tag`コマンドでタグをつけた後、リモートリポジトリにpushするときのコマンドは`git push --tags`です。これはtagをまとめてpushするので、複数形なんでしょう。しかしです。tagの一覧を出すときに使うのも`git tag`と単数形なんですね。
ついつい`git tags`と打ってしまいませんか？

そんなあなたはこんなaliasを登録しておきましょう

``` ini
[alias]
tags = tag
```

地味ですが、これで単数形か複数形か悩まずに済みます。

### `git discard`

ファイルを変更して、「あ、やっぱやーめた」、とそんなこと、ありませんか？そんなときに[magit](https://github.com/magit/magit)を使っていればM-x magit-statusからのk、で一発ですが、さてコマンドでやるにはどうしたらいいんでしょうか？
`git reset`？`git checkout`？なんにせよ少し悩んで場合によってはGoogle先生にお聞きする必要がありそうです。

そんなときに便利なのが次のalias。

``` ini
[alias]
discard = checkout --
```

正解は`git checkout`ですが、もっとわかりやすく、`git discard`とすれば悩む必要もないですね。


### `git unstage`

普段はなにかしらのクライアントから`git`を操作しているあなた。一度`git add`したファイルをaddしていない状態に戻すコマンドをすぐに答えられますか？私はすぐには答えられません。確実に[Googleで検索](https://www.google.com/search?q=git+unstage)する自信があります。

そこで、こんなaliasを登録しておきます。

``` ini
[alias]
unstage = reset -q HEAD --
```

これで間違ってaddしたファイルも`git unstage hogehoge`と一発です。

### `git uncommit`

さて、編集しただけだったり、addしただけならそんなに難しいことはありませんが、一旦commitした後はどうでしょうか。ヒントは`reset`を使うということですが、どのように指定をしたら良いかわかりますか？
`--mixed`オプションを使う、が答えです。とはいえ、こんなのすぐには思い出せません。やりたいことはcommitを取り消したい、ですから。

こんなaliasが便利でしょう。

``` ini
[alias]
uncommit = reset --mixed HEAD~
```

`git uncommit`。うん、わかりやすくなりました。

### `git ignore`

最後はこれです。[前にも一度紹介しましたが](/gitignore-from-cli/)、みなさんは`.gitignore`をどのように作成していますか？
色々と方法はあると思いますが、私は[gitignore.io](https://gitignore.io)が好きです。
しかし毎回ブラウザでアクセスしたり、URLをタイプするのは面倒です。

私は次のように設定しています。

``` ini
[alias]
ignore = !curl -L -s https://www.gitignore.io/api/$@
```

これで、`git ignore`コマンドが使えるようになり、`git ignore macos > .gitignore`の形で簡単に`.gitignore`のテンプレートを作れるようになりました。

なお、普段私が使っている`.gitconfig`は[GitHubで](https://github.com/nasa9084/dotfiles/blob/master/.gitconfig)公開しています。
