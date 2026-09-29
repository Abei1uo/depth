/// 应用级配置。地址可通过 --dart-define 覆盖，便于多环境构建。
///
/// Android 模拟器访问宿主机 localhost 使用 10.0.2.2；
/// iOS 模拟器 / 桌面可直接用 127.0.0.1；真机请填局域网后端 IP。
class AppConfig {
  const AppConfig._();

  static const String httpBaseUrl = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'http://10.0.2.2:8080/api/v1',
  );

  static const String wsBaseUrl = String.fromEnvironment(
    'WS_BASE',
    defaultValue: 'ws://10.0.2.2:8080/ws',
  );

  /// WebSocket 连接携带访问令牌的查询参数名，需与服务端 HandleConn 一致。
  static const String wsTokenQuery = 'token';

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
