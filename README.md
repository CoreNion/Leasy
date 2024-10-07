# Leasy
シンプルで扱いやすい暗記帳アプリ。

## [ホームページ](https://cnion.dev/leasy/)

# Features
## 使いやすい暗記帳！
このアプリは、自分で覚えたい単語やフレーズなどを登録して、暗記帳のように暗記学習が出来るアプリです。
問題形式は4択問題か入力問題で、不正解だった問題に絞って復習できる学習モードや、ランダムに出題されるテストモードもあります！
## 端末内で完結、そしてオープンソース！
問題などは全て端末内のみに保存されます。そのため、アカウントを作成する必要はなく、作成した問題が不正に利用されることもありません！

# Releases
iOS / Androidに対応、リリースタブからダウンロードしてください。
[Web(PWA)へはこちら](https://leasy-pwa.cnion.dev/)
# Build
## Web Support
最初にWeb向けにビルドする前に、必ず以下のコマンドを実行してくだい！
`dart run sqflite_common_ffi_web:setup`