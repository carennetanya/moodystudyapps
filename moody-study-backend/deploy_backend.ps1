# Deploy backend JAR to remote SSH server using scp.
# Edit $RemotePath jika ingin menyesuaikan folder tujuan di server.

$LocalJar = Join-Path $PSScriptRoot 'target\moody-study-backend-0.0.1-SNAPSHOT.jar.original'
$RemoteUser = 'caren'
$RemoteHost = '202.46.28.170'
$RemotePath = '/home/caren/backend/'

if (-not (Test-Path $LocalJar)) {
    Write-Error "File not found: $LocalJar"
    exit 1
}

Write-Host "Uploading $LocalJar to $RemoteUser@$RemoteHost:$RemotePath"
scp $LocalJar "$RemoteUser@$RemoteHost:$RemotePath"
