import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/token_store.dart';
import '../app_config.dart';

/// 封装 HTTP 访问：自动附加 Bearer 令牌，遇 401 触发一次性刷新并重试，
/// 刷新失败则清理会话并回调 [onUnauthorized]。
class ApiClient {
  ApiClient(this._store) {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.httpBaseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      contentType: Headers.jsonContentType,
    ));
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _store.accessToken;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: _handleError,
      ),
    );
  }

  final TokenStore _store;
  late final Dio _dio;

  /// 会话失效（刷新失败）时的回调，由 SessionController 注入以执行登出。
  void Function()? onUnauthorized;

  /// 单飞刷新：并发 401 共享同一次刷新请求，避免令牌抖动。
  Completer<bool>? _refreshing;

  Dio get dio => _dio;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? query,
  }) =>
      _dio.get<T>(path, queryParameters: query);

  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? query,
  }) =>
      _dio.post<T>(path, data: data, queryParameters: query);

  Future<Response<T>> put<T>(String path, {Object? data}) =>
      _dio.put<T>(path, data: data);

  Future<void> _handleError(
      DioException err, ErrorInterceptorHandler handler) async {
    final status = err.response?.statusCode;
    final path = err.requestOptions.path;
    final retried = err.requestOptions.extra['retried'] == true;
    final isAuthEndpoint = path.contains('/auth/');

    if (status == 401 && !isAuthEndpoint && !retried && _store.refreshToken != null) {
      final ok = await _refreshToken();
      if (ok) {
        err.requestOptions.extra['retried'] = true;
        try {
          final retry = await _dio.fetch(err.requestOptions);
          return handler.resolve(retry);
        } on DioException catch (e) {
          return handler.next(e);
        }
      }
      _store.clear();
      onUnauthorized?.call();
    }
    return handler.next(err);
  }

  Future<bool> _refreshToken() async {
    if (_refreshing != null) {
      return _refreshing!.future;
    }
    final completer = Completer<bool>();
    _refreshing = completer;
    try {
      final rt = _store.refreshToken!;
      // 用裸 Dio 调刷新接口，避免再次进入拦截器。
      final raw = Dio(BaseOptions(
        baseUrl: AppConfig.httpBaseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
      ));
      final resp =
          await raw.post<Map<String, dynamic>>('/auth/refresh', data: {
        'refresh_token': rt,
      });
      final data = resp.data ?? const <String, dynamic>{};
      final access = data['access_token'] as String?;
      final refresh = data['refresh_token'] as String?;
      if (access == null || refresh == null) {
        completer.complete(false);
      } else {
        _store.save(accessToken: access, refreshToken: refresh);
        completer.complete(true);
      }
    } catch (_) {
      completer.complete(false);
    } finally {
      _refreshing = null;
    }
    return completer.future;
  }
}

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.watch(tokenStoreProvider));
});
