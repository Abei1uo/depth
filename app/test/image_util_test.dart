import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:depth_app/core/utils/image_util.dart';

void main() {
  test('compressImageBytes 等比缩小到最长边以内并输出 JPEG', () {
    // 造一张 200x100 的原图并编码为 PNG 作为输入。
    final original = img.Image(width: 200, height: 100);
    final png = img.encodePng(original);

    final out = compressImageBytes(Uint8List.fromList(png), maxDim: 50);
    expect(out, isNotNull);

    final decoded = img.decodeImage(out!);
    expect(decoded, isNotNull);
    final longest =
        decoded!.width > decoded.height ? decoded.width : decoded.height;
    expect(longest, lessThanOrEqualTo(50));
    // 等比缩放：宽高比约为 2:1。
    expect(decoded.width / decoded.height, closeTo(2.0, 0.2));
  });

  test('compressImageBytes 小于阈值时不改尺寸（仍重编码）', () {
    final original = img.Image(width: 40, height: 20);
    final png = img.encodePng(original);

    final out = compressImageBytes(Uint8List.fromList(png), maxDim: 1280);
    expect(out, isNotNull);
    final decoded = img.decodeImage(out!);
    expect(decoded!.width, 40);
    expect(decoded.height, 20);
  });

  test('compressImageBytes 对非法字节返回 null', () {
    expect(compressImageBytes(Uint8List.fromList([1, 2, 3, 4])), isNull);
  });
}
