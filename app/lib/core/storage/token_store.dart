import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 令牌存储：内存为主（供 ApiClient 拦截器同步读取），并经由
/// flutter_secure_storage 异步落盘，支持重启后免登录恢复会话。
class TokenStore {
  TokenStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const String _kAccess = 'access_token';
  static const String _kRefresh = 'refresh_token';

  final FlutterSecureStorage _storage;
  String? _accessToken;
  String? _refreshToken;

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;

  bool get hasAccessToken => _accessToken != null && _accessToken!.isNotEmpty;

  /// 启动时从安全存储回填内存（在 runApp 前调用）。
  Future<void> restore() async {
    try {
      _accessToken = await _storage.read(key: _kAccess);
      _refreshToken = await _storage.read(key: _kRefresh);
    } catch (_) {
      // 读取失败视为未登录，不阻断启动。
    }
  }

  void save({required String accessToken, required String refreshToken}) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _persist();
  }

  void clear() {
    _accessToken = null;
    _refreshToken = null;
    _erase();
  }

  Future<void> _persist() async {
    try {
      await _storage.write(key: _kAccess, value: _accessToken);
      await _storage.write(key: _kRefresh, value: _refreshToken);
    } catch (_) {
      // 落盘失败不影响本次会话（内存仍有效）。
    }
  }

  Future<void> _erase() async {
    try {
      await _storage.delete(key: _kAccess);
      await _storage.delete(key: _kRefresh);
    } catch (_) {
      // 忽略删除异常。
    }
  }
}

final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());
