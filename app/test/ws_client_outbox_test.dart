import 'package:flutter_test/flutter_test.dart';

import 'package:depth_app/core/ws/ws_client.dart';
import 'package:depth_app/core/ws/ws_envelope.dart';

WsEnvelope _env(String id) => WsEnvelope(
      type: WsEvents.sendMessage,
      payload: <String, dynamic>{'client_msg_id': id},
    );

void main() {
  // 不 connect，_channel 为 null，send 应进入离线待发队列。
  test('未连接时 send 入队而非丢弃', () {
    final c = WsClient();
    expect(c.pendingOutbox, 0);
    c.send(_env('a'));
    c.send(_env('b'));
    expect(c.pendingOutbox, 2);
    c.dispose();
  });

  test('待发队列超过上限丢弃最旧，长度封顶 200', () {
    final c = WsClient();
    for (var i = 0; i < 250; i++) {
      c.send(_env('m$i'));
    }
    expect(c.pendingOutbox, 200);
    c.dispose();
  });

  test('close 清空待发队列', () {
    final c = WsClient();
    c.send(_env('a'));
    expect(c.pendingOutbox, 1);
    c.close();
    expect(c.pendingOutbox, 0);
    c.dispose();
  });
}
