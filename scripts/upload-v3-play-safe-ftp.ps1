# Upload crash-safe FCM fix + payout/timers to Hostinger newapp.
param()
$ErrorActionPreference = "Stop"
$Root = "D:\dev\mintzer-app"
$CredFile = Join-Path $Root "mintzer.in\fpt details.txt"
$LocalNewapp = Join-Path $Root "_hostinger_explore\newapp"
$lines = Get-Content $CredFile -Encoding UTF8 | ForEach-Object { $_.Trim() } | Where-Object { $_ -and ($_ -notmatch '^\s*#') }
$hostRaw = $lines[0] -replace '^ftp://', '' -replace '^ftps://', '' -replace '/.*$', ''
$user = $lines[1]; $pass = $lines[2]
$RemoteBase = "/domains/mintzer.in/public_html/newapp"

$files = @(
  "app\Http\Controllers\CronjobController.php",
  "app\Http\Controllers\Admin\Masters\DealsController.php",
  "app\Http\Controllers\Admin\Order\OrderController.php",
  "app\Http\Controllers\API\Push\V3PushController.php",
  "app\Services\AdminApp\OrderActionService.php",
  "app\Services\V3Push\V3PushGateway.php",
  "app\Services\V3Push\V3PayoutNotifyService.php",
  "app\Services\V3Push\V3PlacementTimerService.php"
)

function Upload-Ftp([string]$Local, [string]$RemotePath) {
  $uri = "ftp://$hostRaw$RemotePath"
  Write-Host "PUT $RemotePath"
  $req = [System.Net.FtpWebRequest]::Create($uri)
  $req.Method = [System.Net.WebRequestMethods+Ftp]::UploadFile
  $req.Credentials = New-Object System.Net.NetworkCredential($user, $pass)
  $req.UseBinary = $true; $req.UsePassive = $true; $req.KeepAlive = $false
  $bytes = [IO.File]::ReadAllBytes($Local)
  $req.ContentLength = $bytes.Length
  $stream = $req.GetRequestStream()
  $stream.Write($bytes, 0, $bytes.Length)
  $stream.Close()
  $resp = $req.GetResponse(); $resp.Close()
}

foreach ($rel in $files) {
  $local = Join-Path $LocalNewapp $rel
  if (-not (Test-Path $local)) { throw "Missing $local" }
  Upload-Ftp $local ("$RemoteBase/" + ($rel -replace '\\', '/'))
}
Write-Host "DONE $($files.Count) files"
