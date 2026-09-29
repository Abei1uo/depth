# Depth IM 本地环境安装与运行教程

本教程面向 **Windows** 开发机，覆盖 Monorepo（`d:\workspace\tss\depth`）跑起来所需的全部工具链：
Go 后端、PostgreSQL、Redis、Flutter/Dart、Android SDK、buf（Protobuf 代码生成）。
本项目**不使用 Docker**，全部以源码 / 原生二进制方式运行。

> 约定：所有 SDK 统一安装到 `D:\sdk`，PostgreSQL 安装到 `D:\PostgreSQL`，
> 项目路径为 `d:\workspace\tss\depth`。若你的路径不同，请相应替换。

---

## 0. 组件与已验证版本

| 组件 | 版本 | 安装位置 | 用途 |
| --- | --- | --- | --- |
| Go | 1.26（经 `GOTOOLCHAIN=auto` 拉取；PATH 上可为 1.25.x） | 系统 | 后端服务 |
| PostgreSQL | 18.6 | `D:\PostgreSQL\18` | 主数据库 |
| Redis | 5+（Windows 可用 Memurai / WSL redis） | 系统/WSL | 序号、幂等、在线状态 |
| Flutter | 3.47.2 | `D:\sdk\flutter` | 客户端框架 |
| Dart | 3.13.2（随 Flutter） | `D:\sdk\flutter\bin` | 客户端语言 |
| Android SDK | 建议 API 34+ | `D:\sdk\android` | 安卓构建/模拟器 |
| buf | 最新（`buf` CLI） | 加入 PATH | Protobuf lint/生成 |

先决条件自检：

```powershell
go version
flutter --version
dart --version
psql --version
```

---

## 1. 目录结构

```
depth/
├─ app/       Flutter 客户端（lib/ 已含脚手架）
├─ server/    Go 后端（cmd/server + internal + pkg + migrations）
├─ proto/     共享 Protobuf 协议（buf 工作区）
├─ scripts/   本地脚本（init_db.ps1 等）
├─ docs/      本教程
└─ deploy/    部署相关（暂缓）
```

---

## 2. Go 后端

1. 安装 Go（winget）：
   ```powershell
   winget install --id GoLang.Go -e
   ```
2. 项目 `go.mod` 指定 Go 1.26。若本机 `go` 低于该版本，`GOTOOLCHAIN=auto`（默认）会
   自动下载匹配的工具链，无需手动升级：
   ```powershell
   go env -w GOTOOLCHAIN=auto
   ```
3. 拉取依赖：
   ```powershell
   cd d:\workspace\tss\depth\server
   go mod download
   go build ./...
   ```

### 后端配置（全部走环境变量，均有本地默认值）

| 变量 | 默认值 | 说明 |
| --- | --- | --- |
| `APP_ENV` | `development` | `production` 时强制要求 JWT RSA 密钥 |
| `HTTP_ADDR` | `:8080` | 监听地址 |
| `WS_PATH` | `/ws` | WebSocket 端点 |
| `POSTGRES_DSN` | `postgres://im:im@localhost:5432/im?sslmode=disable` | 见 §3 |
| `REDIS_ADDR` | `localhost:6379` | 见 §4 |
| `REDIS_PASSWORD` | 空 | |
| `REDIS_DB` | `0` | |
| `JWT_DEV_SECRET` | `dev-only-insecure-secret` | 仅开发回退 HS256 |
| `JWT_PRIVATE_KEY_PATH` / `JWT_PUBLIC_KEY_PATH` | 空 | 生产 RS256 |
| `ACCESS_TOKEN_TTL` / `REFRESH_TOKEN_TTL` | `2h` / `720h` | |

> 本地开发通常**一个环境变量都不用设**，默认值即可连本机 PG + Redis。

---

## 3. PostgreSQL 18

后端启动时会 `pool.Ping()`，连不上直接退出，所以数据库必须先就绪。

### 3.1 安装

推荐用官方安装器（EDB）。⚠️ **关键坑**：EDB 安装器的 `--prefix/--datadir`
**不接受含空格的路径**（如 `D:\Program Files\...` 会被拒并导致 exit code 1）。
务必装到无空格路径，例如 `D:\PostgreSQL\18`：

