import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/sound_service.dart';
import '../../core/theme/branding_provider.dart';
import '../navigation/main_shell_screen.dart';
import 'auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _usernameCtrl = TextEditingController(text: 'admin@zorar.app');
  final _passwordCtrl = TextEditingController(text: 'zorar@2026');
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(brandingProvider);
    final auth = ref.watch(authProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Center Branding Logo & Name
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [branding.primaryColor, branding.primaryColor.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: branding.primaryColor.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(LucideIcons.sparkles, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 16),
                Text(
                  branding.centerName,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'تطبيق الإدارة والمساعدين والمدرسين (Zorar Staff Pro)',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 12.5,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 32),

                // Credentials Box
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تسجيل الدخول',
                          style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 14),

                        TextField(
                          controller: _usernameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'اسم المستخدم أو البريد أو الهاتف',
                            prefixIcon: Icon(LucideIcons.user, size: 20),
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 12),

                        TextField(
                          controller: _passwordCtrl,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'كلمة المرور',
                            prefixIcon: const Icon(LucideIcons.lock, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                                size: 18,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            isDense: true,
                          ),
                        ),

                        if (auth.errorMessage != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            auth.errorMessage!,
                            style: GoogleFonts.cairo(color: Colors.red, fontSize: 11.5),
                          ),
                        ],

                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: auth.isLoading
                                ? null
                                : () async {
                                    SoundService.successFeedback();
                                    final success = await ref
                                        .read(authProvider.notifier)
                                        .login(_usernameCtrl.text, _passwordCtrl.text);
                                    if (success && mounted) {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (ctx) => const MainShellScreen(),
                                        ),
                                      );
                                    }
                                  },
                            child: auth.isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('دخول إلى النظام'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Fast Role Test Entry
                Text(
                  'أو الدخول المباشر بحساب تجريبي حسب الدور:',
                  style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          SoundService.successFeedback();
                          ref.read(authProvider.notifier).switchDemoRole(AppConstants.roleOwner);
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (ctx) => const MainShellScreen()),
                          );
                        },
                        child: Text('👑 الأدمن', style: GoogleFonts.cairo(fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          SoundService.successFeedback();
                          ref.read(authProvider.notifier).switchDemoRole(AppConstants.roleAssistant);
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (ctx) => const MainShellScreen()),
                          );
                        },
                        child: Text('💼 المساعد', style: GoogleFonts.cairo(fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          SoundService.successFeedback();
                          ref.read(authProvider.notifier).switchDemoRole(AppConstants.roleTeacher);
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (ctx) => const MainShellScreen()),
                          );
                        },
                        child: Text('👨‍🏫 المعلم', style: GoogleFonts.cairo(fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
