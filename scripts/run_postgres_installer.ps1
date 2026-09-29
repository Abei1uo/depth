# 以提权方式运行 PostgreSQL 18 安装器（unattended）。
# 注意：EDB 安装器的 --prefix/--datadir 不允许路径含空格，
#       因此安装到 D:\PostgreSQL\18（而非 D:\Program Files）。
$ErrorActionPreference = 'Stop'

$exe  = 'D:\sdk\_installer\PostgreSQL 18_18.6-4_Machine_X64_exe_zh-CN.exe'
$log  = 'D:\sdk\_installer\install.log'
if (-not (Test-Path $exe)) { throw "installer not found: $exe" }

$installerArgs = '--mode unattended --unattendedmodeui none ' +
        '--superpassword im_root_2026 --serverport 5432 ' +
        '--servicename postgresql-x64-18 ' +
        '--prefix "D:/PostgreSQL/18" ' +
        '--datadir "D:/PostgreSQL/18/data"'

$inner = '"' + $exe + '" ' + $installerArgs + ' > "' + $log + '" 2>&1'
Start-Process -FilePath 'cmd.exe' -ArgumentList '/c', $inner -Verb RunAs -Wait

Write-Host '=== service status ==='
Get-Service -Name 'postgresql*' | Select-Object Name, Status | Format-Table -AutoSize
Write-Host ('psql.exe exists: ' + (Test-Path 'D:\PostgreSQL\18\bin\psql.exe'))