```powershell
# 用 winget 下载安装器
winget download PostgreSQL.PostgreSQL.18 -d D:\sdk\_installer -e
# 静默安装（路径无空格！superuser 密码自定，本教程用 123456）
#   安装器 exe 支持 --mode unattended --prefix <dir> --password <pw> --datadir <dir>
```

安装完成后 Windows 上会有服务 `postgresql-x64-18`（开机自启），`psql` 位于
`D:\PostgreSQL\18\bin\psql.exe`。

### 3.2 初始化 im 角色与数据库

项目已备好建表迁移 `server/migrations/0001_init.sql`（幂等，PG 13+ 内置 `gen_random_uuid()`）。
用脚本一键建角色 + 建库 + 执行迁移：

```powershell
pwsh -File d:\workspace\tss\depth\scripts\init_db.ps1
```

脚本用超级用户 `postgres/123456` 建 `im` 角色与 `im` 库，再以 `im` 身份执行迁移。

> ⚠️ **常见坑（角色密码认证失败）**：`init_db.ps1` 里 `CREATE ROLE im ... PASSWORD 'im'`
> 加了 `ON_ERROR_STOP=0`，若 `im` 角色**上次已存在但没设密码**，这条会因
> `role already exists` 被吞掉，导致密码从未写入、`im/im` 连接报
> “Password 认证失败”。修复只需一句（超级用户执行）：
> ```powershell
> & 'D:\PostgreSQL\18\bin\psql.exe' 'postgresql://postgres:123456@localhost:5432/postgres?sslmode=disable' -c "ALTER ROLE im WITH PASSWORD 'im'"
> ```
> 之后重跑迁移即可。

### 3.3 手动执行迁移（可选）

```powershell
& 'D:\PostgreSQL\18\bin\psql.exe' 'postgresql://im:im@localhost:5432/im?sslmode=disable' `
  -v ON_ERROR_STOP=1 -f 'D:\workspace\tss\depth\server\migrations\0001_init.sql'
```

### 3.4 想直接用超级用户跑后端？

可跳过 `im` 角色，临时用超级用户连接（记得库要存在）：

```powershell
$env:POSTGRES_DSN = 'postgres://postgres:123456@localhost:5432/im?sslmode=disable'
```

---

## 4. Redis

后端启动也会 `rdb.Ping()`，Redis 必须在跑（序号 `INCR`、幂等 `SETNX`、在线状态都依赖它）。

- **Windows 原生**：官方无 Windows 版，可用 [Memurai](https://www.memurai.com/)（Redis 兼容，装成服务）
  或 `winget install Memurai.MemuraiDeveloper`。
- **WSL**（推荐）：
  ```powershell
  wsl -u root apt-get install -y redis-server
  wsl redis-server --daemonize yes
  ```
  Windows 侧访问 `localhost:6379` 通常直连即可（WSL2 端口转发）。
- **快速验证**：
  ```powershell
  redis-cli -h localhost -p 6379 ping   # 期望 PONG
  ```

---

## 5. Flutter / Dart

已安装到 `D:\sdk\flutter`（内含 Dart）。若需重装/换机：

1. 从稳定渠道获取 SDK 到 `D:\sdk\flutter`（Gitee 镜像可加速克隆）。
2. 加入 PATH：
   ```powershell
   # 用户级 PATH
   [Environment]::SetEnvironmentVariable('Path', ($env:Path + ';D:\sdk\flutter\bin'), 'User')
   ```
3. 国内镜像（用于 Flutter 引擎产物下载）：
   ```powershell
   flutter config --enable-web   # 可选
   ```
   设置环境变量 `FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn`
   与 `PUB_HOSTED_URL=https://pub.flutter-io.cn`。

   > ⚠️ **坑**：`pub.flutter-io.cn` 镜像对**新增依赖的下载**偶尔会长时间卡在
   > “Downloading packages”。遇到时可临时（仅当前进程）改用官方源：
   > ```powershell
   > $env:PUB_HOSTED_URL = 'https://pub.dev'
   > flutter pub get
   > ```

4. 自检：
   ```powershell
   flutter doctor
   ```

---

## 6. Android SDK

用于安卓真机/模拟器构建。本机采用 **headless 命令行**方式（不装 Android Studio，避免 GUI 弹窗），
统一装到 `D:\sdk\android`，已验证可成功编译出 debug APK。

