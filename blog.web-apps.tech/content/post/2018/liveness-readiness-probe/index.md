---
author: nasa9084
date: "2018-07-26T05:09:35Z"
description: ""
cover:
  image: images/kubernetes_logo-2.png
  relative: true
slug: liveness-readiness-probe
tags:
  - kubernetes
  - health check
title: Liveness/Readiness Probe
---


[Kubernetes](https://kubernetes.io)によるヘルスチェックには、Liveness ProbeとReadiness Probeと呼ばれる二つのものがあります。これらは混乱しがちな一方、日本語による情報が多くない(2018/07/26現在で、Google検索の1ページ目にヒットするのが4件ほど)ため、ここで一つ情報をまとめておきます。

## 共通

Liveness ProbeとReadiness Probeの設定は共通で、`Deployment`や`Pod`のマニフェスト内で、`containers`の中に`livenessProbe`と`readinessProbe`としてそれぞれ[`Probe` spec](https://v1-10.docs.kubernetes.io/docs/reference/generated/kubernetes-api/v1.10/#probe-v1-core)を記述します。

次の項目を設定することが出来ます。

* `failureThreshold`
    * `Success`状態の時、何回失敗したら`Failure`になるか。最小で1回。
    * Default: 3
* `initialDelaySeconds`
    * コンテナが起動してからヘルスチェックを始めるまでの秒数。
    * Default: 0
* `periodSeconds`
    * ヘルスチェックの間隔。最小で1秒
    * Default: 10
* successThreshold
    * `Failure`状態の時、何回成功したら`Success`になるか。最小で1回。
    * Default: 1
* timeoutSeconds
    *  ヘルスチェックのタイムアウト秒数。最小で1秒。
    *  Default: 1
* httpGet
    * ヘルスチェックでアクセスするhttpエンドポイントの情報を書く。

`httpGet`の項目は次の様な項目を持ったobjectを書きます。


* `host`
    * 対象のホスト名。
    * Default: PodのIP
* `httpHeaders`
    * リクエストのカスタムヘッダ指定。`{name: HEADER_NAME, value: HEADER_VALUE}`の形のオブジェクトの配列で書く。
* `port`
    * アクセスするポート番号または名称
* `path`
    * アクセスするパス。
* `scheme`
    * アクセスする際のスキーム。
    * Default: HTTP

## Liveness Probe

一つ目は**Liveness Probe**です。[公式ドキュメント](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#container-probes)には次の様に書いてあります。

> `livenessProbe`: Indicates whether the Container is running. If the liveness probe fails, the kubelet kills the Container, and the Container is subjected to its [restart policy](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#restart-policy). If a Container does not provide a liveness probe, the default state is `Success`.

Liveness Probeの役割はその名の通り、アプリケーションの生存確認です。コンテナ起動後の状態は`Success`で、`Failure`になるとKubernetesはコンテナをkillします。コンテナがkillされた後は、Podのrestart policyに従います。
よく使用されるエンドポイントパスは`/healthz`です(最後のzがどこから来たのか、知ってる人がいたら教えてください)。

Go言語でのLiveness Probe用エンドポイントのサンプルを次に示します。

``` go
func livenessProbeHandler(w http.ResponseWriter, r *http.Request) {
    w.Write([]byte("OK"))
}
```

## Readiness Probe

もう一つのヘルスチェックが**Readiness Probe**です。[公式ドキュメント](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#container-probes)の説明は次の通りです。

> `readinessProbe`: Indicates whether the Container is ready to service requests. If the readiness probe fails, the endpoints controller removes the Pod’s IP address from the endpoints of all Services that match the Pod. The default state of readiness before the initial delay is `Failure`. If a Container does not provide a readiness probe, the default state is `Success`.

ReadinessProbeは、サービスがリクエストを受け付けられる状態かどうかを確認します。例えば、DB接続の初期化処理に時間がかかる場合など、アプリケーションは生きているがまだ対応出来ない、という状態を判断します。コンテナ起動後の状態は`Failure`で、`Success`になるとKubernetesはPodのIPを、セレクタがマッチするサービスの対象として追加します。また、`Success`から`Failure`になった場合は、同様にサービスからIPを削除します。これにより、準備が出来ていないPodはServiceによるロードバランシングの対象から外れることとなります。
よく使用されるエンドポイントパスは`/readiness`です。

Go言語でのサンプルは次の様なものです。

``` go
func readinessProbeHandler(w http.ResponseWriter, r *http.Request) {
    if err := db.Ping(); err != nil {
        w.WriteHeader(http.StatusServiceUnavailable)
        w.Write([]byte("error: DB connection"))
        return
    }
    w.WriteHeader(http.StatusOK)
    w.Write([]byte("OK"))
    return
}
```

