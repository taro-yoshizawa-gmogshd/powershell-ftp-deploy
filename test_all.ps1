#Requires -Version 5.0
# ==========================================
# FTP / FTPS スクリプト 通しテスト
# ==========================================
# 前提: ftp/ftp_settings.json, ftp/ftp_cred.xml
#       ftps/ftp_settings.json, ftps/ftp_cred.xml が設置済み
#
# 使い方:
#   .\test_all.ps1              # FTP・FTPS 両方テスト
#   .\test_all.ps1 -Protocol FTP    # FTP のみ
#   .\test_all.ps1 -Protocol FTPS   # FTPS のみ
#   .\test_all.ps1 -Verbose         # スクリプト出力も表示する

param (
    [ValidateSet("FTP", "FTPS", "All")]
    [string]$Protocol = "All",

    [switch]$Verbose
)

$ErrorActionPreference = "Continue"

# ==========================================
# テスト結果管理
# ==========================================
$script:PassCount = 0
$script:FailCount = 0
$script:Results   = [System.Collections.Generic.List[PSCustomObject]]::new()

function Write-Pass { param([string]$Name)
    Write-Host "  [PASS] $Name" -ForegroundColor Green
    $script:PassCount++
    $script:Results.Add([pscustomobject]@{ テスト名 = $Name; 結果 = "PASS"; 詳細 = "" })
}

function Write-Fail { param([string]$Name, [string]$Detail = "")
    Write-Host "  [FAIL] $Name" -ForegroundColor Red
    if ($Detail) { Write-Host "         └ $Detail" -ForegroundColor Yellow }
    $script:FailCount++
    $script:Results.Add([pscustomobject]@{ テスト名 = $Name; 結果 = "FAIL"; 詳細 = $Detail })
}

# スクリプトを実行してすべての出力（Write-Host含む）を文字列として取得する
# ※ 同一プロセス内で実行すると FTP→FTPS の順でテストする際に .NET の
#   ServicePoint キャッシュ（ネットワーク接続状態）が汚染され FTPS の SSL
#   接続が失敗するため、毎回独立した powershell.exe プロセスで実行する。
function Invoke-ScriptCapture {
    param ([string]$ScriptPath, [hashtable]$Params = @{})

    $argList = [System.Collections.Generic.List[string]]::new()
    $argList.Add("-NoProfile")
    $argList.Add("-NonInteractive")
    $argList.Add("-File")
    $argList.Add($ScriptPath)

    foreach ($kv in $Params.GetEnumerator()) {
        $argList.Add("-$($kv.Key)")
        # 配列はカンマ区切りで渡す（各スクリプト側でカンマ分割に対応済み）
        if ($kv.Value -is [array]) {
            $argList.Add(($kv.Value -join ","))
        } else {
            $argList.Add([string]$kv.Value)
        }
    }

    return (powershell.exe $argList 2>&1 | Out-String).Trim()
}

