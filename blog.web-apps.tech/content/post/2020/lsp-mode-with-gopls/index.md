---
author: nasa9084
date: "2020-02-07T08:19:29Z"
description: ""
cover:
  image: images/gopher.png
  relative: true
slug: lsp-mode-with-gopls
tags:
  - emacs
  - golang
  - lsp
title: emacs/lsp-mode + goplsでGo用のLSP環境を設定する
---


[Language Server Protocol](https://microsoft.github.io/language-server-protocol/)(以下LSP)はこれまでエディタ/IDEが独自に実装する必要があった、補完や定義参照、静的解析によるエラー分析などをサービスとして実現するためのプロトコルです。
LSPを実装したクライアントは、Language Serverを提供している言語であれば何でも補完や定義参照、静的解析といった便利機能を使用することができます。

Microsoftが2016年にその仕様を公開してから、多くのエディタ用のLSPのクライアント実装が作られ、また各種言語用のLanguage Serverも公開されています。

Go言語も例に漏れずLanguage Serverの実装がいくつか存在します。今回は準公式提供の[gopls](golang.org/x/tools/gopls)を使用して設定してみます。
もちろんemacsにも複数のLSP Client実装がありますが、今回は[lsp-mode](https://github.com/emacs-lsp/lsp-mode)を使用します。

まずはemacs用のパッケージをインストールします。次のモノを`package-install`か`package-list-packages`か、そのあたりでよしなにインストールします。

* lsp-mode
* lsp-ui
* company-lsp

インストールできたら、(私はuse-packageを使っているので)設定ファイルにuse-packageの設定を入れておきます。ついでにgo用の設定も入れておきましょう。

``` lisp
;; Golang
(defun lsp-go-install-save-hooks()
  (add-hook 'before-save-hook #'lsp-format-buffer t t)
  (add-hook 'before-save-hook #'lsp-organize-imports t t))

(use-package go-mode
  :ensure t
  :mode (("\\.go\\'" . go-mode))
  :init
  (add-hook 'go-mode-hook #'lsp-go-install-save-hooks))

;; Language Server
(use-package lsp-mode
  :ensure t
  :hook
  (go-mode . lsp-deferred)
  :commands (lsp lsp-deferred))

(use-package lsp-ui
  :ensure t
  :commands lsp-ui-mode)

(use-package company-lsp
  :ensure t
  :commands company-lsp)
```

goplsのインストールもしましょう。

``` shell
$ go get golang.org/x/tools/gopls@latest
```

これで完了です！



