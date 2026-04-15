# ==========================================
# 引数の設定
# ==========================================
param (
    [string]$FtpServer,      # 例: ftp.example.com

    [Parameter(Mandatory=$true, HelpMessage="アップロード先のディレクトリを指定してください")]
    [string]$RemoteDir,      # 例: /target_directory/

    [Parameter(Mandatory=$true, HelpMessage="アップロードするローカルファイルを指定してください")]
    [string]$LocalFile       # 例: C:\path\to\your_local_file.txt
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
if ([string]::IsNullOrWhiteSpace($FtpServer) -or [string]::IsNullOrWhiteSpace($LocalFile)) {
    Write-Host "エラー: ホスト名またはファイルが指定されていません。" -ForegroundColor Red
    exit
}

# アップロード対象のファイルが実在するかチェック
if (-Not (Test-Path $LocalFile)) {
    Write-Host "エラー: 指定されたローカルファイルが見つかりません ($LocalFile)" -ForegroundColor Red
    exit
}

# ==========================================
# URLの組み立て
# ==========================================
# ローカルファイルからファイル名だけを抽出 (例: data.txt)
$fileName = Split-Path $LocalFile -Leaf

# ディレクトリ指定の末尾に「/」がなければ補完する（エラー防止）
if (-Not $RemoteDir.EndsWith("/")) {
    $RemoteDir += "/"
}

# アップロード先の完全なURLを作成 (例: ftp://ftp.example.com/target_directory/data.txt)
$ftpUrl = "ftp://$FtpServer$RemoteDir$fileName"

# ==========================================
# 実行処理
# ==========================================
# 認証情報の読み込み
$credential = Import-Clixml -Path $credPath
$webClient = New-Object System.Net.WebClient
$webClient.Credentials = $credential

try {
    Write-Host "アップロード先: $ftpUrl"
    Write-Host "アップロードを開始します..."
    
    $webClient.UploadFile($ftpUrl, $LocalFile)
    
    Write-Host "アップロードが完了しました！" -ForegroundColor Green
}
catch {
    Write-Host "エラーが発生しました: $_" -ForegroundColor Red
}
finally {
    $webClient.Dispose()
}