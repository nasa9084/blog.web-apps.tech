---
title: RenovateでGitHub Actionsで使っているHugoを更新する
author: nasa9084
date: 2022-09-27T01:53:45+09:00
draft: false
categories:
- github
tags:
- github
cover:
  image: images/renovate_logo.jpg
  relative: true
slug: renovate-hugo-version
---

GitHub ActionsとHugoを使用して静的サイト生成を行う場合、[peaceiris/actions-hugo](https://github.com/peaceiris/actions-hugo)を使用するか、自分で適当にHugoをインストールするかのいずれかが一般的だと思います。このブログでは、セットアップ当初はpeaceiris/actions-hugoを使っていたのですが、最近debパッケージを自分でインストールする方式に切り替えました。
[gohugoio/hugoのreleases](https://github.com/gohugoio/hugo/releases)から直接debパッケージを持ってきているので、peaceiris/actions-hugoとは違い`latest`指定をする事ができず、Hugoの更新を手動で行う必要があり、ちょっと面倒だな〜と感じていました(しかもHugoは結構開発が活発で、更新もはやいんですよね)。

仕事のリポジトリでは最近renovateがどんどん導入されているので、これを機にrenovateを導入することにしました。

Hugoのバージョンは[GitHub ActionsのWorkflowファイル内にenvで指定されていて](https://github.com/nasa9084/blog.web-apps.tech/blob/7d285d9448d11cdfb09369748229f35b63f836cc/.github/workflows/gh-pages.yml#L31-L32)、もちろん標準状態のrenovateはこれを検知・更新してくれません。これに対応するには、[regexManagers](https://docs.renovatebot.com/configuration-options/#regexmanagers)を使用します。

regexManagersは正規表現でバージョン番号を引っかけて更新してくれる[manager](https://docs.renovatebot.com/modules/manager/)で、`fileMatch`と`matchStrings`という二つの正規表現を書くことで使う事ができます。

`fileMatch`はその名の通り、どのファイルを監視するかを指定する正規表現で、今回はGitHub Actionsの設定ファイルを監視して欲しいので、デフォルトの`github-actions` managerが監視する正規表現をそのままコピーしてきて使用しました。

``` yaml
"fileMatch": [
   "^(workflow-templates|\.github\/workflows)\/[^/]+\.ya?ml$",
   "(^|\/)action\.ya?ml$"
]
```

`matchStrings`はバージョンを引っかけるための正規表現で、`datasource`、`depName`、`currentValue`の三つの値をキャプチャするか、`datasourceTemplate`、`depNameTemplate`、`currentValueTemplate`で値を指定する必要があります。`datasource`(`datasourceTemplate`)と`depName`(`depNameTemplate`)はバージョンを比較するためのデータソースと依存の名称で、今回はGitHub上にあるgohugoio/hugoリポジトリのリリースと比較をしたいため、`datasourceTemplate`に`github-releases`を、`depNameTemplate`に`gohugoio/hugo`を指定しました。`currentValue`(`currentValueTemplate`)は現在のバージョン番号を表す値で、これはGitHub Actionsの設定ファイルに書かれている値なので、`matchStrings`で引っかけてキャプチャします。

``` yaml
"matchStrings": [
  "HUGO_VERSION: (?<currentValue>.*)"
],
"datasourceTemplate": "github-releases",
"depNameTemplate": "gohugoio/hugo"
```

設定ファイル全体としては次の様になります:

``` yaml
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": [
    "config:base"
  ],
  "regexManagers": [
    {
      "fileMatch": [
         "^(workflow-templates|\.github\/workflows)\/[^/]+\.ya?ml$",
         "(^|\/)action\.ya?ml$"
      ],
      "matchStrings": [
        "HUGO_VERSION: (?<currentValue>.*)"
      ],
      "datasourceTemplate": "github-releases",
      "depNameTemplate": "gohugoio/hugo"
    }
  ]
}
```

これで無事[renovateがHugoのバージョンをチェックしてくれる](https://github.com/nasa9084/blog.web-apps.tech/pull/11)様になりました。めでたしめでたし。