# ==========================================
# プロトコル別テスト関数
# ==========================================
function Start-ProtocolTest {
    param (
        [string]$Label,     # "FTP" or "FTPS"
        [string]$ScriptDir  # ftp/ または ftps/ のフルパス
    )

    $p = $Label.ToLower()   # スクリプト名プレフィックス (ftp / ftps)

    Write-Host ""
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "  $Label テスト開始" -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan

    # テストごとにユニークなディレクトリ・ファイル名を使う
    $stamp          = Get-Date -Format "yyyyMMddHHmmss"
    $testRemoteDir  = "/copilot_test_$stamp/"
    $testFileName   = "test_$stamp.txt"
    $testContent    = "FTP Test Content [$stamp]"
    $remoteFilePath = "$testRemoteDir$testFileName"

    # ローカル一時ディレクトリ
    $localTempDir = Join-Path $env:TEMP "ftp_test_$stamp"
    New-Item -ItemType Directory -Path $localTempDir -Force | Out-Null
    $localFile = Join-Path $localTempDir $testFileName
    Set-Content -Path $localFile -Value $testContent -Encoding UTF8

    Write-Host "  リモートディレクトリ : $testRemoteDir"
    Write-Host "  テストファイル名      : $testFileName"
    Write-Host "  テスト内容            : $testContent"
    Write-Host ""

    try {
        # ------------------------------------------
        # Step 1: アップロード
        # ------------------------------------------
        Write-Host "  [Step 1] ${p}_upload" -ForegroundColor White
        $out = Invoke-ScriptCapture "$ScriptDir\${p}_upload.ps1" @{
            RemoteDir = $testRemoteDir
            LocalFile = $localFile
        }
        if ($Verbose) { Write-Host $out; Write-Host "" }

        if ($out -match "完了") {
            Write-Pass "$Label upload: アップロード成功"
        } else {
            Write-Fail "$Label upload: アップロード失敗" ($out -replace "`n", " ")
        }

        # ------------------------------------------
        # Step 2: 一覧表示 (ls) - ファイルが存在するか確認
        # ------------------------------------------
        Write-Host ""
        Write-Host "  [Step 2] ${p}_ls" -ForegroundColor White
        $lsOut = Invoke-ScriptCapture "$ScriptDir\${p}_ls.ps1" @{
            RemoteDir = $testRemoteDir
        }
        if ($Verbose) { Write-Host $lsOut; Write-Host "" }

        if ($lsOut -match [regex]::Escape($testFileName)) {
            Write-Pass "$Label ls: アップロードしたファイルが一覧に存在する"
        } else {
            Write-Fail "$Label ls: ファイルが一覧に見つからない" "期待: $testFileName"
        }

        # ------------------------------------------
        # Step 3: ファイル内容表示 (cat) - 内容が一致するか確認
        # ------------------------------------------
        Write-Host ""
        Write-Host "  [Step 3] ${p}_cat" -ForegroundColor White
        $catOut = Invoke-ScriptCapture "$ScriptDir\${p}_cat.ps1" @{
            RemoteFile = $remoteFilePath
        }
        if ($Verbose) { Write-Host $catOut; Write-Host "" }

        if ($catOut -match [regex]::Escape($testContent)) {
            Write-Pass "$Label cat: ファイル内容が一致する"
        } else {
            Write-Fail "$Label cat: ファイル内容が不一致" "期待: $testContent"
        }

        # ------------------------------------------
        # Step 4: ダウンロード - ファイルが取得できるか
        # ------------------------------------------
        Write-Host ""
        Write-Host "  [Step 4] ${p}_download" -ForegroundColor White
        $downloadDir = Join-Path $localTempDir "download"
        New-Item -ItemType Directory -Path $downloadDir -Force | Out-Null

        $dlOut = Invoke-ScriptCapture "$ScriptDir\${p}_download.ps1" @{
            RemoteFile = $remoteFilePath
            LocalDir   = $downloadDir
        }
        if ($Verbose) { Write-Host $dlOut; Write-Host "" }

        if ($dlOut -match "完了") {
            Write-Pass "$Label download: ダウンロード成功"
        } else {
            Write-Fail "$Label download: ダウンロード失敗" ($dlOut -replace "`n", " ")
        }

        # ダウンロードしたファイルの内容確認
        $downloadedPath = Join-Path $downloadDir $testFileName
        if (Test-Path $downloadedPath) {
            $downloadedContent = (Get-Content $downloadedPath -Raw).Trim()
            if ($downloadedContent -eq $testContent.Trim()) {
                Write-Pass "$Label download: ダウンロードしたファイル内容が一致する"
            } else {
                Write-Fail "$Label download: ダウンロードしたファイル内容が不一致" `
                           "期待: [$testContent] / 実際: [$downloadedContent]"
            }
        } else {
            Write-Fail "$Label download: ダウンロードしたファイルが見つからない" $downloadedPath
        }

        # ------------------------------------------
        # Step 5: 削除 (delete)
        # ------------------------------------------
        Write-Host ""
        Write-Host "  [Step 5] ${p}_delete" -ForegroundColor White
        $delOut = Invoke-ScriptCapture "$ScriptDir\${p}_delete.ps1" @{
            RemoteFile = $remoteFilePath
        }
        if ($Verbose) { Write-Host $delOut; Write-Host "" }

        if ($delOut -match "完了") {
            Write-Pass "$Label delete: 削除成功"
        } else {
            Write-Fail "$Label delete: 削除失敗" ($delOut -replace "`n", " ")
        }

        # ------------------------------------------
        # Step 6: 削除後の確認 (ls で消えているか)
        # ------------------------------------------
        Write-Host ""
        Write-Host "  [Step 6] ${p}_ls (削除後確認)" -ForegroundColor White
        try {
            $lsOut2 = Invoke-ScriptCapture "$ScriptDir\${p}_ls.ps1" @{
                RemoteDir = $testRemoteDir
            }
            if ($Verbose) { Write-Host $lsOut2; Write-Host "" }

            # ファイル名が一覧に含まれていなければ削除成功
            if (-not ($lsOut2 -match [regex]::Escape($testFileName))) {
                Write-Pass "$Label delete: 削除後 ls でファイルが消えている"
            } else {
                Write-Fail "$Label delete: 削除後も ls にファイルが残っている"
            }
        }
        catch {
            # ディレクトリごと消えた等で ls 自体がエラーになる場合は削除済みとみなす
            Write-Pass "$Label delete: 削除後 ls でディレクトリが消えている（削除済み）"
        }
    }
    finally {
        # ローカル一時ファイルを常にクリーンアップ
        Remove-Item -Path $localTempDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    Write-Host ""
}

# ==========================================
# メイン処理
# ==========================================
$rootDir = $PSScriptRoot

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  FTP/FTPS スクリプト 通しテスト" -ForegroundColor Cyan
Write-Host "  実行日時: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
Write-Host "  対象    : $Protocol" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

if ($Protocol -eq "FTP" -or $Protocol -eq "All") {
    Start-ProtocolTest -Label "FTP"  -ScriptDir (Join-Path $rootDir "ftp")
}

if ($Protocol -eq "FTPS" -or $Protocol -eq "All") {
    Start-ProtocolTest -Label "FTPS" -ScriptDir (Join-Path $rootDir "ftps")
}

# ==========================================
# サマリー表示
# ==========================================
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  テスト結果サマリー" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$script:Results | Format-Table -AutoSize

$totalColor = if ($script:FailCount -eq 0) { "Green" } else { "Red" }
Write-Host "合計: $($script:PassCount + $script:FailCount) テスト  " -NoNewline
Write-Host "合格: $($script:PassCount)" -ForegroundColor Green -NoNewline
Write-Host "  /  " -NoNewline
Write-Host "失敗: $($script:FailCount)" -ForegroundColor $totalColor
Write-Host ""

if ($script:FailCount -gt 0) {
    exit 1
}
