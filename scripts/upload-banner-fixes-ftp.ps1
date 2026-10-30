# Community banner gets the saved WhatsApp group link.
# Browse cards becomes a normal admin banner with an image.
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
  $req = [System.Net.FtpWebRequest]::Create("ftp://$hostRaw$RemotePath")
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
  $req = [System.Net.FtpWebRequest]::Create("ftp://$hostRaw$RemotePath")
  $req.Method = [System.Net.WebRequestMethods+Ftp]::DeleteFile
  $req.Credentials = New-Object System.Net.NetworkCredential($user, $pass)
  $req.UsePassive = $true
  $req.KeepAlive = $false
  $resp = $req.GetResponse()
  $resp.Close()
  Write-Host "DEL $RemotePath"
}

$uploads = @(
  @{ L = Join-Path $Explore "app\Http\Controllers\API\BannerController.php"; R = "$RemoteBase/app/Http/Controllers/API/BannerController.php" },
  @{ L = Join-Path $Mirror "app\Models\Banner.php"; R = "$RemoteBase/app/Models/Banner.php" },
  @{ L = Join-Path $Mirror "app\Http\Controllers\Admin\Settings\BannerController.php"; R = "$RemoteBase/app/Http/Controllers/Admin/Settings/BannerController.php" },
  @{ L = Join-Path $Mirror "resources\views\admin\settings\banners.blade.php"; R = "$RemoteBase/resources/views/admin/settings/banners.blade.php" },
  @{ L = Join-Path $Mirror "public\assets\js\admin\masters\banner.js"; R = "$RemoteBase/public/assets/js/admin/masters/banner.js" },
  @{ L = Join-Path $Root "assets\banners\browse-cards.png"; R = "$RemoteBase/public/upload/bank/browse-cards.png" }
)
foreach ($u in $uploads) { Upload-Ftp $u.L $u.R }

$chars = [char[]]((48..57) + (97..122))
$key = -join (1..24 | ForEach-Object { $chars | Get-Random })
$php = @"
<?php
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
if ((`$_GET['k'] ?? '') !== '$key') { http_response_code(404); exit; }
require __DIR__.'/../vendor/autoload.php';
`$app = require __DIR__.'/../bootstrap/app.php';
`$kernel = `$app->make(Illuminate\Contracts\Console\Kernel::class);
`$kernel->bootstrap();
`$out = [];
if (!Schema::hasColumn('banners', 'opens_cards')) {
  Schema::table('banners', function (Blueprint `$table) {
    `$table->unsignedTinyInteger('opens_cards')->default(0);
  });
  `$out[] = 'opens_cards';
}
`$link = trim((string) \App\Models\BusinessSettings::where('key', 'whatsapp_group_link')->value('value'));
if (`$link !== '' && stripos(`$link, 'http') === 0) {
  `$n = DB::table('banners')->where('id', 9)->where('name', 'Community')->update(['url' => `$link]);
  `$out[] = `$n ? 'community-link' : 'community-skip';
} else {
  `$out[] = 'community-nolink';
}
`$has = DB::table('banners')->where('opens_cards', 1)->exists();
if (!`$has) {
  DB::table('banners')->insert([
    'name' => 'Browse cards',
    'image' => 'upload/bank/browse-cards.png',
    'url' => null,
    'short_description' => '',
    'status' => 1,
    'is_popup' => 0,
    'opens_cards' => 1,
    'created_at' => now(),
    'updated_at' => now(),
  ]);
  `$out[] = 'browse-row';
} else {
  `$out[] = 'browse-exists';
}
echo implode(',', `$out);
"@
$tmp = Join-Path $env:TEMP ("mintzer-banner-fix-" + [guid]::NewGuid().ToString("n") + ".php")
$remote = "$RemoteBase/public/_mintzer_banner_fix.php"
[System.IO.File]::WriteAllText($tmp, $php)
try {
  Upload-Ftp $tmp $remote
  $body = ""
  $status = 0
  try {
    $resp = Invoke-WebRequest -Uri "https://app.mintzer.in/_mintzer_banner_fix.php?k=$key" -UseBasicParsing -TimeoutSec 90
    $status = [int]$resp.StatusCode
    $body = [string]$resp.Content
  } catch {
    if ($_.Exception.Response) { $status = [int]$_.Exception.Response.StatusCode }
  }
  if ($body -match 'community-link|browse-row|browse-exists|opens_cards') { Write-Host "MIG $status $body" } else { Write-Host "MIG $status body-not-ok" }
} finally {
  if (Test-Path $tmp) { Remove-Item $tmp -Force }
  try { Delete-Ftp $remote } catch { Write-Host "DEL failed" }
}
$j = Invoke-RestMethod -Uri "https://app.mintzer.in/api/getbanners" -TimeoutSec 30
foreach ($row in $j.data) {
  $wa = if ([string]$row.banner_url -match 'whatsapp') { 'wa' } else { 'link-other-or-empty' }
  Write-Host ("id=" + $row.id + " name=[" + $row.banner_name + "] cards=" + $row.opens_cards + " " + $wa)
}
Write-Host "Done"
