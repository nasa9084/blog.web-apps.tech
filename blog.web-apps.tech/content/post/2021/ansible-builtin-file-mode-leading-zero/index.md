---
author: nasa9084
date: "2021-12-13T10:45:28Z"
description: ""
cover:
  image: images/ansible.png
  relative: true
slug: ansible-builtin-file-mode-leading-zero
tags:
  - ansible
title: ansible.builtin.fileのmodeパラメータは頭に0が必要
---


多分ほとんどのケースでは気にすることもなく`0755`とか`0644`とか書くと思うんですが、特殊な属性を付ける必要があるときに困るよ、という話。

世の中にはSUIDとかSGIDとかスティッキービットとかいう、特殊な属性がありまして、例えば基本のファイルパーミッションが`0755`でSUIDを指定したいという場合は`chmod`で言うと`chmod 4755 path/to/file`といった感じになるんですけれども、`ansible.builtin.file`のmodeパラメータでは以下の様に書くとパーサが10進数として解釈して訳の分からんことになってしまいます。

``` yaml
ansible.builtin.file:
  path: path/to/file
  mode: 4755
```

これはこう書く必要があります:

``` yaml
ansible.builtin.file:
  path: path/to/file
  mode: 04755
```

もしくはこう:

``` yaml
ansible.builtin.file:
  path: path/to/file
  mode: '4755'
```

これは例えば、結構古いAnsible playbookなんかで、

``` yaml
file: path=path/to/file mode=4755
```

とか書いていたやつを書き直したりしたときに注意が必要です。

まぁ、[公式ドキュメントに書いてある](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/file_module.html#parameter-mode)んですけど、そうは言ってもみんなそんなに細かいところまで読んでないでしょ、という。

> You must either add a leading zero so that Ansible's YAML parser knows it is an octal number (like 0644 or 01777) or quote it (like '644' or '1777') so Ansible receives a string and can do its own conversion from string into number.



