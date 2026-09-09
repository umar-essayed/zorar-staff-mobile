import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/branding_provider.dart';
import '../auth/auth_provider.dart';
import '../auth/auth_screen.dart';
import '../navigation/main_shell_screen.dart';
import '../onboarding/onboarding_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.05).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );

    _animController.forward();
    _initializeApp();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    final startTime = DateTime.now();

    // Parallel initialization: load prefs and let auth/branding sync
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('zorar_has_seen_onboarding') ?? false;

    // Wait at least 1000ms for smooth splash animation
    final elapsed = DateTime.now().difference(startTime).inMilliseconds;
    if (elapsed < 1000) {
      await Future.delayed(Duration(milliseconds: 1000 - elapsed));
    }

    if (!mounted) return;

    // Await async session restore from SharedPreferences
    await ref.read(authProvider.notifier).waitForSessionRestore();
    if (!mounted) return;

    final auth = ref.read(authProvider);

    if (!hasSeenOnboarding) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const OnboardingScreen(),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    } else if (auth.isAuthenticated) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const MainShellScreen(),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const AuthScreen(),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(brandingProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Premium dark navy background
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: branding.primaryColor.withValues(alpha: 0.35),
                        blurRadius: 35,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(18),
                  child: Image.asset(
                    'assets/images/zorar_icon.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.play_arrow_rounded,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'زُرار كود • Zorar Code',
                style: GoogleFonts.cairo(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                branding.centerName.isNotEmpty ? branding.centerName : 'نظام إدارة السناتر التعليمية والمنصة الذكية',
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  color: Colors.white60,
                ),
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(branding.primaryColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
