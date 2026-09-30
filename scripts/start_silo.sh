#!/usr/bin/env bash
# 本地以单二进制方式启动 Silo（MinIO 社区分支，S3 兼容对象存储），不使用 Docker。
# 平台：macOS（Apple Silicon arm64 / Intel amd64 自动选择）。Windows 请用 scripts/start_silo.ps1。
#
# Silo 与 MinIO 协议/数据完全兼容，后端 minio-go 代码无需改动，仅改环境变量。
# 下载地址：https://github.com/pgsty/silo/releases
#
# 用法：
#   bash scripts/start_silo.sh
#   TAG=RELEASE.2026-09-16T00-00-00Z INSTALL_DIR=$HOME/silo DATA_DIR=$HOME/silo-data bash scripts/start_silo.sh
#
# 首次运行会下载并解压 silo；之后复用缓存直接启动。
# 启动后：S3 API localhost:9000，控制台 http://localhost:9001（minioadmin/minioadmin）。
set -euo pipefail

TAG="${TAG:-RELEASE.2026-09-16T00-00-00Z}"
INSTALL_DIR="${INSTALL_DIR:-$HOME/silo}"
DATA_DIR="${DATA_DIR:-$HOME/silo-data}"
ROOT_USER="${ROOT_USER:-minioadmin}"
ROOT_PASS="${ROOT_PASS:-minioadmin}"
ADDRESS="${ADDRESS:-:9000}"
CONSOLE_ADDRESS="${CONSOLE_ADDRESS:-:9001}"

# uname -m: arm64 (Apple Silicon) -> arm64；x86_64 (Intel) -> amd64
case "$(uname -m)" in
  arm64)  ARCH=arm64 ;;
  x86_64) ARCH=amd64 ;;
  *) echo "不支持的架构: $(uname -m)" >&2; exit 1 ;;
esac

VER="$(echo "$TAG" | sed -E 's/^RELEASE\.//; s/T00-00-00Z$//; s/-//g')"
ASSET="silo_${VER}.0.0_darwin_${ARCH}.tar.gz"
URL="https://github.com/pgsty/silo/releases/download/${TAG}/${ASSET}"

mkdir -p "$INSTALL_DIR" "$DATA_DIR"
SILO_BIN="$INSTALL_DIR/silo"

if [ ! -x "$SILO_BIN" ]; then
  echo "=== 下载 Silo（darwin/$ARCH）：$URL ==="
  curl -fL "$URL" -o "$INSTALL_DIR/$ASSET"
  echo "=== 解压到 $INSTALL_DIR ==="
  tar -xzf "$INSTALL_DIR/$ASSET" -C "$INSTALL_DIR"
  rm -f "$INSTALL_DIR/$ASSET"
fi

# curl 下载一般不带 quarantine；若经浏览器下载后被 Gatekeeper 拦，可手动放行：
#   xattr -d com.apple.quarantine "$SILO_BIN"
chmod +x "$SILO_BIN"

export MINIO_ROOT_USER="$ROOT_USER"
export MINIO_ROOT_PASSWORD="$ROOT_PASS"

echo "=== 启动 Silo：API $ADDRESS / 控制台 $CONSOLE_ADDRESS / 数据 $DATA_DIR ==="
echo "（桶 im-media 会在服务端首次上传时自动创建，无需手动建）"
exec "$SILO_BIN" server "$DATA_DIR" --address "$ADDRESS" --console-address "$CONSOLE_ADDRESS"
