# ==========================================
# 引数の設定
# ==========================================
param (
    [string]$FtpServer,      # 例: ftp.example.com

    [Parameter(Mandatory=$true, HelpMessage="ダウンロードするリモートファイルのパスを指定してください")]
    [string]$RemoteFile,     # 例: /target_directory/data.txt

    [string]$LocalDir = "."  # 例: C:\path\to\save\ (省略時はカレントディレクトリ)
)

# ==========================================
# 事前準備・チェック
# ==========================================
# 暗号化された認証情報のパス（ここは固定）
$credPath = Join-Path $PSScriptRoot "ftp_cred.xml"

# 設定ファイルのパス
$configPath = Join-Path $PSScriptRoot "ftp_settings.json"

# 設定のロード
if (Test-Path $configPath) {
    $config = Get-Content $configPath | ConvertFrom-Json

    # 引数が空（指定なし）の場合のみ、JSONの値で埋める
    if ([string]::IsNullOrWhiteSpace($FtpServer)) { $FtpServer = $config.FtpServer }
}

# パラメータチェック
if ([string]::IsNullOrWhiteSpace($FtpServer)) {
    Write-Host "エラー: ホスト名が指定されていません。" -ForegroundColor Red
    exit
}

# ==========================================
# URLの組み立て・保存先の決定
# ==========================================
# リモートファイルのファイル名を抽出 (例: data.txt)
$fileName = Split-Path $RemoteFile -Leaf

# ダウンロード先のローカルパスを作成
$localPath = Join-Path $LocalDir $fileName

# ダウンロード元の完全なURLを作成 (例: ftp://ftp.example.com/target_directory/data.txt)
$ftpUrl = "ftp://$FtpServer$RemoteFile"

# ==========================================
# 実行処理 (FTPS対応版)
# ==========================================
# 認証情報の読み込み
$credential = Import-Clixml -Path $credPath

try {
    Write-Host "ダウンロード元: $ftpUrl"
    Write-Host "保存先: $localPath"
    Write-Host "FTPS (FTP over SSL) でのダウンロードを開始します..."
    Write-Host ""

    $request = [System.Net.WebRequest]::Create($ftpUrl) -as [System.Net.FtpWebRequest]
    $request.Method = [System.Net.WebRequestMethods+Ftp]::DownloadFile
    $request.Credentials = $credential

    # ----------------------------------------------------
    # ここで FTPS (SSL/TLS) を有効化します
    $request.EnableSsl = $true
    # ----------------------------------------------------

    $response = $request.GetResponse() -as [System.Net.FtpWebResponse]
    $responseStream = $response.GetResponseStream()
    $fileStream = [System.IO.File]::Create($localPath)

    $responseStream.CopyTo($fileStream)

    $fileStream.Close()
    $responseStream.Close()
    $response.Close()

    Write-Host "ダウンロードが完了しました！" -ForegroundColor Green
}
catch {
    Write-Host "エラーが発生しました: $_" -ForegroundColor Red
}
