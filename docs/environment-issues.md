# 环境搭建问题记录（Windows 本机）

本文汇总 Depth IM 在本地开发环境搭建过程中遇到的典型问题、根因与解决方案。
完整安装步骤见 [setup.md](./setup.md)。

---

## 1. Go：PATH 上 1.25.9，但 go.mod 要求 1.26

- **症状**：`go run` 报 `go.mod requires go >= 1.26.0 (running go 1.25.9; GOTOOLCHAIN=local)`。
- **根因**：本机 PATH 上的 go 是 1.25.9；当环境变量 `GOTOOLCHAIN=local` 时不会自动下载匹配工具链。
- **解决**：进程内设 `$env:GOTOOLCHAIN='auto'`（默认值），Go 会按 go.mod 自动使用 1.26 工具链。
  `go build ./...` 通过。

## 2. PostgreSQL：EDB 安装器静默安装失败（exit code 1）

- **根因**：EDB 安装器的 `--prefix/--datadir` **不接受含空格的路径**，`D:\Program Files\...` 被拒
  （日志：`The installation directory must be an absolute path ... containing only letters, numbers ...`）。
- **解决**：装到无空格路径 `D:\PostgreSQL\18`。

## 3. PostgreSQL：`im` 角色密码认证失败

- **症状**：`psql 'postgresql://im:im@.../im'` 报 `用户 "im" Password 认证失败`。
- **根因**：早期残留的 `im` 角色没有有效密码；`init_db.ps1` 里 `CREATE ROLE ... PASSWORD 'im'`
  因 `role already exists` 被 `ON_ERROR_STOP=0` 吞掉，密码从未写入。
- **解决**：超级用户执行 `ALTER ROLE im WITH PASSWORD 'im';`。已把 `init_db.ps1` 改为幂等
  （每次 `CREATE` + `ALTER` 校正密码）。验证 `im/im` 可连、迁移成功、4 张表就绪。

## 4. 后端：会话列表接口 500（真实代码 bug）

- **症状**：`GET /api/v1/conversations` 返回 `获取会话列表失败`（handler 吞掉了底层错误）。
- **根因**：`internal/chat/repository.go` 的 `ListForUser` 用 `COALESCE(c.owner_id,'')`，
  而 `owner_id` 是 `uuid` 列，PostgreSQL 无法把 `''` 转成 uuid。
- **解决**：改为 `COALESCE(c.owner_id::text,'')`。已端到端复验通过。

## 5. Flutter：`pub` 镜像下载新增依赖卡死

- **症状**：`flutter pub add` 在 `pub.flutter-io.cn` 镜像长时间卡在 “Downloading packages”。
- **解决**：仅当前进程临时改用官方源 `$env:PUB_HOSTED_URL='https://pub.dev'` 后 `pub get` 秒成。

## 6. Riverpod：代码生成依赖版本求解冲突

- **症状**：`riverpod_generator` + `riverpod_annotation 4.0.7` 与 analyzer/_macros 版本求解失败。
- **解决**：放弃代码生成，改用**手写 Notifier/AsyncNotifier**；`riverpod_annotation ^4.0.7` 保留以匹配 lockfile。

## 7. Android：SDK 缺失 + Gradle 国内网络卡死（本轮最大坑）

- **SDK 接入**：本机原无任何安卓组件。headless 方式装：JDK17(winget) → cmdline-tools →
  platform-tools / platforms;android-34,36 / build-tools;36.0.0；NDK 构建时按需自动拉取。
  `flutter config --android-sdk D:\sdk\android` 后 `flutter doctor` 安卓工具链转绿。
  注意 Flutter 3.47 要求 **Android SDK 36**。
- **网络卡死**：`flutter build apk` 卡在 `assembleDebug`（daemon CPU 空转、无本地写入），
  根因是 **`maven.google.com` 超时、`github.com` 连不上、`repo.maven.apache.org` 的 60MB
  `kotlin-compiler-embeddable-2.4.0.jar` 下载超时**。
- **解决**（三管齐下，已落地）：
  1. 阿里云镜像优先：`app/android/build.gradle.kts` 的 `allprojects.repositories` 与
     `app/android/settings.gradle.kts` 的 `pluginManagement.repositories` 把
     `maven { url = uri("https://maven.aliyun.com/repository/google|public|central") }`
     插到 `google()/mavenCentral()` 之前。
  2. 调大超时/重试：`~/.gradle/gradle.properties` 加 `connectionTimeout/socketTimeout=180000`、
     `repository.max.tentatives=6`。
  3. 清掉从 central 误解析、只下到 pom 的构件缓存，使其按镜像优先重新解析。
- **结果**：`flutter build apk --debug` 约 1 分钟成功产出 debug APK，整条安卓工具链验证通过。

---

## 关键路径 / 凭据备忘

| 项 | 值 |
| --- | --- |
| Flutter/Dart | `D:\sdk\flutter`（3.47.2 / 3.13.2）|
| Android SDK | `D:\sdk\android`（platforms 34+36、build-tools 36、NDK r28c）|
| JDK | `C:\Program Files\Microsoft\jdk-17.0.20.101-hotspot` |
| PostgreSQL | `D:\PostgreSQL\18`，服务 `postgresql-x64-18`，超级用户 `postgres`，业务库/角色 `im` |
| Redis | 本机 `localhost:6379` |
| 后端 | `:8080`，`go run ./cmd/server`（需 `GOTOOLCHAIN=auto`）|
