# ==========================================
# 実行処理 (FTPS対応版)
# ==========================================
# 認証情報の読み込み
$credential = Import-Clixml -Path $credPath

try {
    Write-Host "アップロード先: $ftpUrl"
    Write-Host "FTPS (FTP over SSL) でのアップロードを開始します..."
    
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
