import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../models/auth_session.dart';
import '../../../models/user.dart';

/// 认证与用户相关的 HTTP 数据源。
class AuthRepository {
  AuthRepository(this._api);

  final ApiClient _api;

  /// POST /api/v1/auth/register
  Future<AuthSession> register({
    required String username,
    required String nickname,
    required String password,
  }) async {
    return _session(() => _api.post<Map<String, dynamic>>('/auth/register', data: {
          'username': username,
          'nickname': nickname,
          'password': password,
        }));
  }

  /// POST /api/v1/auth/login
  Future<AuthSession> login({
    required String username,
    required String password,
  }) async {
    return _session(() => _api.post<Map<String, dynamic>>('/auth/login', data: {
          'username': username,
          'password': password,
        }));
  }

  /// GET /api/v1/users/me
  Future<AppUser> me() async {
    try {
      final resp = await _api.get<Map<String, dynamic>>('/users/me');
      return AppUser.fromJson(resp.data!);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// GET /api/v1/users/search?q=
  Future<List<AppUser>> search(String q) async {
    try {
      final resp =
          await _api.get<Map<String, dynamic>>('/users/search', query: {'q': q});
      final list = (resp.data?['users'] as List<dynamic>? ?? const []);
      return list
          .map((e) => AppUser.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// GET /api/v1/users/:id —— 查看他人资料。
  Future<AppUser> userById(String id) async {
    try {
      final resp = await _api.get<Map<String, dynamic>>('/users/$id');
      return AppUser.fromJson(resp.data!);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// PUT /api/v1/users/me —— 修改本人昵称/头像，返回更新后的用户。
  Future<AppUser> updateProfile({String? nickname, String? avatarUrl}) async {
    try {
      final resp = await _api.put<Map<String, dynamic>>('/users/me', data: {
        'nickname': ?nickname,
        'avatar_url': ?avatarUrl,
      });
      return AppUser.fromJson(resp.data!);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<AuthSession> _session(
      Future<Response<Map<String, dynamic>>> Function() action) async {
    try {
      final resp = await action();
      return AuthSession.fromJson(resp.data!);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(apiClientProvider));
});
