# Upload app-open and deal-alert popup files, add columns once, then delete the migrator.
$ErrorActionPreference = "Stop"
$Root = "D:\dev\mintzer-app"
$CredFile = Join-Path $Root "mintzer.in\fpt details.txt"
$Explore = Join-Path $Root "_hostinger_explore\newapp"
$Mirror = Join-Path $Root "mintzer.in\Current Mintzer hosinter file manager\mintzer.in\public_html\newapp"
$lines = Get-Content $CredFile -Encoding UTF8 | ForEach-Object { $_.Trim() } | Where-Object { $_ -and ($_ -notmatch '^\s*#') }
$hostRaw = $lines[0] -replace '^ftp://', '' -replace '^ftps://', '' -replace '/.*$', ''
$user = $lines[1]
$pass = $lines[2]
$RemoteBase = "/domains/mintzer.in/public_html/newapp"

function Upload-Ftp([string]$Local, [string]$RemotePath) {
  if (-not (Test-Path $Local)) { throw "Missing $Local" }
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
  Write-Host "UP $($bytes.Length) $RemotePath"
}

function Delete-Ftp([string]$RemotePath) {
  $uri = "ftp://$hostRaw$RemotePath"
  $req = [System.Net.FtpWebRequest]::Create($uri)
  $req.Method = [System.Net.WebRequestMethods+Ftp]::DeleteFile
  $req.Credentials = New-Object System.Net.NetworkCredential($user, $pass)
  $req.UsePassive = $true
  $req.KeepAlive = $false
  $resp = $req.GetResponse()
  $resp.Close()
  Write-Host "DEL $RemotePath"
}

$uploads = @(
  @{ L = Join-Path $Explore "routes\api.php"; R = "$RemoteBase/routes/api.php" },
  @{ L = Join-Path $Explore "app\Http\Controllers\API\BannerController.php"; R = "$RemoteBase/app/Http/Controllers/API/BannerController.php" },
  @{ L = Join-Path $Explore "app\Traits\Common.php"; R = "$RemoteBase/app/Traits/Common.php" },
  @{ L = Join-Path $Explore "app\Models\Deal.php"; R = "$RemoteBase/app/Models/Deal.php" },
  @{ L = Join-Path $Explore "app\Http\Controllers\Admin\Masters\DealsController.php"; R = "$RemoteBase/app/Http/Controllers/Admin/Masters/DealsController.php" },
  @{ L = Join-Path $Mirror "app\Models\Banner.php"; R = "$RemoteBase/app/Models/Banner.php" },
  @{ L = Join-Path $Mirror "app\Http\Controllers\Admin\Settings\BannerController.php"; R = "$RemoteBase/app/Http/Controllers/Admin/Settings/BannerController.php" },
  @{ L = Join-Path $Mirror "resources\views\admin\settings\banners.blade.php"; R = "$RemoteBase/resources/views/admin/settings/banners.blade.php" },
  @{ L = Join-Path $Mirror "resources\views\admin\masters\deals\create.blade.php"; R = "$RemoteBase/resources/views/admin/masters/deals/create.blade.php" },
  @{ L = Join-Path $Mirror "resources\views\admin\masters\deals\edit.blade.php"; R = "$RemoteBase/resources/views/admin/masters/deals/edit.blade.php" },
  @{ L = Join-Path $Mirror "resources\views\admin\masters\deals\copy.blade.php"; R = "$RemoteBase/resources/views/admin/masters/deals/copy.blade.php" },
  @{ L = Join-Path $Mirror "resources\views\admin\masters\deals\_popup_fields.blade.php"; R = "$RemoteBase/resources/views/admin/masters/deals/_popup_fields.blade.php" },
  @{ L = Join-Path $Mirror "public\assets\js\admin\masters\banner.js"; R = "$RemoteBase/public/assets/js/admin/masters/banner.js" }
)
foreach ($u in $uploads) { Upload-Ftp $u.L $u.R }

$chars = [char[]]((48..57) + (97..122))
$key = -join (1..24 | ForEach-Object { $chars | Get-Random })
$php = @"
<?php
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
if ((`$_GET['k'] ?? '') !== '$key') { http_response_code(404); exit; }
require __DIR__.'/../vendor/autoload.php';
`$app = require __DIR__.'/../bootstrap/app.php';
`$kernel = `$app->make(Illuminate\Contracts\Console\Kernel::class);
`$kernel->bootstrap();
`$out = [];
if (!Schema::hasColumn('banners', 'is_popup')) {
  Schema::table('banners', function (Blueprint `$table) {
    `$table->unsignedTinyInteger('is_popup')->default(0);
  });
  `$out[] = 'banners.is_popup';
}
if (!Schema::hasColumn('deals', 'popup_on')) {
  Schema::table('deals', function (Blueprint `$table) {
    `$table->unsignedTinyInteger('popup_on')->default(0);
  });
  `$out[] = 'deals.popup_on';
}
if (!Schema::hasColumn('deals', 'popup_image')) {
  Schema::table('deals', function (Blueprint `$table) {
    `$table->string('popup_image', 255)->nullable();
  });
  `$out[] = 'deals.popup_image';
}
if (!Schema::hasColumn('deals', 'popup_link')) {
  Schema::table('deals', function (Blueprint `$table) {
    `$table->string('popup_link', 500)->nullable();
  });
  `$out[] = 'deals.popup_link';
}
if (!Schema::hasTable('home_popup_seen')) {
  Schema::create('home_popup_seen', function (Blueprint `$table) {
    `$table->bigIncrements('id');
    `$table->unsignedBigInteger('user_id');
    `$table->unsignedBigInteger('banner_id');
    `$table->timestamp('created_at')->nullable();
    `$table->unique(['user_id', 'banner_id']);
  });
  `$out[] = 'home_popup_seen';
}
foreach (glob(base_path('bootstrap/cache/routes*.php')) ?: [] as `$f) {
  @unlink(`$f);
  `$out[] = 'route-cache';
}
echo count(`$out) ? implode(',', `$out) : 'already';
"@
$tmp = Join-Path $env:TEMP ("mintzer-popup-cols-" + [guid]::NewGuid().ToString("n") + ".php")
$remoteMigrator = "$RemoteBase/public/_mintzer_popup_cols.php"
[System.IO.File]::WriteAllText($tmp, $php)
try {
  Upload-Ftp $tmp $remoteMigrator
  $status = 0
  $body = ""
  try {
    $resp = Invoke-WebRequest -Uri "https://app.mintzer.in/_mintzer_popup_cols.php?k=$key" -UseBasicParsing -TimeoutSec 90
    $status = [int]$resp.StatusCode
    $body = [string]$resp.Content
  } catch {
    $r = $_.Exception.Response
    if ($r) { $status = [int]$r.StatusCode }
  }
  if ($body -match 'banners\.is_popup|deals\.popup_on|home_popup_seen|already') {
    Write-Host "MIG $status $body"
  } else {
    Write-Host "MIG $status body-not-ok"
  }
} finally {
  if (Test-Path $tmp) { Remove-Item $tmp -Force }
  try { Delete-Ftp $remoteMigrator } catch { Write-Host "DEL failed" }
}

try {
  $b = Invoke-WebRequest -Uri "https://app.mintzer.in/api/getbanners" -UseBasicParsing -TimeoutSec 30
  $text = [string]$b.Content
  $hasData = $text.Contains('"data"')
  $hasPopup = $text.Contains('"home_popup"')
  Write-Host "BANNERS $($b.StatusCode) data=$hasData home_popup=$hasPopup bytes=$($text.Length)"
} catch {
  Write-Host "BANNERS request failed"
}
Write-Host "Done"
