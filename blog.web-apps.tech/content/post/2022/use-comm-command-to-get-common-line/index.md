---
title: 二つのファイルの共通行(または共通しない行)を得る
author: nasa9084
date: 2022-09-28T23:59:17+09:00
draft: false
categories:
- bash
tags:
- bash
- shell
- zsh
cover:
  image: images/shell_prompt.png
  relative: true
slug: use-comm-command-to-get-common-line
---

例えば、サービスAでは登録されているけれどもサービスBには登録されていないユーザの一覧を得たい、という様な場合。もちろん`diff`でよしなにやることもできますが、`comm`も便利です。

例えば次の様にリストがあるとします。

サービスAのユーザーリスト(users_a.txt):

```text
alice
bob
charlie
dave
oscar
```

サービスBのユーザーリスト(users_b.txt):

```text
charlie
isaac
justin
mallory
oscar
```

これらに対して`comm`を使うと次の出力が得られます:

``` shell
$ comm users_a.txt users_b.txt
alice
bob
                charlie
dave
        isaac
        justin
        mallory
                oscar
```

TABで揃えられた列がそれぞれ左から、Aにだけ存在する行、Bにだけ存在する行、Cにだけ存在する行、となっています。これだけだと別にそれほど便利ではないんですが、`comm`はそれぞれの行を非表示にする事もできます。それぞれ、非表示にしたい行を`-1` `-2` `-3`で指定します。

Aだけに存在する行を表示する:

``` shell
$ comm -23 users_a.txt users_b.txt
alice
bob
dave
```

両方に存在する行を表示する:

``` shell
$ comm -12 users_a.txt users_b.txt
charlie
oscar
```

`diff`だと`diff`の後に`grep`やらなんやらして必要な物を抜き出す必要があるでしょうから、これは楽ですね。

もちろん、`diff`の様に他のコマンドの標準出力を取ることもできます。

例えば`https://example.com/api/users_b.txt`が先ほどのusers_b.txtと同じ内容を返すとするとしてAだけに登録しているユーザーを取得したい場合

``` shell
$ curl -s https://example.com/api | comm -23 users_a.txt -
alice
bob
dave
```

とできますし、2つのユーザーリストを返すAPIが有ったとして、共通のユーザーを一覧にしたい場合、次の様にできます:

``` shell
$ curl https://example1.com/users | jq .
[
  {
    "username": "alice"
  },
  {
    "username": "bob"
  },
  {
    "username": "charlie"
  },
  {
    "username": "dave"
  },
  {
    "username": "oscar"
  }
]
$ curl https://example2.com/users | jq .
[
  {
    "username": "charlie"
  },
  {
    "username": "isaac"
  },
  {
    "username": "justin"
  },
  {
    "username": "mallory"
  },
  {
    "username": "oscar"
  }
]
$ comm -12 \
  <(curl -s https://example1.com/users | jq -r '.[].username') \
  <(curl -s https://example2.com/users | jq -r '.[].username')
charlie
oscar
```

便利ですね。

なお、入力となるテキストはソートされている必要があることに注意が必要です。

以上です。
