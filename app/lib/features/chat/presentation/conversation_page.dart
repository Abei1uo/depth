import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/presence/presence_controller.dart';
import '../../../core/ws/ws_client.dart';
import '../../../core/ws/ws_envelope.dart';
import '../../../models/conversation.dart';
import '../../../models/message.dart';
import '../../../models/user.dart';
import '../../auth/application/session_controller.dart';
import '../../auth/data/auth_repository.dart';
import '../application/conversations_controller.dart';
import '../data/chat_repository.dart';

/// 会话详情页：加载历史消息 + 通过 WebSocket 实时收发。
class ConversationPage extends ConsumerStatefulWidget {
  const ConversationPage({super.key, required this.conversationId});

  final String conversationId;

  @override
  ConsumerState<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends ConsumerState<ConversationPage> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _random = Random();

  final List<ChatMessage> _messages = <ChatMessage>[];
  bool _loading = true;
  bool _online = true;
  int _lastSeq = 0; // 本会话已知最大 seq，用于断线重连补拉
  int? _oldestSeq; // 已加载的最早 seq，用于向更早分页
  bool _loadingMore = false;
  bool _hasMore = true;
  bool _peerTyping = false; // 对方正在输入
  Timer? _typingStop; // 本地停止输入后下发 typing=false
  Timer? _typingExpire; // 远端 typing 自动过期
  DateTime? _lastTypingSent;
  ConversationDetail? _detail; // 会话详情（标题/成员/对方）
  String? _peerId; // 单聊对方用户 ID
  String? _error;
  StreamSubscription<WsEnvelope>? _wsSub;
  StreamSubscription<bool>? _statusSub;
  // 在 initState 捕获会话列表控制器，以便在 dispose 中安全刷新（避免用失效的 ref）。
  ConversationsController? _conversations;

  String get _meId => ref.read(sessionControllerProvider).user?.id ?? '';

  @override
  void initState() {
    super.initState();
    _conversations = ref.read(conversationsProvider.notifier);
    _loadHistory();
    _loadDetail();
    _scroll.addListener(_onScroll);
    final client = ref.read(wsClientProvider);
    _online = client.isConnected;
    _wsSub = client.incoming.listen(_onIncoming);
    _statusSub = client.status.listen((v) {
      if (!mounted) return;
      final wasOffline = !_online;
      setState(() => _online = v);
      // 由断线恢复到在线：按 last_seq 补拉。
      if (v && wasOffline && !_loading) _requestSync();
    });
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _wsSub?.cancel();
    _statusSub?.cancel();
    _input.dispose();
    _scroll.dispose();
    _typingStop?.cancel();
    _typingExpire?.cancel();
    // 离开会话后刷新列表，以同步已读后的未读数。
    _conversations?.reload();
    super.dispose();
  }

  // 接近列表顶部时触发加载更早消息。
  void _onScroll() {
    if (!_scroll.hasClients) return;
    if (_scroll.position.pixels <= 60 &&
        _hasMore &&
        !_loadingMore &&
        !_loading &&
        _oldestSeq != null) {
      _loadOlder();
    }
  }

