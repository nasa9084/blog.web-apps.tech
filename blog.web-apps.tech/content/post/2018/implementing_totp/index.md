---
author: nasa9084
categories:
- golang
- crypto/sha1
- encoding/binary
- crypto/hmac
- bytes
- totp
- 2fa-auth
- hotp
- rfc
date: "2018-03-30T17:03:45Z"
description: ""
draft: false
cover:
  image: images/gopher-5.png
  relative: true
slug: implementing_totp
tags:
- golang
- crypto/sha1
- encoding/binary
- crypto/hmac
- bytes
- totp
- 2fa-auth
- hotp
- rfc
title: TOTPを実装する
---


ここ数年で多くのサービスで採用されてきている二要素認証ですが、皆さん使っているでしょうか。
私は実は最近までは面倒であまり使っていなかったのですが、ようやく重い腰を上げてあちこち設定しました。
そのうち、近年特によく使われているのがTOTP(Time-Based One-Time Password)と呼ばれるアルゴリズムです。
TOTPアルゴリズムは[RFC6238](https://tools.ietf.org/html/rfc6238)で定義されたアルゴリズムで、サーバとクライアントが共有する秘密鍵および現在時刻から確認用のコードを生成するものです。
RFCや[Wikipedia](https://en.wikipedia.org/wiki/Time-based_One-time_Password_algorithm)を見てわかるよう、かなり簡素なアルゴリズムで、一つ一つ理解していけば比較的簡単に実装することができます。
Go言語のコードを実例に、サンプルコードを実装してみます。

## HOTPとTOTP

TOTPアルゴリズムとよく似たものに、HOTP(HMAC-Based One-Time Password)と呼ばれるアルゴリズムがあります。
これは、サーバとクライアントが共有する秘密鍵と、「何回目の認証か」から確認用のコードを生成するアルゴリズムです。
HOTPアルゴリズムは(勿論)アルゴリズムですから、ある計算手順であり、秘密鍵と認証回数を引数にとって認証用コードを返す関数として表すことができます。
この、認証回数という引数に対して、現在時刻を入力したものがTOTPです。
認証「回数」というくらいですから、値は正の整数値です。時刻を整数として入力するため、UnixTimeを使用します。

実際にはUnixTimeそのままで入力すると1秒ごとに認証用コードが変わってしまい実用できではありませんから、ある秒数を一周期として、現在が何周期目なのか、という値を入力します。

## TOTPを実装する

扨、前置きはこれくらいにしてTOTPアルゴリズムを実装します。
次の式で表されます。

\begin{eqnarray*}
TOTP(K, T_0, X) &=& HOTP(K, T(T_0, X)) \\\\
T(T_0, X) &=& \frac{(CurrentUnixTime - T_0)}{X}
\end{eqnarray*}

* $K$は共有秘密鍵です。
* $T_0$は数えはじめの時間で、通常はUnix epoch、すなわち0を使用します。
* $X$は一周期の秒数で、規定値は30秒です。(実際、多くのサービスが30秒ベースです)

プログラム実装は以下の様に書いてみます。

``` go
func TOTP(k string, t0, x int) int {
    return HOTP(k, T(t0, x))
}

func T(t0, x int) int {
    return (time.Now().Unix - t0)/x
}
```

簡単ですね。上記の内、定義されていないのは`HOTP(K, T)`だけとなりました。

## HOTPを実装する

TOTPのコードではHOTPアルゴリズム部分が実装されていませんので、ここを実装すれば実際に使用できるはずです。
HOTPアルゴリズムは[RFC4226](https://tools.ietf.org/html/rfc4226)で定義されているので、これを読みながら実装します。

RFCを読むと、HOTPは大きく次の3ステップで求められることがわかります。

1. 共有秘密鍵と認証回数からHMAC-SHA1の値を求める
2. 4byteの文字列を生成する
3. HOTPの値を計算する

何が何やらですね。もう少し詳しく見ていきましょう。

### 1. HMAC-SHA1の値を求める

HMACはメッセージ認証コードの一種で、ハッシュ関数を使用し、秘密鍵とメッセージから認証コードを生成します。
ここでは、その名の通り、ハッシュ関数としてSHA1を使用します。
また、メッセージとして認証回数を使用します。

HMAC-SHA1の値を$HS$として、式で表すと次のような形です。

\[
HS = HMAC-SHA-1(K, C)
\]

* $K$は秘密鍵
* $C$はメッセージ(ここでは認証回数)

Go言語では、HMACもSHA1も標準パッケージに入ってますので、こちらを使用します。
HMACは[`crypto/hmac`](https://golang.org/pkg/crypto/hmac)パッケージ、SHA1は[`crypto/sha1`](https://golang.org/pkg/crypto/sha1)パッケージです。

実装してみます。

``` go
func HMACSHA1(k, c []byte) []byte {
    mac := hmac.New(sha1.New, k)
    mac.Write(c)
    return mac.Sum(nil)
}
```

Go言語で、HMACは`hash.Hash`として実装されており、`hmac.New(func() hash.Hash, []byte)`でハッシュ関数オブジェクトを得て使用します。
SHA1のブロック長[^block_length]は160bitですから、文字列でいうと20文字の文字列を得ることになります。

### 2. 4byteの文字列を生成する

次に、先に計算した$HS$から4byteの文字列を作ります。
RFCの6ページ目に、計算方法が書かれていますので、その通り計算します。

\[
Sbits = DT(HS)
\]]

まず、`offsetbits`を求めます。
`offsetbits`は$HS$の20文字目(つまり最後の文字)の下位4bitです。
Go言語で扱うのはbyte列ですから、20文字目を8bitまるごと取り出して、上位4bitを0で埋める($00001111_{(2)}$でマスクをかける)ことで下位4bitを取り出したこととします。
なお、Python等では2進数のリテラルもありますが、Goでは2進数のリテラルはありませんので、16進数で表記します($00001111_{(2)}$は$F_{(16)}$です)。

``` go
offsetbits := hs[19] & 0xF
```

次に、`offset`を求めます。
`offset`は、`offsetbits`を数値として取り出します。
これは、特別変換を行うわけでは無く、byte列を直接intとして読みます(4bitなので、0〜15の値)。

``` go
offset := int(offsetbits)
```

続いて、$HS$の`offset`番目の文字から4文字を抜き出し、これを`p`とします。

``` go
p := hs[offset:offset+4]
```

`p`の終端31bitを抜き出します。
これも、`offsetbits`の時の計算同様、マスクをかけることで同様の処理とします($01111111111111111111111111111111_{(2)}$は$7FFFFFFF_{(16)}$)。
尚、byte列に直接マスクをかけるのは少々面倒ですし、次のステップで数値への変換を行いますので、一旦数値にしてからマスクをかけます。
`[]byte`から`int`へは直接キャストできないため、[`encoding/binary`](https://golang.org/pkg/encoding/binary)パッケージを使用します。

ここまでをまとめると以下の様になります。

``` go
func DT(hs []byte) int {
    offsetbits := hs[19] & 0xF
    offset := int(offsetbits)
    p := hs[offset:offset+4]
    return int(binary.BigEndian.Uint32(p)) & 0x7FFFFFFF
}
```

### 3. HOTPの値を計算する

前のステップで出た値の数値表現と、$10^{Digit}$の剰余をとり、所定の桁数に納めます。
幸い、前のステップの出力値は`int`となっていますから、ほとんどそのまま使えます。

``` go
func ReductionModulo(snum int) int {
    return int(int64(snum) % int64(math.Pow10(g.Digit)))
}
```

### HOTPアルゴリズムまとめ

ここまでに見てきたステップを合わせて、HOTPを得る関数を作成しましょう。
改めてRFCを眺めると、HOTPは次のように定義されています。

\[
HOTP(K, C) = Truncate(HMAC-SHA-1(K, C))
\]

$Truncate$は`DT`のことです。

これをGo言語で書き直すと次のようになります。

``` go
func HOTP(k, c []byte) int {
    return DT(HMACSHA1(k, c))
}
```

## TOTPに併せてHOTPを修正する

扨、本記事の目標はTOTPアルゴリズムの実装でした。
本記事の冒頭で作成したTOTP関数は、次のようなものでした。

``` go
func TOTP(k string, t0, x int) int {
    return HOTP(k, T(t0, x))
}

func T(t0, x int) int {
    return (time.Now().Unix - t0)/x
}
```

`T(t0, x)`の返り値は`int`ですから、`func HOTP(k, c []byte) int`に渡すことができません。
ここはHOTP関数をちょっと修正してみます。

``` go
func HOTP(k []byte, c int) int {
    cb := make([]byte, 8)
    binary.BigEndian.PutUint64(cb, c)
    return DT(HMACSHA1(k, cb))
}
```

引数を`TOTP`関数で与えたい形に合わせ、関数内で型変換ロジックを入れました。

これで、無事TOTPアルゴリズムを実装することができました。
(本文中のソースコードはテストされていません。**本番では使用しないでください**)


[^block_length]: 出力の長さのこと

