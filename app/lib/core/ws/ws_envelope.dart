import 'dart:convert';

/// WebSocket 统一信封，对应服务端 pkg/ws.Envelope。
class WsEnvelope {
  const WsEnvelope({required this.type, required this.payload});

  final String type;
  final Map<String, dynamic> payload;

  factory WsEnvelope.decode(String raw) {
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final payload = map['payload'];
    return WsEnvelope(
      type: map['type'] as String? ?? '',
      payload: payload is Map<String, dynamic>
          ? payload
          : (payload == null ? const <String, dynamic>{} : <String, dynamic>{'value': payload}),
    );
  }

  String encode() => jsonEncode(<String, dynamic>{
        'type': type,
        'payload': payload,
      });
}

/// 事件类型常量，与服务端 pkg/ws 保持同步。
class WsEvents {
  // 上行：客户端 -> 服务端
  static const String sendMessage = 'send_message';
  static const String markRead = 'mark_read';
  static const String typing = 'typing';
  static const String sync = 'sync';
  static const String recallMessage = 'recall_message';
  static const String editMessage = 'edit_message';
  static const String deleteMessage = 'delete_message';

  // 下行：服务端 -> 客户端
  static const String newMessage = 'new_message';
  static const String msgAck = 'msg_ack';
  static const String msgRead = 'msg_read';
  static const String messageUpdate = 'message_update';
  static const String presenceUpdate = 'presence_update';
  static const String syncResult = 'sync_result';
  static const String error = 'error';
}
