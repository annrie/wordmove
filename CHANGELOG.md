# v5.3.0.pre.2

## 日本語

Ruby 3.3 / 3.4 対応フォークの修正版プレビューです。MoveDock での実サイト確認中に見つかった SSH 鍵認証・ファイル転送の問題を修正しました。

### 修正内容

- Ed25519 鍵（パスフレーズ付きも含む）の認証に必要な `ed25519` と `bcrypt_pbkdf` を依存関係に追加。
- rsync のリモートパスを `host:/path` 形式に修正し、SSH のユーザー名・ポート・ゲートウェイ指定を引き継ぐよう修正。
- rsync の接続・転送失敗を非ゼロ終了として伝播。`--simulate` の失敗も成功扱いにしない。
- パスに空白や引用符を含む場合の SSH 引数処理と、パスワードを含むコマンドのログ秘匿に対応。

### 導入・更新

[このバージョンの README](https://github.com/annrie/wordmove/blob/v5.3.0.pre.2/README.md#日本語) を参照してください。新規導入は `git clone --branch v5.3.0.pre.2 https://github.com/annrie/wordmove.git`、既存のクローンは次の手順で更新できます。作業中の変更がある場合は先に保存してください。

```sh
git fetch origin --tags
git checkout v5.3.0.pre.2
bundle install
bundle exec wordmove --version
# 5.3.0.pre.2
```

RubyGems には公開していません。GitHub から Bundler で導入する非公式フォークです。Photocopier は引き続き `v1.5.0.pre.1` を固定して利用します。

### 検証

128 件の RSpec と RuboCop、Ruby 3.3 / 3.4 の CI を確認しています。rsync の回帰テストは一時ディレクトリと SSH 代替スクリプトを使用し、実サイトへ接続せず転送・除外・削除・シミュレーション・異常終了を検証します。MoveDock を使い、Local.app の2サイトで実環境の同期を確認済みです。すべての接続先・構成を検証したものではないため、バックアップを取り、ステージング環境で確認してください。

## English

A maintenance preview of the Ruby 3.3 / 3.4 compatibility fork, fixing SSH key authentication and file-transfer issues found while testing real sites with MoveDock.

### Fixes

- Add `ed25519` and `bcrypt_pbkdf` dependencies for Ed25519 SSH keys, including passphrase-protected keys.
- Use `host:/path` rsync endpoints and preserve SSH user, port and gateway options.
- Propagate rsync connection and transfer failures as nonzero exits, including failures during `--simulate`.
- Handle SSH arguments containing spaces or quotes and redact password-bearing commands from logs.

### Install or update

See the [README for this version](https://github.com/annrie/wordmove/blob/v5.3.0.pre.2/README.md#english). For a new installation, use `git clone --branch v5.3.0.pre.2 https://github.com/annrie/wordmove.git`. To update an existing clone, save any local changes first, then run:

```sh
git fetch origin --tags
git checkout v5.3.0.pre.2
bundle install
bundle exec wordmove --version
# 5.3.0.pre.2
```

This unofficial fork is installed from GitHub through Bundler, not published to RubyGems. Photocopier remains pinned to `v1.5.0.pre.1`.

### Verification

Verification covers 128 RSpec examples, RuboCop, and CI on Ruby 3.3 / 3.4. The rsync regression tests use temporary directories and an SSH stand-in to check transfers, exclusions, deletion, simulation and failures without connecting to real sites. Real-world synchronization has been verified on two Local.app sites using MoveDock. This does not cover every server or configuration; back up your data and validate in staging first.

---

# v5.3.0.pre.1

## 日本語

Ruby 3.3 / 3.4対応の非公式プレビュー。Loggerの読み込み順、Psychのキーワード引数、Kwalifyスキーマの読み込み方法を修正し、Thor 1系とPhotocopier 1.5.0.pre.1を使用します。YAMLの安全性とDB同期の制御フローを含む回帰テストを追加しました。

GitHubからBundlerで導入してください。RubyGemsには公開していません。導入手順と要件は[README](https://github.com/annrie/wordmove/blob/v5.3.0.pre.1/README.md)に記載しています。

外部通信はテストでモック化しています。実サーバー・実DBでの同期は未検証です。まずバックアップを取り、使い捨てのステージング環境で検証してください。

## English

Unofficial Ruby 3.3 / 3.4 compatibility preview. Fixes Logger load order, Psych keyword arguments, and Kwalify schema loading; uses Thor 1.x and Photocopier 1.5.0.pre.1. Adds regression tests including YAML safety and database synchronization control flow.

Install from GitHub with Bundler; this fork is not published to RubyGems. See the [README](https://github.com/annrie/wordmove/blob/v5.3.0.pre.1/README.md) for installation and requirements.

Tests mock external operations. Synchronization against real servers/databases has not been verified. Back up first and validate in a disposable staging environment.

## Upstream history / 上流の履歴

https://github.com/welaika/wordmove/releases
