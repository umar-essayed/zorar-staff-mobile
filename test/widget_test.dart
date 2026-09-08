import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:staff_mobile/main.dart';

void main() {
  testWidgets('App smoke test loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: ZorarStaffApp(),
      ),
    );

    // Initial render verify
    expect(find.byType(ZorarStaffApp), findsOneWidget);
  });
}
