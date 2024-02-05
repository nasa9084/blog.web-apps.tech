---
author: nasa9084
date: "2017-10-18T09:17:00Z"
cover:
  image: images/TravisCI-Full-Color.png
  relative: true
slug: travis-ci-update-docker
tags:
  - docker
  - dockerfile
  - travis-ci
  - test
  - ci
title: Travis CIでdockerのバージョンを最新にする
---


Travis CIでDockerfileをテストする等、dockerを使用したい場合、以下の様に`.travis.yml`に記述することでdockerを有効にすることできます。

``` yaml
sudo: required

service:
  - docker
```

が、その際のdockerのバージョンは17.03.1[^1]と、最新版ではありません。
特に問題なのが、[multi-stage build](https://docs.docker.com/engine/userguide/eng-image/multistage-build/)は17.05からの機能であるということです。
Travis CIで使用できるdockerでは、multi-stage buildを使用したDockerfileはビルドすることができず、常にfailedとなってしまいます。

## 解決方法
Travis-CIでDockerのバージョンを上げるには、以下の記述を`.travis.yml`に追加します。

``` yaml
sudo: required

service:
  - docker

before_install:
  - sudo apt-get update
  - sudo apt-get install -y -o Dpkg::Options::="--force-confnew" docker-ce
```

dockerの再起動などの処理は必要ありません。
以上の記述により、Dockerのバージョンが最新版にアップデートされ、multi-stage buildも使用できるようになります。

[^1]: 2017年10月18日現在

