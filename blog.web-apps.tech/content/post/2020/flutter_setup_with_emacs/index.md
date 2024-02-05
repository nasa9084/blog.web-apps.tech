---
author: nasa9084
date: "2020-01-18T15:18:55Z"
description: ""
cover:
  image: images/flutter_logo.png
  relative: true
slug: flutter_setup_with_emacs
title: Flutter環境構築 with emacs
---


ここ数日、FlutterでAndroidアプリを書く、ということに入門してみています。
Androidアプリの開発自体は大分前(無印Galaxy Sを使っていた頃なので、EclairとかFroyoとかの頃)にすこしだけやったことがあるんですが、そのころと比べるとかなり簡単に、きれいなアプリがシュッと動いて、ちょっとばかし感動しています。

扨、Flutter/Android開発の環境構築ですが、ほとんどのドキュメントがAndroid Studioを前提としており、私のようなemacsユーザがどうしたらいいのか、ちょっとばかし躓きそうなので、メモがてら残しておきます。

なお、基本的な手順は[公式サイト](https://flutter.dev/docs/get-started/install/macos)に準じます。また、環境はmacOS Catalina バージョン 10.15.1、emacsはbrewで入れるemacs-mac 26.3です。
Flutterのバージョンは執筆時点でv1.12.13+hotfix.5でした。

## Flutter SDKのインストール

[公式サイト](https://flutter.dev/docs/get-started/install/macos)のダウンロードリンクからFlutter SDKをダウンロードしてきて解凍、任意の場所に配置します。私はなんとなくで`$HOME/.local/flutter`以下に配置しています。

``` bash
$ wget https://storage.googleapis.com/flutter_infra/releases/stable/macos/flutter_macos_v1.12.13+hotfix.5-stable.zip
$ unzip flutter_macos_v1.12.13+hotfix.5-stable.zip
$ mv flutter $HOME/.local/
```

配置できたらPATHを通します。
私はzshを使っているので、`$HOME/.zshrc`に以下の行を追加しました。

``` bash
# Flutter SDK
export PATH="$PATH:$HOME/.local/flutter/bin"
```

PATHを通したら、`flutter --version`でちゃんとPATHが通っているかを確認します。

## Android SDKのインストール

[公式サイト](https://flutter.dev/docs/get-started/install/macos)の手順ではAndroid Studioを入れろとのことですが、emacsを使う予定なので、Android Studioはインストールせず、Android SDKのみをインストールします。
[Android Studioのサイト](https://developer.android.com/studio)へアクセスし、[DOWNLOAD OPTIONS](https://developer.android.com/studio#downloads)をクリックしてCommand line tools onlyのところからmacOS用のCommand line toolsをダウンロード、Flutter SDKと同様に適宜配置してPATHを通すか、簡単に`brew cask install android-sdk`とします。
私は今回はbrewで入れました。(Flutter SDKもbrewで配布されていますが、Flutter SDKは少し古かったので、公式からダウンロードしてきた方が良さそうです)

`brew cask install android-sdk`をしたときにもメッセージが出ますが、android-sdkを使用するにはJDK 8が必要なので、`brew cask install adoptopenjdk8`としてJDKもインストールしておきます。

インストールできたら、`ANDROID_HOME`環境変数をandroid-sdkのパス(brewで入れた場合は`/usr/local/share/android-sdk`)に設定し、android-sdkにもPATHを通しておきます。

``` bash
# Android SDK
export ANDROID_HOME="/usr/local/share/android-sdk"
export PATH="$PATH:/usr/local/share/android-sdk-tools"
export PATH="$PATH:/usr/local/share/android-sdk/tools/bin"
export PATH="$PATH:/usr/local/share/android-sdk/platform-tools"
```

PATHが正しく通っていれば、`sdkmanager`が使えるようになっているはずなので、次のコマンドでSDKをインストールします。

``` bash
sdkmanager "platform-tools" "platforms;android-28" "build-tools;28.0.3"
```

続いて、`flutter doctor --android-licenses`を実行し、android SDKのライセンスに同意します。

ここまでやったあと、`flutter doctor`コマンドを実行すると、FlutterおよびAndroid toolchainがOKになると思いますので、あとはお手持ちのAndroid端末のUSBデバッグを有効にし、[公式のデモアプリを実行してみましょう](https://flutter.dev/docs/get-started/test-drive?tab=terminal)。

## emacsの設定をする

`use-package`を使用している場合は、次の設定を入れてemacsを再起動します

``` lisp
(use-package dart-mode
  :ensure t
  :custom
  (dart-format-on-save t)
  (dart-sdk-path "~/.local/flutter/bin/cache/dart-sdk/"))

(use-package flutter
  :ensure t
  :after dart-mode
  :bind (:map dart-mode-map
              ("C-M-x" . #'flutter-run-or-hot-reload))
  :custom
  (flutter-sdk-path "~/.local/flutter/")
  :hook (dart-mode . (lambda ()
                          (add-hook 'after-save-hook #'flutter-run-or-hot-reload nil t))))
```

`dart-sdk-path`および`flutter-sdk-path`の値は適宜変更してください。これでdartファイルを変更時にホットリロードが走るようになります。



