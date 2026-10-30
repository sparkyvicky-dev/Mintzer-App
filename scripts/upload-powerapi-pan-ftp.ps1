# Point Hostinger newapp PAN verify at PowerAPI.
# Reads the key from Sen Info and never prints it.
# API Sathi stays in .env for IFSC. PAN falls back to API Sathi only if POWERAPI_PAN_ENABLED=false.
param()
$ErrorActionPreference = "Stop"
$Root = "D:\dev\mintzer-app"
$CredFile = Join-Path $Root "mintzer.in\fpt details.txt"
$LocalExplore = Join-Path $Root "_hostinger_explore\newapp"
$KeyFile = Join-Path $Root "Sen Info\Api keys\Powerapi pan api.txt"
$BackupDir = Join-Path $Root ("_hostinger_explore\backups\powerapi-pan-" + (Get-Date -Format "yyyyMMdd-HHmmss"))

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

$key = (Get-Content $KeyFile -Raw).Trim()
if ($key -notmatch '^pk_') { throw "PowerAPI key file is missing a pk_ key" }

New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
Ensure-FtpDir "$RemoteBase/app/Services/PowerApi"

$php = @(
  @{ Local = Join-Path $LocalExplore "app\Services\PowerApi\PowerApiPanService.php"; Remote = "$RemoteBase/app/Services/PowerApi/PowerApiPanService.php" },
  @{ Local = Join-Path $LocalExplore "app\Http\Controllers\API\ProfileController.php"; Remote = "$RemoteBase/app/Http/Controllers/API/ProfileController.php" }
)
foreach ($u in $php) {
  if (-not (Test-Path $u.Local)) { throw "Missing $($u.Local)" }
  try { Download-Ftp $u.Remote (Join-Path $BackupDir (Split-Path $u.Remote -Leaf)) } catch { Write-Host "BAK skip $($u.Remote)" }
  Upload-Ftp $u.Local $u.Remote
}

$envTemp = Join-Path $env:TEMP ("mintzer-dotenv-" + [guid]::NewGuid().ToString("n") + ".env")
try {
  Download-Ftp "$RemoteBase/.env" $envTemp
  $envText = [System.IO.File]::ReadAllText($envTemp)
  $envText = [regex]::Replace($envText, '(?m)^POWERAPI_PAN_KEY=.*\r?\n?', '')
  $envText = [regex]::Replace($envText, '(?m)^POWERAPI_PAN_ENABLED=.*\r?\n?', '')
  if (-not $envText.EndsWith("`n")) { $envText += "`n" }
  $envText += "`n# PowerAPI PAN name only. IFSC stays on API Sathi.`n"
  $envText += "POWERAPI_PAN_KEY=$key`n"
  $envText += "POWERAPI_PAN_ENABLED=true`n"
  [System.IO.File]::WriteAllText($envTemp, $envText)
  Upload-Ftp $envTemp "$RemoteBase/.env"
} finally {
  if (Test-Path $envTemp) { Remove-Item $envTemp -Force }
}

Write-Host "Remote .env: PowerAPI PAN on. API Sathi keys left in place. Key not printed."
Write-Host "Done. PHP backup: $BackupDir"
