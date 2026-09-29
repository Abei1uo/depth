# 初始化本地开发数据库：创建 im 角色、im 库，并执行迁移。
# 使用 superuser postgres/123456 建库建角色，迁移以 im 身份执行。
$ErrorActionPreference = 'Stop'

$psql   = 'D:\PostgreSQL\18\bin\psql.exe'
$super  = 'postgresql://postgres:123456@localhost:5432/postgres?sslmode=disable'
$migDir = 'D:\workspace\tss\depth\server\migrations'

Write-Host '=== 1. 确保 im 角色存在且密码正确（幂等）==='
# 先尝试创建（已存在则报错被忽略），再用 ALTER 强制把密码校正为 im，
# 避免历史残留角色没有密码 / 密码不一致导致的认证失败。
& $psql $super -v ON_ERROR_STOP=0 -c "CREATE ROLE im LOGIN PASSWORD 'im'"
& $psql $super -v ON_ERROR_STOP=1 -c "ALTER ROLE im WITH PASSWORD 'im'"

Write-Host '=== 2. 确保 im 数据库存在 ==='
$exists = & $psql $super -t -A -c "SELECT 1 FROM pg_database WHERE datname='im'"
if (-not $exists) {
    & $psql $super -v ON_ERROR_STOP=1 -c "CREATE DATABASE im OWNER im"
    Write-Host 'created database im'
} else {
    Write-Host 'database im already exists'
}

Write-Host '=== 3. 执行迁移（以 im 身份）==='
$imDsn = 'postgresql://im:***@localhost:5432/im?sslmode=disable'
& $psql $imDsn -v ON_ERROR_STOP=1 -f "$migDir\0001_init.sql"

Write-Host '=== 4. 列出 public 下表 ==='
& $psql $imDsn -c "\dt"
Write-Host '=== done ==='
