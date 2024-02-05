---
author: nasa9084
date: "2017-05-02T05:06:00Z"
description: ""
draft: false
cover:
  image: images/gopher.png
  relative: true
slug: golang_nethttp_basicauth
tags:
  - golang
  - net/http
  - basic
title: 'golang: net/httpでBASIC認証'
---


golangでベーシック認証するのはどうしたら良いのかなー。って思ってたら、`net/http`でhandlerに渡される`http.Request`に`BasicAuth()`というメソッドが生えてました。
これはBASIC認証用のユーザ名、パスワード、ヘッダ解析のフラグという値を返してくれます。
なので、

``` go
func handler(w http.ResponseWriter, r *http.Request) {
    username, password, ok := r.BasicAuth()
    if !ok {
        return
    }
    if username == "hogehogeuser" && password == "fugafugapasswd" {
        // something
    }
}
```

とすることで認証することができます。簡単、簡単。
なお残念ながらダイジェスト認証はサポートされていない様子。

