---
author: nasa9084
categories:
- golang
- io
- fmt
- benchmark
date: "2017-09-02T04:30:59Z"
description: ""
draft: false
cover:
  image: images/gopher-1.png
slug: benchmark-iowriter-and-fprintf
tags:
- golang
- io
- fmt
- benchmark
title: io.Writer.Write()とfmt.Fprintf()のBenchmark
---


## tl;dr

基本的に`io.Writer.Write()`を使用するのが高速なようです。

## result

``` shell
$ go test -bench . -benchmem
BenchmarkWrite-4                  	30000000	        48.7 ns/op	      16 B/op	       1 allocs/op
BenchmarkWriteWithBytes-4         	500000000	         3.95 ns/op	       0 B/op	       0 allocs/op
BenchmarkFprintf-4                	20000000	        91.5 ns/op	       0 B/op	       0 allocs/op
BenchmarkWriteTo-4                	100000000	        10.0 ns/op	       0 B/op	       0 allocs/op
BenchmarkWriteWithBufferBytes-4   	300000000	         4.31 ns/op	       0 B/op	       0 allocs/op
```

## source

``` go
package main_test

import (
	"bytes"
	"fmt"
	"io"
	"net/http"
	"testing"
)

var s = "Hello, my world"
var bs = []byte(s)
var buf = bytes.Buffer{}

type NullWriter struct{}

func (w *NullWriter) Write(b []byte) (int, error) {
	return len(b), nil
}

func BenchmarkWrite(b *testing.B) {
	var w io.Writer = &NullWriter{}
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		w.Write([]byte(s))
	}
}

func BenchmarkWriteWithBytes(b *testing.B) {
	var w io.Writer = &NullWriter{}
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		w.Write(bs)
	}
}

func BenchmarkFprintf(b *testing.B) {
	var w io.Writer = &NullWriter{}
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		fmt.Fprintf(w, s)
	}
}

func BenchmarkWriteTo(b *testing.B) {
	var w io.Writer = &NullWriter{}
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		buf.WriteTo(w)
	}
}

func BenchmarkWriteWithBufferBytes(b *testing.B) {
	var w io.Writer = &NullWriter{}
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		w.Write(buf.Bytes())
	}
}
```

