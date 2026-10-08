import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// 上传前压缩：按最长边不超过 [maxDim] 等比缩放，并以 JPEG [quality] 重编码。
/// 解码失败返回 null（调用方回退到原图）。纯 Dart，可在单元测试中验证。
Uint8List? compressImageBytes(
  Uint8List src, {
  int maxDim = 1280,
  int quality = 82,
}) {
  try {
    final img.Image? decoded = img.decodeImage(src);
    if (decoded == null) return null;

    final longest =
        decoded.width > decoded.height ? decoded.width : decoded.height;
    img.Image out = decoded;
    if (longest > maxDim) {
      final scale = maxDim / longest;
      var w = (decoded.width * scale).round();
      var h = (decoded.height * scale).round();
      if (w < 1) w = 1;
      if (h < 1) h = 1;
      out = img.copyResize(decoded, width: w, height: h);
    }
    return img.encodeJpg(out, quality: quality);
  } catch (_) {
    // 解码/编码失败（非法字节等）交由调用方回退到原图。
    return null;
  }
}
