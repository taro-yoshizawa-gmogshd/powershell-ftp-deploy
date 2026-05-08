---
name: ftps-deploy
description: "FTPS（SSL）プロトコルでリモートサーバーにファイルをアップロード・ダウンロード・一覧表示・内容表示する。Use when: FTPSでファイル転送、FTPSアップロード、FTPSダウンロード、リモートファイル一覧、リモートファイル表示、ftps deploy、ftps upload、ftps download"
argument-hint: "操作内容を指定（例: /images/ にファイルをアップロード）"
---

# FTPS デプロイスキル

FTPS（SSL）プロトコルを使ってリモートサーバーとファイルをやり取りするスキルです。
スクリプトは `ftps/` ディレクトリにあります。

## 前提条件

スクリプト実行前に以下のセットアップが必要です。

1. **ftp_settings.json** — `ftps/` ディレクトリに配置。FTPサーバーのホスト名を記述。
   ```json
   {
       "FtpServer": "ftp.example.com"
   }
   ```
2. **ftp_cred.xml** — 暗号化された認証情報。以下のコマンドで一度だけ作成する。
   ```powershell
   Get-Credential | Export-Clixml -Path ".\ftps\ftp_cred.xml"
   ```

セットアップ未実施の場合はユーザーに案内してください。

## 操作一覧

### 1. アップロード

リモートサーバーの指定ディレクトリにローカルファイルをアップロードします。

**パラメータ**
- `-RemoteDir`（必須）: アップロード先のリモートディレクトリ（例: `/target/`）
- `-LocalFile`（必須）: アップロードするローカルファイルのパス（例: `.\sample.jpg`）
- `-FtpServer`（任意）: FTPサーバーのホスト名またはIP（省略時は `ftp_settings.json` から読み込み）

**実行コマンド**
```powershell
powershell -ExecutionPolicy Bypass -File ".\ftps\ftps_upload.ps1" -RemoteDir "/images/" -LocalFile ".\sample.jpg"
```

### 2. リスト表示

リモートサーバーの指定ディレクトリのファイル一覧を表示します。

**パラメータ**
- `-RemoteDir`（任意）: 一覧表示するリモートディレクトリ（省略時: `/`）
- `-FtpServer`（任意）: FTPサーバーのホスト名またはIP（省略時は `ftp_settings.json` から読み込み）

**実行コマンド**
```powershell
powershell -ExecutionPolicy Bypass -File ".\ftps\ftps_ls.ps1" -RemoteDir "/images/"
```

### 3. ファイル表示

リモートサーバー上のファイルの内容を表示します。

**パラメータ**
- `-RemoteFile`（必須）: 内容を表示するリモートファイルのパス（例: `/logs/app.log`）
- `-FtpServer`（任意）: FTPサーバーのホスト名またはIP（省略時は `ftp_settings.json` から読み込み）

**実行コマンド**
```powershell
powershell -ExecutionPolicy Bypass -File ".\ftps\ftps_cat.ps1" -RemoteFile "/logs/app.log"
```

### 4. ダウンロード

リモートサーバーのファイルをローカルにダウンロードします。

**パラメータ**
- `-RemoteFile`（必須）: ダウンロードするリモートファイルのパス（例: `/data/report.csv`）
- `-LocalDir`（任意）: 保存先のローカルディレクトリ（省略時: カレントディレクトリ）
- `-FtpServer`（任意）: FTPサーバーのホスト名またはIP（省略時は `ftp_settings.json` から読み込み）

**実行コマンド**
```powershell
powershell -ExecutionPolicy Bypass -File ".\ftps\ftps_download.ps1" -RemoteFile "/data/report.csv" -LocalDir "C:\Downloads\"
```

## 手順

1. ユーザーの要求から操作（アップロード/ダウンロード/一覧/表示）を判断する
2. 必須パラメータが不足している場合はユーザーに確認する
3. ワークスペースのルートディレクトリで上記のコマンドをターミナルで実行する
4. 実行結果を確認し、エラーがあれば原因を報告する
