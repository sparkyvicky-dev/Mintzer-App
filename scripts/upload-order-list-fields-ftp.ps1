# Additive: getOrderList must return store_order_id (V3 Orders/Wallet).
param()
$ErrorActionPreference = "Stop"
$Root = "D:\dev\mintzer-app"
$CredFile = Join-Path $Root "mintzer.in\fpt details.txt"
$Local = Join-Path $Root "_hostinger_explore\newapp\app\Traits\Common.php"
$lines = Get-Content $CredFile -Encoding UTF8 | ForEach-Object { $_.Trim() } | Where-Object { $_ -and ($_ -notmatch '^\s*#') }
$hostRaw = $lines[0] -replace '^ftp://', '' -replace '^ftps://', '' -replace '/.*$', ''
$user = $lines[1]; $pass = $lines[2]
$Remote = "/domains/mintzer.in/public_html/newapp/app/Traits/Common.php"
$BackupDir = Join-Path $Root ("_hostinger_explore\backups\order-format-" + (Get-Date -Format "yyyyMMdd-HHmmss"))
New-Item -ItemType Directory -Force -Path $BackupDir | Out-Null

# Download current remote as backup
$bak = Join-Path $BackupDir "Common.php"
$dl = [System.Net.FtpWebRequest]::Create("ftp://$hostRaw$Remote")
$dl.Method = [System.Net.WebRequestMethods+Ftp]::DownloadFile
$dl.Credentials = New-Object System.Net.NetworkCredential($user, $pass)
$dl.UseBinary = $true; $dl.UsePassive = $true; $dl.KeepAlive = $false
$resp = $dl.GetResponse(); $stream = $resp.GetResponseStream()
$fs = [IO.File]::Create($bak)
$stream.CopyTo($fs); $fs.Close(); $stream.Close(); $resp.Close()
Write-Host "BACKUP $bak"

$req = [System.Net.FtpWebRequest]::Create("ftp://$hostRaw$Remote")
$req.Method = [System.Net.WebRequestMethods+Ftp]::UploadFile
$req.Credentials = New-Object System.Net.NetworkCredential($user, $pass)
$req.UseBinary = $true; $req.UsePassive = $true; $req.KeepAlive = $false
$bytes = [IO.File]::ReadAllBytes($Local)
$req.ContentLength = $bytes.Length
$out = $req.GetRequestStream()
$out.Write($bytes, 0, $bytes.Length)
$out.Close()
$up = $req.GetResponse(); $up.Close()
Write-Host "UPLOADED Common.php ($($bytes.Length) bytes)"