  Future<void> _loadHistory() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list =
          await ref.read(chatRepositoryProvider).history(widget.conversationId);
      setState(() {
        _messages
          ..clear()
          ..addAll(list);
        _lastSeq = 0;
        _oldestSeq = null;
        for (final m in list) {
          if (m.seq <= 0) continue;
          if (m.seq > _lastSeq) _lastSeq = m.seq;
          if (_oldestSeq == null || m.seq < _oldestSeq!) _oldestSeq = m.seq;
        }
        _hasMore = list.length >= 30;
        _loading = false;
      });
      _scrollToBottom();
      _markRead();
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _error = '加载失败';
        _loading = false;
      });
    }
  }

  /// 加载当前最早一页之前的更早消息，前插到列表顶部。
  Future<void> _loadOlder() async {
    final before = _oldestSeq;
    if (before == null) return;
    setState(() => _loadingMore = true);
    try {
      final older = await ref
          .read(chatRepositoryProvider)
          .history(widget.conversationId, beforeSeq: before, limit: 30);
      setState(() {
        if (older.isEmpty) {
          _hasMore = false;
        } else {
          // 去重后前插（保持时间正序：更早 -> 当前顶部）。
          final existing = _messages
              .map((m) => m.serverMsgId)
              .where((id) => id.isNotEmpty)
              .toSet();
          final fresh = older
              .where((m) =>
                  m.serverMsgId.isEmpty || !existing.contains(m.serverMsgId))
              .toList();
          _messages.insertAll(0, fresh);
          for (final m in older) {
            if (m.seq > 0 && (_oldestSeq == null || m.seq < _oldestSeq!)) {
              _oldestSeq = m.seq;
            }
          }
          _hasMore = older.length >= 30;
        }
        _loadingMore = false;
      });
    } catch (_) {
      setState(() => _loadingMore = false);
    }
  }

  Future<void> _loadDetail() async {
    try {
      final d = await ref
          .read(chatRepositoryProvider)
          .detail(widget.conversationId);
      if (!mounted) return;
      setState(() {
        _detail = d;
        final peer = d.members.where((m) => m.userId != _meId).toList();
        _peerId = peer.isEmpty ? null : peer.first.userId;
      });
    } catch (_) {
      // 详情拉取失败不阻断聊天。
    }
  }

  String get _titleText {
    final d = _detail;
    if (d == null) return '会话';
    if (d.conversation.isGroup) {
      return d.conversation.name.isEmpty ? '群聊' : d.conversation.name;
    }
    final peers = d.members.where((m) => m.userId != _meId).toList();
    if (peers.isEmpty) return '聊天';
    final name = peers.first.displayName;
    return name.isEmpty ? '聊天' : name;
  }

  void _showMembers() {
    final d = _detail;
    if (d == null) return;
    final online = ref.read(presenceProvider);
    final isGroup = d.conversation.isGroup;
    final isOwner =
        d.members.any((m) => m.userId == _meId && m.role == 2);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('成员',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  if (isOwner && isGroup)
                    IconButton(
                      tooltip: '添加成员',
                      icon: const Icon(Icons.person_add_alt),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _addMember(d.conversation.id);
                      },
                    ),
                  if (isOwner && isGroup)
                    IconButton(
                      tooltip: '改名',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _renameGroup(d.conversation.id, d.conversation.name);
                      },
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  ...d.members.map(
                    (m) => ListTile(
                      leading: CircleAvatar(
                        child: Text(m.displayName.characters.first),
                      ),
                      title: Text(m.displayName),
                      subtitle: Text('@${m.username}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (online.contains(m.userId))
                            const Icon(Icons.circle,
                                size: 10, color: Colors.green),
                          if (m.role == 2)
                            const Padding(
                              padding: EdgeInsets.only(left: 6),
                              child: Chip(
                                  label: Text('群主'),
                                  visualDensity: VisualDensity.compact),
                            ),
                          if (isOwner && isGroup && m.userId != _meId && m.role != 2)
                            IconButton(
                              tooltip: '移出',
                              icon: const Icon(Icons.person_remove_alt_1),
                              onPressed: () {
                                Navigator.of(ctx).pop();
                                _removeMember(d.conversation.id, m);
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (isGroup)
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('退出群聊',
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _leaveGroup(d.conversation.id);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _renameGroup(String convId, String current) async {
    final controller = TextEditingController(text: current);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('修改群名称'),
        content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: '群名称')),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(), child: const Text('取消')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
              child: const Text('保存')),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      await ref.read(conversationsProvider.notifier).rename(convId, name);
      _loadDetail();
    }
  }

  Future<void> _removeMember(String convId, ChatMember m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text('确定将「${m.displayName}」移出群聊？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('取消')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('移出')),
        ],
      ),
    );
    if (ok == true) {
      await ref
          .read(conversationsProvider.notifier)
          .removeMember(convId, m.userId);
      _loadDetail();
    }
  }

  Future<void> _leaveGroup(String convId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: const Text('确定退出该群聊？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('取消')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('退出')),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(conversationsProvider.notifier).leave(convId);
      if (mounted) context.go('/');
    }
  }

  Future<void> _addMember(String convId) async {
    final picked = await showModalBottomSheet<AppUser>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _MemberPickerSheet(),
    );
    if (picked != null) {
      await ref
          .read(conversationsProvider.notifier)
          .addMembers(convId, [picked.id]);
      _loadDetail();
    }
  }

  void _onIncoming(WsEnvelope env) {
    switch (env.type) {
      case WsEvents.newMessage:
        final m = ChatMessage.fromJson(env.payload);
        if (m.conversationId != widget.conversationId) return;
        if (_appendMessage(m)) {
          if (m.seq > _lastSeq) _lastSeq = m.seq;
          _scrollToBottom();
          _markRead();
        }
        break;
      case WsEvents.msgAck:
        final ack = MessageAck.fromJson(env.payload);
        final idx =
            _messages.indexWhere((x) => x.clientMsgId == ack.clientMsgId);
        if (idx >= 0) {
          final old = _messages[idx];
          setState(() {
            _messages[idx] = ChatMessage(
              serverMsgId: ack.serverMsgId,
              clientMsgId: old.clientMsgId,
              conversationId: old.conversationId,
              senderId: old.senderId,
              seq: ack.seq,
              content: old.content,
              createdAt: old.createdAt,
            );
          });
          if (ack.seq > _lastSeq) _lastSeq = ack.seq;
        }
        break;
      case WsEvents.syncResult:
        final raw = env.payload['messages'];
        if (raw is! List) return;
        var appended = false;
        for (final item in raw) {
          if (item is! Map<String, dynamic>) continue;
          final m = ChatMessage.fromJson(item);
          if (m.conversationId != widget.conversationId) continue;
          if (_appendMessage(m)) {
            if (m.seq > _lastSeq) _lastSeq = m.seq;
            appended = true;
          }
        }
        if (appended) {
          _scrollToBottom();
          _markRead();
        }
        break;
      case WsEvents.typing:
        if (env.payload['conversation_id'] != widget.conversationId) break;
        if (env.payload['from_user_id'] == _meId) break;
        final on = env.payload['typing'] == true;
        setState(() => _peerTyping = on);
        _typingExpire?.cancel();
        if (on) {
          _typingExpire = Timer(const Duration(seconds: 6), () {
            if (mounted) setState(() => _peerTyping = false);
          });
        }
        break;
      default:
        break;
    }
  }

  /// 去重追加一条消息（按 server_msg_id）；返回是否新增。
  bool _appendMessage(ChatMessage m) {
    final dup = _messages.any((x) =>
        m.serverMsgId.isNotEmpty && x.serverMsgId == m.serverMsgId);
    if (dup) return false;
    setState(() => _messages.add(m));
    return true;
  }

  /// 断线重连后向服务端按 last_seq 补拉。
  void _requestSync() {
    ref.read(wsClientProvider).send(WsEnvelope(
          type: WsEvents.sync,
          payload: <String, dynamic>{
            'conversation_id': widget.conversationId,
            'last_seq': _lastSeq,
          },
        ));
  }

  /// 上报已读：将本会话已知最大 seq 作为已读游标（仅在在线时）。
  void _markRead() {
    if (_lastSeq <= 0 || !_online) return;
    ref.read(wsClientProvider).send(WsEnvelope(
          type: WsEvents.markRead,
          payload: <String, dynamic>{
            'conversation_id': widget.conversationId,
            'max_seq': _lastSeq,
          },
        ));
  }

  /// 输入变化时节流下发 typing=true，静默 4s 后下发 false。
  void _notifyTyping() {
    final now = DateTime.now();
    if (_lastTypingSent == null ||
        now.difference(_lastTypingSent!) > const Duration(seconds: 2)) {
      _lastTypingSent = now;
      _sendTyping(true);
    }
    _typingStop?.cancel();
    _typingStop = Timer(const Duration(seconds: 4), () => _sendTyping(false));
  }

  void _sendTyping(bool on) {
    if (!_online) return;
    ref.read(wsClientProvider).send(WsEnvelope(
          type: WsEvents.typing,
          payload: <String, dynamic>{
            'conversation_id': widget.conversationId,
            'typing': on,
          },
        ));
  }

  void _send() {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    _input.clear();
    _sendContent(MessageContent.text(text));
  }

  /// 发送一条内容（文本或媒体）：走 WS + 本地乐观上屏。
  void _sendContent(MessageContent content) {
    final clientMsgId = _genClientMsgId();

    ref.read(wsClientProvider).send(WsEnvelope(
          type: WsEvents.sendMessage,
          payload: <String, dynamic>{
            'client_msg_id': clientMsgId,
            'conversation_id': widget.conversationId,
            'content': content.toJson(),
          },
        ));

    // 乐观发送：本地先上屏，收到 msg_ack 后补全 server_msg_id / seq。
    final optimistic = ChatMessage(
      serverMsgId: '',
      clientMsgId: clientMsgId,
      conversationId: widget.conversationId,
      senderId: _meId,
      seq: 0,
      content: content,
      createdAt: DateTime.now(),
    );
    setState(() => _messages.add(optimistic));
    _scrollToBottom();
  }

  /// 选择图片/文件：上传到对象存储拿 url，再以媒体消息发送。
  Future<void> _pickAttachment() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: const Text('发送图片'),
              onTap: () => Navigator.of(ctx).pop('image'),
            ),
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: const Text('发送文件'),
              onTap: () => Navigator.of(ctx).pop('file'),
            ),
          ],
        ),
      ),
    );
    if (choice == null) return;
    try {
      if (choice == 'image') {
        final x = await ImagePicker().pickImage(source: ImageSource.gallery);
        if (x == null) return;
        await _uploadAndSend(File(x.path), type: MessageType.image);
      } else {
        final files = await FilePicker.pickFiles();
        if (files.isEmpty) return;
        final f = files.first;
        final path = f.path;
        if (path == null) return;
        await _uploadAndSend(File(path), type: MessageType.file, name: f.name);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('发送失败：$e')));
      }
    }
  }

  Future<void> _uploadAndSend(File file,
      {required int type, String? name}) async {
    final repo = ref.read(chatRepositoryProvider);
    final upload = await repo.uploadMedia(file, name: name);
    if (!mounted) return;
    _sendContent(MessageContent(
      type: type,
      mediaUrl: upload.url,
      size: upload.size,
    ));
  }

  String _genClientMsgId() =>
      '${DateTime.now().microsecondsSinceEpoch}-${_random.nextInt(0x7fffffff)}';

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final peerOnline =
        _peerId != null && ref.watch(presenceProvider).contains(_peerId);
    return Scaffold(
      appBar: AppBar(
        title: Text(_titleText),
        actions: [
          if (_peerId != null)
            IconButton(
              tooltip: peerOnline ? '对方在线' : '对方离线',
              icon: Icon(
                peerOnline ? Icons.circle : Icons.circle_outlined,
                color: peerOnline ? Colors.green : Colors.grey,
                size: 16,
              ),
              onPressed: null,
            ),
          IconButton(
            tooltip: '成员',
            icon: const Icon(Icons.people_outline),
            onPressed: _detail == null ? null : _showMembers,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      FilledButton(
                          onPressed: _loadHistory, child: const Text('重试')),
                    ],
                  ),
                )
              : Column(
                  children: [
                    if (!_online) const _OfflineBanner(),
                    Expanded(
                      child: _messages.isEmpty
                          ? const _EmptyMessages()
                          : ListView.builder(
                              controller: _scroll,
                              padding: const EdgeInsets.all(12),
                              itemCount: _messages.length + 1,
                              itemBuilder: (context, i) {
                                if (i == 0) {
                                  return _loadingMore
                                      ? const Padding(
                                          padding: EdgeInsets.symmetric(
                                              vertical: 8),
                                          child: Center(
                                            child: SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2),
                                            ),
                                          ),
                                        )
                                      : const SizedBox(height: 8);
                                }
                                final m = _messages[i - 1];
                                return _Bubble(
                                    message: m, isMe: m.senderId == _meId);
                              },
                            ),
                    ),
                    if (_peerTyping)
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(16, 0, 16, 4),
                          child: Text('对方正在输入…',
                              style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    _InputBar(
                        controller: _input,
                        onSend: _send,
                        onChanged: _notifyTyping,
                        onAttach: _pickAttachment),
                  ],
                ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.isMe});

  final ChatMessage message;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final align = isMe ? TextAlign.right : TextAlign.left;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: isMe ? scheme.primaryContainer : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            _messageBody(context, message.content, align),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_formatTime(message.createdAt),
                    style: Theme.of(context).textTheme.labelSmall),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.serverMsgId.isEmpty
                        ? Icons.schedule
                        : Icons.check_circle_outline,
                    size: 12,
                    color: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.color,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar(
      {required this.controller,
      required this.onSend,
      this.onChanged,
      this.onAttach});

  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback? onChanged;
  final VoidCallback? onAttach;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            if (onAttach != null)
              IconButton(
                  onPressed: onAttach,
                  icon: const Icon(Icons.add_circle_outline)),
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onChanged: (_) => onChanged?.call(),
                onSubmitted: (_) => onSend(),
                decoration: const InputDecoration(
                  hintText: '输入消息…',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
                onPressed: onSend, icon: const Icon(Icons.send)),
          ],
        ),
      ),
    );
  }
}

