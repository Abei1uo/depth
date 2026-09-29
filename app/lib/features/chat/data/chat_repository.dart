import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../models/conversation.dart';
import '../../../models/message.dart';

/// 会话与消息相关的 HTTP 数据源。
class ChatRepository {
  ChatRepository(this._api);

  final ApiClient _api;

  /// GET /api/v1/conversations
  Future<List<Conversation>> listConversations() async {
    try {
      final resp = await _api.get<Map<String, dynamic>>('/conversations');
      final list = resp.data?['conversations'] as List<dynamic>? ?? const [];
      return list
          .map((e) => Conversation.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// POST /api/v1/conversations/direct，返回会话 ID。
  Future<String> createDirect(String peerId) async {
    try {
      final resp = await _api.post<Map<String, dynamic>>(
          '/conversations/direct', data: {'peer_id': peerId});
      return resp.data?['conversation_id'] as String? ?? '';
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// GET /api/v1/conversations/:id/messages?before_seq=&limit=
  Future<List<ChatMessage>> history(
    String conversationId, {
    int? beforeSeq,
    int limit = 30,
  }) async {
    try {
      final resp = await _api.get<Map<String, dynamic>>(
        '/conversations/$conversationId/messages',
        query: <String, dynamic>{
          'before_seq': ?beforeSeq,
          'limit': limit,
        },
      );
      final list = resp.data?['messages'] as List<dynamic>? ?? const [];
      return list
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }
}

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(ref.watch(apiClientProvider));
});
