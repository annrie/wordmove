# v5.3.0.pre.1

## 日本語

Ruby 3.3 / 3.4対応の非公式プレビュー。Loggerの読み込み順、Psychのキーワード引数、Kwalifyスキーマの読み込み方法を修正し、Thor 1系とPhotocopier 1.5.0.pre.1を使用します。YAMLの安全性とDB同期の制御フローを含む回帰テストを追加しました。

GitHubからBundlerで導入してください。RubyGemsには公開していません。導入手順と要件は[README](https://github.com/annrie/wordmove/blob/v5.3.0.pre.1/README.md)に記載しています。

外部通信はテストでモック化しています。実サーバー・実DBでの同期は未検証です。まずバックアップを取り、使い捨てのステージング環境で検証してください。

## English

Unofficial Ruby 3.3 / 3.4 compatibility preview. Fixes Logger load order, Psych keyword arguments, and Kwalify schema loading; uses Thor 1.x and Photocopier 1.5.0.pre.1. Adds regression tests including YAML safety and database synchronization control flow.

Install from GitHub with Bundler; this fork is not published to RubyGems. See the [README](https://github.com/annrie/wordmove/blob/v5.3.0.pre.1/README.md) for installation and requirements.

Tests mock external operations. Synchronization against real servers/databases has not been verified. Back up first and validate in a disposable staging environment.
