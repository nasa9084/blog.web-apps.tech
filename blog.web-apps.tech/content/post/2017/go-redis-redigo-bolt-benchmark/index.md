---
author: nasa9084
date: "2017-09-07T04:40:01Z"
description: ""
cover:
  image: images/gopher-2.png
  relative: true
slug: go-redis-redigo-bolt-benchmark
tags:
  - golang
  - redis
  - boltdb
  - benchmark
title: go-redis, redigo, boltのベンチマークを取ってみた
---


## tl;dr

* データベースに接続済みの状態からstringで値をセット・ゲットするベンチマーク
    * BoltのGetがめちゃめちゃ速い
    * go-redisよりはredigoの方が速い
    * Boltのセットがメモリアロケーションすごく多い

## result

``` shell
$ go test -bench .
BenchmarkRedisSet-4    	   10000	    246527 ns/op	     249 B/op	       9 allocs/op
BenchmarkRedisGet-4    	    5000	    231569 ns/op	     225 B/op	       9 allocs/op
BenchmarkRedigoSet-4   	    5000	    204545 ns/op	      70 B/op	       4 allocs/op
BenchmarkRedigoGet-4   	    5000	    209392 ns/op	      80 B/op	       6 allocs/op
BenchmarkBoltSet-4     	   10000	    166142 ns/op	   34287 B/op	      57 allocs/op
BenchmarkBoltGet-4     	 1000000	      1140 ns/op	     488 B/op	       8 allocs/op
PASS
ok  	practices/redis-bolt-benchmark	8.705s
```

## source

``` go
package rbbench_test

import (
	"testing"

	"github.com/boltdb/bolt"
	redigo "github.com/garyburd/redigo/redis"
	redis "github.com/go-redis/redis"
)

var redisOpts = &redis.Options{
	Addr:     "localhost:6379",
	Password: "",
	DB:       0,
}

func BenchmarkRedisSet(b *testing.B) {
	client := redis.NewClient(redisOpts)
	defer client.Close()
	b.ResetTimer()

	for i := 0; i < b.N; i++ {
		client.Set("key"+string(i), "value", 0).Err()
	}
}

func BenchmarkRedisGet(b *testing.B) {
	client := redis.NewClient(redisOpts)
	defer client.Close()
	b.ResetTimer()

	for i := 0; i < b.N; i++ {
		client.Get("key" + string(i)).Val()
	}
}

func BenchmarkRedigoSet(b *testing.B) {
	conn, _ := redigo.Dial("tcp", "localhost:6379")
	defer conn.Close()
	b.ResetTimer()

	for i := 0; i < b.N; i++ {
		conn.Do("SET", "key"+string(i), "value")
	}
}

func BenchmarkRedigoGet(b *testing.B) {
	conn, _ := redigo.Dial("tcp", "localhost:6379")
	defer conn.Close()
	b.ResetTimer()

	for i := 0; i < b.N; i++ {
		redigo.String(conn.Do("GET", "key"+string(i)))
	}
}

func BenchmarkBoltSet(b *testing.B) {
	db, _ := bolt.Open("bolt.db", 0600, nil)
	defer db.Close()
	b.ResetTimer()

	for i := 0; i < b.N; i++ {
		db.Update(func(tx *bolt.Tx) error {
			b, _ := tx.CreateBucketIfNotExists([]byte("bucket"))
			b.Put([]byte("key"+string(i)), []byte("value"))
			return nil
		})
	}
}

func BenchmarkBoltGet(b *testing.B) {
	db, _ := bolt.Open("bolt.db", 0600, nil)
	defer db.Close()
	b.ResetTimer()

	for i := 0; i < b.N; i++ {
		db.View(func(tx *bolt.Tx) error {
			_ = string(tx.Bucket([]byte("bucket")).Get([]byte("key" + string(i))))
			return nil
		})
	}
}
```

