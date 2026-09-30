import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'features/auth/application/session_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final container = ProviderContainer();
  // 先恢复会话（读安全存储 + 拉 /users/me），再启动 UI，避免登录页闪现。
  await container.read(sessionControllerProvider.notifier).bootstrap();
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const DepthApp(),
    ),
  );
}
