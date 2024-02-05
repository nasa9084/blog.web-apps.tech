---
author: nasa9084
date: "2017-01-10T17:05:00Z"
description: ""
draft: false
cover:
  image: images/python-1.jpg
slug: bottle-websocket_with_python3
tags:
  - python
  - python3
  - websocket
  - bottle
title: Python 3でbottle-websocketを使う
---


Python 3で[bottle-websocket](https://github.com/zeekay/bottle-websocket)がそのままでは動かなかったので簡単にメモしておきます。

# 解決方法
通常通り`pip install bottle-websocket`してから、 `pip install karellen-geventws`すると動作するようになります。
karellen-geventwsはGeventWebSocketのforkで、Python 3に対応しています。

