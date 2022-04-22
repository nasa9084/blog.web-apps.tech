---
author: nasa9084
categories:
- vagrant
- vm
- box
date: "2017-07-11T02:39:00Z"
description: ""
draft: false
cover:
  image: images/vagrant.png
slug: create_vagrant_box_from_vagrant_vm
tags:
- vagrant
- vm
- box
title: Vagrantで起動したVMからBOXを作る
---


Vagrantで、centos/7等の標準的なBOXをベースにカスタムしたVMを保存しておいたり、配布したりするためにBOXを作る手順です。
自分用のメモとして。

# VM内での操作
## VBoxGuestAdditionsを導入する。
以下のソースを適当なファイルに保存する。(ここでは`$HOME/ins.sh`とします。)
このとき、二行目はVirtualboxのバージョンに合わせて適宜書き換える。
リストは[こちら](http://download.virtualbox.org/virtualbox/)

``` bash
yum install -y wget kernel kernel-devel perl gcc
wget http://download.virtualbox.org/virtualbox/5.1.18/VBoxGuestAdditions_5.1.18.iso
mkdir /media/VBoxGuestAdditions
mount -o loop,ro VBoxGuestAdditions_5.1.18.iso /media/VBoxGuestAdditions
sh /media/VBoxGuestAdditions/VBoxLinuxAdditions.run
rm VBoxGuestAdditions_5.1.18.iso
umount /media/VBoxGuestAdditions
rmdir /media/VBoxGuestAdditions
```

保存したスクリプトを管理者権限で実行します。
``` bash
sudo bash ins.sh
```

## yumをきれいにする
軽量化のため、yumをきれいにします。
``` bash
sudo yum clean all
```

## ゼロ埋めして消す
圧縮効率向上のため、ゼロ埋めして消します。
``` bash
sudo dd if=/dev/zero of=/EMPTY bs=1M
sudo rm /EMPTY
```

# ホストからの操作
## BOXを作成する
``` bash
vagrant package
```

** box listに登録する
``` bash
vagrant box add package.box
```

