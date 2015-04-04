my-macbook-initial-setup
========================

hnakamurのMacBookセットアップスクリプトです。

## 動作環境

* OS X Yosemite Japanese
* US keyboard

## 事前準備

以下の手順で「ターミナル」にコンピュータの制御を許可するように設定します。

* [システム環境設定]メニューを開く
* [セキュリティとプライバシー]を選ぶ
* [プライバシー]タブを選ぶ
* 左のリストで[アクセシビリティ]を選ぶ
* 左下の[変更するにはカギをクリックします。]をクリック
* パスワードを入力してロックを解除
* 右の[+]ボタンを押し、[アプリケーション]/[ユーティリティ]/[ターミナル]を選択して[開く]を押す

## 使い方

Finderで[アプリケーション]/[ユーティリティ]/[ターミナル]を選択してターミナルを起動して以下のコマンドを実行。

```
curl https://raw.githubusercontent.com/hnakamur/my-macbook-initial-setup/master/bootstrap.sh | sh
```

## ライセンス

MIT
