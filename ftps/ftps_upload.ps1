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
# 実行処理 (FTPS対応版)
# ==========================================
# 認証情報の読み込み
$credential = Import-Clixml -Path $credPath

function Ensure-RemoteDirectoryExists {
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

        # FTPS の MKD コマンドでディレクトリ作成を試行
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

try {
    Write-Host "アップロード先: $ftpUrl"
    Write-Host "FTPS (FTP over SSL) でのアップロードを開始します..."

    # 指定ディレクトリが未存在なら作成する
    Ensure-RemoteDirectoryExists -Server $FtpServer -Path $RemoteDir -Credential $credential -EnableSsl $true
    
    # WebClientの代わりに FtpWebRequest を作成
    $request = [System.Net.WebRequest]::Create($ftpUrl) -as [System.Net.FtpWebRequest]
    $request.Method = [System.Net.WebRequestMethods+Ftp]::UploadFile
    $request.Credentials = $credential
    
    # ----------------------------------------------------
    # ここで FTPS (SSL/TLS) を有効化します
    $request.EnableSsl = $true
    # ----------------------------------------------------

    # ローカルファイルを読み込んでサーバーへ転送
    $fileStream = [System.IO.File]::OpenRead($LocalFile)
    $requestStream = $request.GetRequestStream()
    
    $fileStream.CopyTo($requestStream)
    
    # ストリームを閉じる
    $fileStream.Close()
    $requestStream.Close()
    
    Write-Host "アップロードが完了しました！" -ForegroundColor Green
}
catch {
    Write-Host "エラーが発生しました: $_" -ForegroundColor Red
}