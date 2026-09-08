import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:staff_mobile/features/onboarding/onboarding_screen.dart';
import 'package:staff_mobile/features/auth/auth_screen.dart';
import 'package:staff_mobile/features/admissions/student_admission_public_screen.dart';

void main() {
  testWidgets('OnboardingScreen renders slides and skip button', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: OnboardingScreen(),
        ),
      ),
    );

    expect(find.text('زُرار برو (Zorar Pro)'), findsOneWidget);
    expect(find.text('تخطي'), findsOneWidget);
    expect(find.text('التالي'), findsOneWidget);
  });

  testWidgets('AuthScreen renders login and register tabs', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: AuthScreen(),
        ),
      ),
    );

    expect(find.text('تسجيل الدخول'), findsAtLeastNWidgets(1));
    expect(find.text('إنشاء سنتر جديد'), findsOneWidget);
    expect(find.text('دخول إلى النظام'), findsOneWidget);
  });

  testWidgets('StudentAdmissionPublicScreen renders form fields and submit button', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: StudentAdmissionPublicScreen(),
        ),
      ),
    );

    expect(find.text('استمارة الحجز والتقديم الإلكتروني'), findsOneWidget);
    expect(find.text('إرسال طلب الحجز'), findsOneWidget);
  });
}
