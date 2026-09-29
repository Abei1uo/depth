import 'package:depth_app/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('未登录时展示登录页', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: DepthApp()));
    await tester.pumpAndSettle();
    expect(find.text('Depth'), findsOneWidget);
    expect(find.text('登录'), findsOneWidget);
  });
}
