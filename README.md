# powershell-ftp-deploy
WindowsのPowerShellを使ったFTP/FTPSクライアントスクリプト集です。
アップロード・ダウンロード・ファイル一覧取得・ファイル内容表示に対応しています。

---

# セッティング
スクリプトと同じディレクトリに `ftp_settings.json` と `ftp_cred.xml` を設置してください。

## かんたんセットアップ（推奨）
`setup.bat` をダブルクリックすると、対話形式で必要なファイルがすべて自動作成されます。

> コマンドラインから実行する場合: `powershell -ExecutionPolicy Bypass -File ".\setup.ps1"`

画面の案内に従って「プロトコル選択」「FTPサーバー名」「ユーザー名/パスワード」を入力するだけで完了します。

## 手動セットアップ

<details>
<summary>手動で設定ファイルを作成する場合はこちら</summary>

### ftp_settings.json
設定ファイルを作成する必要があります。FTPのホスト名またはIPアドレスを `ftp_settings.json` に記述してください。構造は以下の通りです。

```json
{
    "FtpServer": "ftp.example.com"
}
```

> `-FtpServer` 引数でコマンドラインから直接指定することもできます。引数が優先されます。

### 認証情報（ftp_cred.xml）
FTPの認証情報を暗号化して保存しておく必要があります。以下のコマンドを一度だけ実行してください。

```powershell
Get-Credential | Export-Clixml -Path ".\ftp_cred.xml"
```

実行するとユーザー名とパスワードの入力を求められます。入力内容は `ftp_cred.xml` に暗号化されて保存されます。

</details>

---

# 使い方

各プロトコルの詳細な使い方は以下を参照してください。

- [FTP の使い方](ftp/FTP.md)
- [FTPS の使い方](ftps/FTPS.md)

---

# AI アシスタント連携（SKILL.md）

GitHub Copilot および Claude 向けのスキル定義ファイルを用意しています。
対応するエディタで本リポジトリを開くと、AIアシスタントが FTPS 操作（アップロード・ダウンロード・一覧表示・ファイル内容表示）を自動で実行できるようになります。

| AI アシスタント | スキルファイル |
|---|---|
| GitHub Copilot | [.github/skills/ftps-deploy/SKILL.md](.github/skills/ftps-deploy/SKILL.md) |
| Claude | [.claude/skills/ftps-deploy/SKILL.md](.claude/skills/ftps-deploy/SKILL.md) |
