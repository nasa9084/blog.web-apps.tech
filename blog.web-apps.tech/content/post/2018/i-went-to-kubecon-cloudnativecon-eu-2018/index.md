---
author: nasa9084
date: "2018-05-07T07:08:58Z"
cover:
  image: images/----------2018-05-07-16.10.49.png
  relative: true
slug: i-went-to-kubecon-cloudnativecon-eu-2018
tags:
  - conference
  - KubeCon
  - Europe
  - Copenhagen
  - CloudNativeCon
  - 2018
title: KubeCon + CloudNativeCon Europe 2018にいってきた
---


過ぎし5月1日〜5月6日、出張で[KubeCon + CloudNativeCon Europe 2018](https://events.linuxfoundation.org/kubecon-eu-2018/)に行ってきました！

KubeConは[Kubernetes(k8s)](https://kubernetes.io/)のイベントで、[Cloud Native Computing Foundation(CNCF)](https://www.cncf.io/)が主催するCloudNativeConと併せた開催でした。
今回の開催地はデンマークはコペンハーゲンのBella Centerで、実に4000人以上が参加したとのことです。
twitterハッシュタグは[#kubecon](https://twitter.com/hashtag/kubecon)で、一部[#cloudnativecon](https://twitter.com/hashtag/cloudnativecon)も使われていたようです。

私個人としては初海外で、初日の移動で腰をぎっくりするなど、トラブルに見舞われながらも、なんとかこんとか行ってきました。

## finnair

今回、飛行機は[Finnair](https://www.finnair.com/jp/jp/)を使用しました。
成田空港からヘルシンキ、ヘルシンキからコペンハーゲンの一回乗り継ぎです。
成田空港からヘルシンキは約10時間、ヘルシンキからコペンハーゲンは約1.5時間のフライトです。

成田空港からヘルシンキのフライトでは、機内に備え付けのヘッドホンがノイズキャンセラー付きで、意外と音もよく、また、機内食もそこそこおいしかったため、比較的お勧め出来る航空会社かと思います。
成田空港からヘルシンキのフライトはJALも含めたコードシェア便だったため、機内の放送では日本語でも放送される点が安心感があって良いなと感じました。

## The Square

今回とったホテルはコペンハーゲンの繁華街にほど近い[The Square](https://www.thesquarecopenhagen.com/)というホテルです。
繁華街に近いため、観光にも困らず、飲み会をした後にも戻りやすい立地でした。

近所には[NETTO](https://netto.dk/)という24時間営業の比較的安いスーパーや、お土産の購入等にも便利な[Irma](https://irma.dk/)という高級スーパーもあり、買い物には困ることがありませんでした。

繁華街まで脚を伸ばせば、[Hard Rock Cafe](http://www.hardrock.com/cafes/copenhagen/)や、国内でも一時期話題となったSuperdry[^superdry]などもあります。

また、今回のKubeConのパーティーが[Tivoli garden](https://www.tivoli.dk/en/)での開催だったため、パーティー会場がホテルの隣のブロック、という点でも非常に良い立地でした。

ホテルそのものも、おしゃれで、清潔な感じのホテルでした。
シャワーが出ないということもありませんでしたし、最低限のアメニティも揃っていました。

冷蔵庫が壊れていたのか、中の飲み物等を冷やしてくれないのだけが少々残念でした。

## KubeCon + CloudNativeCon Europe 2018

KubeCon + CloudNativeCon Europe 2018は非常に多くのトラックがあり、その多くのスライドがPDFで公開されています。

スライドは[スケジュール](https://kccnceu18.sched.com/)からダウンロードすることができます。
また、[@superbrothers](https://twitter.com/superbrothers)さんが一気にダウンロードするスクリプトを書いてくださっているので、こちらを使用することも出来ます。

<blockquote class="twitter-tweet" data-lang="ja"><p lang="en" dir="ltr">I created a script that downloads all KubeCon + CloudNativeCon Europe 2018 slides from Sched! ? <a href="https://t.co/FyD1zhJbNk">https://t.co/FyD1zhJbNk</a> <a href="https://twitter.com/hashtag/KubeCon?src=hash&amp;ref_src=twsrc%5Etfw">#KubeCon</a></p>&mdash; Kazuki Suda / すぱぶら (@superbrothers) <a href="https://twitter.com/superbrothers/status/991980611526066176?ref_src=twsrc%5Etfw">2018年5月3日</a></blockquote>
<script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

``` shell
$ curl https://gist.githubusercontent.com/superbrothers/2c2d3713d8d30a785cabf77831489fcd/raw/666ba22738e1d18ece311d7ba9bb4b88e5def60c/kccnceu18-dl.sh |  bash -
```

<blockquote class="twitter-tweet" data-lang="ja"><p lang="und" dir="ltr"><a href="https://t.co/drmFJzq7RX">https://t.co/drmFJzq7RX</a> <a href="https://twitter.com/hashtag/kubecon?src=hash&amp;ref_src=twsrc%5Etfw">#kubecon</a></p>&mdash; nasa9084@某某某某(0x19歳) (@nasa9084) <a href="https://twitter.com/nasa9084/status/991575989099655168?ref_src=twsrc%5Etfw">2018年5月2日</a></blockquote>
<script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

上記tweetはURLが間違っていました・・・

<blockquote class="twitter-tweet" data-lang="ja"><p lang="und" dir="ltr"><a href="https://t.co/tIqBuF7oL1">https://t.co/tIqBuF7oL1</a>を見よ <a href="https://twitter.com/hashtag/kubecon?src=hash&amp;ref_src=twsrc%5Etfw">#kubecon</a></p>&mdash; nasa9084@某某某某(0x19歳) (@nasa9084) <a href="https://twitter.com/nasa9084/status/991578293836173312?ref_src=twsrc%5Etfw">2018年5月2日</a></blockquote>
<script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

https://l.cncf.io では、CNCFのプロジェクトや、関連する(Cloud-Nativeな)プロジェクトの一覧をインタラクティブに検索することが出来ます。
非常に見やすいため、情報収集にはもってこいです。

[^superdry]: 日本国内からは公式サイトへのアクセスが出来ない

