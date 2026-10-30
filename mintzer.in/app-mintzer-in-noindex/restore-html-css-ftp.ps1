# Upload HTML/CSS/JS only — do not touch images or newapp.
$ErrorActionPreference = "Stop"
$Root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
# This file is mintzer.in/app-mintzer-in-noindex/ so parent parent is mintzer.in
$MintzerIn = Split-Path $PSScriptRoot -Parent
$Src = Join-Path $MintzerIn "mintzer\mintzer"
$CredFile = Join-Path $MintzerIn "fpt details.txt"
$RemoteRoot = "/domains/mintzer.in/public_html"

$files = @(
    @{ Local = "index.html"; Remote = "index.html" },
    @{ Local = "contact.html"; Remote = "contact.html" },
    @{ Local = "privacy.html"; Remote = "privacy.html" },
    @{ Local = "terms.html"; Remote = "terms.html" },
    @{ Local = "assets\css\styles.css"; Remote = "assets/css/styles.css" },
    @{ Local = "assets\js\main.js"; Remote = "assets/js/main.js" }
)

$lines = Get-Content -Path $CredFile -Encoding UTF8 | ForEach-Object { $_.Trim() } | Where-Object { $_ -and ($_ -notmatch '^\s*#') }
$FtpHost = $lines[0] -replace '^ftp://', '' -replace '^ftps://', '' -replace '/.*$', ''
$FtpUser = $lines[1]
$FtpPass = $lines[2]

function Upload-FtpFile([string]$LocalPath, [string]$RemotePath) {
    $bytes = [System.IO.File]::ReadAllBytes($LocalPath)
    $uri = "ftp://{0}{1}" -f $FtpHost, $RemotePath
    $req = [System.Net.FtpWebRequest]::Create($uri)
    $req.Credentials = New-Object System.Net.NetworkCredential($FtpUser, $FtpPass)
    $req.Method = [System.Net.WebRequestMethods+Ftp]::UploadFile
    $req.UseBinary = $true
    $req.UsePassive = $true
    $req.KeepAlive = $false
    $req.ContentLength = $bytes.Length
    $stream = $req.GetRequestStream()
    $stream.Write($bytes, 0, $bytes.Length)
    $stream.Close()
    $resp = $req.GetResponse()
    $resp.Close()
}

$dst = Join-Path $MintzerIn "UPLOAD-TO-PUBLIC-HTML"
foreach ($f in $files) {
    $local = Join-Path $Src $f.Local
    $copyTo = Join-Path $dst $f.Local
    Copy-Item $local $copyTo -Force
    $remote = ($RemoteRoot.TrimEnd("/") + "/" + $f.Remote)
    Write-Host ("PUT {0}" -f $f.Remote)
    Upload-FtpFile $local $remote
}
Write-Host "HTML/CSS/JS restored. Images were not re-uploaded."
