---
author: nasa9084
categories:
- golang
- advent  calendar
date: "2017-12-13T02:44:32Z"
description: ""
draft: false
cover:
  image: images/gopher.png
slug: go-sqlrow
tags:
- golang
- advent  calendar
title: go-sqlrow
---


この記事は[Go2 Advent Calendar 2017](https://qiita.com/advent-calendar/2017/go2) 13日目の記事です。
昨日は[@kami_zh](https://qiita.com/kami_zh)さんの [Goで標準出力をキャプチャするパッケージを書いた](https://qiita.com/kami_zh/items/e6bea56db36bac8ca108) でした。

## go-sqlrow
Go言語で標準パッケージを使用してRDBMSからデータを取ってくるには、以下の様に書きます[^omit]。

``` go
type Person struct {
    ID   string
    Name string
}

db, _ := sql.Open("dn", "dsn")
row, _ := db.Query(`SELECT id, name FROM person where id='foo'`)
var p Person
row.Scan(&p.ID, &p.Name)
```

SQL文を発行するまではいいのですが、最後の行、`sql.Row#Scan`がくせ者です。
上記の例のように、`sql.row#Scan`は可変長個のポインタを引数にとり、それらにそれぞれ値をセットします。この例では値の数が2つのため大きな問題ではありませんが、値の数が増えた場合などは非常に面倒です。また、テーブルの構造が変わった場合なども非常に面倒です。

この問題を解決するため、[go-sqlrow](https://github.com/nasa9084/go-sqlrow)という小さなパッケージを作りました[^go-sqlrow.godoc]。
これは上記の`row.Scan`を代わりにやってくれるパッケージです。

機能・使い方は簡単で、先ほどの例を次の様に書き換えます。

``` go
type Person struct {
    ID   string
    Name string
}

db, _ := sql.Open("dn", "dsn")
row, _ := db.Query(`SELECT id, name FROM person where id='foo'`)
var p Person
sqlrow.Bind(row, &p)
```

後は内部で`row.Scan`相当の処理を行います。
unexportedなフィールドは`encoding/json`同様、`sql.Row`との対応がとれませんので、注意が必要です。

[^omit]: エラー処理やトランザクションなどは省略
[^go-sqlrow.godoc]: godoc: https://godoc.org/github.com/nasa9084/go-sqlrow

