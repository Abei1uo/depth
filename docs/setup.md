# Depth IM 本地环境安装与运行教程

本教程覆盖 Monorepo 跑起来所需的全部工具链：Go 后端、PostgreSQL、Redis、
对象存储 Silo（富媒体）、Flutter/Dart、Android SDK、buf（Protobuf 代码生成）。
本项目**不使用 Docker**，全部以源码 / 原生二进制方式运行。

同时面向**两台机器 / 两个平台**：
- 🏢 **Windows**（办公室机，项目路径 `d:\workspace\tss\depth`）—— shell 用 `powershell`/`pwsh`，包管理 `winget`。
- 🏠 **macOS**（家里机，Apple Silicon 或 Intel，项目路径示例 `~/workspace/tss/depth`）—— shell 用 `zsh`/`bash`，包管理 [Homebrew](https://brew.sh)（`brew`）。

各节默认先给 Windows 命令，随后以「**macOS**」段给出等价命令；两者差异（路径、服务管理、IPv6/防火墙、Gatekeeper）单独标注。

> 约定：Windows 侧 SDK 统一装到 `D:\sdk`、PostgreSQL 装到 `D:\PostgreSQL`；macOS 侧统一用 Homebrew
> （Apple Silicon 前缀 `/opt/homebrew`，Intel 前缀 `/usr/local`）。路径不同请自行替换。

### 平台速查（命令 / 包管理对照）

| 事项 | Windows | macOS |
| --- | --- | --- |
| Shell | `powershell` / `pwsh` | `zsh` / `bash` |
| 装工具 | `winget install <id>` | `brew install <formula>` |
| 设环境变量（当前会话） | `$env:NAME='值'` | `export NAME='值'` |
| PATH 追加 | `[Environment]::SetEnvironmentVariable(...,'User')` | `export PATH="...:$PATH"`（写进 `~/.zshrc`） |
| 后台服务 | Windows 服务 / 隐藏进程 | `brew services start <formula>` |
| 下载解包 | `Invoke-WebRequest` + `tar -xzf` | `curl -fL` + `tar -xzf` |
| 对象存储启动脚本 | `scripts/start_silo.ps1` | `scripts/start_silo.sh` |

---

## 0. 组件与已验证版本

| 组件 | 版本 | Windows 位置 | macOS 位置 | 用途 |
| --- | --- | --- | --- | --- |
| Go | 1.26（经 `GOTOOLCHAIN=auto` 拉取；PATH 上可为 1.25.x） | 系统 | `brew install go` | 后端服务 |
| PostgreSQL | 18 | `D:\PostgreSQL\18` | `/opt/homebrew/opt/postgresql@18` | 主数据库 |
| Redis | 5+ | 无官方版：原生移植版 / Memurai / WSL | `brew install redis` | 序号、幂等、在线状态 |
| 对象存储 Silo | `RELEASE.2026-09-16`（MinIO 社区分支） | `D:\silo` | `~/silo` | 富媒体上传/下载 |
| Flutter | 3.47.2 | `D:\sdk\flutter` | `~/sdk/flutter`（或 `brew --cask flutter`） | 客户端框架 |
| Dart | 3.13.2（随 Flutter） | `D:\sdk\flutter\bin` | `~/sdk/flutter/bin` | 客户端语言 |
| Android SDK | API 34 / 36 | `D:\sdk\android` | `~/Library/Android/sdk` | 安卓构建/模拟器 |
| buf | 最新（`buf` CLI） | `winget install bufbuild.buf` | `brew install bufbuild/buf/buf` | Protobuf lint/生成 |

> **Silo** 即 MinIO 的开源社区分支（`pgsty/silo`）：官方 MinIO 已停发 Windows/macOS 二进制，
> 本地对象存储统一改用 Silo，协议与数据完全兼容，后端 `minio-go` 代码无需改动（见 §2）。

先决条件自检（Windows 用 PowerShell、macOS 用 zsh，命令一致）：

```powershell
go version
flutter --version
dart --version
psql --version
silo --version   # 或 ~/silo/silo --version（对象存储，见 §2）
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
| `STORAGE_BACKEND` | `s3` | 对象存储后端；`s3`/`minio` 都走 minio-go（S3 协议，兼容 Silo / MinIO / 任意 S3） |
| `S3_ENDPOINT` | `localhost:9000` | Silo/S3 服务地址（兼容旧名 `MINIO_ENDPOINT`）；本机如遇解析问题用 `127.0.0.1:9000` |
| `S3_ACCESS_KEY` / `S3_SECRET_KEY` | `minioadmin` / `minioadmin` | 凭据（对应 Silo 的 `MINIO_ROOT_USER/PASSWORD`） |
| `S3_BUCKET` | `im-media` | 桶名（服务端首次上传自动建桶） |
| `S3_USE_SSL` | `false` | 生产置 `true` |

> 本地开发通常**一个环境变量都不用设**，默认值即可连本机 PG + Redis。
>
> ⚠️ **Windows 下 Redis 连不上（`dial tcp [::1]:6379 ... refused`）**：`REDIS_ADDR` 默认 `localhost:6379`，
> 而 Windows 版 Redis 常只监听 IPv4 `127.0.0.1`，go-redis 先解析到 `::1` 会被拒。设：
> ```powershell
> $env:REDIS_ADDR = '127.0.0.1:6379'
> ```

### 对象存储 Silo（富媒体消息，非 Docker）

上传/下载媒体需要一个 S3 兼容后端。**官方 MinIO 已停发社区预编译二进制**
（`dl.min.io` 与 winget 清单的 Windows 直链均返回 410，GitHub release 也无 `minio.exe`），
本地改用它的开源社区分支 **Silo**（`pgsty/silo`，协议与数据与 MinIO 完全兼容、`minio-go` 是其保留依赖）。
后端代码**一行都不用改**，只是把起的存储服务的换为 Silo。两平台各有脚本（首次自动下载对应架构二进制）：

**Windows（办公室）**
```powershell
pwsh -File scripts/start_silo.ps1     # 下载 silo.exe 到 D:\silo，起 API :9000 / 控制台 :9001
```

**macOS（家里）**
```bash
bash scripts/start_silo.sh            # 按 uname -m 自动选 arm64/amd64，装到 ~/silo，数据 ~/silo-data
# 可覆盖：TAG=... INSTALL_DIR=... DATA_DIR=... ROOT_PASS=... bash scripts/start_silo.sh
```

> 启动后：S3 API `localhost:9000`、控制台 `http://localhost:9001`（`minioadmin/minioadmin`）。
> 后端默认配置即可连上；无需手动建桶——`im-media` 桶在首次上传时自动创建；客户端只访问 `:8080`（媒体经服务端代理）。

> **验证**（需后端已在 `:8080`，Silo 已起）：
> ```powershell
> # Windows
> cd server; $env:REDIS_ADDR='127.0.0.1:6379'; go test -tags=integration -count=1 ./test/... -run TestMediaUploadAndFetch -v
> ```
> ```bash
> # macOS
> cd server; REDIS_ADDR=127.0.0.1:6379 go test -tags=integration -count=1 ./test/... -run TestMediaUploadAndFetch -v
> ```
> 预期 `--- PASS: TestMediaUploadAndFetch`；上传的对象会落在 Silo 数据目录的 `im-media/` 下。

> **生产切换**：把 `S3_ENDPOINT/S3_ACCESS_KEY/S3_SECRET_KEY/S3_BUCKET/S3_USE_SSL` 指向任意 S3 兼容服务
> （AWS S3 / 阿里 OSS S3 兼容模式 / Ceph / Cloudflare R2）即可，仍是这套配置、无代码改动；接非 S3 协议服务时在 `internal/media` 新增一个 `Store` 实现。


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

**macOS**：用 Homebrew 最省事（Apple Silicon 前缀 `/opt/homebrew`，Intel 为 `/usr/local`）：
```bash
brew install postgresql@18
brew services start postgresql@18          # 注册为开机自启服务
# 若 PATH 未含 brew 的 bin（Apple Silicon）：
export PATH="/opt/homebrew/opt/postgresql@18/bin:$PATH"   # Intel 换成 /usr/local/...
psql --version
```
> macOS 默认超级用户是你的登录名、无密码（本机 `psql postgres` 直接进），与 Windows 的 `postgres/123456` 不同；
> 建 `im` 角色/库见 3.2 的 macOS 段。

### 3.2 初始化 im 角色与数据库

项目已备好建表迁移 `server/migrations/0001_init.sql`（幂等，PG 13+ 内置 `gen_random_uuid()`）。
用脚本一键建角色 + 建库 + 执行迁移：

```powershell
pwsh -File d:\workspace\tss\depth\scripts\init_db.ps1
```

脚本用超级用户 `postgres/123456` 建 `im` 角色与 `im` 库，再以 `im` 身份执行迁移。

**macOS**（无 `init_db.ps1`，直接建角色 + 库 + 首个迁移）：
```bash
psql -d postgres -c "CREATE ROLE im LOGIN PASSWORD 'im'"     # 已存在会报错，可忽略
psql -d postgres -c "CREATE DATABASE im OWNER im"
psql 'postgresql://im:im@localhost:5432/im?sslmode=disable' -v ON_ERROR_STOP=1 \
     -f server/migrations/0001_init.sql
```

> ⚠️ **常见坑（角色密码认证失败）**：`init_db.ps1` 里 `CREATE ROLE im ... PASSWORD 'im'`
> 加了 `ON_ERROR_STOP=0`，若 `im` 角色**上次已存在但没设密码**，这条会因
> `role already exists` 被吞掉，导致密码从未写入、`im/im` 连接报
> “Password 认证失败”。修复只需一句（超级用户执行）：
> ```powershell
> & 'D:\PostgreSQL\18\bin\psql.exe' 'postgresql://postgres:123456@localhost:5432/postgres?sslmode=disable' -c "ALTER ROLE im WITH PASSWORD 'im'"
> ```
> 之后重跑迁移即可。

### 3.3 应用全部迁移（幂等，可重复跑）

`server/migrations/` 下按序号存放迁移（`0001_init.sql`、`0002_add_reads.sql` …），
脚本会按文件名升序依次执行，SQL 自身用 `CREATE ... IF NOT EXISTS`，可安全重复运行：

```powershell
pwsh -File d:\workspace\tss\depth\scripts\migrate.ps1
# 需要连别的库/psql 路径时：
# pwsh -File scripts\migrate.ps1 -Dsn 'postgresql://im:im@localhost:5432/im?sslmode=disable' -Psql 'D:\PostgreSQL\18\bin\psql.exe'
```

> 说明：`init_db.ps1` 负责「建角色 + 建库」并只执行首个 `0001`；此后新增的迁移
> （如 `0002`）请用 `migrate.ps1` 补跑，它覆盖 `migrations/` 下的**全部** `.sql`。

**macOS**：`migrate.ps1` 是 PowerShell 脚本，Mac 上按序手动跑或用一行 shell：
```bash
for f in server/migrations/*.sql; do
  echo "applying $f"
  psql 'postgresql://im:im@localhost:5432/im?sslmode=disable' -v ON_ERROR_STOP=1 -f "$f" || break
done
```

手动执行单条迁移也可：

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

- **Windows**：官方无 Windows 版，任选其一：
  - 原生移植版 `redis-x64-3.2.100`（本机在用，**仅监听 IPv4 `127.0.0.1`**）——后端需设 `$env:REDIS_ADDR='127.0.0.1:6379'` 避开 `::1`；
  - [Memurai](https://www.memurai.com/)：`winget install Memurai.MemuraiDeveloper`（装成服务）；
  - WSL（推荐）：
    ```powershell
    wsl -u root apt-get install -y redis-server
    wsl redis-server --daemonize yes     # WSL2 端口转发后 localhost:6379 可直连
    ```
- **macOS**：
  ```bash
  brew install redis
  brew services start redis              # 开机自启；停止：brew services stop redis
  # 或前台跑一次：redis-server
  ```
- **快速验证**（两平台相同）：`redis-cli -h 127.0.0.1 -p 6379 ping` 期望 `PONG`。

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

**macOS**：
```bash
# 方式一：直接装稳定版 SDK 到 ~/sdk（与 Windows 同思路）
git clone -b stable https://github.com/flutter/flutter.git ~/sdk/flutter
export PATH="$HOME/sdk/flutter/bin:$PATH"          # 写进 ~/.zshrc
# 方式二：brew install --cask flutter
# 国内镜像（同 Windows）：
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
export PUB_HOSTED_URL=https://pub.flutter-io.cn
flutter doctor
```
> Apple Silicon 首次 `flutter doctor` 后需跑 `flutter doctor --android-licenses`；打 iOS 包另装 Xcode（本项目暂不打 iOS）。

---

## 6. Android SDK

用于安卓真机/模拟器构建。本机采用 **headless 命令行**方式（不装 Android Studio，避免 GUI 弹窗），
统一装到 `D:\sdk\android`（Windows）/ `~/Library/Android/sdk`（macOS），已验证可成功编译出 debug APK。

> **macOS 速记**（与下面 Windows 步骤一一对应）：
> ```bash
> brew install --cask temurin@17                       # JDK 17
> export JAVA_HOME="$(/usr/libexec/java_home -v 17)"
> # 下载 commandlinetools-mac-<build>_latest.zip（dl.google.com/android/repository），
> # 解压到 ~/Library/Android/sdk/cmdline-tools/latest（保持 cmdline-tools/latest/bin 结构）
> yes | ~/Library/Android/sdk/cmdline-tools/latest/bin/sdkmanager --licenses
> ~/Library/Android/sdk/cmdline-tools/latest/bin/sdkmanager "platform-tools" "platforms;android-36" "build-tools;36.0.0"
> export ANDROID_HOME="$HOME/Library/Android/sdk"      # 写进 ~/.zshrc
> flutter config --android-sdk "$ANDROID_HOME"
> ```
> §6.4 的国内 Gradle 镜像/超时坑与平台无关，macOS 同样适用（`~/.gradle/gradle.properties`）。

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
   winget install bufbuild.buf -e        # Windows
   ```
   ```bash
   brew install bufbuild/buf/buf          # macOS
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

### macOS 专属排错
- 下载的二进制被 Gatekeeper 拦（“已损坏/无法验证”）→ `xattr -dr com.apple.quarantine <该二进制>`（Silo 用 `curl` 下载一般不会触发）。
- 服务没起 → `brew services list` 看状态；`brew services start postgresql@18` / `brew services start redis`。
- Apple Silicon 上误装 Intel 版工具导致架构不匹配 → 确认 `uname -m` 为 `arm64`，`start_silo.sh` 会自动选 arm64 资产。
- 对象存储连不上 → 先确认 Silo 已起（`localhost:9000`）；后端 `S3_ENDPOINT` 用 `127.0.0.1:9000` 更稳。
