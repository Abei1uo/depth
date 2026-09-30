import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../app_config.dart';
import 'ws_envelope.dart';

/// WebSocket 客户端骨架：连接管理 + 断线指数退避重连 + 广播下行信封。
///
/// 与后端 Hub 的对应关系：连接时通过查询参数携带访问令牌完成认证，
/// 之后按 [WsEnvelope] 收发 JSON 信封。心跳由服务端 pingPump 负责，
/// 客户端仅需在 stream 断开时重连。
class WsClient {
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  Timer? _reconnectTimer;

  bool _disposed = false;
  bool _shouldReconnect = false;
  int _attempt = 0;
  String? _url;
  String? _token;

  final StreamController<WsEnvelope> _incoming =
      StreamController<WsEnvelope>.broadcast();
  final StreamController<bool> _status = StreamController<bool>.broadcast();

  static const List<int> _backoffSeconds = <int>[1, 2, 5, 10, 30];

  /// 未连接时的待发队列（内存态，FIFO）。重连成功后按序补发。
  /// 注意：App 进程被杀则丢失；持久化待发队列列入后续轮次。
  static const int _maxOutbox = 200;
  final List<WsEnvelope> _outbox = <WsEnvelope>[];

  Stream<WsEnvelope> get incoming => _incoming.stream;
  Stream<bool> get status => _status.stream;
  bool get isConnected => _channel != null;

  void connect(String url, String token) {
    _url = url;
    _token = token;
    _disposed = false;
    _shouldReconnect = true;
    _attempt = 0;
    _open();
  }

  void _open() {
    if (_disposed || _url == null || _token == null) return;
    final uri = Uri.parse(
        '$_url?${AppConfig.wsTokenQuery}=${Uri.encodeComponent(_token!)}');
    try {
      final channel = WebSocketChannel.connect(uri);
      _channel = channel;
      _sub = channel.stream.listen(
        (dynamic data) {
          _attempt = 0;
          final raw = data is String ? data : utf8.decode(data as List<int>);
          if (!_incoming.isClosed) _incoming.add(WsEnvelope.decode(raw));
        },
        onDone: _handleDisconnect,
        onError: (Object _) => _handleDisconnect(),
        cancelOnError: true,
      );
      _addStatus(true);
      _flushOutbox();
    } catch (_) {
      _handleDisconnect();
    }
  }

  void _handleDisconnect() {
    _addStatus(false);
    _sub?.cancel();
    _sub = null;
    _channel = null;
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_disposed || !_shouldReconnect) return;
    _reconnectTimer?.cancel();
    final seconds = _backoffSeconds[_attempt.clamp(0, _backoffSeconds.length - 1)];
    _attempt = (_attempt + 1).clamp(0, _backoffSeconds.length - 1);
    _reconnectTimer = Timer(Duration(seconds: seconds), _open);
  }

  void _addStatus(bool value) {
    if (!_status.isClosed) _status.add(value);
  }

  /// 发送一个信封；未连接则入队，待重连成功后补发（上限 [_maxOutbox]，满则丢弃最旧）。
  void send(WsEnvelope envelope) {
    final channel = _channel;
    if (channel == null) {
      if (_outbox.length >= _maxOutbox) {
        _outbox.removeAt(0); // 超出上限，丢弃最旧一条
      }
      _outbox.add(envelope);
      return;
    }
    channel.sink.add(envelope.encode());
  }

  /// 重连成功后补发队列中的信封。仍携带原 client_msg_id，服务端会幂等去重。
  void _flushOutbox() {
    final channel = _channel;
    if (channel == null || _outbox.isEmpty) return;
    final pending = List<WsEnvelope>.of(_outbox);
    _outbox.clear();
    for (final env in pending) {
      channel.sink.add(env.encode());
    }
  }

  /// 当前待发队列长度（仅供测试观察）。
  @visibleForTesting
  int get pendingOutbox => _outbox.length;

  /// 主动断开（登出时调用），不再自动重连。
  void close() {
    _shouldReconnect = false;
    _outbox.clear();
    _reconnectTimer?.cancel();
    _sub?.cancel();
    _sub = null;
    _channel?.sink.close();
    _channel = null;
    _addStatus(false);
  }

  void dispose() {
    _disposed = true;
    close();
    _incoming.close();
    _status.close();
  }
}

final wsClientProvider = Provider<WsClient>((ref) {
  final client = WsClient();
  ref.onDispose(client.dispose);
  return client;
});

/// 连接状态流。先同步发出当前状态作为初始值，随后转发后续变更，
/// 以便 UI（如断线重连横幅）能拿到首个状态而非停留在 loading。
final wsStatusProvider = StreamProvider<bool>((ref) async* {
  final client = ref.watch(wsClientProvider);
  yield client.isConnected;
  yield* client.status;
});
