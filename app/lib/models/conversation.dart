/// 会话实体，对应服务端 internal/chat 的 Conversation 结构。
class Conversation {
  const Conversation({
    required this.id,
    required this.type,
    required this.name,
    required this.avatarUrl,
    required this.ownerId,
    required this.memberIds,
    this.unread = 0,
    this.pinned = false,
    this.muted = false,
    this.preview = '',
    this.lastAt,
    this.mentionMe = false,
    this.announcement = '',
  });

  /// 会话类型：0 单聊，1 群聊（与服务端常量一致）。
  final String id;
  final int type;
  final String name;
  final String avatarUrl;
  final String ownerId;
  final List<String> memberIds;
  /// 未读数（他人发来且未读的消息数）。
  final int unread;
  /// 成员级偏好：置顶 / 免打扰。
  final bool pinned;
  final bool muted;
  /// 最后一条消息预览（服务端根据类型/撤回生成）。
  final String preview;
  /// 最后消息时间（用于列表排序展示）。
  final DateTime? lastAt;
  /// 最后一条消息是否 @ 了本人。
  final bool mentionMe;
  /// 群公告（仅群聊，群主可改）。
  final String announcement;

  bool get isGroup => type == 1;

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
        id: json['id'] as String,
        type: (json['type'] as num? ?? 0).toInt(),
        name: json['name'] as String? ?? '',
        avatarUrl: json['avatar_url'] as String? ?? '',
        ownerId: json['owner_id'] as String? ?? '',
        unread: (json['unread'] as num? ?? 0).toInt(),
        pinned: json['pinned'] as bool? ?? false,
        muted: json['muted'] as bool? ?? false,
        preview: json['preview'] as String? ?? '',
        lastAt: DateTime.tryParse(json['last_at'] as String? ?? ''),
        mentionMe: json['mention_me'] as bool? ?? false,
        announcement: json['announcement'] as String? ?? '',
        memberIds: (json['member_ids'] as List<dynamic>? ?? const <dynamic>[])
            .map((e) => e as String)
            .toList(),
      );
}

/// 会话成员（含用户展示信息），对应服务端 chat.Member。
class ChatMember {
  const ChatMember({
    required this.userId,
    required this.username,
    required this.nickname,
    required this.avatarUrl,
    required this.role,
  });

  final String userId;
  final String username;
  final String nickname;
  final String avatarUrl;
  final int role; // 0 普通 / 2 群主

  String get displayName => nickname.isNotEmpty ? nickname : username;

  factory ChatMember.fromJson(Map<String, dynamic> json) => ChatMember(
        userId: json['user_id'] as String? ?? '',
        username: json['username'] as String? ?? '',
        nickname: json['nickname'] as String? ?? '',
        avatarUrl: json['avatar_url'] as String? ?? '',
        role: (json['role'] as num? ?? 0).toInt(),
      );
}

/// 会话详情：会话 + 成员列表。
class ConversationDetail {
  const ConversationDetail({required this.conversation, required this.members});

  final Conversation conversation;
  final List<ChatMember> members;

  factory ConversationDetail.fromJson(Map<String, dynamic> json) =>
      ConversationDetail(
        conversation:
            Conversation.fromJson(json['conversation'] as Map<String, dynamic>),
        members: (json['members'] as List<dynamic>? ?? const <dynamic>[])
            .map((e) => ChatMember.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
