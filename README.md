※本リポジトリはバックエンド側のソースコードとなります。
 フロントエンド側、及びアプリケーションの説明は[こちら](https://github.com/momonga11/notenext-client "github notenext-client")よりご参照ください。

# NOTENEXT

## ER図

<img src="https://github.com/momonga11/notenext-docs/blob/f32c332552ec8ae2847df09cfa94dbf9ddfc4e76/API%E8%A8%AD%E8%A8%88/DB/ER.png" alt="er_diagram">

## プロジェクトセットアップ手順

※本手順はNOTENEXTのバックエンドのセットアップ手順となります。
[こちら](https://github.com/momonga11/notenext-server "github notenext-server")より、別途フロントエンドのセットアップもおこなってください。

### 前提

#### プロジェクトをクローン

```
git clone git@github.com:momonga11/notenext-server.git
```

### 開発用の場合

#### アプリケーションを起動

```
docker-compose -f docker-compose.dev.yml up -d
```

以下のURLから接続できます。

http://localhost:3000

またブラウザから以下のURLに接続することで、アプリケーションから送信したメールを確認することができます。

http://localhost:1080

#### アプリケーションを廃棄

```
docker-compose -f docker-compose.dev.yml down --volumes
```

### 本番用(オンプレ環境)の場合

#### ※ローカル環境以外から利用する場合

環境変数設定ファイルの作成

```
touch .env.production
```

作成されたファイルに以下を入力する

```
HOST_DEFAULT_URL_HOST=[アプリケーションを実行するサーバーのホスト名]
FRONT_SERVER_ORIGIN=[フロントエンドのホスティング先のオリジン]
CORS_ORIGINS=[フロントエンドのホスティング先のオリジン等(APIに接続する対象のオリジン)]

# メールサーバーの指定
MAILER_SMTP_ADDRESS=[smtpサーバーのホスト名]
MAILER_SMTP_PORT=[smptサーバーのポート番号]
MAILER_SMTP_USER_NAME=[smtpサーバーの認証ユーザー名]
MAILER_SMTP_PASSWORD=[smtpサーバーの認証パスワード]
MAILER_SMTP_DOMAIN=[メール送信元アドレスのドメイン]
```

##### (例)

```
HOST_DEFAULT_URL_HOST=http://192.168.20.120
FRONT_SERVER_ORIGIN=http://192.168.20.2:8001
CORS_ORIGINS=http://192.168.20.2:8001,http://notesystem # 複数指定したい場合はカンマ区切りで設定してください

# メールサーバーの指定
MAILER_SMTP_ADDRESS=smtp.gmail.com
MAILER_SMTP_PORT=587
MAILER_SMTP_USER_NAME=test
MAILER_SMTP_PASSWORD=password
MAILER_SMTP_DOMAIN=example.com
```

#### アプリケーションを起動

```
docker-compose up -d
```

####  アプリケーションを廃棄

```
docker-compose down
```
