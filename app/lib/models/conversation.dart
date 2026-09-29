/// 会话实体，对应服务端 internal/chat 的 Conversation 结构。
class Conversation {
  const Conversation({
    required this.id,
    required this.type,
    required this.name,
    required this.avatarUrl,
    required this.ownerId,
    required this.memberIds,
  });

  /// 会话类型：0 单聊，1 群聊（与服务端常量一致）。
  final String id;
  final int type;
  final String name;
  final String avatarUrl;
  final String ownerId;
  final List<String> memberIds;

  bool get isGroup => type == 1;

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
        id: json['id'] as String,
        type: (json['type'] as num? ?? 0).toInt(),
        name: json['name'] as String? ?? '',
        avatarUrl: json['avatar_url'] as String? ?? '',
        ownerId: json['owner_id'] as String? ?? '',
        memberIds: (json['member_ids'] as List<dynamic>? ?? const <dynamic>[])
            .map((e) => e as String)
            .toList(),
      );
}
