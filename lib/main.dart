import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/branding_provider.dart';
import 'features/navigation/main_shell_screen.dart';
import 'features/onboarding/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final hasSeenOnboarding = prefs.getBool('zorar_has_seen_onboarding') ?? false;

  runApp(
    ProviderScope(
      child: ZorarStaffApp(hasSeenOnboarding: hasSeenOnboarding),
    ),
  );
}

class ZorarStaffApp extends ConsumerWidget {
  final bool hasSeenOnboarding;

  const ZorarStaffApp({
    super.key,
    this.hasSeenOnboarding = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branding = ref.watch(brandingProvider);

    return MaterialApp(
      title: branding.centerName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getTheme(
        primaryColor: branding.primaryColor,
        isDark: branding.isDarkMode,
      ),
      locale: const Locale('ar', 'EG'),
      supportedLocales: const [
        Locale('ar', 'EG'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: hasSeenOnboarding ? const MainShellScreen() : const OnboardingScreen(),
    );
  }
}
