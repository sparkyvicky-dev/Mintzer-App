# Add noindex to app.mintzer.in only. Does not touch marketing files.
# Credentials: mintzer.in\fpt details.txt (same as marketing upload).

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$CredFile = Join-Path (Split-Path $ScriptDir -Parent) "fpt details.txt"

$HeaderBlock = @"
<IfModule mod_headers.c>
  Header set X-Robots-Tag "noindex, nofollow"
</IfModule>

"@

$RemoteHtaccess = "/domains/mintzer.in/public_html/newapp/public/.htaccess"
$RemoteLogin = "/domains/mintzer.in/public_html/newapp/resources/views/login/login.blade.php"
$Work = Join-Path $env:TEMP "mintzer-noindex-ftp"
if (Test-Path $Work) { Remove-Item $Work -Recurse -Force }
New-Item -ItemType Directory -Path $Work | Out-Null

$lines = Get-Content -Path $CredFile -Encoding UTF8 | ForEach-Object { $_.Trim() } | Where-Object { $_ -and ($_ -notmatch '^\s*#') }
if ($lines.Count -lt 3) { throw "FTP details file needs host, user, password." }
$FtpHost = $lines[0] -replace '^ftp://', '' -replace '^ftps://', '' -replace '/.*$', ''
$FtpUser = $lines[1]
$FtpPass = $lines[2]

function Get-FtpUri([string]$RemotePath) {
    $path = $RemotePath.Replace("\", "/")
    if (-not $path.StartsWith("/")) { $path = "/" + $path }
    return ("ftp://{0}{1}" -f $FtpHost, $path)
}

function Download-FtpFile([string]$RemotePath, [string]$LocalPath) {
    $uri = Get-FtpUri $RemotePath
    $req = [System.Net.FtpWebRequest]::Create($uri)
    $req.Credentials = New-Object System.Net.NetworkCredential($FtpUser, $FtpPass)
    $req.Method = [System.Net.WebRequestMethods+Ftp]::DownloadFile
    $req.UseBinary = $true
    $req.UsePassive = $true
    $req.KeepAlive = $false
    $resp = $req.GetResponse()
    $stream = $resp.GetResponseStream()
    $fs = [System.IO.File]::Create($LocalPath)
    $stream.CopyTo($fs)
    $fs.Close()
    $stream.Close()
    $resp.Close()
}

function Upload-FtpFile([string]$LocalPath, [string]$RemotePath) {
    $bytes = [System.IO.File]::ReadAllBytes($LocalPath)
    $uri = Get-FtpUri $RemotePath
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

Write-Host "Downloading live newapp public/.htaccess ..."
$localHt = Join-Path $Work "htaccess"
Download-FtpFile $RemoteHtaccess $localHt
$ht = [System.IO.File]::ReadAllText($localHt)
if ($ht -match 'X-Robots-Tag') {
    Write-Host "X-Robots-Tag already present. Leaving .htaccess as-is."
} else {
    $newHt = $HeaderBlock + $ht
    [System.IO.File]::WriteAllText($localHt, $newHt)
    Write-Host "Uploading patched newapp public/.htaccess ..."
    Upload-FtpFile $localHt $RemoteHtaccess
    Write-Host "Uploaded .htaccess with noindex header."
}

Write-Host "Downloading login.blade.php ..."
$localLogin = Join-Path $Work "login.blade.php"
Download-FtpFile $RemoteLogin $localLogin
$login = [System.IO.File]::ReadAllText($localLogin)
if ($login -match 'noindex') {
    Write-Host "Login already has noindex. Leaving blade as-is."
} else {
    $oldTitle = '<title>Login</title>'
    $newTitle = "<title>Mintzer admin</title>`r`n    <meta name=`"robots`" content=`"noindex, nofollow`" />"
    $login = $login.Replace($oldTitle, $newTitle)
    if ($login -notmatch 'noindex') {
        throw "Could not find title Login in login.blade.php. Aborting blade edit."
    }
    [System.IO.File]::WriteAllText($localLogin, $login)
    Write-Host "Uploading patched login.blade.php ..."
    Upload-FtpFile $localLogin $RemoteLogin
    Write-Host "Uploaded login noindex meta."
}

Write-Host "Done. Check https://app.mintzer.in/ still loads."
