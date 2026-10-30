# Upload V3 push engagement engine to Hostinger newapp (FTP).
# Source: _hostinger_explore/newapp — never prints password.
param()
$ErrorActionPreference = "Stop"
$Root = "D:\dev\mintzer-app"
$CredFile = Join-Path $Root "mintzer.in\fpt details.txt"
$LocalNewapp = Join-Path $Root "_hostinger_explore\newapp"
$BackupDir = Join-Path $Root ("_hostinger_explore\backups\v3-engagement-" + (Get-Date -Format "yyyyMMdd-HHmmss"))

$lines = Get-Content $CredFile -Encoding UTF8 | ForEach-Object { $_.Trim() } | Where-Object { $_ -and ($_ -notmatch '^\s*#') }
$hostRaw = $lines[0] -replace '^ftp://', '' -replace '^ftps://', '' -replace '/.*$', ''
$user = $lines[1]
$pass = $lines[2]
$RemoteBase = "/domains/mintzer.in/public_html/newapp"

$files = @(
  "app\Services\V3Push\V3PushGateway.php",
  "app\Services\V3Push\V3DealLiveService.php",
  "app\Services\V3Push\V3PushTemplateBank.php",
  "app\Services\V3Push\V3ViewFollowUpService.php",
  "app\Services\V3Push\V3StillLiveService.php",
  "app\Services\V3Push\V3OutboxDrainService.php",
  "app\Services\V3Push\V3AutomationMap.php",
  "app\Http\Controllers\API\Push\V3PushController.php",
  "app\Http\Controllers\Admin\Masters\DealsController.php",
  "app\Http\Controllers\API\Order\OrderController.php",
  "app\Http\Controllers\CronjobController.php",
  "routes\api.php",
  "resources\v3_push\templates.json",
  "database\sql\v3_push_engine.sql",
  "public\v3_push_migrate_once.php"
)

function Ensure-FtpDir([string]$RemoteDir) {
  # Create each path segment (ignore "already exists")
  $parts = $RemoteDir.Trim('/').Split('/') | Where-Object { $_ }
  $acc = ""
  foreach ($p in $parts) {
    $acc = "$acc/$p"
    try {
      $uri = "ftp://$hostRaw$acc"
      $req = [System.Net.FtpWebRequest]::Create($uri)
      $req.Method = [System.Net.WebRequestMethods+Ftp]::MakeDirectory
      $req.Credentials = New-Object System.Net.NetworkCredential($user, $pass)
      $req.UsePassive = $true
      $req.KeepAlive = $false
      $resp = $req.GetResponse()
      $resp.Close()
      Write-Host "MKD $acc"
    } catch {
      # exists or not allowed — continue
    }
  }
}

function Download-Ftp([string]$RemotePath, [string]$LocalPath) {
  try {
    $uri = "ftp://$hostRaw$RemotePath"
    $req = [System.Net.FtpWebRequest]::Create($uri)
    $req.Method = [System.Net.WebRequestMethods+Ftp]::DownloadFile
    $req.Credentials = New-Object System.Net.NetworkCredential($user, $pass)
    $req.UseBinary = $true
    $req.UsePassive = $true
    $req.KeepAlive = $false
    $resp = $req.GetResponse()
    $stream = $resp.GetResponseStream()
    $ms = New-Object System.IO.MemoryStream
    $stream.CopyTo($ms)
    $stream.Close()
    $resp.Close()
    $dir = Split-Path $LocalPath -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    [System.IO.File]::WriteAllBytes($LocalPath, $ms.ToArray())
    Write-Host "BAK $RemotePath"
  } catch {
    Write-Host "BAK skip (missing): $RemotePath"
  }
}

function Upload-Ftp([string]$Local, [string]$RemotePath) {
  $uri = "ftp://$hostRaw$RemotePath"
  Write-Host "PUT $RemotePath"
  $req = [System.Net.FtpWebRequest]::Create($uri)
  $req.Method = [System.Net.WebRequestMethods+Ftp]::UploadFile
  $req.Credentials = New-Object System.Net.NetworkCredential($user, $pass)
  $req.UseBinary = $true
  $req.UsePassive = $true
  $req.KeepAlive = $false
  $bytes = [System.IO.File]::ReadAllBytes($Local)
  $req.ContentLength = $bytes.Length
  $stream = $req.GetRequestStream()
  $stream.Write($bytes, 0, $bytes.Length)
  $stream.Close()
  $resp = $req.GetResponse()
  $resp.Close()
}

Write-Host "FTP host: $hostRaw"
Write-Host "Local: $LocalNewapp"
Write-Host "Backup: $BackupDir"
New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null

# Ensure remote dirs for new paths
Ensure-FtpDir "$RemoteBase/app/Services/V3Push"
Ensure-FtpDir "$RemoteBase/resources/v3_push"
Ensure-FtpDir "$RemoteBase/database/sql"
Ensure-FtpDir "$RemoteBase/app/Http/Controllers/API/Push"

foreach ($rel in $files) {
  $local = Join-Path $LocalNewapp $rel
  if (-not (Test-Path $local)) { throw "Missing $local" }
  $remote = "$RemoteBase/" + ($rel -replace '\\', '/')
  $bakLocal = Join-Path $BackupDir $rel
  Download-Ftp $remote $bakLocal
  Upload-Ftp $local $remote
}

Write-Host "DONE V3 engagement FTP uploads ($($files.Count) files)"
