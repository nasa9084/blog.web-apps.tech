---
author: nasa9084
date: "2019-10-09T07:02:52Z"
description: ""
cover:
  image: images/gG9QcK.jpg
slug: how-to-check-empty-string
tags:
  - golang
  - string
  - benchmark
title: 空文字列確認は長さをとるべきか？
---


## TL;DR

* `s == ""`と`len(s) == 0`は等価


## 文字列比較か、長さ比較か

Go言語で文字列が空かどうかを調べるには次の二つの方法があります。

``` go
// 1: 文字列を空文字列と比較する
if s == "" {
    // do something
}

// 2: 文字列の長さが0かどうか調べる
if len(s) == "" {
    // do something
}
```

標準パッケージ・サードパーティパッケージともに、どちらの書き方も散見されます。
どちらを使うのが良いのでしょうか？

答えは**どちらでも良い**だそうです。

``` go
package benchmark_test

import "testing"

var somethingString = "hogehogefugafuga"

func BenchmarkCompareString(b *testing.B) {
    for i := 0; i < b.N; i++ {
        if somethingString == "" {
        }
    }
}

func BenchmarkCompareStringByLength(b *testing.B) {
    for i := 0; i < b.N; i++ {
        if len(somethingString) == 0 {

        }
    }
}
```

このコードに対して `go tool compile -S`した結果が以下。
`BenchmarkCompareString`と`BenchmarkCompareStringByLength`では同じ内容となっています。

