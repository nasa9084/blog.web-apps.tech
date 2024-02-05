---
author: nasa9084
date: "2018-03-05T14:00:00Z"
description: ""
draft: false
cover:
  image: images/gopher.png
  relative: true
slug: string-processing-in-go
tags:
  - golang
  - string
  - regexp
  - strings
  - strconv
  - unicode
title: Go言語で文字列を処理する
---


Go言語の`regexp`パッケージを使用した正規表現の処理は、一般的なスクリプト言語の処理速度と同程度で、正規表現を使用しない処理に比べてパフォーマンスがよくありません[^regexp-pospome]。
そのため、可能であるなら`regexp`パッケージを使用しないようにすべきです。
しかし、すべての処理を自分で書くのは大変です。
標準パッケージにも文字列を処理する関数が数多く用意されています。

# `strings` パッケージ

`strings`パッケージはその名の通り、文字列を取り扱うパッケージです。
UTF-8でエンコードされた文字列(普通の文字列)をそのまま取り扱います。

## 判別系

### `Contains`

``` go
func Contains(s, substr string) bool
```

`Contains`関数は、`s`の中に`substr`が存在するかどうかを返します。
Pythonで言うところの`substr in s`に相当します。
正規表現ならば、`substr`とのmatchで真偽値をとることに相当します。

#### example

``` go
fmt.Println(strings.Contains("hogefugapiyo", "fuga"))
// Output: true

fmt.Println(strings.Contains("hogefugapiyo", "foo"))
// Output: false
```

### `ContainsAny`

``` go
func ContainsAny(s, chars string) bool
```

`ContainsAny`関数は`s`の中に、`chars`に含まれる文字のいずれかが存在するかどうかを返します。
つまり、`chars`は文字列ですが、扱いとしては文字の配列であると考えた方が良いでしょう。

正規表現で表すなら、`/[${chars}]/`の様な表現と考えられます(${chars}は置き換える)。

#### example

``` go
fmt.Println(strings.ContainsAny("hogefugapiyo", "abcd"))
// Output: true

fmt.Println(strings.ContainsAny("hogefugapiyo", "1234"))
// Output: false
```

### `HasPrefix`

``` go
func HasPrefix(s, prefix string) bool
```

`HasPrefix`関数は、`s`の頭が`prefix`と等しいかどうかを判別します。
正規表現で`^`を使った文字列マッチに相当します。

Prefixなのでマッチさせたい文字列をつい第一引数に与えたくなりますが、第二引数がPrefixです。

#### example

``` go
fmt.Println(strings.HasPrefix("hogefugapiyo", "hoge"))
// Output: true

fmt.Println(strings.HasPrefix("hogefugapiyo", "piyo"))
// Output: false
```

### `HasSuffix`

``` go
func HasSuffix(s, suffix string) bool
```

`HasSuffix`関数は、`HasPrefix`関数と対になる関数で、`s`の末尾が`suffix`と等しいかどうかを判別します。
正規表現で`$`を使った文字列マッチに相当します。

#### example

``` go
fmt.Println(strings.HasSuffix("hogefugapiyo", "piyo))
// Output: true

fmt.Println(strings.HasSuffix("hogefugapiyo", "hoge"))
// Output: false
```

## 分割系

### `Split`

``` go
func Split(s, sep string) []string
func SplitN(s, sep string, n int) []string
```

`Split`関数は任意の区切り文字列`sep`で`s`を分割し、分割した後の配列を返します。
`SplitN`関数では第三引数に分割されたあとの配列の長さを与えることができ、これを超えた分割は行わずに配列の最後の要素にまとめて入れられます。
`SplitN`の`n`に負の値を入れると、無限回を意味することができ、`SplitN(s, sep, -1)`は`Split(s, sep)`と等価です。

#### example

``` go
fmt.Println(strings.Split("hoge,fuga,piyo", ","))
// Output: [hoge fuga piyo]

fmt.Println(strings.SplitN("hoge,fuga,piyo", ",", 2))
// Output: [hoge fuga,piyo]
```

### `SplitAfter`

``` go
func SplitAfter(s, sep string) []string
func SplitAfterN(s, sep string, n int) []string
```

`SplitAfter`及び`SplitAfterN`関数は、任意の文字列`sep`の**直後**で`s`を分割します。
`Split`及び`SplitN`との違いは、区切った後の文字列に区切り文字が含まれるところでしょう。

#### example

``` go
fmt.Println(strings.SplitAfter("hoge,fuga,piyo", ","))
// Output: [hoge, fuga, piyo]
```

### `Fields`

``` go
func Fields(s string) []string
```

`Fields`関数は、任意回数の空白文字[^whitespace_chars]で文字列を分割します。
`Split`に空白文字を与えた場合と違い、任意回数の連続する空白文字を一区切りとします(`Split`では固定回数しか指定できない)。

[^whitespace_chars]: unicode.IsSpaceで規定されたもの

#### example

