# Swap Hostinger newapp PAN verify from The Verifico to API Sathi.
# Reads the key from Sen Info (never prints it). Turns Verifico off.
param()
$ErrorActionPreference = "Stop"
$Root = "D:\dev\mintzer-app"
$CredFile = Join-Path $Root "mintzer.in\fpt details.txt"
$LocalExplore = Join-Path $Root "_hostinger_explore\newapp"
$LocalMirror = Join-Path $Root "mintzer.in\Current Mintzer hosinter file manager\mintzer.in\public_html\newapp"
$KeyFile = Join-Path $Root "Sen Info\Api keys\api sathi.txt"
$BackupDir = Join-Path $Root ("_hostinger_explore\backups\apisathi-pan-" + (Get-Date -Format "yyyyMMdd-HHmmss"))

$lines = Get-Content $CredFile -Encoding UTF8 | ForEach-Object { $_.Trim() } | Where-Object { $_ -and ($_ -notmatch '^\s*#') }
$hostRaw = $lines[0] -replace '^ftp://', '' -replace '^ftps://', '' -replace '/.*$', ''
$user = $lines[1]
$pass = $lines[2]
$RemoteBase = "/domains/mintzer.in/public_html/newapp"

function Ensure-FtpDir([string]$RemoteDir) {
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
    } catch { }
  }
}

function Download-Ftp([string]$RemotePath, [string]$LocalPath) {
  $uri = "ftp://$hostRaw$RemotePath"
  $req = [System.Net.FtpWebRequest]::Create($uri)
  $req.Method = [System.Net.WebRequestMethods+Ftp]::DownloadFile
  $req.Credentials = New-Object System.Net.NetworkCredential($user, $pass)
  $req.UseBinary = $true
  $req.UsePassive = $true
  $req.KeepAlive = $false
  $resp = $req.GetResponse()
  $ms = New-Object System.IO.MemoryStream
  $resp.GetResponseStream().CopyTo($ms)
  $resp.Close()
  $dir = Split-Path $LocalPath -Parent
  if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
  [System.IO.File]::WriteAllBytes($LocalPath, $ms.ToArray())
  Write-Host "BAK $RemotePath ($($ms.Length) bytes)"
}

function Upload-Ftp([string]$Local, [string]$RemotePath) {
  $bytes = [System.IO.File]::ReadAllBytes($Local)
  $uri = "ftp://$hostRaw$RemotePath"
  $req = [System.Net.FtpWebRequest]::Create($uri)
  $req.Method = [System.Net.WebRequestMethods+Ftp]::UploadFile
  $req.Credentials = New-Object System.Net.NetworkCredential($user, $pass)
  $req.UseBinary = $true
  $req.UsePassive = $true
  $req.KeepAlive = $false
  $req.ContentLength = $bytes.Length
  $stream = $req.GetRequestStream()
  $stream.Write($bytes, 0, $bytes.Length)
  $stream.Close()
  $resp = $req.GetResponse()
  $resp.Close()
  Write-Host "UP  $RemotePath ($($bytes.Length) bytes)"
}

New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null

$uploads = @(
  @{ Local = Join-Path $LocalExplore "app\Services\ApiSathi\ApiSathiPanService.php"; Remote = "$RemoteBase/app/Services/ApiSathi/ApiSathiPanService.php" },
  @{ Local = Join-Path $LocalExplore "app\Http\Controllers\API\ProfileController.php"; Remote = "$RemoteBase/app/Http/Controllers/API/ProfileController.php" },
  @{ Local = Join-Path $LocalMirror "config\services.php"; Remote = "$RemoteBase/config/services.php" }
)

Ensure-FtpDir "$RemoteBase/app/Services/ApiSathi"

foreach ($u in $uploads) {
  if (-not (Test-Path $u.Local)) { throw "Missing $($u.Local)" }
  try { Download-Ftp $u.Remote (Join-Path $BackupDir (Split-Path $u.Remote -Leaf)) } catch { Write-Host "BAK skip $($u.Remote)" }
  Upload-Ftp $u.Local $u.Remote
}

$key = (Get-Content $KeyFile -Raw).Trim()
if ($key -notmatch '^test_') { throw "Expected a test_ key in api sathi.txt" }
$envLocal = Join-Path $BackupDir "dotenv-before.env"
Download-Ftp "$RemoteBase/.env" $envLocal
$envText = [System.IO.File]::ReadAllText($envLocal)
if ($envText -match '(?m)^VERIFICO_PAN_ENABLED=.*$') {
  $envText = [regex]::Replace($envText, '(?m)^VERIFICO_PAN_ENABLED=.*$', 'VERIFICO_PAN_ENABLED=false')
} else {
  if (-not $envText.EndsWith("`n")) { $envText += "`n" }
  $envText += "VERIFICO_PAN_ENABLED=false`n"
}
$envText = [regex]::Replace($envText, '(?m)^APISATHI_API_KEY=.*\r?\n?', '')
$envText = [regex]::Replace($envText, '(?m)^APISATHI_BASE_URL=.*\r?\n?', '')
$envText = [regex]::Replace($envText, '(?m)^APISATHI_PAN_PATH=.*\r?\n?', '')
$envText = [regex]::Replace($envText, '(?m)^APISATHI_PAN_ENABLED=.*\r?\n?', '')
if (-not $envText.EndsWith("`n")) { $envText += "`n" }
$envText += "`n# API Sathi PAN (server-side only). test_ = sandbox mock.`n"
$envText += "APISATHI_API_KEY=$key`n"
$envText += "APISATHI_BASE_URL=https://apisathi.in/gw/v1`n"
$envText += "APISATHI_PAN_PATH=/pan-verification-v1/`n"
$envText += "APISATHI_PAN_ENABLED=true`n"
$envPatched = Join-Path $BackupDir "dotenv-patched.env"
[System.IO.File]::WriteAllText($envPatched, $envText)
Upload-Ftp $envPatched "$RemoteBase/.env"
Write-Host "Remote .env: Verifico PAN off, API Sathi on (key not printed)"
Write-Host "Done. Backup: $BackupDir"
