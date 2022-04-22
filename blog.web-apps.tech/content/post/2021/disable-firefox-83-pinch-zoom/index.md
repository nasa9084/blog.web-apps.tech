---
author: nasa9084
categories:
- firefox
- macos
date: "2021-02-02T06:49:47Z"
description: ""
draft: false
cover:
  image: images/firefox.png
slug: disable-firefox-83-pinch-zoom
tags:
- firefox
- macos
title: Firefox 83で導入されたピンチズームを無効にする
---


11月7日にリリースされた[Firefox 83](https://www.mozilla.org/en-US/firefox/83.0/releasenotes/)では、タッチスクリーン/タッチパッドを搭載したデバイスでのピンチズームがサポートされました。

が、私としてはスクロールしたいだけなのにズームされてしまったりと誤動作が多く、使いづらいなーと感じましたので、無効化しましたが、設定画面からは無効化できなかったのでメモを残しておきます。

1. [about:config](https://support.mozilla.org/ja/kb/about-config-editor-firefox)を開く
2. `zoom`で検索し`apz.allow_zooming`をfalseに設定する

以上です。



