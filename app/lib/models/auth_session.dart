import 'user.dart';

/// 登录/注册成功后返回的令牌对，对应服务端 auth.TokenPair。
class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
  final AppUser user;

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
        accessToken: json['access_token'] as String,
        refreshToken: json['refresh_token'] as String,
        expiresAt: DateTime.fromMillisecondsSinceEpoch(
            (json['expires_at'] as num? ?? 0).toInt() * 1000),
        user: AppUser.fromJson(json['user'] as Map<String, dynamic>),
      );
}
