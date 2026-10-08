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
    this.replyTo,
    this.mentions = const <String>[],
  });

  final int type;
  final String text;
  final String mediaUrl;
  final String thumbUrl;
  final int size;
  final ReplyInfo? replyTo;
  final List<String> mentions;

  factory MessageContent.fromJson(Map<String, dynamic> json) => MessageContent(
        type: (json['type'] as num? ?? 0).toInt(),
        text: json['text'] as String? ?? '',
        mediaUrl: json['media_url'] as String? ?? '',
        thumbUrl: json['thumb_url'] as String? ?? '',
        size: (json['size'] as num? ?? 0).toInt(),
        replyTo: json['reply_to'] is Map<String, dynamic>
            ? ReplyInfo.fromJson(json['reply_to'] as Map<String, dynamic>)
            : null,
        mentions: (json['mentions'] as List?)?.cast<String>() ?? const <String>[],
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type,
        if (text.isNotEmpty) 'text': text,
        if (mediaUrl.isNotEmpty) 'media_url': mediaUrl,
        if (thumbUrl.isNotEmpty) 'thumb_url': thumbUrl,
        if (size != 0) 'size': size,
        if (replyTo != null) 'reply_to': replyTo!.toJson(),
        if (mentions.isNotEmpty) 'mentions': mentions,
      };

  factory MessageContent.text(String value) =>
      MessageContent(type: MessageType.text, text: value);
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
  });

  final String serverMsgId;
  final String clientMsgId;
  final String conversationId;
  final String senderId;
  final int seq;
  final MessageContent content;
  final DateTime createdAt;
  final bool recalled;

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
