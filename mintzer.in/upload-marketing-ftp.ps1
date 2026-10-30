# Upload mintzer.in marketing site via FTP - avoids Hostinger 409 Conflict
# NEVER deletes newapp / beta
#
# Credentials file (optional): "fpt details.txt" or "ftp-details.txt" in this folder
# Format (3 lines):
#   ftp://HOST_OR_IP
#   USERNAME
#   PASSWORD
#
# Usage: upload-marketing-ftp.bat

param(
    [string]$FtpHost = "",
    [string]$FtpUser = "",
    [string]$FtpPass = "",
    [string]$RemoteRoot = "",
    [string]$LocalDir = ""
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $LocalDir) {
    $LocalDir = Join-Path $ScriptDir "mintzer\mintzer"
}
if (-not (Test-Path $LocalDir)) {
    $LocalDir = Join-Path $ScriptDir "UPLOAD-TO-PUBLIC-HTML"
}

$ConflictFiles = @(
    "index.html",
    "contact.html",
    "privacy.html",
    "terms.html",
    "privacypolicy.html",
    "termsandconditions.html",
    "aboutus.html",
    "faqs.html",
    "favicon.ico",
    "robots.txt",
    "sitemap.xml",
    "site.webmanifest",
    "mintzer.zip"
)
$ConflictDirs = @("assets")
$Protected = @("newapp", "beta", "cgi-bin", ".htaccess", ".user.ini")

function Normalize-FtpHost([string]$HostValue) {
    $h = ($HostValue).Trim()
    $h = $h -replace '^ftp://', ''
    $h = $h -replace '^ftps://', ''
    $h = $h -replace '/.*$', ''
    return $h
}

function Load-FtpDetailsFile {
    $candidates = @(
        (Join-Path $ScriptDir "fpt details.txt"),
        (Join-Path $ScriptDir "ftp-details.txt"),
        (Join-Path $ScriptDir "ftp details.txt")
    )
    foreach ($p in $candidates) {
        if (-not (Test-Path $p)) { continue }
        $lines = Get-Content -Path $p -Encoding UTF8 | ForEach-Object { $_.Trim() } | Where-Object { $_ -and ($_ -notmatch '^\s*#') }
        if ($lines.Count -ge 3) {
            if (-not $script:FtpHost) { $script:FtpHost = $lines[0] }
            if (-not $script:FtpUser) { $script:FtpUser = $lines[1] }
            if (-not $script:FtpPass) { $script:FtpPass = $lines[2] }
            Write-Host ("Loaded FTP login from: {0}" -f (Split-Path $p -Leaf))
            return
        }
    }
}

