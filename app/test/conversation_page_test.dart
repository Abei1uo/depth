import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:depth_app/core/api/api_client.dart';
import 'package:depth_app/core/storage/token_store.dart';
import 'package:depth_app/core/ws/ws_client.dart';
import 'package:depth_app/core/ws/ws_envelope.dart';
import 'package:depth_app/features/chat/data/chat_repository.dart';
import 'package:depth_app/features/chat/presentation/conversation_page.dart';
import 'package:depth_app/models/conversation.dart';
import 'package:depth_app/models/message.dart';

const _convId = 'conv-1';
const _peerId = 'peer-1';

/// 受控的假 WebSocket：记录上行、可注入下行与连接状态。
class FakeWsClient extends WsClient {
  final StreamController<WsEnvelope> _incoming =
      StreamController<WsEnvelope>.broadcast();
  final StreamController<bool> _status = StreamController<bool>.broadcast();
  final List<WsEnvelope> sent = <WsEnvelope>[];
  bool _connected = true;

  @override
  bool get isConnected => _connected;
  @override
  Stream<WsEnvelope> get incoming => _incoming.stream;
  @override
  Stream<bool> get status => _status.stream;

  @override
  void connect(String url, String token) {}

  @override
  void send(WsEnvelope envelope) => sent.add(envelope);

  @override
  void close() {}

  @override
  void dispose() {
    _incoming.close();
    _status.close();
  }

  void emit(WsEnvelope envelope) => _incoming.add(envelope);

  void emitStatus(bool value) {
    _connected = value;
    _status.add(value);
  }

  WsEnvelope? firstOfType(String type) {
    for (final e in sent) {
      if (e.type == type) return e;
    }
    return null;
  }
}

/// 假数据源：历史/详情/列表均可控，避免真实网络。
class FakeChatRepository extends ChatRepository {
  FakeChatRepository() : super(ApiClient(TokenStore()));

  List<ChatMessage> historyResult = <ChatMessage>[];

  @override
  Future<List<ChatMessage>> history(
    String conversationId, {
    int? beforeSeq,
    int limit = 30,
  }) async =>
      historyResult;

  @override
  Future<ConversationDetail> detail(String conversationId) async =>
      ConversationDetail(
        conversation: const Conversation(
          id: _convId,
          type: 0,
          name: '',
          avatarUrl: '',
          ownerId: '',
          memberIds: [_peerId],
        ),
        members: const [
          ChatMember(
              userId: _peerId,
              username: 'peer',
              nickname: 'Peer',
              avatarUrl: '',
              role: 0),
        ],
      );

  @override
  Future<List<Conversation>> listConversations() async => const [];
}

Widget _wrap(FakeWsClient ws, FakeChatRepository repo) => ProviderScope(
      overrides: [
        wsClientProvider.overrideWithValue(ws),
        chatRepositoryProvider.overrideWithValue(repo),
      ],
      child: const MaterialApp(home: ConversationPage(conversationId: _convId)),
    );

ChatMessage _msg(String serverId, String text, int seq, {String? sender}) =>
    ChatMessage(
      serverMsgId: serverId,
      clientMsgId: '',
      conversationId: _convId,
      senderId: sender ?? _peerId,
      seq: seq,
      content: MessageContent.text(text),
      createdAt: DateTime(2024),
    );

Map<String, dynamic> _msgJson(String serverId, String text, int seq,
        {String? sender}) =>
    <String, dynamic>{
      'server_msg_id': serverId,
      'client_msg_id': '',
      'conversation_id': _convId,
      'sender_id': sender ?? _peerId,
      'seq': seq,
      'content': <String, dynamic>{'type': 0, 'text': text},
      'timestamp': DateTime(2024).toIso8601String(),
    };

