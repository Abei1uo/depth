import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/app_config.dart';
import '../../../core/storage/token_store.dart';
import '../../../core/ws/ws_client.dart';
import '../../../models/auth_session.dart';
import '../../../models/user.dart';
import '../data/auth_repository.dart';

/// 认证状态机。
enum AuthStatus { initial, authenticating, authenticated, unauthenticated }

class AuthState {
  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.error,
  });

  final AuthStatus status;
  final AppUser? user;
  final String? error;

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isBusy => status == AuthStatus.authenticating;

  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    String? error,
    bool clearError = false,
  }) =>
      AuthState(
        status: status ?? this.status,
        user: user ?? this.user,
        error: clearError ? null : (error ?? this.error),
      );
}

/// 会话控制器：编排登录/注册/登出，维护令牌并驱动 WebSocket 连接。
class SessionController extends Notifier<AuthState> {
  @override
  AuthState build() {
    // 令牌刷新失败时由 ApiClient 回调触发登出。
    ref.read(apiClientProvider).onUnauthorized = logout;
    // 脚手架阶段无安全存储持久化，初始即为未认证。
    return const AuthState(status: AuthStatus.unauthenticated);
  }

  AuthRepository get _repo => ref.read(authRepositoryProvider);
  TokenStore get _tokens => ref.read(tokenStoreProvider);
  WsClient get _ws => ref.read(wsClientProvider);

  Future<bool> login({
    required String username,
    required String password,
  }) =>
      _run(() => _repo.login(username: username, password: password));

  Future<bool> register({
    required String username,
    required String nickname,
    required String password,
  }) =>
      _run(() =>
          _repo.register(username: username, nickname: nickname, password: password));

  /// 修改本人资料（昵称/头像），成功后刷新内存中的 user。
  Future<bool> updateProfile({String? nickname, String? avatarUrl}) async {
    try {
      final u =
          await _repo.updateProfile(nickname: nickname, avatarUrl: avatarUrl);
      state = state.copyWith(user: u);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
      return false;
    } catch (_) {
      return false;
    }
  }

  void logout() {
    _tokens.clear();
    _ws.close();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<bool> _run(Future<AuthSession> Function() action) async {
    state = state.copyWith(status: AuthStatus.authenticating, clearError: true);
    try {
      final session = await action();
      _apply(session);
      return true;
    } on ApiException catch (e) {
      state = AuthState(status: AuthStatus.unauthenticated, error: e.message);
      return false;
    } catch (_) {
      state = const AuthState(
        status: AuthStatus.unauthenticated,
        error: '未知错误',
      );
      return false;
    }
  }

  void _apply(AuthSession session) {
    _tokens.save(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );
    _ws.connect(AppConfig.wsBaseUrl, session.accessToken);
    state = AuthState(status: AuthStatus.authenticated, user: session.user);
  }

  /// 启动时尝试恢复会话：从安全存储取回令牌，若有效则拉取用户信息并连接 WS。
  /// 由 main() 在 runApp 前 await 调用，避免登录页闪现。
  Future<void> bootstrap() async {
    await _tokens.restore();
    if (!_tokens.hasAccessToken) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }
    try {
      final user = await _repo.me();
      _ws.connect(AppConfig.wsBaseUrl, _tokens.accessToken!);
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (_) {
      // 令牌失效且刷新失败：登出回到登录页。
      _tokens.clear();
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }
}

final sessionControllerProvider =
    NotifierProvider<SessionController, AuthState>(SessionController.new);
