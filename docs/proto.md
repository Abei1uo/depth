# Protobuf 协议与代码生成

## 定位（重要取舍）
- `proto/depth/v1/*.proto` 是**跨端协议的权威契约（单一事实来源）**，Go 与 Dart 两端据此生成强类型模型。
- **当前运行时传输仍是 JSON 信封**（HTTP REST + WebSocket `Envelope{type,payload}`）。
  本轮**不把二进制 Protobuf 接入运行链路**，原因：MVP 阶段带宽收益小、改动面大、风险高；
  proto 的价值先体现在「契约一致 + 生成模型」上。后续可对 WS 通道灰度切换为二进制帧。

## 目录与生成产物
- 协议源：`proto/depth/v1/{common,user,message,chat,event,call}.proto`
- buf 配置：`proto/buf.yaml`、`proto/buf.gen.go.yaml`、`proto/buf.gen.dart.yaml`
- Go 产物：`server/gen/pb/depth/v1/*.pb.go`（含 `*_grpc.pb.go`，为将来 gRPC 预留，当前不被业务引用）
- Dart 产物：`app/lib/gen/pb/depth/v1/*.pb.dart` 等（已在 `analysis_options.yaml` 排除出 lint）

## 字段一致性
生成模型与手写 JSON 模型一一对应，命名遵循 proto3 → 各语言默认转换：
- `server_msg_id` → Go `ServerMsgId` / Dart `serverMsgId`
- `conversation_id` → Go `ConversationId` / Dart `conversationId`
- `int64 seq` → Go `int64` / Dart `fixnum.Int64`
- 枚举 `MessageType`：`MESSAGE_TYPE_TEXT/IMAGE/FILE/VOICE/SYS`，取值与后端 `internal/message` 常量一致。

## 重新生成步骤
前置：安装 `buf`（见 setup.md）；Dart 侧 `dart pub global activate protoc_plugin`。

```powershell
cd d:\workspace\tss\depth\proto
& $buf lint
& $buf generate --template buf.gen.go.yaml      # -> server/gen/pb（需 google.golang.org/protobuf、grpc）
$env:PATH += ";$env:LOCALAPPDATA\Pub\Cache\bin"  # protoc-gen-dart 所在
& $buf generate --template buf.gen.dart.yaml     # -> app/lib/gen/pb
cd ..\server; go mod tidy                        # 拉齐 protobuf/grpc 依赖
cd ..\app ; flutter pub add protobuf fixnum      # Dart 生成代码依赖
```

验证：`go build ./...` 通过；`flutter test`（含 `test/proto_gen_test.dart` 构造并往返序列化）通过。

## 说明：buf lint 放宽项
`buf.yaml` 的 `except` 关掉了若干 RPC 命名/唯一性规则
（`RPC_REQUEST_STANDARD_NAME`、`RPC_RESPONSE_STANDARD_NAME`、`RPC_REQUEST_RESPONSE_UNIQUE`、
枚举命名规则）。因为这些 service 仅作契约展示、不启用生成的 gRPC 桩，共享请求/响应类型与简洁枚举命名可接受。
若将来要正式启用 gRPC，再移除这些豁免并按规范补齐每个 RPC 的独立 wrapper 消息。
