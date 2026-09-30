# 本地以单二进制方式启动 MinIO（不使用 Docker）。
#
# 前置：手动下载 minio.exe（https://min.io/download 或 GitHub releases），
# 放到下方 $MinioExe 指定路径（默认 D:\minio\minio.exe）。
#
# 用法：
#   powershell -File scripts/start_minio.ps1
#   pwsh -File scripts/start_minio.ps1 -MinioExe 'D:\minio\minio.exe' -DataDir 'D:\miniodata'
#
# 启动后：API 端点 localhost:9000，控制台 http://localhost:9001（登录 minioadmin/minioadmin）。
# 服务端 .env 默认 S3_ENDPOINT=localhost:9000 / S3_ACCESS_KEY=minioadmin / S3_SECRET_KEY=minioadmin / S3_BUCKET=im-media。
[CmdletBinding()]
param(
    [string]$MinioExe = 'D:\minio\minio.exe',
    [string]$DataDir  = 'D:\miniodata',
    [string]$RootUser = 'minioadmin',
    [string]$RootPass = 'minioadmin',
    [string]$Address  = ':9000',
    [string]$ConsoleAddress = ':9001'
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $MinioExe)) {
    throw "找不到 minio.exe：$MinioExe（请先下载并放到该路径，或用 -MinioExe 指定）"
}
if (-not (Test-Path $DataDir)) {
    New-Item -ItemType Directory -Path $DataDir -Force | Out-Null
}

$env:MINIO_ROOT_USER = $RootUser
$env:MINIO_ROOT_PASSWORD = $RootPass

Write-Host "=== 启动 MinIO：API $Address / 控制台 $ConsoleAddress / 数据 $DataDir ==="
Write-Host "（桶会在服务端首次上传时自动创建，无需手动建）"
& $MinioExe server $DataDir --address $Address --console-address $ConsoleAddress
