---
author: nasa9084
categories:
- gitlab
- git
- docker
- automation
- ci
date: "2017-11-22T01:17:14Z"
description: ""
draft: false
cover:
  image: images/gitlab.png
  relative: true
slug: gitlab-docker-init-runners-reg-token
tags:
- gitlab
- git
- docker
- automation
- ci
title: 'GitLab Docker: initial runners registration token'
---


[GitLab](https://about.gitlab.com/)はRuby on Railsで書かれたオープンソースのGitサーバアプリケーションです。おそらく、オープンソースのGitサーバとしては最もよく使われているものではないでしょうか。
GitLabは他のOSS Gitサーバアプリケーションと比べて、非常に多くの機能を持っています。
GitLab-CIもその一つで、GitLab上で自動テストを回すことができます。

この、GitLab-CIを使用するにはrunnerと呼ばれる、CI環境用のホストを追加する必要があります。
このとき、Registration Tokenという登録用トークンが必要なのですが、REST APIで取得することができません。そのため、Dockerを用いた自動構築時に少々困りました。

## 解法
GitLab omnibusの設定項目でRegistration Tokenの初期値を設定することができます。
`docker run`する際のオプションに、以下を追加します。
 
``` shell
-e GITLAB_OMNIBUS_CONFIG="gitlab_rails['initial_shared_runners_registration_token'] = 'HOGEHOGETOKEN'"
```

もし、ほかの理由ですでに`GITLAB_OMNIBUS_CONFIG`の指定がある場合、セミコロン区切りで複数の値を指定することができます。たとえば、初期パスワードを与えている場合は、以下の様にできます。

``` shell
-e GITLAB_OMNIBUS_CONFIG="gitlab_rails['initial_root_password'] = 'FUGAFUGAPASSWORD'; gitlab_rails['initial_shared_runners_registration_token'] = 'HOGEHOGETOKEN'"
```

ここで指定した値をrunnerの登録時に与えれば、OKです。

``` shell
docker exec GITLAB_RUNNER_CONTAINER_NAME gitlab-runner register -n -r HOGEHOGETOKEN --run-untagged --executor docker --docker-image alpine:latest --url http://GITLAB_URL --docker-volumes /var/run/docker.sock:/var/run/docker.sock
```

このとき、GITLAB_RUNNER_CONTAINER_NAMEとGITLAB_URLは適宜置き換えてください。

