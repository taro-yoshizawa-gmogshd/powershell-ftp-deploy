# ==========================================
# 引数の設定
# ==========================================
param (
    [string]$FtpServer,      # 例: ftp.example.com

    [string]$RemoteDir = "/" # 例: /target_directory/
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
# URLの組み立て
# ==========================================
# ディレクトリ指定の末尾に「/」がなければ補完する（エラー防止）
if (-Not $RemoteDir.EndsWith("/")) {
    $RemoteDir += "/"
}

# 一覧取得先の完全なURLを作成 (例: ftp://ftp.example.com/target_directory/)
$ftpUrl = "ftp://$FtpServer$RemoteDir"

# ==========================================
# 実行処理 (FTPS対応版)
# ==========================================
# 認証情報の読み込み
$credential = Import-Clixml -Path $credPath

try {
    Write-Host "一覧取得先: $ftpUrl"
    Write-Host "FTPS (FTP over SSL) での一覧取得を開始します..."
    Write-Host ""

    $request = [System.Net.WebRequest]::Create($ftpUrl) -as [System.Net.FtpWebRequest]
    $request.Method = [System.Net.WebRequestMethods+Ftp]::ListDirectoryDetails
    $request.Credentials = $credential

    # ----------------------------------------------------
    # ここで FTPS (SSL/TLS) を有効化します
    $request.EnableSsl = $true
    # ----------------------------------------------------

    $response = $request.GetResponse() -as [System.Net.FtpWebResponse]
    $reader = New-Object System.IO.StreamReader($response.GetResponseStream())
    $listing = $reader.ReadToEnd()
    $reader.Close()
    $response.Close()

    Write-Host $listing
}
catch {
    Write-Host "エラーが発生しました: $_" -ForegroundColor Red
    exit 1
}
