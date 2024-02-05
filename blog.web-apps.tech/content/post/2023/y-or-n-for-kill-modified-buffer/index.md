---
title: y-or-n for kill modified buffer
author: nasa9084
date: 2023-09-26T23:13:06+09:00
draft: false
tags:
  - emacs
cover:
  image: images/short-answer-minibuffer.png
  relative: true
slug: y-or-n-for-kill-modified-buffer
---

emacs 29.1はuse-packageやeglotの同梱、tree-sitterのネイティブサポートなどが大きな変更として話題ですが、他にも非常に多くの変更があります。

[そのうちの一つ](https://git.savannah.gnu.org/cgit/emacs.git/tree/etc/NEWS?h=emacs-29#n664)が、変更が加えられた後保存されていないbufferをkillしようとしたときの質問です。これまで、編集があるbufferのkillはyesまたはnoの二択でしたが、第三の選択肢、`save and then kill`が加えられました。

もともと`(fset 'yes-or-no-p 'y-or-n-p)`として`y`または`n`で返事をすることが記憶された私の体はこれに順応することができず、毎回`y`で止まってしまいます。そこでこれを再びy-or-nに置き換える方法を探したのですが、まだまだみんなemacs 29.1を使っていないのか、情報が全然ありませんでした。しかし(多分)唯一の記事として、[Kill Unsaved Emacs Buffers UX: Replacing Yes/No/Save with Meaningful Options](https://christiantietze.de/posts/2023/09/kill-unsaved-buffer-ux-action-labels/)というブログ記事を見つけました。この記事は単純にy-or-nにするのではなく、もう少し踏み込んでいるのですが、それはさておき、これによると[`kill-buffer--possibly-save`](https://github.com/emacs-mirror/emacs/blob/emacs-29.1/lisp/simple.el#L10837)という関数で実装されているようです。
adviceをしても良いけれど、できれば関数全体をコピペして置き換えるみたいなことはやりたくないがどうしたモノか、と思っていたところ、`use-short-answers`という、何やらよさげな変数名が目に入りました。

`describe-variable`で説明を見てみると、non-nilの時に`yes-or-no-p`の代わりに`y-or-n-p`を使うための変数、ということらしいということが分かりました(どうやら28.1で導入された様子。知らなかった)。`(setq use-short-answers t)`として試したところ、上手い具合にy/n/sで確定できるようになりましたので、正解だったようです。

`yes-or-no-p`の説明を確認してみても、

> If the ‘use-short-answers’ variable is non-nil, instead of asking for
> "yes" or "no", this function will ask for "y" or "n".

と書いてありました。

というわけで、`(fset 'yes-or-no-p 'y-or-n-p)`を`(setq use-short-answers t)`に置き換えて解決、という感じでした。めでたしめでたし。
