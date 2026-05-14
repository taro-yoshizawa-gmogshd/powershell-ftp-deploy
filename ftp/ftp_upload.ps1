# ==========================================
# 引数の設定
# ==========================================
param (
    [string]$FtpServer,      # 例: ftp.example.com

    [Parameter(Mandatory=$true, HelpMessage="アップロード先のディレクトリを指定してください")]
    [string]$RemoteDir,      # 例: /target_directory/

    [Parameter(Mandatory=$true, HelpMessage="アップロードするローカルファイルを指定してください（複数指定可）")]
    [string[]]$LocalFile     # 例: C:\path\to\file1.txt, C:\path\to\file2.txt
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

# カンマ区切りで渡された場合に分割する（スペースを含むパスを引用符でまとめて渡した場合の対応）
$LocalFile = $LocalFile | ForEach-Object { $_ -split "," } | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }

# パラメータチェック
if ([string]::IsNullOrWhiteSpace($FtpServer) -or $LocalFile.Count -eq 0) {
    Write-Host "エラー: ホスト名またはファイルが指定されていません。" -ForegroundColor Red
    exit
}

# アップロード対象のファイルが実在するかチェック
foreach ($file in $LocalFile) {
    if (-Not (Test-Path $file)) {
        Write-Host "エラー: 指定されたローカルファイルが見つかりません ($file)" -ForegroundColor Red
        exit
    }
}

# ==========================================
# URLの組み立て（共通部分）
# ==========================================
# ディレクトリ指定の末尾に「/」がなければ補完する（エラー防止）
if (-Not $RemoteDir.EndsWith("/")) {
    $RemoteDir += "/"
}

# ==========================================
# 実行処理
# ==========================================
# 認証情報の読み込み
$credential = Import-Clixml -Path $credPath

function Initialize-RemoteDirectory {
    param (
        [string]$Server,
        [string]$Path,
        [System.Management.Automation.PSCredential]$Credential,
        [bool]$EnableSsl
    )

    # 入力パスを正規化し、ルート指定なら作成不要
    $normalizedPath = $Path.Trim()
    if ([string]::IsNullOrWhiteSpace($normalizedPath) -or $normalizedPath -eq "/") {
        return
    }

    # /a/b/c のような階層を1段ずつ作成するために分解
    $segments = $normalizedPath.Trim("/").Split("/", [System.StringSplitOptions]::RemoveEmptyEntries)
    $currentPath = ""

    foreach ($segment in $segments) {
        $currentPath += "/$segment"
        $dirUrl = "ftp://$Server$currentPath"

        # FTP の MKD コマンドでディレクトリ作成を試行
        $mkdirRequest = [System.Net.WebRequest]::Create($dirUrl) -as [System.Net.FtpWebRequest]
        $mkdirRequest.Method = [System.Net.WebRequestMethods+Ftp]::MakeDirectory
        $mkdirRequest.Credentials = $Credential
        $mkdirRequest.EnableSsl = $EnableSsl
        $mkdirRequest.KeepAlive = $false

        try {
            $mkdirResponse = $mkdirRequest.GetResponse() -as [System.Net.FtpWebResponse]
            $mkdirResponse.Close()
        }
        catch [System.Net.WebException] {
            $ftpResponse = $_.Exception.Response -as [System.Net.FtpWebResponse]
            if ($null -ne $ftpResponse) {
                $statusCode = $ftpResponse.StatusCode
                $ftpResponse.Close()

                # 既存ディレクトリはエラー扱いにせず次の階層へ進む
                if ($statusCode -eq [System.Net.FtpStatusCode]::ActionNotTakenFileUnavailable) {
                    continue
                }
            }

            throw
        }
    }
}

# 指定ディレクトリが未存在なら作成する（最初の1回だけ実行）
try {
    Initialize-RemoteDirectory -Server $FtpServer -Path $RemoteDir -Credential $credential -EnableSsl $false
}
catch {
    Write-Host "エラー: リモートディレクトリの作成に失敗しました: $_" -ForegroundColor Red
    exit
}

$successCount = 0
$failCount = 0

foreach ($file in $LocalFile) {
    # ローカルファイルからファイル名だけを抽出
    $fileName = Split-Path $file -Leaf

    # アップロード先の完全なURLを作成
    $ftpUrl = "ftp://$FtpServer$RemoteDir$fileName"

    try {
        Write-Host "アップロード中: $file -> $ftpUrl"

        # FtpWebRequest を作成
        $request = [System.Net.WebRequest]::Create($ftpUrl) -as [System.Net.FtpWebRequest]
        $request.Method = [System.Net.WebRequestMethods+Ftp]::UploadFile
        $request.Credentials = $credential
        $request.EnableSsl = $false

        # ローカルファイルを読み込んでサーバーへ転送
        $fileStream = [System.IO.File]::OpenRead($file)
        $requestStream = $request.GetRequestStream()

        $fileStream.CopyTo($requestStream)

        # ストリームを閉じる
        $fileStream.Close()
        $requestStream.Close()

        Write-Host "  完了: $fileName" -ForegroundColor Green
        $successCount++
    }
    catch {
        Write-Host "  エラー: $fileName のアップロードに失敗しました: $_" -ForegroundColor Red
        $failCount++
    }
}

Write-Host ""
Write-Host "アップロード結果: 成功 $successCount 件 / 失敗 $failCount 件" -ForegroundColor Cyan