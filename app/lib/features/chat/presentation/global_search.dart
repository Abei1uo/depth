import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/message.dart';
import '../../../models/user.dart';
import '../../auth/data/auth_repository.dart';
import '../application/conversations_controller.dart';
import '../data/chat_repository.dart';

/// 全局搜索面板：同时检索用户与跨会话消息，点击进入对应会话。
class GlobalSearchSheet extends ConsumerStatefulWidget {
  const GlobalSearchSheet({super.key});

  @override
  ConsumerState<GlobalSearchSheet> createState() => _GlobalSearchSheetState();
}

class _GlobalSearchSheetState extends ConsumerState<GlobalSearchSheet> {
  final TextEditingController _ctl = TextEditingController();
  Timer? _debounce;
  List<AppUser> _users = <AppUser>[];
  List<ChatMessage> _msgs = <ChatMessage>[];
  bool _loading = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _ctl.dispose();
    super.dispose();
  }

  void _onQuery(String q) {
    _debounce?.cancel();
    if (q.trim().isEmpty) {
      setState(() {
        _users = <AppUser>[];
        _msgs = <ChatMessage>[];
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () => _search(q.trim()));
  }

  Future<void> _search(String q) async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait<dynamic>([
        ref.read(authRepositoryProvider).search(q),
        ref.read(chatRepositoryProvider).searchAll(q),
      ]);
      setState(() {
        _users = results[0] as List<AppUser>;
        _msgs = results[1] as List<ChatMessage>;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openWithUser(AppUser u) async {
    final id = await ref.read(conversationsProvider.notifier).startDirect(u.id);
    if (!mounted) return;
    Navigator.of(context).pop();
    if (id.isNotEmpty) context.go('/chat/$id');
  }

  void _openConversation(ChatMessage m) {
    Navigator.of(context).pop();
    context.go('/chat/${m.conversationId}');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom, left: 8, right: 8),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _ctl,
              autofocus: true,
              onChanged: _onQuery,
              decoration: const InputDecoration(
                  hintText: '搜索用户与消息…', prefixIcon: Icon(Icons.search)),
            ),
            if (_loading)
              const LinearProgressIndicator(minHeight: 2),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  if (_users.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.fromLTRB(12, 8, 12, 4),
                      child: Text('用户',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ..._users.map((u) => ListTile(
                        leading: u.avatarUrl.isNotEmpty
                            ? CircleAvatar(
                                backgroundImage: NetworkImage(u.avatarUrl))
                            : CircleAvatar(
                                child: Text(u.displayName.characters.first)),
                        title: Text(u.displayName),
                        subtitle: Text('@${u.username}'),
                        onTap: () => _openWithUser(u),
                      )),
                  if (_msgs.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.fromLTRB(12, 8, 12, 4),
                      child: Text('消息',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ..._msgs.map((m) => ListTile(
                        dense: true,
                        leading: const Icon(Icons.chat_bubble_outline),
                        title: Text(m.content.text.isEmpty ? '[消息]' : m.content.text,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(
                            '时间：${m.createdAt.toLocal().toString().substring(0, 16)}'),
                        onTap: () => _openConversation(m),
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
