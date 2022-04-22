---
author: nasa9084
categories:
- bash
- shell
date: "2021-09-08T09:33:25Z"
description: ""
draft: false
cover:
  image: images/shell_prompt.png
slug: bash-here-document-makes-tmp-file
tags:
- bash
- shell
title: bashのhere-documentは一時ファイルを作成するらしい
---


皆さん使ってますか、here-document。bashでいうとこういう奴:

``` bash
cat <<EOF
this
is
here
document
EOF
```

出力はこう:

```
this
is
here
document
```

複数行に渡るテキストをリテラルとして表現したい場合に便利ですね。で、shellscriptからREST APIにリクエストを投げたくて、here-documentを使ってJSONをべたっとスクリプト内で書いてたんですけど、こんなエラーが出てました(パスはもちろん違いますよ。念のため。):

```
/path/to/shellscript/using/here-document.sh: line 179: cannot create temp file for here-document: No space left on device
```

全然知らなかったけど、here-documentって一時ファイルを作成するんですね。確かめてみます。

```
$ docker run -it --rm centos:7 bash
[root@8017e5e28d6e /]# yum install -y strace
(中略)
[root@8017e5e28d6e /]# cat <<EOF > script.sh
> cat <<EOS
> foo
> bar
> baz 
> EOS
> EOF
[root@8017e5e28d6e /]# strace -f bash script.sh |& grep tmp
[pid    61] stat("/tmp", {st_mode=S_IFDIR|S_ISVTX|0777, st_size=4096, ...}) = 0
[pid    61] faccessat(AT_FDCWD, "/tmp", W_OK) = 0
[pid    61] statfs("/tmp", {f_type=OVERLAYFS_SUPER_MAGIC, f_bsize=4096, f_blocks=6159700, f_bfree=4601655, f_bavail=4282999, f_files=1572864, f_ffree=1414766, f_fsid={val=[3003212711, 622231591]}, f_namelen=255, f_frsize=4096, f_flags=ST_VALID|ST_RELATIME}) = 0
[pid    61] open("/tmp/sh-thd-1631118709", O_WRONLY|O_CREAT|O_EXCL|O_TRUNC, 0600) = 3
[pid    61] open("/tmp/sh-thd-1631118709", O_RDONLY) = 4
[pid    61] unlink("/tmp/sh-thd-1631118709") = 0
```

`/tmp/sh-thd-1631118709` に書き込みをしている様子が見て取れます。

というわけで、bashのhere-documentは一時ファイルを作成します。なので、ストレージに全く余裕がない状態だと実行に失敗します。実際調査をしたところ、当該サーバはコマンドのサジェストもできないくらいストレージがパンパンでした。
ストレージが埋まる可能性がある環境でスクリプトを実行する必要がある場合、here-documentの部分でもエラーが発生する場合がある、というのを頭に入れておかないと、`cat`しているだけだし、とエラー処理を省いてしまいそうになりますから、要注意ですね。

以上です。



