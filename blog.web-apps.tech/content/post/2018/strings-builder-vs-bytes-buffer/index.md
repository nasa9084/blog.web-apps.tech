---
author: nasa9084
date: "2018-03-05T15:00:00Z"
cover:
  image: images/gopher-1.png
  relative: true
slug: strings-builder-vs-bytes-buffer
tags:
  - golang
  - string
  - strings
  - bytes
  - benchmark
title: strings.Builderとbytes.BufferのWrite系関数のベンチマーク
---


## TL; DR

平均して見ると`strings.Builder#WriteXXX`の方が速そう

## strings.Builder
Go 1.10から`strings.Builder`構造体が追加されました。
公式ドキュメントには、

> A Builder is used to efficiently build a string using Write methods. It minimizes memory copying. The zero value is ready to use. Do not copy a non-zero Builder. 

と説明が書かれています。
おそらく、これまで文字列の組み立てをする際には`bytes.Buffer`を使っている場合が多かったと思われますが、そういった目的の選択肢として作られたようです。
が、説明を読んでもいまいち違いがわかりません。

とりあえず、`bytes.Buffer`と`strings.Builder`では速度面で違いがあるのか調べるべく、ベンチマークを実施しました。

### 条件

#### 実行した環境

* MacBook Air
    * MacOS Sierra 10.12.6
    * CPU: Core i7 1.7GHz
    * メモリ: 8GB

#### 実行する関数

* `Write`
* `WriteByte`
* `WriteRune`
* `WriteString`

### exec

``` shell
$ for i in {1..10}; do go test -bench . | tail -n +4 | head -n 8 && echo; done
BenchmarkBuilderWrite-4         	10000000	       129 ns/op
BenchmarkBuiderWriteByte-4      	200000000	         6.47 ns/op
BenchmarkBuilderWriteRune-4     	200000000	         7.61 ns/op
BenchmarkBuilderWriteString-4   	30000000	        92.4 ns/op
BenchmarkBufferWrite-4          	50000000	       196 ns/op
BenchmarkBufferWriteByte-4      	300000000	         9.40 ns/op
BenchmarkBufferWriteRune-4      	200000000	         8.18 ns/op
BenchmarkBufferWriteString-4    	50000000	       217 ns/op

BenchmarkBuilderWrite-4         	10000000	       189 ns/op
BenchmarkBuiderWriteByte-4      	100000000	        10.5 ns/op
BenchmarkBuilderWriteRune-4     	100000000	        10.4 ns/op
BenchmarkBuilderWriteString-4   	30000000	       157 ns/op
BenchmarkBufferWrite-4          	50000000	       238 ns/op
BenchmarkBufferWriteByte-4      	100000000	        19.9 ns/op
BenchmarkBufferWriteRune-4      	100000000	        15.5 ns/op
BenchmarkBufferWriteString-4    	30000000	       422 ns/op

BenchmarkBuilderWrite-4         	10000000	       131 ns/op
BenchmarkBuiderWriteByte-4      	200000000	         7.58 ns/op
BenchmarkBuilderWriteRune-4     	200000000	         8.48 ns/op
BenchmarkBuilderWriteString-4   	30000000	       113 ns/op
BenchmarkBufferWrite-4          	50000000	       199 ns/op
BenchmarkBufferWriteByte-4      	100000000	        10.4 ns/op
BenchmarkBufferWriteRune-4      	200000000	        12.0 ns/op
BenchmarkBufferWriteString-4    	50000000	       382 ns/op

BenchmarkBuilderWrite-4         	10000000	       122 ns/op
BenchmarkBuiderWriteByte-4      	200000000	         7.45 ns/op
BenchmarkBuilderWriteRune-4     	200000000	         8.44 ns/op
BenchmarkBuilderWriteString-4   	30000000	       155 ns/op
BenchmarkBufferWrite-4          	50000000	       264 ns/op
BenchmarkBufferWriteByte-4      	200000000	         7.08 ns/op
BenchmarkBufferWriteRune-4      	200000000	        10.1 ns/op
BenchmarkBufferWriteString-4    	30000000	       413 ns/op

BenchmarkBuilderWrite-4         	20000000	       117 ns/op
BenchmarkBuiderWriteByte-4      	200000000	         6.81 ns/op
BenchmarkBuilderWriteRune-4     	200000000	         6.87 ns/op
BenchmarkBuilderWriteString-4   	50000000	       219 ns/op
BenchmarkBufferWrite-4          	20000000	       101 ns/op
BenchmarkBufferWriteByte-4      	200000000	         6.22 ns/op
BenchmarkBufferWriteRune-4      	200000000	        12.2 ns/op
BenchmarkBufferWriteString-4    	50000000	       513 ns/op

BenchmarkBuilderWrite-4         	10000000	       161 ns/op
BenchmarkBuiderWriteByte-4      	200000000	         8.36 ns/op
BenchmarkBuilderWriteRune-4     	200000000	         8.24 ns/op
BenchmarkBuilderWriteString-4   	30000000	       109 ns/op
BenchmarkBufferWrite-4          	50000000	       296 ns/op
BenchmarkBufferWriteByte-4      	100000000	        10.6 ns/op
BenchmarkBufferWriteRune-4      	100000000	        11.4 ns/op
BenchmarkBufferWriteString-4    	50000000	       484 ns/op

BenchmarkBuilderWrite-4         	10000000	       133 ns/op
BenchmarkBuiderWriteByte-4      	200000000	         7.16 ns/op
BenchmarkBuilderWriteRune-4     	200000000	         8.10 ns/op
BenchmarkBuilderWriteString-4   	30000000	       194 ns/op
BenchmarkBufferWrite-4          	50000000	       190 ns/op
BenchmarkBufferWriteByte-4      	200000000	         5.51 ns/op
BenchmarkBufferWriteRune-4      	200000000	         8.72 ns/op
BenchmarkBufferWriteString-4    	50000000	       281 ns/op

BenchmarkBuilderWrite-4         	10000000	       136 ns/op
BenchmarkBuiderWriteByte-4      	200000000	        11.4 ns/op
BenchmarkBuilderWriteRune-4     	50000000	        28.0 ns/op
BenchmarkBuilderWriteString-4   	10000000	       119 ns/op
BenchmarkBufferWrite-4          	20000000	       144 ns/op
BenchmarkBufferWriteByte-4      	100000000	        16.0 ns/op
BenchmarkBufferWriteRune-4      	200000000	         8.43 ns/op
BenchmarkBufferWriteString-4    	50000000	       248 ns/op

BenchmarkBuilderWrite-4         	10000000	       130 ns/op
BenchmarkBuiderWriteByte-4      	200000000	         7.83 ns/op
BenchmarkBuilderWriteRune-4     	200000000	         7.13 ns/op
BenchmarkBuilderWriteString-4   	30000000	        99.0 ns/op
BenchmarkBufferWrite-4          	50000000	       202 ns/op
BenchmarkBufferWriteByte-4      	200000000	        10.7 ns/op
BenchmarkBufferWriteRune-4      	100000000	        13.8 ns/op
BenchmarkBufferWriteString-4    	50000000	       452 ns/op

BenchmarkBuilderWrite-4         	10000000	       146 ns/op
BenchmarkBuiderWriteByte-4      	200000000	         7.89 ns/op
BenchmarkBuilderWriteRune-4     	200000000	         8.24 ns/op
BenchmarkBuilderWriteString-4   	30000000	       122 ns/op
BenchmarkBufferWrite-4          	50000000	       248 ns/op
BenchmarkBufferWriteByte-4      	100000000	        31.7 ns/op
BenchmarkBufferWriteRune-4      	100000000	        25.4 ns/op
BenchmarkBufferWriteString-4    	30000000	       413 ns/op
```

