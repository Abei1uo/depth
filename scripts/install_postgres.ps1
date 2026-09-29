# 安装 PostgreSQL 18 到 D:\Program Files。
# 采用 winget download 拉取官方安装器后直接以 unattended 参数执行，
# 规避 winget install --override 对多安装器清单的限制。
$ErrorActionPreference = 'Stop'

$dlDir  = 'D:\sdk\_installer'
$prefix = 'D:/Program Files/PostgreSQL/18'
$dataDir = 'D:/Program Files/PostgreSQL/18/data'
$superPwd = 'im_root_2026'

New-Item -ItemType Directory -Force -Path $dlDir | Out-Null

Write-Host '=== downloading PostgreSQL 18 installer via winget ==='
winget download --id PostgreSQL.PostgreSQL.18 --exact --architecture x64 `
    -d $dlDir `
    --accept-package-agreements --accept-source-agreements
if ($LASTEXITCODE -ne 0) { throw "winget download failed: $LASTEXITCODE" }

$installer = Get-ChildItem -Path $dlDir -Recurse -Filter '*.exe' | Select-Object -First 1
if (-not $installer) { throw 'installer exe not found after download' }
Write-Host ("=== running installer: " + $installer.FullName)

$args = @(
    '--mode', 'unattended',
    '--unattendedmodeui', 'none',
    '--superpassword', $superPwd,
    '--serverport', '5432',
    '--servicename', 'postgresql-x64-18',
    '--prefix', $prefix,
    '--datadir', $dataDir
)

Start-Process -FilePath $installer.FullName -ArgumentList $args -Verb RunAs -Wait
Write-Host '=== installer finished ==='
