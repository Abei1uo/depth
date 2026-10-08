import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../chat/data/chat_repository.dart';
import '../application/session_controller.dart';

/// 个人资料页：展示当前用户，支持修改昵称与上传头像，并可退出登录。
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool _busy = false;

  void _toast(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _pickAvatar() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final x = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (x == null) return;
      final name = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final upload =
          await ref.read(chatRepositoryProvider).uploadMedia(File(x.path), name: name);
      final ok = await ref
          .read(sessionControllerProvider.notifier)
          .updateProfile(avatarUrl: upload.url);
      _toast(ok ? '头像已更新' : '头像更新失败');
    } catch (e) {
      _toast('操作失败：$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _editNickname(String current) async {
    final controller = TextEditingController(text: current);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('修改昵称'),
        content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 64,
            decoration: const InputDecoration(hintText: '昵称')),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(), child: const Text('取消')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
              child: const Text('保存')),
        ],
      ),
    );
    if (name == null) return;
    final ok = await ref
        .read(sessionControllerProvider.notifier)
        .updateProfile(nickname: name);
    _toast(ok ? '已保存' : '保存失败');
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(sessionControllerProvider.select((s) => s.user));
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('个人资料')),
      body: _busy
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                Center(
                  child: Stack(
                    children: [
                      user.avatarUrl.isNotEmpty
                          ? CircleAvatar(
                              radius: 48,
                              backgroundImage: NetworkImage(user.avatarUrl))
                          : CircleAvatar(
                              radius: 48,
                              child: Text(
                                user.displayName.characters.first,
                                style: const TextStyle(fontSize: 32),
                              )),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: InkWell(
                          onTap: _pickAvatar,
                          child: const CircleAvatar(
                            radius: 16,
                            child: Icon(Icons.photo_camera, size: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ListTile(
                  leading: const Icon(Icons.badge_outlined),
                  title: const Text('昵称'),
                  subtitle: Text(user.displayName.isEmpty ? '未设置' : user.displayName),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _editNickname(user.nickname),
                ),
                ListTile(
                  leading: const Icon(Icons.alternate_email),
                  title: const Text('用户名'),
                  subtitle: Text('@${user.username}'),
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('注册时间'),
                  subtitle: Text(user.createdAt.toLocal().toString().split(' ').first),
                ),
                const Divider(height: 32),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('退出登录',
                      style: TextStyle(color: Colors.red)),
                  onTap: () => ref.read(sessionControllerProvider.notifier).logout(),
                ),
              ],
            ),
    );
  }
}
