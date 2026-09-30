# 鏈湴浠ュ崟浜岃繘鍒舵柟寮忓惎鍔?Silo锛圡inIO 绀惧尯鍒嗘敮锛孲3 鍏煎瀵硅薄瀛樺偍锛夛紝涓嶄娇鐢?Docker銆?
# 骞冲彴锛歐indows锛坅md64 / arm64 鑷姩閫夋嫨锛夈€俶acOS 璇风敤 scripts/start_silo.sh銆?
#
# Silo 涓?MinIO 鍗忚/鏁版嵁瀹屽叏鍏煎锛屽悗绔?minio-go 浠ｇ爜鏃犻渶鏀瑰姩锛屼粎鏀圭幆澧冨彉閲忋€?
# 涓嬭浇鍦板潃锛歨ttps://github.com/pgsty/silo/releases
#
# 鐢ㄦ硶锛?
#   pwsh -File scripts/start_silo.ps1
#   pwsh -File scripts/start_silo.ps1 -Tag RELEASE.2026-09-16T00-00-00Z -InstallDir D:\silo -DataDir D:\silodata
#
# 棣栨杩愯浼氫笅杞藉苟瑙ｅ帇 silo.exe锛涗箣鍚庡鐢ㄧ紦瀛樼洿鎺ュ惎鍔ㄣ€?
# 鍚姩鍚庯細S3 API localhost:9000锛屾帶鍒跺彴 http://localhost:9001锛坢inioadmin/minioadmin锛夈€?
# 鍚庣榛樿 S3_ENDPOINT=localhost:9000 / S3_ACCESS_KEY=minioadmin / S3_SECRET_KEY=minioadmin / S3_BUCKET=im-media銆?
[CmdletBinding()]
param(
    [string]$Tag       = 'RELEASE.2026-09-16T00-00-00Z',
    [string]$InstallDir = 'D:\silo',
    [string]$DataDir    = 'D:\silodata',
    [string]$RootUser   = 'minioadmin',
    [string]$RootPass   = 'minioadmin',
    [string]$Address    = ':9000',
    [string]$ConsoleAddress = ':9001'
)

$ErrorActionPreference = 'Stop'

# 渚濇嵁 CPU 鏋舵瀯閫夋嫨璧勪骇鍚?
$arch = if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64') { 'arm64' } else { 'amd64' }
$ver  = $Tag.Replace('RELEASE.', '').Replace('T00-00-00Z', '').Replace('-', '')
$asset = "silo_${ver}.0.0_windows_${arch}.tar.gz"
$url   = "https://github.com/pgsty/silo/releases/download/$Tag/$asset"

$siloExe = Join-Path $InstallDir 'silo.exe'
if (-not (Test-Path $siloExe)) {
    New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
    $tgz = Join-Path $InstallDir $asset
    Write-Host "=== 涓嬭浇 Silo锛坵indows/$arch锛夛細$url ==="
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest $url -OutFile $tgz
    Write-Host "=== 瑙ｅ帇鍒?$InstallDir ==="
    tar -xzf $tgz -C $InstallDir
    Remove-Item $tgz -ErrorAction SilentlyContinue
}
if (-not (Test-Path $siloExe)) { throw "瑙ｅ帇鍚庢湭鎵惧埌 silo.exe锛?siloExe" }

if (-not (Test-Path $DataDir)) { New-Item -ItemType Directory -Force -Path $DataDir | Out-Null }

$env:MINIO_ROOT_USER = $RootUser
$env:MINIO_ROOT_PASSWORD = $RootPass

Write-Host "=== 鍚姩 Silo锛欰PI $Address / 鎺у埗鍙?$ConsoleAddress / 鏁版嵁 $DataDir ==="
Write-Host "锛堟《 im-media 浼氬湪鏈嶅姟绔娆′笂浼犳椂鑷姩鍒涘缓锛屾棤闇€鎵嬪姩寤猴級"
& $siloExe server $DataDir --address $Address --console-address $ConsoleAddress