Future<void> _settle(WidgetTester tester) async {
  // 首帧含加载态 spinner，不能用 pumpAndSettle；分帧推进即可。
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  testWidgets('乐观上屏后收到 msg_ack 替换为已送达', (tester) async {
    final ws = FakeWsClient();
    final repo = FakeChatRepository();
    await tester.pumpWidget(_wrap(ws, repo));
    await _settle(tester);

    await tester.enterText(find.byType(TextField), 'hello');
    await tester.tap(find.byIcon(Icons.send));
    await _settle(tester);

    // 乐观气泡（server_msg_id 为空 -> 时钟图标）。
    expect(find.text('hello'), findsOneWidget);
    expect(find.byIcon(Icons.schedule), findsOneWidget);

    final env = ws.firstOfType(WsEvents.sendMessage);
    expect(env, isNotNull);
    final cid = env!.payload['client_msg_id'] as String;

    ws.emit(WsEnvelope(type: WsEvents.msgAck, payload: <String, dynamic>{
      'client_msg_id': cid,
      'server_msg_id': 'srv-1',
      'seq': 1,
      'timestamp': 0,
    }));
    await _settle(tester);

    // ack 后补全 server_msg_id -> 对勾图标，仍只有一条 hello。
    expect(find.text('hello'), findsOneWidget);
    expect(find.byIcon(Icons.schedule), findsNothing);
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
  });

  testWidgets('new_message 按 server_msg_id 去重追加', (tester) async {
    final ws = FakeWsClient();
    final repo = FakeChatRepository();
    await tester.pumpWidget(_wrap(ws, repo));
    await _settle(tester);

    final m = _msg('dup-1', 'world', 5);
    ws.emit(WsEnvelope(type: WsEvents.newMessage, payload: <String, dynamic>{
      'server_msg_id': 'dup-1',
      'client_msg_id': '',
      'conversation_id': _convId,
      'sender_id': _peerId,
      'seq': 5,
      'content': <String, dynamic>{'type': 0, 'text': 'world'},
      'timestamp': DateTime(2024).toIso8601String(),
    }));
    await _settle(tester);
    expect(find.text('world'), findsOneWidget);

    // 再次推送同 server_msg_id，应被去重。
    ws.emit(WsEnvelope(type: WsEvents.newMessage, payload: <String, dynamic>{
      'server_msg_id': 'dup-1',
      'conversation_id': _convId,
      'sender_id': _peerId,
      'seq': 5,
      'content': <String, dynamic>{'type': 0, 'text': 'world'},
      'timestamp': DateTime(2024).toIso8601String(),
    }));
    await _settle(tester);
    expect(find.text('world'), findsOneWidget);
    expect(m.serverMsgId, 'dup-1');
  });

  testWidgets('断线重连触发 sync 并合并 sync_result', (tester) async {
    final ws = FakeWsClient();
    final repo = FakeChatRepository(
      // historyResult 保留一条 seq=10，用于断言 sync 携带 last_seq。
    );
    repo.historyResult = [_msg('h-1', 'seed', 10)];
    await tester.pumpWidget(_wrap(ws, repo));
    await _settle(tester);

    // 离线 -> 在线，应发出 sync（last_seq 为已知最大值 10）。
    ws.emitStatus(false);
    await _settle(tester);
    ws.emitStatus(true);
    await _settle(tester);

    final sync = ws.firstOfType(WsEvents.sync);
    expect(sync, isNotNull);
    expect(sync!.payload['conversation_id'], _convId);
    expect(sync.payload['last_seq'], 10);

    // sync_result 合并：新消息追加，已有的 seed 去重。
    ws.emit(WsEnvelope(type: WsEvents.syncResult, payload: <String, dynamic>{
      'messages': <Map<String, dynamic>>[
        _msgJson('h-1', 'seed', 10),
        _msgJson('h-2', 'caught-up', 11),
      ],
    }));
    await _settle(tester);
    expect(find.text('caught-up'), findsOneWidget);
    expect(find.text('seed'), findsOneWidget);
  });

  testWidgets('语音消息渲染播放按钮与时长', (tester) async {
    final ws = FakeWsClient();
    final repo = FakeChatRepository();
    repo.historyResult = [
      ChatMessage(
        serverMsgId: 'v-1',
        clientMsgId: '',
        conversationId: _convId,
        senderId: _peerId,
        seq: 3,
        content: const MessageContent(
          type: MessageType.voice,
          mediaUrl: 'http://localhost:8080/api/v1/media/v-1',
          duration: 7,
        ),
        createdAt: DateTime(2024),
      ),
    ];
    await tester.pumpWidget(_wrap(ws, repo));
    await _settle(tester);

    expect(find.byIcon(Icons.play_circle_outline), findsOneWidget);
    expect(find.text('00:07'), findsOneWidget);
  });

  testWidgets('长按菜单含转发/删除(仅我)，删除后本地移除并下发', (tester) async {
    final ws = FakeWsClient();
    final repo = FakeChatRepository();
    repo.historyResult = [_msg('m1', 'hello', 1)];
    await tester.pumpWidget(_wrap(ws, repo));
    await _settle(tester);

    await tester.longPress(find.text('hello'));
    await tester.pumpAndSettle();

    expect(find.text('转发'), findsOneWidget);
    expect(find.text('删除(仅我)'), findsOneWidget);

    await tester.tap(find.text('删除(仅我)'));
    await tester.pumpAndSettle();

    final env = ws.firstOfType(WsEvents.deleteMessage);
    expect(env, isNotNull);
    expect(env!.payload['server_msg_id'], 'm1');
    expect(find.text('hello'), findsNothing);
  });

  testWidgets('发送超时未 ack 标记失败并可点击重发', (tester) async {
    final ws = FakeWsClient();
    final repo = FakeChatRepository();
    await tester.pumpWidget(_wrap(ws, repo));
    await _settle(tester);

    await tester.enterText(find.byType(TextField), 'will-fail');
    await tester.tap(find.byIcon(Icons.send));
    await _settle(tester);
    expect(find.byIcon(Icons.schedule), findsOneWidget);

    // 推进超过 15s 发送超时→失败图标。
    await tester.pump(const Duration(seconds: 16));
    expect(find.byIcon(Icons.error_outline), findsOneWidget);

    // 点击失败气泡重发。
    final before =
        ws.sent.where((e) => e.type == WsEvents.sendMessage).length;
    await tester.tap(find.text('will-fail'));
    await _settle(tester);
    final after = ws.sent.where((e) => e.type == WsEvents.sendMessage).length;
    expect(after, greaterThan(before));
  });

  test('computeUnreadAnchor 定位最早未读', () {
    ChatMessage m(String id, String sender) => ChatMessage(
          serverMsgId: id,
          clientMsgId: '',
          conversationId: _convId,
          senderId: sender,
          seq: 1,
          content: MessageContent.text('t'),
          createdAt: DateTime(2024),
        );
    final list = [m('s1', 'peer'), m('s2', 'me'), m('s3', 'peer'), m('s4', 'peer')];
    expect(computeUnreadAnchor(list, 0, 'me'), isNull);
    expect(computeUnreadAnchor(list, 2, 'me'), 's3');
    expect(computeUnreadAnchor(list, 3, 'me'), 's1');
  });

  testWidgets('系统消息居中渲染', (tester) async {
    final ws = FakeWsClient();
    final repo = FakeChatRepository();
    repo.historyResult = [
      ChatMessage(
        serverMsgId: 's1',
        clientMsgId: '',
        conversationId: _convId,
        senderId: _peerId,
        seq: 1,
        content: const MessageContent(
            type: MessageType.system, text: '「张三」加入了群聊'),
        createdAt: DateTime(2024),
      ),
    ];
    await tester.pumpWidget(_wrap(ws, repo));
    await _settle(tester);
    expect(find.text('「张三」加入了群聊'), findsOneWidget);
  });

  testWidgets('表情回应在气泡下方显示计数', (tester) async {
    final ws = FakeWsClient();
    final repo = FakeChatRepository();
    repo.historyResult = [
      ChatMessage(
        serverMsgId: 's2',
        clientMsgId: '',
        conversationId: _convId,
        senderId: _peerId,
        seq: 2,
        content: const MessageContent(type: MessageType.text, text: 'hi',
            reactions: {'👍': ['u1', 'u2']}),
        createdAt: DateTime(2024),
      ),
    ];
    await tester.pumpWidget(_wrap(ws, repo));
    await _settle(tester);
    expect(find.text('👍 2'), findsOneWidget);
  });
}
