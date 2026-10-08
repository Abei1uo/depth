import 'dart:io';

/// 会话草稿持久化：按 conversationId 存为目录下的文本文件。
/// 目录可注入，便于用临时目录做单元测试；所有 IO 失败均静默（草稿属尽力而为）。
class DraftStore {
  DraftStore(this._dir);

  final Directory _dir;

  File _file(String conversationId) => File(
      '${_dir.path}${Platform.pathSeparator}draft_${_sanitize(conversationId)}.txt');

  String _sanitize(String s) => s.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');

  /// 写入草稿；text 为空则删除对应文件。
  Future<void> save(String conversationId, String text) async {
    try {
      final f = _file(conversationId);
      if (text.isEmpty) {
        if (await f.exists()) await f.delete();
        return;
      }
      await f.writeAsString(text);
    } catch (_) {
      // 忽略：草稿保存失败不影响主流程。
    }
  }

  /// 读取草稿；不存在或异常返回空串。
  Future<String> load(String conversationId) async {
    try {
      final f = _file(conversationId);
      if (await f.exists()) return await f.readAsString();
    } catch (_) {
      // 忽略。
    }
    return '';
  }

  /// 清除草稿。
  Future<void> clear(String conversationId) => save(conversationId, '');
}
