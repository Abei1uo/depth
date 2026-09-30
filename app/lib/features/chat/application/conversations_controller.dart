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

  /// 重新拉取会话列表。供详情页在离开（dispose）时刷新未读角标，
  /// 避免在 widget 的 dispose 中直接使用已失效的 `ref`。
  void reload() => ref.invalidateSelf();

  /// 群改名。
  Future<void> rename(String id, String name) async {
    await ref.read(chatRepositoryProvider).rename(id, name);
    ref.invalidateSelf();
  }

  /// 加成员。
  Future<void> addMembers(String id, List<String> userIds) async {
    await ref.read(chatRepositoryProvider).addMembers(id, userIds);
    ref.invalidateSelf();
  }

  /// 踢成员。
  Future<void> removeMember(String id, String userId) async {
    await ref.read(chatRepositoryProvider).removeMember(id, userId);
    ref.invalidateSelf();
  }

  /// 退出群聊（退出后回首页）。
  Future<void> leave(String id) async {
    await ref.read(chatRepositoryProvider).leave(id);
    ref.invalidateSelf();
  }

  /// 置顶 / 取消置顶。
  Future<void> setPin(String id, bool on) async {
    await ref.read(chatRepositoryProvider).pin(id, on);
    ref.invalidateSelf();
  }

  /// 免打扰 / 取消免打扰。
  Future<void> setMute(String id, bool on) async {
    await ref.read(chatRepositoryProvider).mute(id, on);
    ref.invalidateSelf();
  }

  /// 从列表删除（软隐藏）。
  Future<void> hide(String id) async {
    await ref.read(chatRepositoryProvider).hide(id);
    ref.invalidateSelf();
  }
}

final conversationsProvider =
    AsyncNotifierProvider<ConversationsController, List<Conversation>>(
        ConversationsController.new);
