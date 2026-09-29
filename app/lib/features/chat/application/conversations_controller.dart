import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/conversation.dart';
import '../data/chat_repository.dart';

/// 会话列表：加载 + 新建单聊后刷新。
class ConversationsController extends AsyncNotifier<List<Conversation>> {
  @override
  Future<List<Conversation>> build() =>
      ref.watch(chatRepositoryProvider).listConversations();

  /// 与 [peerId] 建立（或复用）单聊，返回会话 ID 并刷新列表。
  Future<String> startDirect(String peerId) async {
    final id = await ref.read(chatRepositoryProvider).createDirect(peerId);
    ref.invalidateSelf();
    return id;
  }

  /// 新建群聊，返回会话 ID 并刷新列表。
  Future<String> createGroup(String name, List<String> memberIds) async {
    final id =
        await ref.read(chatRepositoryProvider).createGroup(name, memberIds);
    ref.invalidateSelf();
    return id;
  }
}

final conversationsProvider =
    AsyncNotifierProvider<ConversationsController, List<Conversation>>(
        ConversationsController.new);