``` go
fmt.Println(strings.Fields("    hoge fuga   piyo           `))
// Output: [hoge fuga piyo]
```

## 結合系

### `Join`

``` go
func Join(a []string, sep string) string
```

`Join`関数は文字列のスライスを一つの文字列に結合します。
その際、区切り文字として`sep`を与えることができます。

#### example

``` go
fmt.Println(strings.Join([]string{
    "foo",
    "bar",
    "baz",
}, ", "))
// Output: foo, bar, baz
```

### `Repeat`

``` go
func Repeat(s string, count int) string
```

`Repeat`関数は`count`で与えた回数、`s`で与えた文字列を繰り返し、結合した文字列を返します。

Pythonで`s * count`に相当します。

#### example

``` go
fmt.Println(strings.Repeat("foo", 3))
// Output: foofoofoo
```

## 置換系

### `ToUpper`

``` go
func ToUpper(s string) string
```

`ToUpeer`関数は、与えられた文字列をすべて大文字に置換した文字列を返します。
大文字、小文字の別を持たない文字は無視されます。

#### example

``` go
fmt.Println(strings.ToUpper("foo文字α"))
// Output: FOO文字Α
```

### ToLower

``` go
func ToLower(s string) string
```

`ToLower`関数は与えられた文字列を小文字に置換したものを返します。

#### example

``` go
fmt.Println(strings.ToUpper("FOO文字Α")) // Αはαの大文字
// Output: foo文字α
```

### `Replace`

``` go
func Replace(s, old, new string, n int) string
```

`Replace`関数は文字の置換を`n`回実施した文字列を返します。
シェルスクリプトでの`echo ${s} | sed -e "s/${old}/${new}/"`と同様です。

`n`は回数で、負の値を与えると`old`にマッチした部分をすべて置換します。

#### example

``` go
fmt.Println(strings.Replace("barbarbar", "ar", "az", 2))
// Output: bazbazbar

fmt.Println(strings.Replace("barbarbar", "ar", "az", -1))
// Output: bazbazbaz
```

### `Trim`

``` go
func Trim(s string, cutset string) string
```

`Trim`関数は与えられた文字列の左右から`cutset`に含まれる**文字**を削除します。
注意が必要なのは、文字列マッチでは無く、文字セットとのマッチだということです。
`cutset`に含まれない文字の内側はチェックしません。

#### example

``` go
fmt.Print(strings.Trim("foobarbaz", "foaz"))
// Output: barb
```

### `TrimLeft`/`TrimRight`

``` go
func TrimLeft(s string, cutset string) string
func TrinRight(s string, cutset string) string
```

`TrimLeft`関数と`TrimRight`関数はそれぞれ、`Trim`関数を右側または左側に制限したものです。
`TrimLeft(TrimRight(s, cutset), cutset)`は`Trim(s, cutset)`と等価です。

#### example

``` go
fmt.Print(strings.TrimLeft("foobarbaz", "foaz"))
// Output: barbaz

fmt.Print(strings.TrimRight("foobarbaz", "foaz"))
// Output: foobarb

fmt.Print(strings.TrimLeft(strings.TrimRight("foobarbaz", "foaz"), "foaz"))
}
// Output: barb
```

### `TrimPrefix`/`TrimSuffix`

``` go
func TrimPrefix(s, prefix string) string
func TrifSuffix(s, suffix string) string
```

`TrimPrefix`関数と`TrimSuffix`関数はそれぞれ、Prefix文字列とSuffix文字列を取り除きます。
`TrimLeft`関数、`TrimRight`関数との違いは、文字列マッチだと言うことです。
マッチしなかった場合は変更されていない文字列がそのまま返されます。

#### example

``` go
fmt.Println(strings.TrimPrefix("foobarbaz", "fo"))
// Output: obarbaz
```

# `strconv` パッケージ

`strconv`パッケージは、文字列をある型の表現へと変換します。
ここでは二つの関数のみを紹介します。

### `Atoi`

``` go
func Atoi(s string) (int, error)
```

`Atoi`関数は、与えられた文字列を10進数の整数文字列として解釈して変換した結果を返します。
10進数整数として解釈できなかった場合、エラーを返します。(値は0となります。)

`strconv.ParseInt(s, 10, 0)`の返値をint型にキャストしたものと等価な結果となります。

#### example

``` go
var i int
var err error
i, err = strconv.Atoi("1")
fmt.Println(i, err)
// Output: 1, <nil>

i, err = strconv.Atoi("0.1")
fmt.Println(i, err)
// Output: 0 strconv.Atoi: parsing "0.1": invalid syntax
```

### `Quote`

```
func Quote(s string) string
```

`Quote`関数はダブルクォートで囲まれた、**Goでの文字列のリテラル表現**を返します。
改行などの表示されない文字は`\n`などのエスケープシーケンスを使用して表現されます。

#### example

``` go
fmt.Println(strconv.Quote(`foobar
`))
// Output: "foobar\n"
```

# `unicode` パッケージ

`unicode`パッケージは、ユニコードの文字を処理するための関数が含まれています。
ここでは一つのみ紹介します。

### `IsXXX`

`IsXXX`関数群はruneを引数にとり、その文字が所定のカテゴリ[^unicode-category]に属するかどうかを判定します。
例えば`IsGraphic`であればGraphicカテゴリ(L, M, N, P, S, Zsのいずれか)に属するかどうか、`IsNumber`であればNumberカテゴリ(N)に属するかどうか、といった具合です。

[^regexp-pospome]: [golangの正規表現は遅いのか?](http://pospome.hatenablog.com/entry/20161012/1476244900)
[^unicode-category]: [Unicode Character Categories](http://www.fileformat.info/info/unicode/category/index.htm)

