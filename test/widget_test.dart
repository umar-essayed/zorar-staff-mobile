import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:staff_mobile/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App smoke test loads successfully', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const ProviderScope(
        child: ZorarStaffApp(),
      ),
    );

    // Initial render verify
    expect(find.byType(ZorarStaffApp), findsOneWidget);

    // Drain timers from splash screen
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  });
}
