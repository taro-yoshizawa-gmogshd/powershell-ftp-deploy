# ==========================================
# FTP/FTPS セットアップスクリプト
# ==========================================
# ftp_settings.json と ftp_cred.xml を対話形式で作成します。
# 既存ファイルがある場合は上書き確認を行います。

$scriptRoot = $PSScriptRoot
$ftpDir   = Join-Path $scriptRoot "ftp"
$ftpsDir  = Join-Path $scriptRoot "ftps"

Write-Host ""
Write-Host "====================================" -ForegroundColor Cyan
Write-Host "  FTP/FTPS 初期セットアップ" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

# ==========================================
# ステップ 1: プロトコル選択
# ==========================================
Write-Host "[ステップ 1/3] 使用するプロトコルを選択してください" -ForegroundColor Yellow
Write-Host "  1: FTP のみ"
Write-Host "  2: FTPS のみ"
Write-Host "  3: 両方（FTP + FTPS）"
Write-Host ""

do {
    $protocolChoice = Read-Host "番号を入力 (1/2/3)"
} while ($protocolChoice -notin @("1", "2", "3"))

$targetDirs = @()
switch ($protocolChoice) {
    "1" { $targetDirs = @($ftpDir);  Write-Host "→ FTP を設定します" -ForegroundColor Green }
    "2" { $targetDirs = @($ftpsDir); Write-Host "→ FTPS を設定します" -ForegroundColor Green }
    "3" { $targetDirs = @($ftpDir, $ftpsDir); Write-Host "→ FTP と FTPS の両方を設定します" -ForegroundColor Green }
}
Write-Host ""

# ==========================================
# ステップ 2: FTPサーバーの設定
# ==========================================
Write-Host "[ステップ 2/3] FTPサーバーのホスト名かIPアドレスを入力してください" -ForegroundColor Yellow
Write-Host "  例: ftp2.blue.shared-server.net"
Write-Host ""

do {
    $ftpServer = Read-Host "FTPサーバー"
    if ([string]::IsNullOrWhiteSpace($ftpServer)) {
        Write-Host "エラー: 空白は指定できません。もう一度入力してください。" -ForegroundColor Red
    }
} while ([string]::IsNullOrWhiteSpace($ftpServer))

# ftp_settings.json を生成
$settingsJson = @{ FtpServer = $ftpServer } | ConvertTo-Json

foreach ($dir in $targetDirs) {
    $settingsPath = Join-Path $dir "ftp_settings.json"

    # 既存ファイルの上書き確認
    if (Test-Path $settingsPath) {
        $overwrite = Read-Host "既に $settingsPath が存在します。上書きしますか？ (y/n)"
        if ($overwrite -ne "y") {
            Write-Host "→ スキップしました: $settingsPath" -ForegroundColor DarkYellow
            continue
        }
    }

    $settingsJson | Out-File -FilePath $settingsPath -Encoding UTF8
    Write-Host "→ 作成しました: $settingsPath" -ForegroundColor Green
}
Write-Host ""

# ==========================================
# ステップ 3: 認証情報の設定
# ==========================================
Write-Host "[ステップ 3/3] FTPのユーザー名とパスワードを入力してください" -ForegroundColor Yellow
Write-Host "  ※ パスワードは暗号化して保存されます（このPCでのみ復号可能）"
Write-Host "資格情報ダイアログが表示されます。表示されない場合は以下を確認してください:" -ForegroundColor DarkYellow
Write-Host "  → 他のウィンドウに隠れている場合があります。Alt + Tab で切り替えて確認してください" -ForegroundColor DarkYellow
Write-Host "  → 見つからない、または選んでも表示できない時は、Windowsを再ログインすると直る場合があります" -ForegroundColor DarkYellow

$credential = Get-Credential -Message "FTPの認証情報を入力してください"

if ($null -eq $credential) {
    Write-Host "エラー: 認証情報の入力がキャンセルされました。" -ForegroundColor Red
    Write-Host "認証情報なしで終了します。後から以下のコマンドで作成できます:" -ForegroundColor Yellow
    Write-Host '  Get-Credential | Export-Clixml -Path ".\ftp\ftp_cred.xml"' -ForegroundColor White
    exit
}

foreach ($dir in $targetDirs) {
    $credPath = Join-Path $dir "ftp_cred.xml"

    # 既存ファイルの上書き確認
    if (Test-Path $credPath) {
        $overwrite = Read-Host "既に $credPath が存在します。上書きしますか？ (y/n)"
        if ($overwrite -ne "y") {
            Write-Host "→ スキップしました: $credPath" -ForegroundColor DarkYellow
            continue
        }
    }

    $credential | Export-Clixml -Path $credPath
    Write-Host "→ 作成しました: $credPath" -ForegroundColor Green
}

# ==========================================
# 完了
# ==========================================
Write-Host ""
Write-Host "====================================" -ForegroundColor Cyan
Write-Host "  セットアップが完了しました！" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "設定内容:" -ForegroundColor White
Write-Host "  FTPサーバー : $ftpServer"
Write-Host "  ユーザー名  : $($credential.UserName)"
Write-Host ""

# 使い方のガイド表示
$protocolLabel = switch ($protocolChoice) {
    "1" { "ftp" }
    "2" { "ftps" }
    "3" { "ftp / ftps" }
}
Write-Host "使い方の例:" -ForegroundColor White

if ($protocolChoice -in @("1", "3")) {
    Write-Host "  [FTP アップロード]" -ForegroundColor DarkCyan
    Write-Host '  powershell -ExecutionPolicy Bypass -File ".\ftp\ftp_upload.ps1" -RemoteDir "/target/" -LocalFile ".\sample.txt"'
    Write-Host ""
}
if ($protocolChoice -in @("2", "3")) {
    Write-Host "  [FTPS アップロード]" -ForegroundColor DarkCyan
    Write-Host '  powershell -ExecutionPolicy Bypass -File ".\ftps\ftps_upload.ps1" -RemoteDir "/target/" -LocalFile ".\sample.txt"'
    Write-Host ""
}
