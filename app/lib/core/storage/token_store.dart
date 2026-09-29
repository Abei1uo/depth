import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 内存令牌存储。
///
/// 说明：MVP 脚手架先以进程内内存保存令牌；接入 flutter_secure_storage
/// 后可在启动时从安全存储恢复会话（见 flutter-auth 之后的持久化 TODO）。
class TokenStore {
  String? _accessToken;
  String? _refreshToken;

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;

  bool get hasAccessToken => _accessToken != null && _accessToken!.isNotEmpty;

  void save({required String accessToken, required String refreshToken}) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  void clear() {
    _accessToken = null;
    _refreshToken = null;
  }
}

final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());
