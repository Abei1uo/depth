# 按序执行 server/migrations/*.sql（幂等，可重复运行）。
#
# 用法：
#   pwsh -File scripts/migrate.ps1
#   pwsh -File scripts/migrate.ps1 -Dsn 'postgresql://im:im@localhost:5432/im?sslmode=disable'
#
# 迁移文件自身使用 CREATE ... IF NOT EXISTS，因此对已建库可安全重复执行。
# 本脚本只负责「建表/改表」，不创建角色与数据库（那是 init_db.ps1 的职责）。
[CmdletBinding()]
param(
    # psql 可执行文件路径（默认取本机 PostgreSQL 18）。
    [string]$Psql = 'D:\PostgreSQL\18\bin\psql.exe',
    # 目标库连接串（默认业务库 im/im）。
    [string]$Dsn = 'postgresql://im:im@localhost:5432/im?sslmode=disable',
    # 迁移目录（默认 server/migrations）。
    [string]$MigrationDir = (Join-Path $PSScriptRoot '..\server\migrations')
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $Psql)) {
    throw "找不到 psql：$Psql（可用 -Psql 指定路径）"
}
if (-not (Test-Path $MigrationDir)) {
    throw "找不到迁移目录：$MigrationDir"
}

# 按文件名升序（0001_, 0002_ ...）确保依赖顺序。
$migrations = Get-ChildItem -Path $MigrationDir -Filter '*.sql' -File |
    Sort-Object Name

if ($migrations.Count -eq 0) {
    Write-Warning "目录中没有 .sql 迁移文件：$MigrationDir"
    return
}

Write-Host "=== 执行 $($migrations.Count) 个迁移 -> $Dsn ==="

# 在 Windows PowerShell 5.1 下，原生命令向 stderr 输出（如 psql 的 NOTICE）
# 会在 ErrorActionPreference=Stop 时被当成终止性错误。这里临时降为 Continue
# 并把 stderr 并入管道，改由 $LASTEXITCODE 判定成败（NOTICE 退出码为 0）。
function Invoke-Psql {
    param([string]$Dsn, [string[]]$PsqlArgs)
    $prev = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        & $Psql $Dsn @PsqlArgs 2>&1 | ForEach-Object { Write-Host $_ }
        return $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $prev
    }
}

foreach ($m in $migrations) {
    Write-Host "-> $($m.Name)"
    $code = Invoke-Psql -Dsn $Dsn -PsqlArgs @('-v', 'ON_ERROR_STOP=1', '-q', '-f', $m.FullName)
    if ($code -ne 0) {
        throw "迁移 $($m.Name) 失败（exit $code）"
    }
}

Write-Host '=== 当前表 ==='
$null = Invoke-Psql -Dsn $Dsn -PsqlArgs @('-c', '\dt')
Write-Host '=== migrate done ==='
