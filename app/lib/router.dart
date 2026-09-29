import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/auth/application/session_controller.dart';
import 'features/auth/presentation/login_page.dart';
import 'features/auth/presentation/register_page.dart';
import 'features/chat/presentation/conversation_page.dart';
import 'features/chat/presentation/home_page.dart';

/// 基于会话状态的路由守卫：未认证仅可访问 /login、/register；
/// 已认证时自动离开这两个页面。会话变化通过 refreshListenable 触发重算。
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref
    ..onDispose(refresh.dispose)
    ..listen(sessionControllerProvider, (_, _) => refresh.value++);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: refresh,
    redirect: (context, state) {
      final authed = ref.read(sessionControllerProvider).isAuthenticated;
      final loc = state.matchedLocation;
      final isPublic = loc == '/login' || loc == '/register';
      if (!authed && !isPublic) return '/login';
      if (authed && isPublic) return '/';
      return null;
    },
    routes: <RouteBase>[
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterPage()),
      GoRoute(path: '/', builder: (context, state) => const HomePage()),
      GoRoute(
        path: '/chat/:id',
        builder: (context, state) => ConversationPage(
          conversationId: state.pathParameters['id']!,
        ),
      ),
    ],
  );
});
