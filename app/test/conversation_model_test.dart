import 'package:flutter_test/flutter_test.dart';

import 'package:depth_app/models/conversation.dart';

void main() {
  test('Conversation 解析群公告，缺省为空', () {
    final withAnn = Conversation.fromJson(<String, dynamic>{
      'id': 'c1',
      'type': 1,
      'name': '群A',
      'avatar_url': '',
      'owner_id': 'u1',
      'announcement': '本群每周一例会',
      'member_ids': <String>['u1', 'u2'],
    });
    expect(withAnn.isGroup, isTrue);
    expect(withAnn.announcement, '本群每周一例会');

    final without = Conversation.fromJson(<String, dynamic>{
      'id': 'c2',
      'type': 0,
      'name': '',
      'avatar_url': '',
      'owner_id': '',
    });
    expect(without.announcement, '');
    expect(without.isGroup, isFalse);
  });
}
