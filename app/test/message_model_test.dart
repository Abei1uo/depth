import 'package:depth_app/models/message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('消息增强模型', () {
    test('MessageContent 透传 reply_to 与 mentions', () {
      const c = MessageContent(
        type: MessageType.text,
        text: 'hi @bob',
        replyTo: ReplyInfo(msgId: 'm1', senderId: 's1', text: 'quoted'),
        mentions: ['u1', 'u2'],
      );
      final json = c.toJson();
      expect(json['reply_to'], isA<Map<String, dynamic>>());
      expect((json['reply_to'] as Map)['msg_id'], 'm1');
      expect(json['mentions'], ['u1', 'u2']);

      final back = MessageContent.fromJson(json);
      expect(back.replyTo?.senderId, 's1');
      expect(back.replyTo?.text, 'quoted');
      expect(back.mentions, ['u1', 'u2']);
    });

    test('空 reply/mentions 不出现在 JSON 中', () {
      const c = MessageContent(type: MessageType.text, text: 'plain');
      final json = c.toJson();
      expect(json.containsKey('reply_to'), isFalse);
      expect(json.containsKey('mentions'), isFalse);
    });

    test('ChatMessage 解析 recalled 标记', () {
      final m = ChatMessage.fromJson(<String, dynamic>{
        'server_msg_id': 'x',
        'conversation_id': 'c',
        'sender_id': 's',
        'seq': 7,
        'recalled': true,
        'content': <String, dynamic>{'type': 0},
      });
      expect(m.recalled, isTrue);
      expect(m.content.type, MessageType.text);
    });
  });
}
