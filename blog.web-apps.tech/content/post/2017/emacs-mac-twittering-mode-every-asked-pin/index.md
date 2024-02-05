---
author: nasa9084
date: "2017-05-09T00:49:00Z"
cover:
  image: images/emacs_logo-1.png
  relative: true
slug: emacs-mac-twittering-mode-every-asked-pin
tags:
  - emacs
  - macos
  - twitter
  - twittering-mode
title: emacs-macでtwittering-modeを使った際に毎回PINを聞かれる問題の解消
---


twitterのクライアントとして、日頃からemacs上で動くクライアントの"twittering-mode"を使用しています。
ところが最近、新しいmacにインストールしたemacs-macでtwittering-modeを起動すると、毎回twitterのPINを聞かれるようになってしまいました。
毎回、毎回、起動時の暗号化フェーズで
```
Encrypt failed Exit
```
と言われ・・・・
以前使っていたmacではこのようなことが無かったため、困っていたのですが、以下の手順により解決できました。


# 背景
結論から言うと、これはGnuPGのバージョンが新しくなったことによる問題でした。
GnuPG2.1.0から、gpg-agentとpinentryと呼ばれる二つのソフトウェアの利用が必須となりました。
twittering-mode事態はgpg-agentやpinentryが必須でも基本的に問題なく動作するようにはなっているハズ・・・でした。
しかし、これらのソフトウェアの必須化に伴って、これまで標準入力から入力できていたパスフレーズが標準入力から入力できなくなっており、そのために暗号化に失敗して毎回PINを聞く・・・という状態になっていたようです。

# 解決策
みんな大好き[arch wiki](https://wiki.archlinuxjp.org/index.php/GnuPG#.E7.84.A1.E4.BA.BA.E3.81.AE.E3.83.91.E3.82.B9.E3.83.95.E3.83.AC.E3.83.BC.E3.82.BA)に解決策がありました。
まず、`~/.gnupg/gpg-agent.conf`に以下のように記述します。
```
allow-loopback-pinentry
```

つぎに、`~/.gnupg/gpg.conf`に以下のように記述します。
```
pinentry-mode loopback
```

最後に、gpg-agentを再起動します。
コマンドラインから、
``` bash
$ gpgconf --kill gpg-agent
```
でgpg-agentを再起動できます。

以上で、twittering-modeが正常に使用できるようになるはずです。

