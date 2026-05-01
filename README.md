# powershell-ftp-deploy
WindowsのPowerShellを使ったFTP/FTPSクライアントスクリプト集です。
アップロード・ダウンロード・ファイル一覧取得・ファイル内容表示に対応しています。

---

# セッティング

## ftp_settings.json
FTPのホスト名またはIPアドレスを `ftp_settings.json` に記述し、各スクリプトと同じディレクトリに設置してください。

```json
{
    "FtpServer": "ftp.example.com"
}
```

> `-FtpServer` 引数でコマンドラインから直接指定することもできます。引数が優先されます。

## 認証情報（ftp_cred.xml）
FTPの認証情報を暗号化して保存しておく必要があります。以下のコマンドを一度だけ実行してください。

```powershell
Get-Credential | Export-Clixml -Path ".\ftp_cred.xml"
```

実行するとユーザー名とパスワードの入力を求められます。入力内容は `ftp_cred.xml` に暗号化されて保存されます。

---

# アップロード

リモートサーバーの指定ディレクトリにローカルファイルをアップロードします。

| スクリプト | プロトコル |
|---|---|
| `ftp_upload.ps1` | FTP |
| `ftps_upload.ps1` | FTPS（SSL） |

**パラメータ**

| パラメータ | 必須 | 説明 |
|---|---|---|
| `-RemoteDir` | ✔ | アップロード先のリモートディレクトリ（例: `/target/`） |
| `-LocalFile` | ✔ | アップロードするローカルファイルのパス（例: `.\sample.jpg`） |
| `-FtpServer` | | FTPサーバーのホスト名またはIP（省略時は `ftp_settings.json` から読み込み） |

**コマンド例**

```powershell
powershell -ExecutionPolicy Bypass -File ".\ftp_upload.ps1" -RemoteDir "/images/" -LocalFile ".\sample.jpg"
```

---

# リスト表示

リモートサーバーの指定ディレクトリのファイル一覧を表示します。

| スクリプト | プロトコル |
|---|---|
| `ftp_ls.ps1` | FTP |
| `ftps_ls.ps1` | FTPS（SSL） |

**パラメータ**

| パラメータ | 必須 | 説明 |
|---|---|---|
| `-RemoteDir` | | 一覧表示するリモートディレクトリ（省略時: `/`） |
| `-FtpServer` | | FTPサーバーのホスト名またはIP（省略時は `ftp_settings.json` から読み込み） |

**コマンド例**

```powershell
powershell -ExecutionPolicy Bypass -File ".\ftp_ls.ps1" -RemoteDir "/images/"
```

---

# ファイル表示

リモートサーバー上のファイルの内容を表示します。

| スクリプト | プロトコル |
|---|---|
| `ftp_cat.ps1` | FTP |
| `ftps_cat.ps1` | FTPS（SSL） |

**パラメータ**

| パラメータ | 必須 | 説明 |
|---|---|---|
| `-RemoteFile` | ✔ | 内容を表示するリモートファイルのパス（例: `/logs/app.log`） |
| `-FtpServer` | | FTPサーバーのホスト名またはIP（省略時は `ftp_settings.json` から読み込み） |

**コマンド例**

```powershell
powershell -ExecutionPolicy Bypass -File ".\ftp_cat.ps1" -RemoteFile "/logs/app.log"
```

---

# ダウンロード

リモートサーバーのファイルをローカルにダウンロードします。

| スクリプト | プロトコル |
|---|---|
| `ftp_download.ps1` | FTP |
| `ftps_download.ps1` | FTPS（SSL） |

**パラメータ**

| パラメータ | 必須 | 説明 |
|---|---|---|
| `-RemoteFile` | ✔ | ダウンロードするリモートファイルのパス（例: `/data/report.csv`） |
| `-LocalDir` | | 保存先のローカルディレクトリ（省略時: カレントディレクトリ） |
| `-FtpServer` | | FTPサーバーのホスト名またはIP（省略時は `ftp_settings.json` から読み込み） |

**コマンド例**

```powershell
powershell -ExecutionPolicy Bypass -File ".\ftp_download.ps1" -RemoteFile "/data/report.csv" -LocalDir "C:\Downloads\"
```
