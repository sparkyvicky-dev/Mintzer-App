# Download live popup-related files so we patch the server copies, not a stale mirror.
$ErrorActionPreference = "Stop"
$Root = "D:\dev\mintzer-app"
$CredFile = Join-Path $Root "mintzer.in\fpt details.txt"
$Out = Join-Path $Root "_hostinger_explore\backups\popup-live-before"
$lines = Get-Content $CredFile -Encoding UTF8 | ForEach-Object { $_.Trim() } | Where-Object { $_ -and ($_ -notmatch '^\s*#') }
$hostRaw = $lines[0] -replace '^ftp://', '' -replace '^ftps://', '' -replace '/.*$', ''
$user = $lines[1]
$pass = $lines[2]
$RemoteBase = "/domains/mintzer.in/public_html/newapp"

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
  Write-Host "OK $($ms.Length) $RemotePath"
}

$files = @(
  "routes/api.php",
  "app/Http/Controllers/API/BannerController.php",
  "app/Traits/Common.php",
  "app/Models/Deal.php",
  "app/Models/Banner.php",
  "app/Http/Controllers/Admin/Masters/DealsController.php",
  "app/Http/Controllers/Admin/Settings/BannerController.php",
  "resources/views/admin/settings/banners.blade.php",
  "resources/views/admin/masters/deals/create.blade.php",
  "resources/views/admin/masters/deals/edit.blade.php",
  "resources/views/admin/masters/deals/copy.blade.php",
  "public/assets/js/admin/masters/banner.js"
)
foreach ($rel in $files) {
  $local = Join-Path $Out ($rel -replace '/', '\')
  Download-Ftp "$RemoteBase/$rel" $local
}
Write-Host "Saved under popup-live-before"
