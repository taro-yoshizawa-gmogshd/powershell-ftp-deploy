# FTP の使い方

FTP プロトコルを使ったスクリプトの使い方です。  
事前にセッティングが必要です。未実施の場合は [README.md](../README.md) を参照してください。

---

# アップロード

リモートサーバーの指定ディレクトリにローカルファイルをアップロードします。

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

---

# ファイル削除

リモートサーバー上のファイルを削除します。

**パラメータ**

| パラメータ | 必須 | 説明 |
|---|---|---|
| `-RemoteFile` | ✔ | 削除するリモートファイルのパス（例: `/logs/old.log`） |
| `-FtpServer` | | FTPサーバーのホスト名またはIP（省略時は `ftp_settings.json` から読み込み） |

**コマンド例**

```powershell
powershell -ExecutionPolicy Bypass -File ".\ftp_delete.ps1" -RemoteFile "/logs/old.log"
```
