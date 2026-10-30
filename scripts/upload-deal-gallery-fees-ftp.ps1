# Upload deal image/fee/store_name fixes to Hostinger newapp (FTP).
param()
$ErrorActionPreference = "Stop"
$Root = "D:\dev\mintzer-app"
$CredFile = Join-Path $Root "mintzer.in\fpt details.txt"
$LocalNewapp = Join-Path $Root "_hostinger_explore\newapp"
$ViewsLocal = Join-Path $Root "mintzer.in\Current Mintzer hosinter file manager\mintzer.in\public_html\newapp\resources\views\admin\masters\deals"
$lines = Get-Content $CredFile -Encoding UTF8 | ForEach-Object { $_.Trim() } | Where-Object { $_ -and ($_ -notmatch '^\s*#') }
$hostRaw = $lines[0] -replace '^ftp://', '' -replace '^ftps://', '' -replace '/.*$', ''
$user = $lines[1]; $pass = $lines[2]
$RemoteBase = "/domains/mintzer.in/public_html/newapp"
$BackupDir = Join-Path $Root ("_hostinger_explore\backups\deal-gallery-fees-" + (Get-Date -Format "yyyyMMdd-HHmmss"))
New-Item -ItemType Directory -Force -Path $BackupDir | Out-Null

function Upload-Ftp([string]$Local, [string]$RemotePath) {
  if (-not (Test-Path $Local)) { throw "Missing $Local" }
  $uri = "ftp://$hostRaw$RemotePath"
  $req = [System.Net.FtpWebRequest]::Create($uri)
  $req.Method = [System.Net.WebRequestMethods+Ftp]::UploadFile
  $req.Credentials = New-Object System.Net.NetworkCredential($user, $pass)
  $req.UseBinary = $true; $req.UsePassive = $true; $req.KeepAlive = $false
  $bytes = [IO.File]::ReadAllBytes($Local)
  $req.ContentLength = $bytes.Length
  $stream = $req.GetRequestStream()
  $stream.Write($bytes, 0, $bytes.Length)
  $stream.Close()
  $resp = $req.GetResponse()
  $resp.Close()
  Write-Host "UP $RemotePath"
}

$files = @(
  @{ Local = (Join-Path $LocalNewapp "app\Traits\Common.php"); Remote = "$RemoteBase/app/Traits/Common.php" },
  @{ Local = (Join-Path $LocalNewapp "app\Models\Deal.php"); Remote = "$RemoteBase/app/Models/Deal.php" },
  @{ Local = (Join-Path $LocalNewapp "app\Http\Controllers\Admin\Masters\DealsController.php"); Remote = "$RemoteBase/app/Http/Controllers/Admin/Masters/DealsController.php" },
  @{ Local = (Join-Path $LocalNewapp "app\Http\Controllers\API\Order\OrderController.php"); Remote = "$RemoteBase/app/Http/Controllers/API/Order/OrderController.php" },
  @{ Local = (Join-Path $LocalNewapp "public\deal_fees_migrate_once.php"); Remote = "$RemoteBase/public/deal_fees_migrate_once.php" },
  @{ Local = (Join-Path $ViewsLocal "create.blade.php"); Remote = "$RemoteBase/resources/views/admin/masters/deals/create.blade.php" },
  @{ Local = (Join-Path $ViewsLocal "edit.blade.php"); Remote = "$RemoteBase/resources/views/admin/masters/deals/edit.blade.php" }
)

foreach ($f in $files) {
  Upload-Ftp $f.Local $f.Remote
}

Write-Host ""
Write-Host "Done. Hit once: https://app.mintzer.in/deal_fees_migrate_once.php?key=mintzer-deal-fees"
Write-Host "Then delete public/deal_fees_migrate_once.php"