/// 断线重连横幅：WebSocket 断开时显示于消息区顶部。
class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.errorContainer,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.cloud_off, size: 18, color: scheme.onErrorContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '连接已断开，正在重试…',
                  style: TextStyle(color: scheme.onErrorContainer),
                ),
              ),
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: scheme.onErrorContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 会话内无消息时的空态提示。
class _EmptyMessages extends StatelessWidget {
  const _EmptyMessages();

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline,
                size: 40, color: Theme.of(context).disabledColor),
            const SizedBox(height: 12),
            Text('还没有消息，发一条打个招呼吧',
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      );
}

/// 根据消息类型渲染气泡主体（文本/图片/文件/语音）。
Widget _messageBody(BuildContext context, MessageContent c, TextAlign align) {
  switch (c.type) {
    case MessageType.image:
      if (c.mediaUrl.isEmpty) {
        return Text('[图片上传中…]', textAlign: align);
      }
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          c.mediaUrl,
          width: 200,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const Text('图片加载失败'),
          loadingBuilder: (_, child, progress) => progress == null
              ? child
              : const SizedBox(
                  width: 200,
                  height: 120,
                  child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2)),
                ),
        ),
      );
    case MessageType.file:
      final name = c.mediaUrl.split('/').last;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.insert_drive_file_outlined, size: 22),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Text(
              name.isEmpty ? '文件' : name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: align,
            ),
          ),
        ],
      );
    case MessageType.voice:
      return const Text('[语音]（未实现）');
    default:
      return Text(c.text.isEmpty ? '[消息]' : c.text, textAlign: align);
  }
}

/// 将时间格式化为 HH:mm（24 小时制）。
String _formatTime(DateTime t) {
  final local = t.toLocal();
  final hh = local.hour.toString().padLeft(2, '0');
  final mm = local.minute.toString().padLeft(2, '0');
  return '$hh:$mm';
}

/// 搜索用户并选中一人（用于加成员），选中后返回该用户。
class _MemberPickerSheet extends ConsumerStatefulWidget {
  const _MemberPickerSheet();

  @override
  ConsumerState<_MemberPickerSheet> createState() => _MemberPickerSheetState();
}

class _MemberPickerSheetState extends ConsumerState<_MemberPickerSheet> {
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
      final users = await ref.read(authRepositoryProvider).search(keyword);
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
            bottom: MediaQuery.of(context).viewInsets.bottom),
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
                          autofocus: true,
                          onSubmitted: (_) => _search(),
                          decoration: const InputDecoration(
                            labelText: '搜索用户名添加',
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
