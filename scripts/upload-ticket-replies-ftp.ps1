# Upload additive ticket-reply files to Hostinger newapp (FTP).
# Uses mintzer.in\fpt details.txt — never prints password.
param()
$ErrorActionPreference = "Stop"
$Root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
if (-not (Test-Path (Join-Path $Root "mintzer.in\fpt details.txt"))) {
  $Root = "D:\dev\mintzer-app"
}
$CredFile = Join-Path $Root "mintzer.in\fpt details.txt"
$LocalNewapp = Join-Path $Root "mintzer.in\Current Mintzer hosinter file manager\mintzer.in\public_html\newapp"

$lines = Get-Content $CredFile -Encoding UTF8 | ForEach-Object { $_.Trim() } | Where-Object { $_ -and ($_ -notmatch '^\s*#') }
$hostRaw = $lines[0] -replace '^ftp://', '' -replace '^ftps://', '' -replace '/.*$', ''
$user = $lines[1]
$pass = $lines[2]

$files = @(
  "routes\api.php",
  "routes\web.php",
  "app\Http\Controllers\API\TicketController.php",
  "app\Http\Controllers\API\ProfileController.php",
  "app\Http\Controllers\API\AdminApp\TicketController.php",
  "app\Http\Controllers\Admin\Customer\CustomerController.php",
  "app\Models\Ticket.php",
  "app\Models\TicketReply.php",
  "resources\views\admin\customer\tickets.blade.php",
  "public\assets\js\admin\masters\ticket.js"
)

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

foreach ($rel in $files) {
  $local = Join-Path $LocalNewapp $rel
  if (-not (Test-Path $local)) { throw "Missing $local" }
  $remote = "/domains/mintzer.in/public_html/newapp/" + ($rel -replace '\\', '/')
  Upload-Ftp $local $remote
}
Write-Host "DONE uploads"
