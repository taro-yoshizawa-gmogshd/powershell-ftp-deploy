# ==========================================
# 引数の設定
# ==========================================
param (
    [string]$FtpServer,      # 例: ftp.example.com

    [Parameter(Mandatory=$true, HelpMessage="削除するリモートファイルのパスを指定してください")]
    [string]$RemoteFile      # 例: /target_directory/your_file.txt
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
if ([string]::IsNullOrWhiteSpace($FtpServer) -or [string]::IsNullOrWhiteSpace($RemoteFile)) {
    Write-Host "エラー: ホスト名またはリモートファイルパスが指定されていません。" -ForegroundColor Red
    exit
}

# ==========================================
# URLの組み立て
# ==========================================
# 削除対象ファイルの完全なURLを作成 (例: ftp://ftp.example.com/target_directory/your_file.txt)
$ftpUrl = "ftp://$FtpServer$RemoteFile"

# ==========================================
# 実行処理
# ==========================================
# 認証情報の読み込み
$credential = Import-Clixml -Path $credPath

try {
    Write-Host "削除対象: $ftpUrl"
    Write-Host "削除を開始します..."

    $request = [System.Net.WebRequest]::Create($ftpUrl) -as [System.Net.FtpWebRequest]
    $request.Method = [System.Net.WebRequestMethods+Ftp]::DeleteFile
    $request.Credentials = $credential
    $request.EnableSsl = $false

    $response = $request.GetResponse() -as [System.Net.FtpWebResponse]
    $statusDescription = $response.StatusDescription
    $response.Close()

    Write-Host "削除が完了しました！ ($statusDescription)" -ForegroundColor Green
}
catch {
    Write-Host "エラーが発生しました: $_" -ForegroundColor Red
}
