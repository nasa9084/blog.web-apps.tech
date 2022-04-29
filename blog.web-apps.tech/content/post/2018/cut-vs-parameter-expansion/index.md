---
author: nasa9084
categories:
- bash
- zsh
- shell
- command-line
date: "2018-02-26T08:07:11Z"
description: ""
draft: false
cover:
  image: images/shell_prompt.png
  relative: true
slug: cut-vs-parameter-expansion
tags:
- bash
- zsh
- shell
- command-line
title: cut vs. parameter expansion
---


**TL;DR**::  bash/zsh parameter expansion is faster than cut.

## which is faster?

Consider you want to take out hostname from URL or IP with port like `some.mysql.server:3306` or `192.168.1.10:3306` using bash/zsh.
There are some way to do this.

The first way is using `cut` command:

``` shell
$ TARGET="192.168.1.10:3306"
$ echo ${TARGET} | cut -d ":" -f 1
```

Now printed `192.168.1.10` on your screen.

The second way is using "shell parameter expansion", which is functions of bash/zsh built-in.
You can use shell parameter expansion like below:

``` shell
$ TARGET="192.168.1.10:3306"
$ echo ${TARGET%:*}
```

Printed `192.168.1.10` too.

Which is faster, using cut or shell parameter expansion?
I make a small benchmark.

``` shell
$ time for i in {1..1000}; do echo $(echo ${TARGET} | cut -d ':' -f 1); done > /dev/null

real	0m17.422s
user	0m1.325s
sys	0m1.890s
$ time for i in {1..1000}; do echo ${TARGET%:*}; done > /dev/null

real	0m0.008s
user	0m0.007s
sys	0m0.001s
```

Wow! In this situation, shell parameter expansion is faster than cut command solution!

Because this is very simple situation, shell parameter expantion is not always better than cut command.
However, situations like this example, we should use shell parameter expansion.

