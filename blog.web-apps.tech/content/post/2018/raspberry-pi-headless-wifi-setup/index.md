---
author: nasa9084
date: "2018-04-18T09:17:54Z"
cover:
  image: images/raspberry_pi.png
  relative: true
slug: raspberry-pi-headless-wifi-setup
tags:
  - raspberry pi
title: Raspberry PiのヘッドレスインストールでWi-Fiを設定する
---


uzullaさんがブログでこんなことを書いてた。

> しかし…/boot/のどこかに起動後実行されるスクリプトがあれば楽なのにな…（そこで無理やりwifi情報を書き込めば良いわけで）
[ヘッドレスRaspberry Pi Zero w(h)のコンソールやネットワークなど初期設定についてメモ - uzullaがブログ](http://uzulla.hateblo.jp/entry/2018/04/17/134526)

私も過去何度かRaspberry Pi Zeroのヘッドレスインストールをしてまして、実はヘッドレスインストールの時にWi-Fi情報を書き込めるファイルがあるのです。

`/boot/wpa_supplicant.conf`というファイルで、ここにWi-Fiの設定を書き込んで起動すると、raspbianが`/etc/wpa_supplicant/wpa_supplicant.conf`に良い感じにコピーしてくれます。

上記uzullaさんのブログでいうと、「**microSDのファイルを編集**」の時に一緒に書き込んでおくと、起動時にその情報を使ってWi-Fiをつかんでくれます。
あとは`nmap`するなり、ルータやらDHCPサーバやらのリース状況を確認するなりでラズパイに割当たったIPをゲットして`ssh pi@xxx.xxx.xxx.xxx`的にSSHするか、avahi/bonjourをつかって`ssh pi@raspberrypi.local`的にSSHするかでログインできます。

`wpa_supplicant.conf`の書き方は、上記uzullaさんのブログ記事の、「**Raspberry Pi Zero wにWifiを設定する**」ってところを見るか、[ここ](https://steveedson.co.uk/tools/wpa/)とか[ここ](https://mascii.github.io/wpa-supplicant-conf-tool/)にジェネレータを作ってくれてる人がいるので、利用して生成すると良いと思います。
パスワードは平文でOKなので、適当な文字列を突っ込んで手元で書き換えると安心かもしれないです。

なお、NOOBSでやるときは、`wpa_supplicant.conf`と`ssh`は`/boot`ではなく、ルートディレクトリにおけばOKです。
さらに、`recovery.cmdline`と言うファイルの`quiet`という部分を`vncinstall`に書き換えることで起動したNOOBSにVNC接続できるようになります。

