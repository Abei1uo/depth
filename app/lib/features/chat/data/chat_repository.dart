import 'dart:io' show File;

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

  /// POST /api/v1/conversations/group，返回会话 ID。
  Future<String> createGroup(String name, List<String> memberIds) async {
    try {
      final resp = await _api.post<Map<String, dynamic>>(
          '/conversations/group',
          data: {'name': name, 'member_ids': memberIds});
      return resp.data?['conversation_id'] as String? ?? '';
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<void> _postVoid(String path, [Object? data]) async {
    try {
      await _api.post<Map<String, dynamic>>(path, data: data);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// 群改名（仅群主）。
  Future<void> rename(String conversationId, String name) =>
      _postVoid('/conversations/$conversationId/rename', {'name': name});

  /// 设置群公告（仅群主）。
  Future<void> setAnnouncement(String conversationId, String text) =>
      _postVoid('/conversations/$conversationId/announcement',
          {'announcement': text});

  /// 加成员（仅群主）。
  Future<void> addMembers(String conversationId, List<String> userIds) =>
      _postVoid('/conversations/$conversationId/members/add', {'user_ids': userIds});

  /// 踢成员（仅群主）。
  Future<void> removeMember(String conversationId, String userId) =>
      _postVoid('/conversations/$conversationId/members/remove', {'user_id': userId});

  /// 退出群聊。
  Future<void> leave(String conversationId) =>
      _postVoid('/conversations/$conversationId/leave');

  /// 置顶 / 取消置顶。
  Future<void> pin(String conversationId, bool on) =>
      _postVoid('/conversations/$conversationId/pin', {'pinned': on});

  /// 免打扰 / 取消免打扰。
  Future<void> mute(String conversationId, bool on) =>
      _postVoid('/conversations/$conversationId/mute', {'muted': on});

  /// 从我的会话列表删除（软隐藏）。
  Future<void> hide(String conversationId) async {
    try {
      await _api.delete<Map<String, dynamic>>('/conversations/$conversationId');
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// GET /api/v1/conversations/:id，返回会话详情与成员。
  Future<ConversationDetail> detail(String conversationId) async {
    try {
      final resp = await _api
          .get<Map<String, dynamic>>('/conversations/$conversationId');
      return ConversationDetail.fromJson(resp.data ?? const <String, dynamic>{});
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

  /// GET /api/v1/conversations/:id/messages/search?q=&limit=
  Future<List<ChatMessage>> search(String conversationId, String q,
      {int limit = 50}) async {
    try {
      final resp = await _api.get<Map<String, dynamic>>(
        '/conversations/$conversationId/messages/search',
        query: <String, dynamic>{'q': q, 'limit': limit},
      );
      final list = resp.data?['messages'] as List<dynamic>? ?? const [];
      return list
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// GET /api/v1/search/messages?q=&limit= —— 跨会话的全局消息检索。
  Future<List<ChatMessage>> searchAll(String q, {int limit = 50}) async {
    try {
      final resp = await _api.get<Map<String, dynamic>>(
        '/search/messages',
        query: <String, dynamic>{'q': q, 'limit': limit},
      );
      final list = resp.data?['messages'] as List<dynamic>? ?? const [];
      return list
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// POST /api/v1/media（multipart）——上传一个文件，返回媒体登记（含下载 url）。
  Future<MediaUpload> uploadMedia(File file, {String? name}) async {
    try {
      final fileName = name ?? file.path.split(RegExp(r'[\\/]')).last;
      final form = FormData.fromMap(<String, dynamic>{
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
      });
      // 直接用带鉴权拦截器的 dio；baseUrl 已含 /api/v1。
      final resp = await _api.dio.post<Map<String, dynamic>>('/media', data: form);
      final data = resp.data ?? const <String, dynamic>{};
      return MediaUpload(
        mediaId: data['media_id'] as String? ?? '',
        url: data['url'] as String? ?? '',
        mime: data['mime'] as String? ?? '',
        size: (data['size'] as num? ?? 0).toInt(),
        fileName: fileName,
      );
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }
}

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(ref.watch(apiClientProvider));
});

/// 一次媒体上传的结果。
class MediaUpload {
  const MediaUpload({
    required this.mediaId,
    required this.url,
    required this.mime,
    required this.size,
    required this.fileName,
  });

  final String mediaId;
  final String url;
  final String mime;
  final int size;
  final String fileName;
}
