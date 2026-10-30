# Upload The Verifico PAN wire to Hostinger newapp (FTP).
# Also appends VERIFICO_* to remote .env from Sen Info key file (never prints key).
param()
$ErrorActionPreference = "Stop"
$Root = "D:\dev\mintzer-app"
$CredFile = Join-Path $Root "mintzer.in\fpt details.txt"
$LocalExplore = Join-Path $Root "_hostinger_explore\newapp"
$LocalMirror = Join-Path $Root "mintzer.in\Current Mintzer hosinter file manager\mintzer.in\public_html\newapp"
$KeyFile = Join-Path $Root "Sen Info\Api keys\Pan api.txt"
$BackupDir = Join-Path $Root ("_hostinger_explore\backups\verifico-pan-" + (Get-Date -Format "yyyyMMdd-HHmmss"))

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
  @{ Local = Join-Path $LocalExplore "app\Services\Verifico\VerificoPanService.php"; Remote = "$RemoteBase/app/Services/Verifico/VerificoPanService.php" },
  @{ Local = Join-Path $LocalExplore "app\Http\Controllers\API\ProfileController.php"; Remote = "$RemoteBase/app/Http/Controllers/API/ProfileController.php" },
  @{ Local = Join-Path $LocalMirror "config\services.php"; Remote = "$RemoteBase/config/services.php" }
)

Ensure-FtpDir "$RemoteBase/app/Services/Verifico"

foreach ($u in $uploads) {
  if (-not (Test-Path $u.Local)) { throw "Missing $($u.Local)" }
  try { Download-Ftp $u.Remote (Join-Path $BackupDir (Split-Path $u.Remote -Leaf)) } catch { Write-Host "BAK skip $($u.Remote)" }
  Upload-Ftp $u.Local $u.Remote
}

# Patch remote .env
$key = (Get-Content $KeyFile -Raw).Trim()
$envLocal = Join-Path $BackupDir "dotenv-before.env"
Download-Ftp "$RemoteBase/.env" $envLocal
$envText = [System.IO.File]::ReadAllText($envLocal)
if ($envText -notmatch 'VERIFICO_API_KEY=') {
  if (-not $envText.EndsWith("`n")) { $envText += "`n" }
  $envText += "`n# The Verifico PAN (server-side only)`n"
  $envText += "VERIFICO_API_KEY=$key`n"
  $envText += "VERIFICO_BASE_URL=https://api.theverifico.com`n"
  $envText += "VERIFICO_PAN_ENABLED=true`n"
  $envPatched = Join-Path $BackupDir "dotenv-patched.env"
  [System.IO.File]::WriteAllText($envPatched, $envText)
  Upload-Ftp $envPatched "$RemoteBase/.env"
  Write-Host "Remote .env: appended VERIFICO_* (key not printed)"
} else {
  Write-Host "Remote .env: VERIFICO_API_KEY already present - left unchanged"
}

Write-Host "Done. Backup: $BackupDir"
Write-Host "Owner still needs Verifico verification credits. OCR key alone returns 402 on verify/pan."
