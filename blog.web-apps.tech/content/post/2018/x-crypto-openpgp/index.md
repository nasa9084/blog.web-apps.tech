---
author: nasa9084
date: "2018-11-26T10:15:09Z"
cover:
  image: images/gopher-2.png
  relative: true
slug: x-crypto-openpgp
tags:
  - golang
  - encrypt
  - openpgp
  - x/crypto/openpgp
title: x/crypto/openpgpでデータを暗号化する
---


OpenPGPはPGP(Pretty Good Privacy)をベースとした暗号化フォーマットです。
Go言語でも[`golang.org/x/crypto/openpgp`](https://godoc.org/golang.org/x/crypto/openpgp)という準標準パッケージで提供されています。

PGPは公開鍵暗号としてメールの暗号化等でよく使用されますが、パスフレーズを用いた対称暗号として使用することもできますので、今回はこちらを紹介します。

## TL;DR

* 暗号化には`SymmetricallyEncrypt()`を使用する
* 復号には`ReadMessage()`を使用する
    * `prompt`次第で無限ループする恐れがあるので注意

## 暗号化

`x/crypto/openpgp`パッケージでパスフレーズを用いてファイルを暗号化するには、`SymmetricallyEncrypt`関数を使用します。
シグネチャは次のようになっています。

``` go
func SymmetricallyEncrypt(ciphertext io.Writer, passphrase []byte, hints *FileHints, config *packet.Config) (plaintext io.WriteCloser, err error)
```

順番に見て行きます。まずは引数から。

第一引数である`ciphertext`には、暗号化されたテキストを出力する`io.Writer`を与えます。`*os.File`などを与えてもいいですが、`*bytes.Buffer`などを与えてその後`*os.File`にコピーする方が良いでしょう。可読なテキストではなく、バイト列が出力されます。

第二引数の`passphrase`はその名の通り、パスフレーズを与えます。

第三引数の`hints`には暗号化するファイルのメタデータなどを含むことができますが、単純に`nil`を与えても良いです。

第四引数の`config`で暗号化方式や乱数エントロピーソース、圧縮アルゴリズムなどを設定することができます。設定しなければ乱数として`crypto/rand.Reader`が、ハッシュ関数としてSHA-256が、暗号化関数としてAES-128が、現在時刻として`time.Now`が、RSAのビット数として2048がそれぞれ使用されます。圧縮はされません。

返り値は二値で、`io.WriteCloser`と`error`です。返り値の`io.WriteCloser`に暗号化したい内容を書き込むことで暗号化が行われます。必ず`Close`する必要があるので忘れないように注意しましょう。

### 使用例

``` go
func encrypt(in io.Reader, out io.Writer, passphrase []byte) error {
    // omit error handling
    w, _ := openpgp.SymmetricallyEncrypt(out, passphrase, nil, nil)
    defer w.Close()
    
    io.Copy(w, in)
    return nil
}
```

## 復号

暗号化したファイルを復号するには、`ReadMessage`関数を使用します。Decrypt〜のような関数ではないので注意が必要でしょう。関数のシグネチャは次のようになっています。

``` go
func ReadMessage(r io.Reader, keyring KeyRing, prompt PromptFunction, config *packet.Config) (*MessageDetails, error)
```

こちらも順に見て行きましょう。

第一引数の`io.Reader`には暗号化されたファイルを与えます。読み込みですから、`*os.File`を直接与えてもいいかもしれません。

第二引数は復号に使用する鍵への`KeyRing`ですから、パスフレーズで暗号化した今回は`nil`を与えます。

第三引数である`prompt`がこの関数の肝で、パスフレーズを返すコールバック関数を与えます。`PromptFunction`の定義は次のようになっています。

``` go
type PromptFunction func(keys []Key, symmetric bool) ([]byte, error)
```

今回の用途の場合は引数を使用する必要はありません。基本的には単純にパスフレーズを返す関数とするか、標準入力等からパスフレーズを読み込んで返す、という関数として作成すれば良いでしょう。

一点だけ注意点があり、ドキュメントに次のような記載があります。

>  If the decrypted private key or given passphrase isn't correct, the function will be called again, forever.

返されたパスワードが間違っていると、永遠にこの関数が呼ばれ続けます。そのため、二度目に呼ばれた時にエラーを返すように、なんらかの対策が必要です。
例えば、次のようなクロージャを作成しても良いでしょう。

``` go
func promptFn(passphrase []byte) openpgp.PromptFunction {
    var called bool
    return func([]Key, bool) ([]byte, error) {
        if called {
            return nil, errors.New("the passphrase is invalid")
        }
        called = true
        return passphrase, nil
    }
}
```

第四引数の`config`は暗号化の時に使用したものと同じものを使用します。

返り値の`*MessageDetails`に復号された内容が含まれています。この構造体はいくつかのメタデータを含みますが、実際のデータは`MessageDetails.UnverifiedBody`という`io.Reader`に格納されています。

### 使用例

前節で紹介した`promptFn`クロージャを使用した例です。

``` go
func decrypt(in io.Reader, out io.Writer, passphrase []byte) error {
    // omit error handling
    md, _ := openpgp.ReadMessage(in, nil, promptFn(passphrase), nil)
    io.Copy(out, md.UnverifiedBody)
    return nil
}
```



