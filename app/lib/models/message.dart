/// 消息类型常量，与服务端 internal/message 保持一致。
class MessageType {
  static const int text = 0;
  static const int image = 1;
  static const int file = 2;
  static const int voice = 3;
  static const int system = 4;
}

/// 被引用消息的展示快照，对应服务端 message.ReplyInfo。
class ReplyInfo {
  const ReplyInfo({
    required this.msgId,
    required this.senderId,
    required this.text,
  });

  final String msgId;
  final String senderId;
  final String text;

  factory ReplyInfo.fromJson(Map<String, dynamic> json) => ReplyInfo(
        msgId: json['msg_id'] as String? ?? '',
        senderId: json['sender_id'] as String? ?? '',
        text: json['text'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'msg_id': msgId,
        'sender_id': senderId,
        'text': text,
      };
}

/// 消息正文负载，对应服务端 message.Content。
class MessageContent {
  const MessageContent({
    required this.type,
    this.text = '',
    this.mediaUrl = '',
    this.thumbUrl = '',
    this.size = 0,
    this.duration = 0,
    this.replyTo,
    this.mentions = const <String>[],
    this.reactions = const <String, List<String>>{},
    this.pinned = false,
    this.mentionAll = false,
  });

  final int type;
  final String text;
  final String mediaUrl;
  final String thumbUrl;
  final int size;
  final int duration; // 语音时长（秒）
  final ReplyInfo? replyTo;
  final List<String> mentions;
  final Map<String, List<String>> reactions; // emoji -> 已回应成员 ID 列表
  final bool pinned; // 是否被会话成员置顶
  final bool mentionAll; // 群内 @全体成员

  factory MessageContent.fromJson(Map<String, dynamic> json) => MessageContent(
        type: (json['type'] as num? ?? 0).toInt(),
        text: json['text'] as String? ?? '',
        mediaUrl: json['media_url'] as String? ?? '',
        thumbUrl: json['thumb_url'] as String? ?? '',
        size: (json['size'] as num? ?? 0).toInt(),
        duration: (json['duration'] as num? ?? 0).toInt(),
        replyTo: json['reply_to'] is Map<String, dynamic>
            ? ReplyInfo.fromJson(json['reply_to'] as Map<String, dynamic>)
            : null,
        mentions: (json['mentions'] as List?)?.cast<String>() ?? const <String>[],
        reactions: _parseReactions(json['reactions']),
        pinned: json['pinned'] as bool? ?? false,
        mentionAll: json['mention_all'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type,
        if (text.isNotEmpty) 'text': text,
        if (mediaUrl.isNotEmpty) 'media_url': mediaUrl,
        if (thumbUrl.isNotEmpty) 'thumb_url': thumbUrl,
        if (size != 0) 'size': size,
        if (duration != 0) 'duration': duration,
        if (replyTo != null) 'reply_to': replyTo!.toJson(),
        if (mentions.isNotEmpty) 'mentions': mentions,
        if (reactions.isNotEmpty) 'reactions': reactions,
        if (pinned) 'pinned': pinned,
        if (mentionAll) 'mention_all': mentionAll,
      };

  /// 按需返回副本（用于本地切换置顶等就地更新）。
  MessageContent copyWith({
    int? type,
    String? text,
    bool? pinned,
    bool? mentionAll,
  }) =>
      MessageContent(
        type: type ?? this.type,
        text: text ?? this.text,
        mediaUrl: mediaUrl,
        thumbUrl: thumbUrl,
        size: size,
        duration: duration,
        replyTo: replyTo,
        mentions: mentions,
        reactions: reactions,
        pinned: pinned ?? this.pinned,
        mentionAll: mentionAll ?? this.mentionAll,
      );

  factory MessageContent.text(String value) =>
      MessageContent(type: MessageType.text, text: value);
}

/// 解析 reactions JSON（emoji -> 用户 ID 列表）为强类型映射。
Map<String, List<String>> _parseReactions(dynamic raw) {
  if (raw is Map) {
    final out = <String, List<String>>{};
    for (final e in raw.entries) {
      if (e.key is String && e.value is List) {
        out[e.key as String] = (e.value as List).cast<String>();
      }
    }
    return out;
  }
  return const <String, List<String>>{};
}

/// 完整消息实体，对应服务端 message.Message。
class ChatMessage {
  const ChatMessage({
    required this.serverMsgId,
    required this.clientMsgId,
    required this.conversationId,
    required this.senderId,
    required this.seq,
    required this.content,
    required this.createdAt,
    this.recalled = false,
    this.sendFailed = false,
  });

  final String serverMsgId;
  final String clientMsgId;
  final String conversationId;
  final String senderId;
  final int seq;
  final MessageContent content;
  final DateTime createdAt;
  final bool recalled;
  /// 本地发送状态：长时间未收到 ack 时置为失败（仅客户端，不参与序列化）。
  final bool sendFailed;

  ChatMessage copyWith(
          {String? serverMsgId, int? seq, bool? sendFailed, MessageContent? content}) =>
      ChatMessage(
        serverMsgId: serverMsgId ?? this.serverMsgId,
        clientMsgId: clientMsgId,
        conversationId: conversationId,
        senderId: senderId,
        seq: seq ?? this.seq,
        content: content ?? this.content,
        createdAt: createdAt,
        recalled: recalled,
        sendFailed: sendFailed ?? this.sendFailed,
      );

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        serverMsgId: json['server_msg_id'] as String? ?? '',
        clientMsgId: json['client_msg_id'] as String? ?? '',
        conversationId: json['conversation_id'] as String? ?? '',
        senderId: json['sender_id'] as String? ?? '',
        seq: (json['seq'] as num? ?? 0).toInt(),
        content: MessageContent.fromJson(
            (json['content'] as Map<String, dynamic>?) ?? const <String, dynamic>{}),
        createdAt: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
            DateTime.now(),
        recalled: json['recalled'] as bool? ?? false,
      );
}

/// 消息发送回执，对应服务端 message.Ack。
class MessageAck {
  const MessageAck({
    required this.clientMsgId,
    required this.serverMsgId,
    required this.seq,
    required this.timestamp,
  });

  final String clientMsgId;
  final String serverMsgId;
  final int seq;
  final int timestamp;

  factory MessageAck.fromJson(Map<String, dynamic> json) => MessageAck(
        clientMsgId: json['client_msg_id'] as String? ?? '',
        serverMsgId: json['server_msg_id'] as String? ?? '',
        seq: (json['seq'] as num? ?? 0).toInt(),
        timestamp: (json['timestamp'] as num? ?? 0).toInt(),
      );
}
