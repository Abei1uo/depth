import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ws/ws_client.dart';
import '../ws/ws_envelope.dart';

/// 在线用户集合。全局监听 WebSocket 下行的 presence_update 事件维护。
class PresenceController extends Notifier<Set<String>> {
  StreamSubscription<WsEnvelope>? _sub;

  @override
  Set<String> build() {
    _sub?.cancel();
    final client = ref.read(wsClientProvider);
    _sub = client.incoming.listen((env) {
      if (env.type != WsEvents.presenceUpdate) return;
      final uid = env.payload['user_id'] as String?;
      if (uid == null || uid.isEmpty) return;
      final online = env.payload['online'] == true;
      final next = <String>{...state};
      if (online) {
        next.add(uid);
      } else {
        next.remove(uid);
      }
      state = next;
    });
    ref.onDispose(() => _sub?.cancel());
    return <String>{};
  }
}

final presenceProvider =
    NotifierProvider<PresenceController, Set<String>>(PresenceController.new);