### 6.1 JDK 17（AGP 9.x 要求）

```powershell
winget install --id Microsoft.OpenJDK.17 -e --accept-source-agreements --accept-package-agreements --silent
# 记录 JAVA_HOME（形如 C:\Program Files\Microsoft\jdk-17.x.x.x-hotspot）
[Environment]::SetEnvironmentVariable('JAVA_HOME','C:\Program Files\Microsoft\jdk-17.0.20.101-hotspot','User')
```

### 6.2 Command-line tools

下载官方 `commandlinetools-win-<build>_latest.zip`（约 140MB），解压到
`D:\sdk\android\cmdline-tools\latest`（注意必须是 `cmdline-tools\latest\bin` 这层结构）：

```powershell
# 可先用 HEAD 探测一个存在的 build 号
$zip='commandlinetools-win-13114758_latest.zip'   # 143MB，dl.google.com 可达
Invoke-WebRequest "https://dl.google.com/android/repository/$zip" -OutFile "D:\sdk\_installer\$zip"
# 解压（若沙箱限制在 D:\sdk 新建目录，先解压到工作区再 Move 过去）
Expand-Archive "D:\sdk\_installer\$zip" -DestinationPath <tmp>
Move-Item <tmp>\cmdline-tools D:\sdk\android\cmdline-tools\latest
```

### 6.3 安装平台 / 工具 / 许可

```powershell
$env:JAVA_HOME='C:\Program Files\Microsoft\jdk-17.0.20.101-hotspot'
$sk='D:\sdk\android\cmdline-tools\latest\bin\sdkmanager.bat'
# 接受所有许可（管道喂 y）
(1..50 | %{ 'y' }) | & $sk --licenses
# Flutter 3.47 需要 Android SDK 36；NDK 会在构建时按需自动拉取
(1..50 | %{ 'y' }) | & $sk "platform-tools" "platforms;android-36" "build-tools;36.0.0" "platforms;android-34"
```

### 6.4 接入 Flutter 并自检

```powershell
[Environment]::SetEnvironmentVariable('ANDROID_HOME','D:\sdk\android','User')
flutter config --android-sdk D:\sdk\android
flutter doctor    # 期望 [√] Android toolchain (SDK 36.0.0)
```

> ⚠️ **国内网络关键坑（务必看）**：`flutter build apk` 会走 Gradle 下载 AGP / Kotlin / AndroidX
> 依赖。本机环境下 **`maven.google.com` 直接超时、`github.com` 连不上、`repo.maven.apache.org`
> 大文件（如 `kotlin-compiler-embeddable-2.4.0.jar` 约 60MB）下载易超时**，构建会卡住空转。
>
> 解决办法（本项目已配置）：
> 1. **镜像优先**：在 `app/android/build.gradle.kts` 的 `allprojects.repositories` 与
>    `app/android/settings.gradle.kts` 的 `pluginManagement.repositories` 里，把阿里云镜像
>    插到 `google()/mavenCentral()` **之前**：
>    ```kotlin
>    maven { url = uri("https://maven.aliyun.com/repository/google") }
>    maven { url = uri("https://maven.aliyun.com/repository/public") }
>    maven { url = uri("https://maven.aliyun.com/repository/central") }
>    ```
> 2. **加大超时/重试**：在 `~/.gradle/gradle.properties` 追加：
>    ```properties
>    systemProp.org.gradle.internal.http.connectionTimeout=180000
>    systemProp.org.gradle.internal.http.socketTimeout=180000
>    systemProp.org.gradle.internal.repository.max.tentatives=6
>    ```
> 3. **清掉错误缓存重试**：若某构件此前已从 central/github 解析（Gradle 会把 jar 绑定到原仓库），
>    删掉 `~/.gradle/caches/modules-2/files-2.1/<该构件>` 再构建，即可按“阿里云优先”重新解析。
>
> 配好后 `flutter build apk --debug` 约 1 分钟内即可产出
> `build/app/outputs/flutter-apk/app-debug.apk`。

---

## 7. buf（Protobuf 代码生成）

`proto/` 已定义共享协议（`depth/v1/{common,user,message,chat,event,call}.proto`）
与 buf 配置（`buf.yaml`、`buf.gen.go.yaml`、`buf.gen.dart.yaml`）。
MVP 后端仍走 JSON 信封，proto 是**权威契约**，代码生成按需执行。

