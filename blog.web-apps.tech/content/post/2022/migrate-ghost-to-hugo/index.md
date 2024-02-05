---
title: Migrate Ghost to Hugo
author: nasa9084
date: 2022-04-23T02:52:34+09:00
draft: false
tags:
  - hugo
cover:
  image: images/ghost2hugo.png
  relative: true
slug: migrate-ghost-to-hugo
---

いつの頃からだったか、もう記憶もあやふやではあるけれど、ブログプラットフォームとして[Ghost](https://github.com/TryGhost/Ghost)を使っていた。[twitter](https://twitter.com/nasa9084/status/928539254304645121)を見る限り、2017年の11月頃には既にGhostを使っていて、確かこの時はDockerでセットアップしていた様な記憶がある。

{{< tweet user="nasa9084" id="928539254304645121" >}}

Ghostは結構更新が頻繁で、特にdocker-composeとかも使わずに運用していたので(使っても良かったんだけど、当時はDBもsqliteを使っていてコンテナ一つと永続ボリューム一つ、という単純な構成だったので使わなくて良いか、と思っていた)微妙にイメージの更新が面倒で、[container-up](/container-up/)というツールを書いてみたりもした。

その後自宅にKubernetesクラスタをセットアップしてKubernetes管理になり、データベースもMySQLに切り替え、最終的にはGCPのfree tierを使ってon VMで運用していた。
Ghostを使い始めた頃はバージョンもまだ1系だったけど、今となっては4系になって、相も変わらず活発に開発され、admin UIも大分変化した。

時代の流れとしては当然といえば当然なのだけれど、Ghost 5.0ではMySQL 8が必須となるということで、最近MySQLの更新をしたところ、頻繁に外形監視がfailする様になった。どうやらリソース不足でレスポンスを返せなくなっていたようだった。free tierのVMなのでe2-microインスタンスを使っているため、さもありなんといった感じ。

もちろん多少のお金を払ってもう少し良いVMにしても良いのだけれど、それほど頻繁に書いているわけでもないブログを運用するためだけに月数千円の出費はいかがなものか、大して書いてもいないのだから静的ページ生成でも良いのではないか、静的ページ生成ならデータベースもいらないしGitHub pagesで配信できて無料ではないか、などと思い、[k8s.io](https://k8s.io)でも使っている[Hugo](https://gohugo.io)に乗り換えることにした。

参考にしたのは[このページ](https://dwmkerr.com/migrating-from-ghost-to-hugo/#the-migration-process)。多少古い記事だけど多少調整すればなんとかなるだろう、と思い見切り発車した。結果なんとか移行はうまくいき、このページが表示されています。

## 移行手順

まず、[ghostToHugo](https://github.com/jbarone/ghostToHugo/)をダウンロードして、Ghostから出力したjsonファイルをHugoにインポート。(ghostToHugoはDarwin_x86_64のバイナリを使ったけど、apple siliconのmacOSでもrosettaで普通に問題無く動いた)

``` shell
$ ./ghostToHugo -p blog.web-apps.tech something-tech.ghost.2022-04-22-02-57-56.json
```

Google Cloud Storageにアップロードしていたバックアップから画像ファイルを取り出してimagesディレクトリに配置した。

``` shell
$ cp ${PATH_TO_BACKUP}/content/images ./blog.web-apps.tech/images
```

イメージのパスをちょっと調整。

``` shell
$ find . -name '*.md' | xargs sed -ie 's/__GHOST_URL__//g'
$ find . -name '*.md' | xargs sed -ie 's/\/content\/images\//\/images\//g'
```

front-matterをYAMLに変更。

``` shell
$ cd blog.web-apps.tech
$ hugo convert toYAML
$ cd ../
```

そのままではすべての記事が年のディレクトリ以下にまとまって入っていて画像管理が大変そうなので次のスクリプトで構成変更。

``` shell
# Go through each post.
for post_path in blog.web-apps.tech/content/post/*.md; do
    echo "Found $post_path"
    filename=$(basename -- "$post_path")
    filename="${filename%.*}"

    # Grep out the date line.
    dateline=$(grep -E "^date: " "$post_path")

    # We know how to get the year as the date line is consistent in all posts:
    # date: "2012-12-09T16:11:27Z"
    year=${dateline:7:4} # i.e. the four characters from index 7

    # Create the folder for the post.
    new_folder="blog.web-apps.tech/content/post/$year/$filename"
    mkdir -p "$new_folder"

    # Move the post.
    mv "$post_path" "$new_folder/index.md"
    echo "  -> $new_folder/index.md"
done
```

画像ファイルを各記事のディレクトリに配置([dwmkerrさんのスクリプト](https://github.com/dwmkerr/dwmkerr.com/blob/main/scripts/collect-images.js)ではimgタグをreplaceしていたけれど、自分の環境ではfigure short codeが使用されていたので正規表現をちょっといじった)

<details>
<summary>collect-images.js(長いのでfold)</summary>

``` javascript
//  Note: requires node 12.
const fs = require('fs');
const os = require('os');
const path = require('path');
const readline = require('readline');
const child_process = require('child_process')

//  Regexes we'll use repeatedly to find image tags or markdown images.
const rexImgTag = new RegExp(/<\ figure\s+([^>]*)[/]?>/);
const regImgSrcAttribute = new RegExp(/src=\"([^"]+)"/);
const regImgAltAttribute = new RegExp(/alt=\"([^"]+)"/);
const regImgWidthAttribute = new RegExp(/width=\"([^"]+)"/);
const rexMarkdownImage = new RegExp(/\!\[([^\]]*)\]\(([^\)]+)\)/);

/**
 * moveFileSafeSync - move src to dest, ensuring all required folders in the
 * destination are created.
 *
 * @param src - the source file path
 * @param dest - the destination file path
 * @returns {undefined}
 */
function moveFileSafeSync(src, dest) {
  //  If the source doesn't exist, but the destination does, we've probably
  //  just already processed the file.
  if (!fs.existsSync(src) && fs.existsSync(dest)) return;

  const directory = path.dirname(dest);
  if (!fs.existsSync(directory)) fs.mkdirSync(directory, { recursive: true } );
  fs.copyFileSync(src, dest);
  fs.unlinkSync(src);
}

/**
 * downloadFile - download a file from the web, ensures the folder for the
 * destination exists.
 *
 * @param src - the source fiile
 * @param dest - the download destination
 * @returns {undefined}
 */
function downloadFile(src, dest) {
  const directory = path.dirname(dest);
  if (!fs.existsSync(directory)) fs.mkdirSync(directory, { recursive: true } );
  const command = `wget "${src}" -P "${directory}"`;
  return child_process.execSync(command);
}

// Thanks: https://gist.github.com/kethinov/6658166
function findInDir (dir, filter, fileList = []) {
  const files = fs.readdirSync(dir);

  files.forEach((file) => {
    const filePath = path.join(dir, file);
    const fileStat = fs.lstatSync(filePath);

    if (fileStat.isDirectory()) {
      findInDir(filePath, filter, fileList);
    } else if (filter.test(filePath)) {
      fileList.push(filePath);
    }
  });

  return fileList;
}

/**
 * processPost
 *
 * @param rootPath
 * @param postPath
 * @returns {undefined}
 */
function processPost(rootPath, postPath) {
  return new Promise((resolve, reject) => {
    //  Get some details about the post which will be useful.
    const postDirectory = path.dirname(postPath);
    const postFileName = path.basename(postPath);
    console.log(`  Processing: ${postFileName}`);

    //  Create the input and output streams. Track whether we change the file.
    const updatedPostPath = `${postPath}.updated`;
    const inputStream = fs.createReadStream(postPath);
    const outputStream = fs.createWriteStream(updatedPostPath, { encoding: 'utf8'} );
    let changed = false;

    //  Read the file line-wise.
    const rl = readline.createInterface({
        input: inputStream,
        terminal: false,
        historySize: 0
    });

    //  Process each line, looking for image info.
    rl.on('line', (line) => {

      //  Check for html image tags.
      if (rexImgTag.test(line)) {
        const imageTagResults = rexImgTag.exec(line);
        const imageTag = imageTagResults[0];
        const imageTagInner = imageTagResults[1];
        console.log(`    Found image tag contents: ${imageTagInner}`);

        //  Rip out the component parts.
        const src = regImgSrcAttribute.test(imageTagInner) && regImgSrcAttribute.exec(imageTagInner)[1];
        const alt = regImgAltAttribute.test(imageTagInner) && regImgAltAttribute.exec(imageTagInner)[1];
        const width = regImgWidthAttribute.test(imageTagInner) && regImgWidthAttribute.exec(imageTagInner)[1];
        console.log(`    src: ${src}, alt: ${alt}, width: ${width}`);

        //  If the source is already in the appropriate location, don't process it.
        if (/^images\//.test(src)) {
          console.log(`    skipping, already processed`);
          outputStream.write(line + os.EOL);
          return;
        }

        //  Now that we have the details of the image tag, we can work out the
        //  desired destination in the images folder.
        const imageFileName = path.basename(src);
        const newRelativePath = path.join("images", imageFileName);
        const newAbsolutePath = path.join(postDirectory, newRelativePath);

        //  If the file is on the web, we need to download it...
        if (/^http/.test(src)) {
          console.log(`    Downloading '${src}' to '${newAbsolutePath}'...`);
          downloadFile(src, newAbsolutePath);
        }
        //  ...otherwise we can just move it.
        else {
          const absoluteSrc = path.join(rootPath, src);
          moveFileSafeSync(absoluteSrc, newAbsolutePath);
          console.log(`    Copied '${absoluteSrc}' to '${newAbsolutePath}'`);
        }

        //  Now re-write the image tag.
        const newImgTag = `< figure src="${newRelativePath}"${alt ? ` alt="${alt}"` : ''}${width ? ` width="${width}"` : ''} >`;
        console.log(`    Changing : ${imageTag}`);
        console.log(`    To       : ${newImgTag}`);
        line = line.replace(imageTag, newImgTag);
        changed = true;
      }

      //  Check for markdown image tags.
      if (rexMarkdownImage.test(line)) {
        const markdownImageCaptures = rexMarkdownImage.exec(line);
        const markdownImage = markdownImageCaptures[0];
        const markdownImageDescription = markdownImageCaptures[1];
        const markdownImagePath = markdownImageCaptures[2];
        console.log(`    Found markdown image: ${markdownImagePath}`);

        //  If the source is already in the appropriate location, don't process it.
        if (/^images\//.test(markdownImagePath)) {
          console.log(`    skipping, already processed`);
          outputStream.write(line + os.EOL);
          return;
        }

        //  Now that we have the details of the image tag, we can work out the
        //  desired destination in the images folder.
        const imageFileName = path.basename(markdownImagePath);
        const newRelativePath = path.join("images", imageFileName);
        const newAbsolutePath = path.join(postDirectory, newRelativePath);

        //  If the file is on the web, we need to download it...
        if (/^http/.test(markdownImagePath)) {
          console.log(`    Downloading '${markdownImagePath}' to '${newAbsolutePath}'...`);
          downloadFile(markdownImagePath, newAbsolutePath);
        }
        //  ...otherwise we can just move it.
        else {
          const absoluteSrc = path.join(rootPath, markdownImagePath);
          moveFileSafeSync(absoluteSrc, newAbsolutePath);
          console.log(`    Copied '${absoluteSrc}' to '${newAbsolutePath}'`);
        }

        //  Now re-write the markdown.
        const newMarkdownImage = `![${markdownImageDescription}](${newRelativePath})`;
        console.log(`    Changing : ${markdownImage}`);
        console.log(`    To       : ${newMarkdownImage}`);
        line = line.replace(markdownImage, newMarkdownImage);
        changed = true;
      }

      outputStream.write(line + os.EOL);
    });


    rl.on('error', (err) => {
      console.log(`  Error reading file: ${err}`);
      return reject(err);
    });

    rl.on('close', () => {
      console.log(`  Completed, written to: ${updatedPostPath}`);

if (changed) moveFileSafeSync(updatedPostPath, postPath);
      else fs.unlinkSync(updatedPostPath);
      return resolve();
    });
  });
}

console.log("collect-images: Tool to co-locate blog post images")
console.log("");

//  Get the directory to search. Arg 0 is node, Arg 1 iis the script path, Arg 3 onwards are commandline arguments.
const sourceDirectory = process.argv[2] || process.cwd();
console.log(`Source Directory: ${sourceDirectory}`);
const rootDirectory = process.argv[3] || sourceDirectory;
console.log(`Root Directory: ${rootDirectory}`);
console.log("");

//  Find all blog posts.
const postPaths = findInDir(sourceDirectory, /\.md$/);

//  Process each path.
postPaths.forEach(postPath => processPost(rootDirectory, postPath));

//  Let the user know we're done.
console.log(`Completed processing ${postPaths.length} file(s)`);
```

</details>

このスクリプトではcover imageについては処理してくれなかったので、cover imageも同様に良い感じにファイルを持ってきてパスを修正するスクリプトを書いた。

``` shell
#!/bin/bash

shopt -s globstar nullglob

site=blog.web-apps.tech

for post in $site/content/post/**/*.md
do
    #echo $post
    if ! grep '^image:' $post > /dev/null
    then
        continue
    fi

    image_path=$(grep '^image:' $post | sed 's/^image: //')
    if ! ls "$site$image_path" > /dev/null
    then
        echo "$site$image_path NOT FOUND"
    fi

    imagefile_name=$(basename "${image_path}")

    if ls "$(dirname $post)/${imagefile_name}" > /dev/null 2>&1
    then
        echo "$(dirname $post)/${imagefile_name} FOUND"
    fi


    mkdir $(dirname $post)/images
    cp $site$image_path $(dirname $post)/images/${imagefile_name}


    sed -i -E "s/^image: (.+)/cover:\n  image: images\/${imagefile_name}/" $post

    echo
done
```

後は[テーマ](https://github.com/adityatelange/hugo-PaperMod)を入れたり[Hugoの設定](https://github.com/nasa9084/blog.web-apps.tech/blob/main/blog.web-apps.tech/config.yml)をいじったりして、[GitHub Actionsの設定](https://github.com/nasa9084/blog.web-apps.tech/blob/main/.github/workflows/gh-pages.yml)入れて、GitHub pagesの設定して、今に至る。

この記事は移行をしたあとに書いている(==markdownファイルをemacsで書いている)けれど、Ghostのエディタで書くよりemacsで書いた方が体験が良く、Hugoであれば拡張性も高いので、やはりCMSを使う必要は無かったかも、と思っている。

一応[古い方も残してはある](https://blog-old.web-apps.tech/)けれど、適当なタイミングで消す予定。
