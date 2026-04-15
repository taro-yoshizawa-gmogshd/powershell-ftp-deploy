# powershell-ftp-deploy
WindowsのPowerShellを使ったFTPアップロードプログラム

# ftp_settings.json
FTPのホスト名 or IPを`ftp_settings.json`に記述し、`ftp_upload.ps1`と同じディレクトリに設置してください。
```
{
    "FtpServer": "ftp.example.com"
}
```

# コマンド例
`powershell -ExecutionPolicy Bypass -File ".\ftp_upload.ps1" -RemoteDir "/" -LocalFile ".\sample.jpg"`
