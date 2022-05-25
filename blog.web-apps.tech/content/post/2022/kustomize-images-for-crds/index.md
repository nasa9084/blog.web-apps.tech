---
title: Kustomizeのimages transformerをCustomResourceでも使う
author: nasa9084
date: 2022-05-25T18:19:05+09:00
draft: false
categories:
- kubernetes
tags:
- kubernetes
cover:
  image: images/kubernetes-logo.png
slug: kustomize-images-for-crds
---

皆さんはKustomizeのimages transformerは使っていますか？kustomization.yamlに書く、こういうやつです:

``` yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - deployment.yaml

images:
  - name: old-image
    newName: new-image
    newTag: v1.0.0
```

kustomization.yamlにこの`images:`というブロックを書くと、deployment.yamlで`image: old-image`と書かれている部分が`image: new-image:v1.0.0`に置き換えられます。これがimages transformerと呼ばれるもので、kustomizeのドキュメントでは[ImageTagTransformer](https://kubectl.docs.kubernetes.io/references/kustomize/builtins/#_imagetagtransformer_)のところとか、[exampleのimages transformer](https://github.com/kubernetes-sigs/kustomize/blob/master/examples/transformerconfigs/README.md#images-transformer)のところとかに説明が書いてあります。

扨、Kubernetesの大きな強みの一つとして、CustomResourceDefinitionを使用して独自のリソースを作成することができる、というものがあります。世の中にはいろいろなOSS CRDがありますが、今回話題にしたいのはDeploymentなどのようにコンテナイメージを指定するタイプのCustomResourceです。例えば、Argo WorkflowsのWorkflowリソースでは次の様にイメージを指定します:

``` yaml
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  name: batchjob
spec:
  entrypoint: main
  templates:
    - name: main
      container:
        image: old-image
```

しかしこの場合、kustomization.yamlでイメージを指定しても、`old-image`を置き換えてくれません。

が、置き換えて欲しいですよね？

それ、images transformer configurationを書くことで実現できます。

上書きしたいリソースのkindと、イメージを指定するpathを書いた設定ファイルを用意するだけです。この例の場合、kindは`Workflow`で、pathは`spec/templates/container/image`です。リストのインデックスとかは書く必要は無いです。設定ファイルは次の様になります:

``` yaml
images:
  - path: spec/templates/container/image
    kind: Workflow
```

これを例えば、images_transformer_configuration.yamlに保存したとすると、kustomization.yamlには次の様な記述を追加します:

``` yaml
configurations:
  - images_transformer_configuration.yaml
```

あとはDeploymentの時と同様に`images:`ブロックを記述するだけです。

今回の例の全体としては次の様になります:

kustomization.yaml:

``` yaml
resources:
  - workflow.yaml

configurations:
  - images_transformer_configuration.yaml

images:
  - name: old-image
    newName: new-image
    newTag: v1.0.0
```

workflow.yaml:

``` yaml
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  name: batchjob
spec:
  entrypoint: main
  templates:
    - name: main
      container:
        image: old-image
```

images_transformer_configuration.yaml:

``` yaml
images:
  - path: spec/templates/container/image
    kind: Workflow
```

これらを一つのディレクトリに置き、`kustomize build`すると次の出力が得られます:

``` yaml
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  name: batchjob
spec:
  entrypoint: main
  templates:
  - container:
      image: new-image:v1.0.0
    name: main
```

以上です。なお、以上のことは[kubernetes-sigs/kustomize/examples/transformerconfigs/images](https://github.com/kubernetes-sigs/kustomize/blob/master/examples/transformerconfigs/images/README.md)に書いてあります。
