# powershell-ftp-deploy
WindowsのPowerShellを使ったFTPアップロードプログラムです。
利用するには、下記ファイルを同じディレクトリ配下に設置する必要があります。

## ftp_cred.xml
WindowsのPowerShellにて、FTPの認証情報ファイルを作成してください。コマンドは下記です。
`Get-Credential | Export-Clixml -Path ".\ftp_cred.xml"`

## ftp_settings.json
FTPのホスト名 or IPを`ftp_settings.json`に記述し、`ftp_upload.ps1`と同じディレクトリに設置してください。
```
{
    "FtpServer": "ftp.example.com"
}
```

## コマンド例
`powershell -ExecutionPolicy Bypass -File ".\ftp_upload.ps1" -RemoteDir "/" -LocalFile ".\index.html"`

`powershell -ExecutionPolicy Bypass -File ".\ftp_upload.ps1" -RemoteDir "/assets/img/" -LocalFile ".\assets\img\sample.jpg"`
