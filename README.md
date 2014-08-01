Webmaster Tools Crawler
====

This is to crawl Webmaster Tools information automaticaly using [Phantom.js](http://phantomjs.org/).

## caucion

スクレイピング部分はハードコーディングなので、WMTの仕様変更で動かなくなる可能性があります

一部、手動で整形が必要です

## Usage

phantomjs wmt-phantomjs.coffee [side-domain]  [output-name]

## Setting

  1. Phantom.jsをインストールする
  1. setting-example.js を setting.js と名前を変えて、アカウント情報などを入れる
  1. run-example.sh を run.sh と名前を変えて、クロールするサイト情報を入れる
  1. `bower install` を実行する
  1. `./run.sh` を実行する
  1. `./log/` フォルダに一式が

## まとめ方

  1. `cat log/*.json > log/all.json`
  2. テキストエディタで `}{` >>> `},{` などと変換
  3. 同様に `\n` を一斉置換で削除
  4. `all.json` を [適当な変換ツール](http://konklone.io/json/) でCSVに変換
  5. `err-*l`, `err-*d` 系の並び順を手動で変換

## Licence

MIT

## Auther

[Sho Otani](beijaflor.jp)
