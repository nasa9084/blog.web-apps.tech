---
author: nasa9084
date: "2017-12-28T04:29:59Z"
description: ""
cover:
  image: images/vagrant-1.png
  relative: true
slug: vagrant-vmware-fusion-nested-vm
tags:
  - vagrant
  - vmware
  - fusion
  - nested-vm
title: Vagrant/vmware-fusionでハードウェア仮想化を有効にしたVMを作成する
---


vmware fusionを使用している場合、仮想マシンのCPU設定で`この仮想マシンでハイパーバイザアプリケーションを有効にする`にチェックを入れることで仮想マシン内でKVMを動作させることができるようになります。
ドキュメントには載っていませんが[^vmx-custom]、Vagrant + vmware-fusion pluginの構成でも設定することが可能です。
Vagrantfileに以下の記述を追加します。

``` ruby
config.vm.provider "vmware_fusion" do |v|
    v.vmx["vhv.enable"] = "TRUE"
end
```

[^vmx-custom]: vmxの設定をする方法自体は[公式ドキュメント](https://www.vagrantup.com/docs/vmware/configuration.html#vmx-customization)にも記載がありますが、詳細がありません

