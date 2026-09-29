import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/ws/ws_client.dart';
import '../../../core/ws/ws_envelope.dart';
import '../../../models/message.dart';
import '../../auth/application/session_controller.dart';
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
  String? _error;
  StreamSubscription<WsEnvelope>? _wsSub;
  StreamSubscription<bool>? _statusSub;

  String get _meId => ref.read(sessionControllerProvider).user?.id ?? '';

  @override
  void initState() {
    super.initState();
    _loadHistory();
    final client = ref.read(wsClientProvider);
    _online = client.isConnected;
    _wsSub = client.incoming.listen(_onIncoming);
    _statusSub = client.status.listen((v) {
      if (mounted) setState(() => _online = v);
    });
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    _statusSub?.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
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
        _loading = false;
      });
      _scrollToBottom();
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

  void _onIncoming(WsEnvelope env) {
    switch (env.type) {
      case WsEvents.newMessage:
        final m = ChatMessage.fromJson(env.payload);
        if (m.conversationId != widget.conversationId) return;
        final dup = _messages.any((x) =>
            m.serverMsgId.isNotEmpty && x.serverMsgId == m.serverMsgId);
        if (dup) return;
        setState(() => _messages.add(m));
        _scrollToBottom();
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
        }
        break;
      default:
        break;
    }
  }

  void _send() {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    final clientMsgId = _genClientMsgId();
    final content = MessageContent.text(text);

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
    setState(() {
      _messages.add(optimistic);
      _input.clear();
    });
    _scrollToBottom();
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
    return Scaffold(
      appBar: AppBar(title: const Text('会话')),
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
                              itemCount: _messages.length,
                              itemBuilder: (context, i) => _Bubble(
                                  message: _messages[i],
                                  isMe: _messages[i].senderId == _meId),
                            ),
                    ),
                    _InputBar(controller: _input, onSend: _send),
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
            Text(message.content.text.isEmpty ? '[非文本消息]' : message.content.text,
                textAlign: align),
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
  const _InputBar({required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
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

/// 将时间格式化为 HH:mm（24 小时制）。
String _formatTime(DateTime t) {
  final local = t.toLocal();
  final hh = local.hour.toString().padLeft(2, '0');
  final mm = local.minute.toString().padLeft(2, '0');
  return '$hh:$mm';
}
