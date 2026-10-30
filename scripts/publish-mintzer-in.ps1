# Packs the inner marketing site and, if SSH keys work, uploads to
# public_html only. Never uploads into newapp.

$ErrorActionPreference = "Stop"
$src = "D:\dev\mintzer-app\mintzer.in\mintzer\mintzer"
$zip = "D:\dev\mintzer-app\mintzer.in\mintzer-in-upload.zip"
$config = "D:\dev\Mintzer-admin-app\server\deploy-config.bat"

python "D:\dev\mintzer-app\mintzer.in\_pack_upload.py"
if (-not (Test-Path $zip)) { throw "Pack failed — no mintzer-in-upload.zip" }

Write-Host "Packed $zip"
Write-Host "SSH user is in $config (public_html, NOT newapp)."

$sshHost = "mintzer.in"
$sshUser = "u477988188"
$remoteZip = "domains/mintzer.in/mintzer-in-upload.zip"
$publicHtml = "domains/mintzer.in/public_html"

Write-Host "Trying SSH upload (BatchMode)..."
scp -o BatchMode=yes -o ConnectTimeout=15 $zip "${sshUser}@${sshHost}:~/${remoteZip}"
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "SSH is not set up from this PC. Use Hostinger File Manager:"
    Write-Host "  1. Open public_html (NOT newapp)"
    Write-Host "  2. Upload $zip"
    Write-Host "  3. Extract with empty folder name, overwrite ON"
    Write-Host "  4. Follow mintzer.in\UPLOAD-ME.txt"
    Start-Process explorer.exe -ArgumentList "/select,$zip"
    exit 1
}

$remote = @"
set -e
cd ~
mkdir -p domains/mintzer.in/public_html_backup_2026-09-18
# Backup current marketing index only; do not copy newapp
if [ -f $publicHtml/index.html ]; then
  cp -f $publicHtml/index.html domains/mintzer.in/public_html_backup_2026-09-18/index.html
fi
cd $publicHtml
unzip -o ~/domains/mintzer.in/mintzer-in-upload.zip
rm -f ~/domains/mintzer.in/mintzer-in-upload.zip
test -d newapp && echo NEWAPP_OK
test -f index.html && echo INDEX_OK
"@

ssh -o BatchMode=yes -o ConnectTimeout=15 "${sshUser}@${sshHost}" $remote
Write-Host "If INDEX_OK and NEWAPP_OK printed, check https://mintzer.in/ and https://app.mintzer.in/"
