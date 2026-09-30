import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/user.dart';
import '../../../models/conversation.dart';
import '../../../core/ws/ws_client.dart';
import '../../auth/application/session_controller.dart';
import '../../auth/data/auth_repository.dart';
import '../application/conversations_controller.dart';

/// 首页：会话列表 + 新建单聊入口。
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionControllerProvider.select((s) => s.user));
    final convs = ref.watch(conversationsProvider);
    final online = ref.watch(wsStatusProvider).value ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(user?.displayName ?? 'Depth'),
        actions: [
          IconButton(
            tooltip: online ? '实时通道已连接' : '实时通道已断开',
            icon: Icon(online ? Icons.circle : Icons.circle_outlined,
                color: online ? Colors.green : Colors.grey),
            onPressed: null,
          ),
          IconButton(
            tooltip: '退出登录',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(sessionControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: convs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorRetry(
          message: e.toString(),
          onRetry: () => ref.invalidate(conversationsProvider),
        ),
        data: (list) => list.isEmpty
            ? const _EmptyHint()
            : ListView.separated(
                itemCount: list.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final c = list[i];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text((c.name.isNotEmpty ? c.name : 'C')[0]),
                    ),
                    title: Row(
                      children: [
                        if (c.pinned) ...[
                          const Icon(Icons.push_pin, size: 14),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            c.name.isEmpty
                                ? '会话 ${c.id.substring(0, 6)}'
                                : c.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (c.muted)
                          const Icon(Icons.notifications_off_outlined,
                              size: 16),
                        if (c.unread > 0) ...[
                          const SizedBox(width: 4),
                          Badge.count(count: c.unread),
                        ],
                      ],
                    ),
                    onTap: () => context.go('/chat/${c.id}'),
                    onLongPress: () => _showConvMenu(context, ref, c),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateMenu(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('新建单聊'),
              onTap: () {
                Navigator.of(ctx).pop();
                _startNewChat(context, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.group_add_outlined),
              title: const Text('新建群聊'),
              onTap: () {
                Navigator.of(ctx).pop();
                _startNewGroup(context, ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showConvMenu(BuildContext context, WidgetRef ref, Conversation c) {
    final notifier = ref.read(conversationsProvider.notifier);
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(c.pinned
                  ? Icons.push_pin
                  : Icons.push_pin_outlined),
              title: Text(c.pinned ? '取消置顶' : '置顶'),
              onTap: () {
                Navigator.of(ctx).pop();
                notifier.setPin(c.id, !c.pinned);
              },
            ),
            ListTile(
              leading: Icon(c.muted
                  ? Icons.notifications_active_outlined
                  : Icons.notifications_off_outlined),
              title: Text(c.muted ? '取消免打扰' : '免打扰'),
              onTap: () {
                Navigator.of(ctx).pop();
                notifier.setMute(c.id, !c.muted);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('从列表删除'),
              onTap: () {
                Navigator.of(ctx).pop();
                notifier.hide(c.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startNewGroup(BuildContext context, WidgetRef ref) async {
    final created = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _GroupCreateSheet(),
    );
    if (created != null && created.isNotEmpty && context.mounted) {
      context.go('/chat/$created');
    }
  }

  Future<void> _startNewChat(BuildContext context, WidgetRef ref) async {
    final picked = await showModalBottomSheet<AppUser>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _UserSearchSheet(),
    );
    if (picked == null || !context.mounted) return;
    final id =
        await ref.read(conversationsProvider.notifier).startDirect(picked.id);
    if (context.mounted && id.isNotEmpty) context.go('/chat/$id');
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint();

  @override
  Widget build(BuildContext context) => const Center(
        child: Text('还没有会话，点击右下角 + 开始聊天'),
      );
}

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: onRetry, child: const Text('重试')),
            ],
          ),
        ),
      );
}

/// 底部弹出的用户搜索面板，选中后返回该用户。
class _UserSearchSheet extends ConsumerStatefulWidget {
  const _UserSearchSheet();

  @override
  ConsumerState<_UserSearchSheet> createState() => _UserSearchSheetState();
}

class _UserSearchSheetState extends ConsumerState<_UserSearchSheet> {
  final _q = TextEditingController();
  List<AppUser> _results = const [];
  bool _loading = false;

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final keyword = _q.text.trim();
    if (keyword.isEmpty) return;
    setState(() => _loading = true);
    try {
      final users =
          await ref.read(authRepositoryProvider).search(keyword);
      setState(() {
        _results = users;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SafeArea(
          child: SizedBox(
            height: 420,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _q,
                          onSubmitted: (_) => _search(),
                          decoration: const InputDecoration(
                            labelText: '搜索用户名',
                            isDense: true,
                          ),
                        ),
                      ),
                      IconButton(
                          onPressed: _search, icon: const Icon(Icons.search)),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          itemCount: _results.length,
                          itemBuilder: (context, i) {
                            final u = _results[i];
                            return ListTile(
                              leading: CircleAvatar(
                                  child: Text(u.displayName.characters.first)),
                              title: Text(u.displayName),
                              subtitle: Text('@${u.username}'),
                              onTap: () => Navigator.of(context).pop(u),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      );
}

/// 新建群聊：输入群名 + 多选成员，创建后返回会话 ID。
class _GroupCreateSheet extends ConsumerStatefulWidget {
  const _GroupCreateSheet();

  @override
  ConsumerState<_GroupCreateSheet> createState() => _GroupCreateSheetState();
}

class _GroupCreateSheetState extends ConsumerState<_GroupCreateSheet> {
  final _name = TextEditingController();
  final _q = TextEditingController();
  final Map<String, AppUser> _selected = <String, AppUser>{};
  List<AppUser> _results = const [];
  bool _loading = false;
  bool _creating = false;

  @override
  void dispose() {
    _name.dispose();
    _q.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final keyword = _q.text.trim();
    if (keyword.isEmpty) return;
    setState(() => _loading = true);
    try {
      final users = await ref.read(authRepositoryProvider).search(keyword);
      setState(() {
        _results = users;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _create() async {
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请至少选择一位成员')));
      return;
    }
    setState(() => _creating = true);
    try {
      final id = await ref.read(conversationsProvider.notifier).createGroup(
            _name.text.trim(),
            _selected.keys.toList(),
          );
      if (mounted) Navigator.of(context).pop(id);
    } catch (_) {
      setState(() => _creating = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('创建群聊失败')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SafeArea(
          child: SizedBox(
            height: 520,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: _name,
                    decoration: const InputDecoration(
                      labelText: '群名称',
                      isDense: true,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _q,
                          onSubmitted: (_) => _search(),
                          decoration: const InputDecoration(
                            labelText: '搜索用户名添加成员',
                            isDense: true,
                          ),
                        ),
                      ),
                      IconButton(
                          onPressed: _search, icon: const Icon(Icons.search)),
                    ],
                  ),
                ),
                if (_selected.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _selected.values
                          .map((u) => InputChip(
                                label: Text(u.displayName),
                                onDeleted: () =>
                                    setState(() => _selected.remove(u.id)),
                              ))
                          .toList(),
                    ),
                  ),
                const Divider(height: 1),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          itemCount: _results.length,
                          itemBuilder: (context, i) {
                            final u = _results[i];
                            final checked = _selected.containsKey(u.id);
                            return CheckboxListTile(
                              value: checked,
                              title: Text(u.displayName),
                              subtitle: Text('@${u.username}'),
                              controlAffinity: ListTileControlAffinity.leading,
                              onChanged: (v) => setState(() {
                                if (v ?? false) {
                                  _selected[u.id] = u;
                                } else {
                                  _selected.remove(u.id);
                                }
                              }),
                            );
                          },
                        ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: FilledButton(
                      onPressed: _creating ? null : _create,
                      child: Text(_creating ? '创建中…' : '创建群聊'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
