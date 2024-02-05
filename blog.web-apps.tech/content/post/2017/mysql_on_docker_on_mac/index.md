---
author: nasa9084
date: "2017-05-02T06:57:00Z"
description: ""
draft: false
cover:
  image: images/docker-mysql.jpg
slug: mysql_on_docker_on_mac
tags:
  - docker
  - macos
  - mysql
title: MySQL on docker macな開発環境でローカルからMySQLに接続する
---


MySQLをdocker上に立てることで、ローカルの環境を汚さずにMySQLを使ったアプリケーションの開発を行うことができます。
特に、練習段階や、動作確認などの場合、 `test_hogehoge` な感じのデータベースやテーブルを作ってしまい、後片付けをしないために汚くなっていく、なんてこと、あるんじゃないでしょうか。

さて、MySQL on dockerへの接続、今までローカルにMySQLを入れて開発していたのでちょっと躓きました。

``` bash
$ docker run -d -p 3306:3306 -e MYSQL_ROOT_PASSWORD password mysql:latest
```

上記のように起動した場合、次のようにコマンドを実行することで接続することができます。
``` bash
$ mysql -u hoge -p -h 127.0.0.1 --port 3306
```
特にポイントなのが、`-h 127.0.0.1`の部分。`localhost`にしてしまうと、socketで接続しようとして、エラーになっちゃうんですね。
ここでしばらく悩みました。。。

以上、簡単ですがメモがてら。

