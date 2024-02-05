---
author: nasa9084
date: "2017-09-29T14:20:16Z"
description: ""
draft: false
cover:
  image: images/OpenStack_logo.png
  relative: true
slug: kolla-ansible-precheck-error
summary: 「OpenStack Kolla(Ocata)環境の構築」を参考にOpenStack Kollaのセットアップを行っていたら、エラーが出ました。
tags:
  - ansible
  - openstack
  - kolla
title: Kolla-ansible precheckで発生するエラーの対処
---


[OpenStack Kolla(Ocata)環境の構築](https://qiita.com/lychee3/items/e0a57c833450654006a5)を参考にOpenStack Kollaのセットアップを行っていたら、以下の様なエラーが出ました。

```
TASK [rabbitmq : fail] **************************************************************************************************************************
 [WARNING]: when statements should not include jinja2 templating delimiters such as {{ }} or {% %}. Found: '{{ hostvars[item['item']]['ansible_'
+ hostvars[item['item']]['api_interface']]['ipv4']['address'] }}' not in '{{ item.stdout }}'

fatal: [localhost]: FAILED! => {"failed": true, "msg": "The conditional check ''{{ hostvars[item['item']]['ansible_' + hostvars[item['item']]['api_interface']]['ipv4']['address'] }}' not in '{{ item.stdout }}'' failed. The error was: Invalid conditional detected: EOL while scanning string literal (<unknown>, line 1)\n\nThe error appears to have been in '/usr/share/kolla-ansible/ansible/roles/rabbitmq/tasks/precheck.yml': line 54, column 3, but may\nbe elsewhere in the file depending on the exact syntax problem.\n\nThe offending line appears to be:\n\n\n- fail: msg=\"Hostname has to resolve to IP address of api_interface\"\n  ^ here\n"}
```

[ansible/ansibleのissue #22397](https://github.com/ansible/ansible/issues/22397)を見ると、Ansible 2.3からwhen文ではJinja2のテンプレートデリミタを使用するのが非推奨となったようです。

対症療法ですが、`pip install ansible==2.2`として少し古いバージョンのansibleをインストールすればエラーは出なくなります。

