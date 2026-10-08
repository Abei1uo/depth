import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:depth_app/core/utils/draft_store.dart';

void main() {
  test('DraftStore save/load/clear 往返', () async {
    final dir = await Directory.systemTemp.createTemp('draft_test');
    final store = DraftStore(dir);
    expect(await store.load('conv1'), '');

    await store.save('conv1', '你好 草稿');
    expect(await store.load('conv1'), '你好 草稿');

    await store.clear('conv1');
    expect(await store.load('conv1'), '');

    await dir.delete(recursive: true);
  });

  test('DraftStore save 空串等同清除', () async {
    final dir = await Directory.systemTemp.createTemp('draft_test2');
    final store = DraftStore(dir);
    await store.save('c', 'x');
    await store.save('c', '');
    expect(await store.load('c'), '');
    await dir.delete(recursive: true);
  });

  test('DraftStore 不同会话互不干扰', () async {
    final dir = await Directory.systemTemp.createTemp('draft_test3');
    final store = DraftStore(dir);
    await store.save('a', 'A文本');
    await store.save('b', 'B文本');
    expect(await store.load('a'), 'A文本');
    expect(await store.load('b'), 'B文本');
    await dir.delete(recursive: true);
  });
}
