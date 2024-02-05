---
author: nasa9084
date: "2021-10-18T07:38:35Z"
cover:
  image: images/drone_logo.png
  relative: true
slug: droneci_early_return
tags:
  - DroneCI
title: DroneCIでパイプライン全体をfailさせずに後続のジョブを停止する
---


例えばmono repoで特定のディレクトリに変更があったときにだけジョブを実行したい、という様なケース。DroneCIのconditionはディレクトリ単位での変更でステップを実行するかという分岐はできません。かといってfailさせてしまうと、対象のディレクトリに変更がない場合はいつもfailする事になり、実際に問題があってfailしているのかどうなのか分からない、という事態に陥ります。

そんなときは `exit 78` すると良いようです。 `exit 78` したステップはsuccess、後続のステップは実行されず、(`depends_on` で設定しているような)後続のパイプラインは実行されます。

## Reference
[How to exit a Pipeline early without Failing](https://discourse.drone.io/t/how-to-exit-a-pipeline-early-without-failing/3951)