function Require-FtpCreds {
    Load-FtpDetailsFile
    if (-not $script:FtpHost) {
        Write-Host "Use FULL hostname or IP from Hostinger FTP Accounts."
        $script:FtpHost = Read-Host "FTP host"
    }
    $script:FtpHost = Normalize-FtpHost $script:FtpHost
    if (-not $script:FtpUser) { $script:FtpUser = Read-Host "FTP username" }
    if (-not $script:FtpPass) {
        $secure = Read-Host "FTP password" -AsSecureString
        $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
        $script:FtpPass = [Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
    }
    if (-not $script:FtpHost -or -not $script:FtpUser -or -not $script:FtpPass) {
        throw "FTP host, user, and password are required."
    }
    Write-Host ("Using FTP host: {0}" -f $script:FtpHost)
}

function Get-FtpUri([string]$RemotePath) {
    $path = $RemotePath.Replace("\", "/")
    if (-not $path.StartsWith("/")) { $path = "/" + $path }
    if ($path -eq "/") { return ("ftp://{0}/" -f $script:FtpHost) }
    return ("ftp://{0}{1}" -f $script:FtpHost, $path)
}

function Invoke-Ftp([string]$RemotePath, [string]$Method, [scriptblock]$WriteBody = $null, [switch]$ThrowOnError) {
    $uri = Get-FtpUri $RemotePath
    $req = [System.Net.FtpWebRequest]::Create($uri)
    $req.Credentials = New-Object System.Net.NetworkCredential($script:FtpUser, $script:FtpPass)
    $req.Method = $Method
    $req.UseBinary = $true
    $req.UsePassive = $true
    $req.KeepAlive = $false
    if ($WriteBody) { & $WriteBody $req }
    try {
        $resp = $req.GetResponse()
        $resp.Close()
        return $true
    } catch {
        if ($ThrowOnError) { throw }
        return $false
    }
}

function Test-FtpConnection {
    Write-Host "Testing FTP login / detecting public_html path..."
    $uri = Get-FtpUri "/"
    $req = [System.Net.FtpWebRequest]::Create($uri)
    $req.Credentials = New-Object System.Net.NetworkCredential($script:FtpUser, $script:FtpPass)
    $req.Method = [System.Net.WebRequestMethods+Ftp]::ListDirectory
    $req.UsePassive = $true
    $req.KeepAlive = $false
    try {
        $resp = $req.GetResponse()
        $reader = New-Object System.IO.StreamReader($resp.GetResponseStream())
        $names = @()
        while ($null -ne ($line = $reader.ReadLine())) { $names += $line.Trim() }
        $reader.Close()
        $resp.Close()
        Write-Host ("FTP OK. Home sample: {0}" -f (($names | Select-Object -First 8) -join ", "))
    } catch {
        throw ("FTP login/list failed: {0}" -f $_.Exception.Message)
    }

    if (-not $script:RemoteRoot) {
        $candidates = @(
            "/domains/mintzer.in/public_html",
            "/public_html",
            "/"
        )
        foreach ($c in $candidates) {
            if (Test-FtpPathExists $c) {
                $script:RemoteRoot = $c
                Write-Host ("Detected remote root: {0}" -f $c)
                break
            }
        }
        if (-not $script:RemoteRoot) {
            $script:RemoteRoot = "/domains/mintzer.in/public_html"
            Write-Host ("Using default remote root: {0}" -f $script:RemoteRoot)
        }
    }

    if (-not (Test-FtpPathExists $script:RemoteRoot)) {
        throw ("Remote folder not found: {0}" -f $script:RemoteRoot)
    }

    # Confirm newapp is visible (protected)
    $checkNewapp = ($script:RemoteRoot.TrimEnd("/") + "/newapp")
    if (Test-FtpPathExists $checkNewapp) {
        Write-Host "Found newapp (will not delete it)."
    }
}

function Test-FtpPathExists([string]$RemotePath) {
    try {
        $uri = Get-FtpUri $RemotePath
        $req = [System.Net.FtpWebRequest]::Create($uri)
        $req.Credentials = New-Object System.Net.NetworkCredential($script:FtpUser, $script:FtpPass)
        $req.Method = [System.Net.WebRequestMethods+Ftp]::ListDirectory
        $req.UsePassive = $true
        $req.KeepAlive = $false
        $resp = $req.GetResponse()
        $resp.Close()
        return $true
    } catch {
        return $false
    }
}

function Remove-FtpFile([string]$RemotePath) {
    Write-Host ("  DEL file  {0}" -f $RemotePath)
    [void](Invoke-Ftp $RemotePath ([System.Net.WebRequestMethods+Ftp]::DeleteFile))
}

function Get-FtpNameList([string]$RemoteDir) {
    $uri = Get-FtpUri $RemoteDir
    $req = [System.Net.FtpWebRequest]::Create($uri)
    $req.Credentials = New-Object System.Net.NetworkCredential($script:FtpUser, $script:FtpPass)
    $req.Method = [System.Net.WebRequestMethods+Ftp]::ListDirectoryDetails
    $req.UsePassive = $true
    $req.KeepAlive = $false
    $lines = @()
    $resp = $req.GetResponse()
    $reader = New-Object System.IO.StreamReader($resp.GetResponseStream())
    while ($null -ne ($line = $reader.ReadLine())) { $lines += $line }
    $reader.Close()
    $resp.Close()
    return $lines
}

function Remove-FtpDirRecursive([string]$RemoteDir) {
    Write-Host ("  LIST      {0}" -f $RemoteDir)
    $lines = @()
    try {
        $lines = Get-FtpNameList $RemoteDir
    } catch {
        Write-Host ("  (skip list) {0} - {1}" -f $RemoteDir, $_.Exception.Message)
        return
    }

    foreach ($line in $lines) {
        $parts = ($line -split "\s+", 9)
        if ($parts.Count -lt 9 -and $line -notmatch "\s") { continue }
        $name = if ($parts.Count -ge 9) { $parts[8] } else { ($line -split "\s+")[-1] }
        if (-not $name -or $name -eq "." -or $name -eq "..") { continue }
        # Hostinger LIST may return "public_html/index.html" — keep basename only
        if ($name -match ' -> ') { $name = ($name -split ' -> ')[0] }
        $name = ($name -replace "\\", "/").Split("/")[-1]
        if (-not $name -or $name -eq "." -or $name -eq "..") { continue }
        if ($Protected -contains $name) {
            Write-Host ("  KEEP      {0}/{1}" -f $RemoteDir, $name)
            continue
        }
        $child = if ($RemoteDir -eq "/" ) { "/$name" } else { ("{0}/{1}" -f $RemoteDir.TrimEnd("/"), $name) }
        $isDir = $line.StartsWith("d") -or $line -match "<DIR>"
        if ($isDir) {
            Remove-FtpDirRecursive $child
            Write-Host ("  DEL dir   {0}" -f $child)
            [void](Invoke-Ftp $child ([System.Net.WebRequestMethods+Ftp]::RemoveDirectory))
        } else {
            Remove-FtpFile $child
        }
    }
}

function Ensure-FtpDir([string]$RemoteDir) {
    if (-not $RemoteDir -or $RemoteDir -eq "/" -or $RemoteDir -eq ".") { return }
    $parts = $RemoteDir.Trim("/").Split("/") | Where-Object { $_ }
    $cur = ""
    foreach ($p in $parts) {
        $cur = "$cur/$p"
        [void](Invoke-Ftp $cur ([System.Net.WebRequestMethods+Ftp]::MakeDirectory))
    }
}

function Upload-FtpFile([string]$LocalPath, [string]$RemotePath) {
    Write-Host ("  PUT       {0}" -f $RemotePath)
    $bytes = [System.IO.File]::ReadAllBytes($LocalPath)
    $ok = Invoke-Ftp $RemotePath ([System.Net.WebRequestMethods+Ftp]::UploadFile) {
        param($req)
        $req.ContentLength = $bytes.Length
        $stream = $req.GetRequestStream()
        $stream.Write($bytes, 0, $bytes.Length)
        $stream.Close()
    }
    if (-not $ok) {
        Invoke-Ftp $RemotePath ([System.Net.WebRequestMethods+Ftp]::UploadFile) {
            param($req)
            $req.ContentLength = $bytes.Length
            $stream = $req.GetRequestStream()
            $stream.Write($bytes, 0, $bytes.Length)
            $stream.Close()
        } -ThrowOnError
    }
}

function Upload-Tree([string]$LocalRoot, [string]$RemoteRootPath) {
    if ($RemoteRootPath -ne "/") { Ensure-FtpDir $RemoteRootPath }
    $skipNames = @(".DS_Store", "Thumbs.db", "desktop.ini")
    Get-ChildItem -Path $LocalRoot -Recurse -File | Where-Object {
        $skipNames -notcontains $_.Name
    } | ForEach-Object {
        $rel = $_.FullName.Substring($LocalRoot.Length).TrimStart("\", "/")
        $relUnix = $rel.Replace("\", "/")
        if ($RemoteRootPath -eq "/") {
            $remote = "/$relUnix"
        } else {
            $remote = ("{0}/{1}" -f $RemoteRootPath.TrimEnd("/"), $relUnix)
        }
        $remoteDir = Split-Path $remote -Parent
        if ($remoteDir -and $remoteDir -ne "\" -and $remoteDir -ne "/") {
            Ensure-FtpDir ($remoteDir.Replace("\", "/"))
        }
        Upload-FtpFile $_.FullName $remote
    }
}

Write-Host ""
Write-Host "Mintzer marketing FTP upload (409 safe)"
Write-Host ("Local:  {0}" -f $LocalDir)
Write-Host ""

if (-not (Test-Path $LocalDir)) {
    throw ("Local folder not found: {0}" -f $LocalDir)
}

Require-FtpCreds
Test-FtpConnection

Write-Host ""
Write-Host "[1/2] Uploading marketing files (overwrite only - does NOT delete newapp/beta)..."
Write-Host "Protected folders are never touched: newapp, beta, cgi-bin"
Upload-Tree $LocalDir $script:RemoteRoot

Write-Host ""
Write-Host "[2/2] Done. Test in Brave:"
Write-Host "  https://mintzer.in/"
Write-Host "  https://mintzer.in/contact.html"
Write-Host "  https://app.mintzer.in/login"
Write-Host ""
