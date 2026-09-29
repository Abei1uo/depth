/// 用户实体，对应服务端 internal/user 的 User 结构。
class AppUser {
  const AppUser({
    required this.id,
    required this.username,
    required this.nickname,
    required this.avatarUrl,
    required this.createdAt,
  });

  final String id;
  final String username;
  final String nickname;
  final String avatarUrl;
  final DateTime createdAt;

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        username: json['username'] as String? ?? '',
        nickname: json['nickname'] as String? ?? '',
        avatarUrl: json['avatar_url'] as String? ?? '',
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
      );

  /// 展示名：优先昵称，回退用户名。
  String get displayName => nickname.isNotEmpty ? nickname : username;
}
