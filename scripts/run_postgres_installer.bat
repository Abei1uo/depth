@echo off
REM 以 unattended 模式安装 PostgreSQL 18 到 D:\PostgreSQL\18（路径不含空格）。
REM 结果写入 D:\sdk\_installer\install.log
set "EXE=D:\sdk\_installer\PostgreSQL 18_18.6-4_Machine_X64_exe_zh-CN.exe"
set "LOG=D:\sdk\_installer\install.log"

start "" /wait "%EXE%" --mode unattended --unattendedmodeui none --superpassword im_root_2026 --serverport 5432 --servicename postgresql-x64-18 --prefix D:\PostgreSQL\18 --datadir D:\PostgreSQL\18\data
echo EXITCODE=%ERRORLEVEL%> "%LOG%"
sc query postgresql-x64-18>> "%LOG%" 2>&1
