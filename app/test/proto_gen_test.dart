import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:depth_app/gen/pb/depth/v1/common.pb.dart';
import 'package:depth_app/gen/pb/depth/v1/message.pb.dart';

void main() {
  test('buf 生成的 Dart protobuf 可构造并序列化/反序列化', () {
    final content = MessageContent()
      ..type = MessageType.MESSAGE_TYPE_TEXT
      ..text = 'hello-proto';
    final msg = Message()
      ..serverMsgId = 'srv-1'
      ..conversationId = 'conv-1'
      ..senderId = 'user-1'
      ..seq = Int64(7)
      ..content = content;

    final bytes = msg.writeToBuffer();
    final back = Message.fromBuffer(bytes);

    expect(back.conversationId, 'conv-1');
    expect(back.seq, Int64(7));
    expect(back.content.text, 'hello-proto');
    expect(back.content.type, MessageType.MESSAGE_TYPE_TEXT);
  });
}
