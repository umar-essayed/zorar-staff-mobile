import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:staff_mobile/features/onboarding/onboarding_screen.dart';
import 'package:staff_mobile/features/auth/auth_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('OnboardingScreen renders slides and skip button', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: OnboardingScreen(),
        ),
      ),
    );

    expect(find.text('زُرار كود (Zorar Code)'), findsOneWidget);
    expect(find.text('تخطي'), findsOneWidget);
    expect(find.text('التالي'), findsOneWidget);
  });

  testWidgets('AuthScreen renders login and register tabs', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: AuthScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('تسجيل الدخول'), findsAtLeastNWidgets(1));
    expect(find.text('إنشاء سنتر جديد'), findsOneWidget);
  });
}
