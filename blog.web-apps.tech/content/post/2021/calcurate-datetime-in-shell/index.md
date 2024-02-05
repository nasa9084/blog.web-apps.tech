---
author: nasa9084
date: "2021-07-13T03:52:44Z"
description: ""
cover:
  image: images/shell_prompt.png
  relative: true
slug: calcurate-datetime-in-shell
tags:
  - shell
title: dateコマンドで簡単な時間計算をする
---


shellscript内で時間計算をしたい事がある。例えば、「最終実行から10分経過していたらxxxをする」という様なケース。定期的にファイルを生成したい、といった簡単なユースケースであれば、`find`コマンドあたりでファイルの変更タイムスタンプを調べるといった方法でも実現可能ではあるけれど、「ファイルの中に記載された時間から10分経過しているかどうか調べる」なんて事もあるでしょう(あった)。
shellscriptで時間の計算するのって面倒そうなんだよな・・・と思っていたのですけれど、私のユースケースだとそれほど難しくなくて、`date`コマンドで大体なんとかなるという事が分かったのでメモしておきます。

## 時間を比較する

二つの時間を比較したい。これは対象の時間がUnix時間で表現されていれば非常に簡単で、`date`コマンドを使用する必要すら無く、`test`乃至`[`で普通に比較ができます。もちろん取り扱いは数字として取り扱うことになるので、比較演算子として`-lt`か`-gt`を使用します。

``` shell
# 1626146220 = 2021-07-13T12:17
# 1626146340 = 2021-07-13T12:19
if [ 1626146220 -lt 1626146340 ]; then
    echo hello
fi

# Output:
# hello
```

対象の時間がUnix時間で表現されていない場合、Unix時間に変換して比較するのがおそらく最も簡単です。`date`コマンドで一度時間をパースして、Unix時間の形で出力します。パースには`-d` / `--date`オプションを使用します。Unix時間として出力するためのフォーマット文字は`%s`です。

``` shell
if [ $(date -d '2021-07-13T12:17' +%s) -lt $(date -d '2021-07-13T12:19' +%s) ]
then
    echo hello
fi

# Output:
# hello
```

`-d` / `--date` オプションは一般的なフォーマットの日付文字列をよしなにパースしてくれます。詳しいフォーマットは[GNU Coreutilsのマニュアル](https://www.gnu.org/software/coreutils/manual/html_node/Date-input-formats.html#Date-input-formats)などを見ると良いでしょう。

## n分前/n分後を求める

扨、ここからが本題なのですが、n分前/n分後を計算してみましょう。といっても、`date`コマンドを使用すると非常に簡単に求めることが可能です。

まずは現在時刻から1時間後を求めてみましょう。`-d` / `--date`オプションに加算したい時間を渡すだけです。

``` shell
date +%R
date -d '1 hour' +%R

# Output:
# 12:34
# 13:34
```

`hour`の他にも、`year`や`month`、`day`、`minute`などそれっぽいモノは大体使用することができます。珍しいところだと`fortnight`(2週間)を使うこともできます。
単に`1 hour`と書くのがなんとなく気持ち悪いという人は`now`や`today`、`this`などを使用してより自然言語っぽい感じで書くこともできます

``` shell
date -d 'this thursday' +%Y-%m-%dT%H:%M:%S
date -d 'now + 1 hour' +%Y-%m-%dT%H:%M:%S

# Output:
# 2021-07-15T00:00:00
# 2021-07-13T13:48:43
```

過去の時間を求めるには、頭に`-`(マイナス)をつけるか、最後に`ago`をつけます。

``` shell
date -d '1 hour ago' +%Y-%m-%dT%H:%M:%S

# Output
# 2021-07-13T11:50:38
```

これらの相対時間記法に関しては[Relative items in date strings](https://www.gnu.org/software/coreutils/manual/html_node/Relative-items-in-date-strings.html#Relative-items-in-date-strings)のページで説明があります。