### Source

ベンチマークスクリプトのソースは以下の様になっています。

``` go
package benchmark_test

import (
	"bytes"
	"strings"
	"testing"
)

var (
	ss = "1234567890abcdefghijklmnopqrstuvwxyz"
	bs = []byte(ss)
	rn = 'a'
	bt = byte('a')
)

func BenchmarkBuilderWrite(b *testing.B) {
	var builder strings.Builder
	for i := 0; i < b.N; i++ {
		builder.Write(bs)
	}
}

func BenchmarkBuiderWriteByte(b *testing.B) {
	var builder strings.Builder
	for i := 0; i < b.N; i++ {
		builder.WriteByte(bt)
	}
}

func BenchmarkBuilderWriteRune(b *testing.B) {
	var builder strings.Builder
	for i := 0; i < b.N; i++ {
		builder.WriteRune(rn)
	}
}

func BenchmarkBuilderWriteString(b *testing.B) {
	var builder strings.Builder
	for i := 0; i < b.N; i++ {
		builder.WriteString(ss)
	}
}

func BenchmarkBufferWrite(b *testing.B) {
	var buffer bytes.Buffer
	for i := 0; i < b.N; i++ {
		buffer.Write(bs)
	}
}

func BenchmarkBufferWriteByte(b *testing.B) {
	var buffer bytes.Buffer
	for i := 0; i < b.N; i++ {
		buffer.WriteByte(bt)
	}
}

func BenchmarkBufferWriteRune(b *testing.B) {
	var buffer bytes.Buffer
	for i := 0; i < b.N; i++ {
		buffer.WriteRune(rn)
	}
}

func BenchmarkBufferWriteString(b *testing.B) {
	var buffer bytes.Buffer
	for i := 0; i < b.N; i++ {
		buffer.WriteString(ss)
	}
}
```

