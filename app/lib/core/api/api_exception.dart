import 'package:dio/dio.dart';

/// 统一的服务端错误封装，携带可读的中文提示。
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  /// 从 DioException 提取后端返回的 {"error": "..."} 文案。
  factory ApiException.from(DioException e) {
    final data = e.response?.data;
    String msg = '网络异常，请稍后重试';
    if (data is Map && data['error'] is String) {
      msg = data['error'] as String;
    } else {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          msg = '连接超时，请检查后端服务是否已启动';
          break;
        case DioExceptionType.connectionError:
          msg = '无法连接服务器';
          break;
        default:
          break;
      }
    }
    return ApiException(msg, statusCode: e.response?.statusCode);
  }

  @override
  String toString() => 'ApiException($statusCode, $message)';
}
