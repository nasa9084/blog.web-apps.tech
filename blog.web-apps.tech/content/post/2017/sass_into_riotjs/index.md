---
author: nasa9084
categories:
- riot.js
- sass
- scss
- javascript
date: "2017-07-19T01:15:00Z"
description: ""
draft: false
cover:
  image: images/riot_logo.png
slug: sass_into_riotjs
tags:
- riot.js
- sass
- scss
- javascript
title: Riot.jsにSass(SCSS)を導入する
---


Riot.jsでは、標準でスタイルシートにLessを使用することができます。
その際の使用方法は簡単で、スタイルタグにtypeを指定するだけです。
``` html
<style type="less">
   ...
</style>
```
扨、ここで、イマドキな皆さんはLessじゃなくてSass(SCSS)を使いたい！と思うかもしれません(思いますよね？)
なので、Sassを使えるようにしてみましょう。

# 基本方針
基本的には、`riot.parser.css.sass`にSassのコンパイラ関数を作成するだけです。
`riot.parser.css.sass`には、引数として、
* タグ名
* stylesheet
が渡されます。この、第二引数をコンパイルして返す関数を作成すれば良いのです。

# ランタイムコンパイルでSass(SCSS)を使用する
ランタイムコンパイル時は`sass.js`を使用します。
`<head>`タグ内で、`https://cdn.rawgit.com/medialize/sass.js/v0.6.3/dist/sass.js`を読み込むなどすれば良いでしょう。
その上で、タグのマウント前に以下の記述を追加します。
``` javascript
riot.parsers.css.sass = function(tagName, stylesheet) {  
  var result = Sass.compile(stylesheet);
  return result;
};
```

# gulp-riotプリコンパイルでSass(SCSS)を使用する
glup-riotでプリコンパイルする際にSassを使用するには、`node-sass`を使用して、`gulpfile.js`に以下のように記述します。
``` javascript
var gulp = require('gulp');  
var riot = require('gulp-riot');  
var sass = require('node-sass');

gulp.task('riot', function() {  
  gulp
    .src('app.tag')
    .pipe(riot({
      parsers: {
        css: {
          sass: function(tagName, stylesheet) {
            var result = sass.renderSync({
              data: stylesheet
            });
            return result.css.toString();
          },
        },
      },
    }))
    .pipe(gulp.dest('./'))
    ;
});
```

