# Wordmove — Ruby 3 compatibility fork / Ruby 3 対応フォーク

[![Tests](https://github.com/annrie/wordmove/actions/workflows/ruby.yml/badge.svg)](https://github.com/annrie/wordmove/actions/workflows/ruby.yml)

## 日本語

WordmoveはWordPressのファイルとデータベースをローカル・リモート間で同期するCLIです。
これは[welaika/wordmove](https://github.com/welaika/wordmove)を基にした**非公式の互換性フォーク**です。
上流の作者・ライセンス表示を保持しています。上流の公式リリースではありません。

### このフォークの変更

- Ruby **3.3 / 3.4**を対象に、Psychのキーワード引数へ対応しました。
- YAMLのアンカー・エイリアスを維持し、任意のRubyオブジェクトの読み込みを引き続き拒否します。
- ActiveSupportの前にLoggerを読み込み、Thor 1系へ更新しました。
- スキーマはPsychで読み込み、Kwalifyの検証機能を維持します。古いKwalify YAMLパーサーへの手修正は不要です。
- [Photocopierの互換性フォーク](https://github.com/annrie/photocopier)を固定して利用します。Net::SSH 7系によりOpenSSL 3へ対応し、新しいNet::Protocolにより`io-wait`の非推奨警告を回避します。
- Ed25519形式のSSH鍵（パスフレーズ付きも含む）に必要な`ed25519`と`bcrypt_pbkdf`を依存関係に含めています。

### インストール

Ruby 3.3または3.4、Git、Bundler 2.5以上5未満が必要です。
`.ruby-version`は開発用に3.3.12を指定しています。rbenvで3.4を使う場合は`RBENV_VERSION=3.4.x`を設定してください（`x`はインストール済みの版）。

```sh
git clone --branch v5.3.0.pre.1 https://github.com/annrie/wordmove.git
cd wordmove
bundle config set --local path vendor/bundle
bundle install
bundle exec wordmove --version
```

この版はGitHubからBundlerで導入します。`gem install wordmove`は上流のRubyGems版を取得するため、このフォークのインストールには使いません。既存gemの直接編集は不要です。

### サイトで実行

Movefileのあるサイトディレクトリへ移動し、クローンしたGemfileを指定します。
`/absolute/path/to/wordmove`を実際のインストール先へ置き換えてください。使用するRubyを先に選択してください。

```sh
cd /absolute/path/to/your/site
BUNDLE_GEMFILE=/absolute/path/to/wordmove/Gemfile bundle exec wordmove --help
BUNDLE_GEMFILE=/absolute/path/to/wordmove/Gemfile bundle exec wordmove doctor
```

SSH、rsync、MySQLクライアントなどは使用する同期方式に合わせて必要です。既定のSQLアダプターにはWP-CLI、FTP利用にはlftpが必要です。
Local.appにも利用できますが、PHP・MySQLクライアントのPATHとMovefileの接続先・ポートを利用環境に合わせて設定してください。
特定のホスティングサービス向けの接続設定を提供するものではありません。

**プレビュー版です。** 自動テストは外部通信をモック化し、実際のリモートサイトやDBを使った同期は未検証です。
同期前にファイルとDBをバックアップし、まず使い捨てのステージング環境でpush/pullを確認してください。
MovefileのERBはRubyコードを実行するため、信頼できるMovefileだけを使用してください。

### 開発・報告

```sh
bundle exec rake  # RSpec + RuboCop
```

RuboCopは上流から引き継いだ指摘を`.rubocop_todo.yml`に記録しています。追加した回帰テストは除外していません。

Photocopierも同時に修正する場合は`PHOTOCOPIER_PATH=/absolute/path/to/photocopier bundle install`でローカル版を指定できます。
その状態のGemfile.lockはコミットせず、公開前に環境変数を外して`bundle install`を実行してください。
不具合は[このフォークのIssues](https://github.com/annrie/wordmove/issues)へ、Rubyの版と匿名化した再現手順を添えて報告してください。
パスワード・SSH鍵・実サイトのDBダンプを添付しないでください。

[変更履歴](CHANGELOG.md) / [上流の詳細ドキュメント（英語・旧版の導入手順を含む）](docs/upstream-readme.md)

## English

Wordmove is a CLI for synchronizing WordPress files and databases between local and remote environments.
This is an **unofficial compatibility fork** of [welaika/wordmove](https://github.com/welaika/wordmove), preserving upstream authorship and licensing. It is not an official upstream release.

### Changes in this fork

- Targets Ruby **3.3 / 3.4** and uses Psych's keyword arguments.
- Preserves YAML anchors and aliases while continuing to reject arbitrary Ruby objects.
- Loads Logger before ActiveSupport and upgrades to Thor 1.x.
- Loads schemas through Psych while retaining Kwalify validation, without patching its legacy YAML parser.
- Pins the [Photocopier compatibility fork](https://github.com/annrie/photocopier), using Net::SSH 7 for OpenSSL 3 and current Net::Protocol to avoid the `io-wait` deprecation warning.
- Includes `ed25519` and `bcrypt_pbkdf` dependencies for Ed25519 SSH keys, including passphrase-protected keys.

### Installation

Requires Ruby 3.3 or 3.4, Git, and Bundler >= 2.5 and < 5.
The development `.ruby-version` selects 3.3.12. To use rbenv with Ruby 3.4, set `RBENV_VERSION=3.4.x`, replacing `x` with your installed patch version.

```sh
git clone --branch v5.3.0.pre.1 https://github.com/annrie/wordmove.git
cd wordmove
bundle config set --local path vendor/bundle
bundle install
bundle exec wordmove --version
```

Install this preview from GitHub with Bundler. `gem install wordmove` retrieves the upstream RubyGems release, not this fork. No manual edits to installed gems are needed.

### Running inside a site

Change to the site directory containing your Movefile and select the cloned Gemfile.
Replace `/absolute/path/to/wordmove` with your installation path and select the appropriate Ruby first.

```sh
cd /absolute/path/to/your/site
BUNDLE_GEMFILE=/absolute/path/to/wordmove/Gemfile bundle exec wordmove --help
BUNDLE_GEMFILE=/absolute/path/to/wordmove/Gemfile bundle exec wordmove doctor
```

Install SSH, rsync, MySQL clients, and other tools required by your transport. The default SQL adapter needs WP-CLI; FTP needs lftp.
For Local.app, configure the PHP/MySQL client PATH and Movefile host/port to match your environment. This fork does not provide hosting-specific connection settings.

**This is a preview.** Automated tests mock external operations; synchronization against real remote sites or databases has not been verified.
Back up files and databases, then verify push/pull against a disposable staging environment before using it for production.
Movefile ERB executes Ruby code: only use trusted Movefiles.

### Development and reporting

```sh
bundle exec rake  # RSpec + RuboCop
```

Existing upstream RuboCop findings are recorded in `.rubocop_todo.yml`; the new regression specs have no exclusions.

To develop both forks together, use `PHOTOCOPIER_PATH=/absolute/path/to/photocopier bundle install`.
Do not commit the resulting local-path Gemfile.lock; unset the variable and run `bundle install` before publishing.
Report bugs to [this fork's Issues](https://github.com/annrie/wordmove/issues) with your Ruby version and sanitized reproduction steps. Do not attach passwords, SSH keys, or live database dumps.

[Changelog](CHANGELOG.md) / [Detailed upstream documentation (English; includes historical installation instructions)](docs/upstream-readme.md)

## License / ライセンス

MIT — see [LICENSE](LICENSE). Original authors retain their copyright. / 原著作者の著作権表示を保持しています。