1. 安装 buf：
   ```powershell
   winget install bufbuild.buf -e
   ```
2. Lint / 破坏式检查：
   ```powershell
   cd d:\workspace\tss\depth\proto
   buf lint
   buf breaking --against '.git#ref=HEAD'
   ```
3. 生成 Go 代码（输出到 `server/gen/pb`），随后补依赖：
   ```powershell
   cd d:\workspace\tss\depth\proto
   buf generate --template buf.gen.go.yaml
   cd ..\server; go mod tidy   # 拉齐 google.golang.org/protobuf 与 grpc
   ```
4. 生成 Dart 代码（输出到 `app/lib/gen/pb`）——需先装插件并将其 bin 加入 PATH：
   ```powershell
   dart pub global activate protoc_plugin
   $env:PATH += ";$env:LOCALAPPDATA\Pub\Cache\bin"   # protoc-gen-dart 所在目录
   cd d:\workspace\tss\depth\proto
   buf generate --template buf.gen.dart.yaml
   cd ..\app; flutter pub add protobuf fixnum          # 生成代码的运行时依赖
   ```
   生成的 `lib/gen/pb/**` 已在 `analysis_options.yaml` 排除出 lint。

> 详见 [proto.md](./proto.md)：proto=权威契约，当前传输仍为 JSON，未把二进制 protobuf 接入运行链路。
> 注：`buf.gen.dart.yaml` 用 v2 的 `local: protoc-gen-dart`（旧写法 `name:` 在 v2 无效）。

---

## 8. 运行后端

前置：PostgreSQL（含 `im` 库与迁移表）+ Redis 都在跑。

```powershell
cd d:\workspace\tss\depth\server
go run ./cmd/server
```

看到 `server listening addr=:8080` 即成功。验证：

```powershell
curl http://localhost:8080/healthz          # {"status":"ok","online":0}
# 注册
curl -X POST http://localhost:8080/api/v1/auth/register `
  -H 'Content-Type: application/json' `
  -d '{"username":"alice","nickname":"Alice","password":"secret123"}'
```

主要接口：

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| POST | `/api/v1/auth/register` | 注册并返回令牌 |
| POST | `/api/v1/auth/login` | 登录 |
| POST | `/api/v1/auth/refresh` | 刷新令牌 |
| GET | `/api/v1/users/me` | 当前用户（需 Bearer） |
| GET | `/api/v1/users/search?q=` | 搜索用户 |
| POST | `/api/v1/conversations/direct` | 建/复用单聊 |
| POST | `/api/v1/conversations/group` | 建群聊 |
| GET | `/api/v1/conversations` | 会话列表 |
| GET | `/api/v1/conversations/:id/messages` | 历史消息 |
| GET | `/ws?token=<access_token>` | WebSocket |

---

## 9. 运行 Flutter App

```powershell
cd d:\workspace\tss\depth\app
flutter pub get
flutter run           # 选择已启动的模拟器/真机
```

后端地址通过 `--dart-define` 覆盖（默认 `http://10.0.2.2:8080`，即 Android 模拟器访问宿主机）。key 为 `API_BASE` / `WS_BASE`：

```powershell
# 真机或同机 Web：指向本机局域网 IP
flutter run --dart-define=API_BASE=http://192.168.x.x:8080/api/v1 `
            --dart-define=WS_BASE=ws://192.168.x.x:8080/ws
```

---

## 10. 快速排错清单

- 后端启动即退出 → PG 或 Redis 没跑 / DSN 不对（先保证 §3、§4）。
- `im/im` 认证失败 → 见 §3.2 的 `ALTER ROLE im WITH PASSWORD 'im'`。
- EDB 安装器 exit 1 → 安装路径含空格，换 `D:\PostgreSQL\18`。
- `flutter pub get/add` 卡住 → 临时切官方 `PUB_HOSTED_URL=https://pub.dev`。
- 模拟器连不上后端 → 用 `10.0.2.2` 而非 `localhost`；确认后端监听 `:8080` 且防火墙放行。
- 真机连不上 → `--dart-define` 指向宿主机局域网 IP，手机与电脑同网段。
