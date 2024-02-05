---
author: nasa9084
date: "2021-02-25T03:17:53Z"
description: ""
draft: false
cover:
  image: images/switchbot_logo.png
  relative: true
slug: go-switchbot
tags:
  - golang
  - gadget
  - switchbot
  - 赤外線
title: SwitchBot APIのGoクライアント、go-switchbotを書いた
---


[SwitchBot](https://www.switchbot.jp/)は所謂IoT機器を扱っているメーカーで、温度計を専用のハブ経由でインターネットに接続し、アプリから室温を確認したり、室温によってエアコンの設定を変更する、などといったホームオートメーションに役立つガジェットを複数販売しています。

しかし、それらのデータを確認できるのはSwitchBotのアプリからか、Bluetooth経由だけ、という状況で、私もHTTPのAPIを用意してくれたら良いのに、とずっと思っていました。

ところが昨日、社のSlackで、[こちらのissue](https://github.com/OpenWonderLabs/homebridge-switchbot-ble/issues/1)を共有してもらい、どうやら昨年12月ごろには[HTTPのAPI](https://github.com/OpenWonderLabs/SwitchBotAPI)が使えるようになっていたっぽいことが分かりました。

我が家にはHub Miniもあり、インターネットに接続してある状態ですから、早速次の手順でtokenを手に入れて試してみました:

1. スマホでSwitchBotのアプリを開く
2. プロフィールタブ > 設定と進み、アプリバージョンを10回連打する
3. 開発者向けオプションが表示されるので、開いてトークンを取得する
4. Authorizationヘッダにトークンを入れ、https://api.switch-bot.com/v1.0/devices にGETでリクエストを投げてみる

結果、確かに自宅のSwitchBotデバイスの一覧を取得することができました。

こうしちゃいられねぇ！と深夜に書いたGolang用のSwitchBotクライアントがこちらです:

[https://github.com/nasa9084/go-switchbot](https://github.com/nasa9084/go-switchbot)

ドキュメントはpkg.go.inなどで見て下さい: https://pkg.go.dev/github.com/nasa9084/go-switchbot
今回はFunctional Option PatternとGoogleっぽいAPIの合わせ技構成にしてみました。

例えば、デバイスの一覧を取得したい場合は次の様にすると取得することができます。

``` go
client := switchbot.New("SET_YOUR_SWITCHBOT_OPEN_TOKEN")

physical, virtual, _ := client.Device().List(context.Background())
```

第一返値のphysicalはSwitchbotデバイスの事で、第二返値のvirtualは赤外線で通信するデバイスの事です。SwitchBot APIでは、SwitchBotデバイスの事を物理デバイス、赤外線で接続するデバイス(エアコンなど)のことをvirtual remote deviceと区別して扱います。

API rate limitは1,000 request / dayとなっていて、あまり多いという訳ではないですが、例えば数分に一回、あるいは一時間に一回室温を取って記録するようなPrometheus Exporterを記述するといったことが捗ると思いますので、SwitchBotデバイスを使っている方は是非使ってみて下さい！



