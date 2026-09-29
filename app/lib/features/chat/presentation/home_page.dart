import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/user.dart';
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
                    title: Text(c.name.isEmpty ? '会话 ${c.id.substring(0, 6)}' : c.name),
                    onTap: () => context.go('/chat/${c.id}'),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _startNewChat(context, ref),
        child: const Icon(Icons.add),
      ),
    );
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
