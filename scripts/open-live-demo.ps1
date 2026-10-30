# Open Mintzer HTML mockups in Brave (not Edge / Chrome / Cursor browser).
param(
  [string]$Query = "home=1",
  [string]$File = "mintzer-designer-taste-demo.html"
)

$brave = "C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe"
$html = Join-Path "D:\dev\mintzer-app\assets\mockups" $File
if (-not (Test-Path $brave)) { throw "Brave not found at $brave" }
if (-not (Test-Path $html)) { throw "Demo not found at $html" }

$uri = ([Uri]$html).AbsoluteUri
if ($Query -and $File -eq "mintzer-designer-taste-demo.html") { $uri = "$uri`?$Query" }
Start-Process $brave $uri
Write-Host "Opened in Brave: $uri"