```
"".BenchmarkCompareString STEXT nosplit size=22 args=0x8 locals=0x0
        0x0000 00000 (benchmark_test.go:7)      TEXT    "".BenchmarkCompareString(SB), NOSPLIT|ABIInternal, $0-8
        0x0000 00000 (benchmark_test.go:7)      FUNCDATA        $0, gclocals·1a65e721a2ccc325b382662e7ffee780(SB)
        0x0000 00000 (benchmark_test.go:7)      FUNCDATA        $1, gclocals·69c1753bd5f81501d95132d08af04464(SB)
        0x0000 00000 (benchmark_test.go:7)      FUNCDATA        $2, gclocals·9fb7f0986f647f17cb53dda1484e0f7a(SB)
        0x0000 00000 (benchmark_test.go:8)      PCDATA  $0, $1
        0x0000 00000 (benchmark_test.go:8)      PCDATA  $1, $1
        0x0000 00000 (benchmark_test.go:8)      MOVQ    "".b+8(SP), AX
        0x0005 00005 (benchmark_test.go:8)      XORL    CX, CX
        0x0007 00007 (benchmark_test.go:8)      JMP     12
        0x0009 00009 (benchmark_test.go:8)      INCQ    CX
        0x000c 00012 (benchmark_test.go:8)      CMPQ    264(AX), CX
        0x0013 00019 (benchmark_test.go:8)      JGT     9
        0x0015 00021 (<unknown line number>)    PCDATA  $0, $-2
        0x0015 00021 (<unknown line number>)    PCDATA  $1, $-2
        0x0015 00021 (<unknown line number>)    RET
        0x0000 48 8b 44 24 08 31 c9 eb 03 48 ff c1 48 39 88 08  H.D$.1...H..H9..
        0x0010 01 00 00 7f f4 c3                                ......
"".BenchmarkCompareStringByLength STEXT nosplit size=22 args=0x8 locals=0x0
        0x0000 00000 (benchmark_test.go:14)     TEXT    "".BenchmarkCompareStringByLength(SB), NOSPLIT|ABIInternal, $0-8
        0x0000 00000 (benchmark_test.go:14)     FUNCDATA        $0, gclocals·1a65e721a2ccc325b382662e7ffee780(SB)
        0x0000 00000 (benchmark_test.go:14)     FUNCDATA        $1, gclocals·69c1753bd5f81501d95132d08af04464(SB)
        0x0000 00000 (benchmark_test.go:14)     FUNCDATA        $2, gclocals·9fb7f0986f647f17cb53dda1484e0f7a(SB)
        0x0000 00000 (benchmark_test.go:15)     PCDATA  $0, $1
        0x0000 00000 (benchmark_test.go:15)     PCDATA  $1, $1
        0x0000 00000 (benchmark_test.go:15)     MOVQ    "".b+8(SP), AX
        0x0005 00005 (benchmark_test.go:15)     XORL    CX, CX
        0x0007 00007 (benchmark_test.go:15)     JMP     12
        0x0009 00009 (benchmark_test.go:15)     INCQ    CX
        0x000c 00012 (benchmark_test.go:15)     CMPQ    264(AX), CX
        0x0013 00019 (benchmark_test.go:15)     JGT     9
        0x0015 00021 (<unknown line number>)    PCDATA  $0, $-2
        0x0015 00021 (<unknown line number>)    PCDATA  $1, $-2
        0x0015 00021 (<unknown line number>)    RET
        0x0000 48 8b 44 24 08 31 c9 eb 03 48 ff c1 48 39 88 08  H.D$.1...H..H9..
        0x0010 01 00 00 7f f4 c3                                ......
go.cuinfo.packagename. SDWARFINFO dupok size=0
        0x0000 62 65 6e 63 68 6d 61 72 6b 5f 74 65 73 74        benchmark_test
go.loc."".BenchmarkCompareString SDWARFLOC size=70
        0x0000 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00  ................
        0x0010 01 00 9c 00 00 00 00 00 00 00 00 00 00 00 00 00  ................
        0x0020 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00  ................
        0x0030 00 00 00 01 00 52 00 00 00 00 00 00 00 00 00 00  .....R..........
        0x0040 00 00 00 00 00 00                                ......
        rel 0+8 t=50 "".BenchmarkCompareString+0
        rel 8+8 t=50 "".BenchmarkCompareString+22
        rel 35+8 t=50 "".BenchmarkCompareString+12
        rel 43+8 t=50 "".BenchmarkCompareString+22
go.info."".BenchmarkCompareString SDWARFINFO size=94
        0x0000 03 22 22 2e 42 65 6e 63 68 6d 61 72 6b 43 6f 6d  ."".BenchmarkCom
        0x0010 70 61 72 65 53 74 72 69 6e 67 00 00 00 00 00 00  pareString......
        0x0020 00 00 00 00 00 00 00 00 00 00 00 01 9c 00 00 00  ................
        0x0030 00 01 10 62 00 00 07 00 00 00 00 00 00 00 00 15  ...b............
        0x0040 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00  ................
        0x0050 0b 69 00 08 00 00 00 00 00 00 00 00 00 00        .i............
        rel 27+8 t=1 "".BenchmarkCompareString+0
        rel 35+8 t=1 "".BenchmarkCompareString+22
        rel 45+4 t=29 gofile../Users/JP24216/src/practice/benchmark_empty_string/benchmark_test.go+0
        rel 55+4 t=28 go.info.*testing.B+0
        rel 59+4 t=28 go.loc."".BenchmarkCompareString+0
        rel 64+8 t=1 "".BenchmarkCompareString+0
        rel 72+8 t=1 "".BenchmarkCompareString+21
        rel 84+4 t=28 go.info.int+0
        rel 88+4 t=28 go.loc."".BenchmarkCompareString+35
go.range."".BenchmarkCompareString SDWARFRANGE size=0
go.isstmt."".BenchmarkCompareString SDWARFMISC size=0
        0x0000 04 05 01 04 02 0a 01 03 00                       .........
go.loc."".BenchmarkCompareStringByLength SDWARFLOC size=70
        0x0000 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00  ................
        0x0010 01 00 9c 00 00 00 00 00 00 00 00 00 00 00 00 00  ................
        0x0020 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00  ................
        0x0030 00 00 00 01 00 52 00 00 00 00 00 00 00 00 00 00  .....R..........
        0x0040 00 00 00 00 00 00                                ......
        rel 0+8 t=50 "".BenchmarkCompareStringByLength+0
        rel 8+8 t=50 "".BenchmarkCompareStringByLength+22
        rel 35+8 t=50 "".BenchmarkCompareStringByLength+12
        rel 43+8 t=50 "".BenchmarkCompareStringByLength+22
go.info."".BenchmarkCompareStringByLength SDWARFINFO size=102
        0x0000 03 22 22 2e 42 65 6e 63 68 6d 61 72 6b 43 6f 6d  ."".BenchmarkCom
        0x0010 70 61 72 65 53 74 72 69 6e 67 42 79 4c 65 6e 67  pareStringByLeng
        0x0020 74 68 00 00 00 00 00 00 00 00 00 00 00 00 00 00  th..............
        0x0030 00 00 00 01 9c 00 00 00 00 01 10 62 00 00 0e 00  ...........b....
        0x0040 00 00 00 00 00 00 00 15 00 00 00 00 00 00 00 00  ................
        0x0050 00 00 00 00 00 00 00 00 0b 69 00 0f 00 00 00 00  .........i......
        0x0060 00 00 00 00 00 00                                ......
        rel 35+8 t=1 "".BenchmarkCompareStringByLength+0
        rel 43+8 t=1 "".BenchmarkCompareStringByLength+22
        rel 53+4 t=29 gofile../Users/JP24216/src/practice/benchmark_empty_string/benchmark_test.go+0
        rel 63+4 t=28 go.info.*testing.B+0
        rel 67+4 t=28 go.loc."".BenchmarkCompareStringByLength+0
        rel 72+8 t=1 "".BenchmarkCompareStringByLength+0
        rel 80+8 t=1 "".BenchmarkCompareStringByLength+21
        rel 92+4 t=28 go.info.int+0
        rel 96+4 t=28 go.loc."".BenchmarkCompareStringByLength+35
go.range."".BenchmarkCompareStringByLength SDWARFRANGE size=0
go.isstmt."".BenchmarkCompareStringByLength SDWARFMISC size=0
        0x0000 04 05 01 04 02 0a 01 03 00                       .........
go.string."hogehogefugafuga" SRODATA dupok size=16
        0x0000 68 6f 67 65 68 6f 67 65 66 75 67 61 66 75 67 61  hogehogefugafuga
""..inittask SNOPTRDATA size=32
        0x0000 00 00 00 00 00 00 00 00 01 00 00 00 00 00 00 00  ................
        0x0010 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00  ................
        rel 24+8 t=1 testing..inittask+0
"".somethingString SDATA size=16
        0x0000 00 00 00 00 00 00 00 00 10 00 00 00 00 00 00 00  ................
        rel 0+8 t=1 go.string."hogehogefugafuga"+0
type..importpath.testing. SRODATA dupok size=10
        0x0000 00 00 07 74 65 73 74 69 6e 67                    ...testing
gclocals·1a65e721a2ccc325b382662e7ffee780 SRODATA dupok size=10
        0x0000 02 00 00 00 01 00 00 00 01 00                    ..........
gclocals·69c1753bd5f81501d95132d08af04464 SRODATA dupok size=8
        0x0000 02 00 00 00 00 00 00 00                          ........
gclocals·9fb7f0986f647f17cb53dda1484e0f7a SRODATA dupok size=10
        0x0000 02 00 00 00 01 00 00 00 00 01                    ..........
```



