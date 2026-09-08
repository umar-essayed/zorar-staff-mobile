import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/sound_service.dart';
import '../../core/theme/branding_provider.dart';
import '../admissions/student_admission_public_screen.dart';
import '../navigation/main_shell_screen.dart';
import 'auth_provider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Login Controllers
  final _loginUserCtrl = TextEditingController(text: 'admin@zorar.app');
  final _loginPassCtrl = TextEditingController(text: 'zorar@2026');
  final _centerCodeCtrl = TextEditingController(text: 'alnoor');
  bool _loginObscure = true;
  bool _rememberMe = true;

  // Register Controllers
  final _regCenterNameCtrl = TextEditingController();
  final _regOwnerNameCtrl = TextEditingController();
  final _regPhoneCtrl = TextEditingController();
  final _regEmailCtrl = TextEditingController();
  final _regPassCtrl = TextEditingController();
  String _regOrgType = 'سنتر تعليمي متكامل';
  bool _regObscure = true;
  final _regFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginUserCtrl.dispose();
    _loginPassCtrl.dispose();
    _centerCodeCtrl.dispose();
    _regCenterNameCtrl.dispose();
    _regOwnerNameCtrl.dispose();
    _regPhoneCtrl.dispose();
    _regEmailCtrl.dispose();
    _regPassCtrl.dispose();
    super.dispose();
  }

  void _showForgotPasswordDialog(BuildContext context, dynamic branding) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(LucideIcons.keyRound, color: branding.primaryColor),
            const SizedBox(width: 10),
            Text('استعادة كلمة المرور', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'أدخل بريدك الإلكتروني أو رقم هاتفك المسجل وسنرسل لك كود إعادة التعيين فوراً:',
              style: GoogleFonts.cairo(fontSize: 12.5, color: Colors.grey[700]),
            ),
            const SizedBox(height: 14),
            const TextField(
              decoration: InputDecoration(
                hintText: 'البريد أو الهاتف المسجل',
                prefixIcon: Icon(LucideIcons.mail, size: 20),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton.icon(
            icon: const Icon(LucideIcons.send, size: 16),
            label: const Text('إرسال كود الاستعادة'),
            onPressed: () {
              SoundService.successFeedback();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Color(0xFF10B981),
                  content: Text('تم إرسال رابط إعادة تعيين كلمة المرور إلى هاتفك وبريدك بنجاح!'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(brandingProvider);
    final auth = ref.watch(authProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Branding Header
                  Container(
                    width: 82,
                    height: 82,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: branding.primaryColor.withOpacity(0.25),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/images/zorar_icon.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          decoration: BoxDecoration(
                            color: branding.primaryColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(LucideIcons.sparkles, color: Colors.white, size: 38),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    branding.centerName,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'المنظومة الميدانية الموحدة للإدارة والمساعدين والمدرسين',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Dual Tabs: Login vs Register
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      labelColor: branding.primaryColor,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: branding.primaryColor,
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13.5),
                      unselectedLabelStyle: GoogleFonts.cairo(fontSize: 13),
                      tabs: const [
                        Tab(text: 'تسجيل الدخول', icon: Icon(LucideIcons.logIn, size: 18)),
                        Tab(text: 'إنشاء حساب سنتر', icon: Icon(LucideIcons.building2, size: 18)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Tab Views Container
                  AnimatedBuilder(
                    animation: _tabController,
                    builder: (context, _) {
                      return _tabController.index == 0
                          ? _buildLoginCard(context, branding, auth)
                          : _buildRegisterCard(context, branding, auth);
                    },
                  ),

                  const SizedBox(height: 20),

                  // Direct link to Public Admission Form
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (ctx) => const StudentAdmissionPublicScreen(),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.25)),
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.clipboardList, color: Color(0xFF3B82F6), size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'استمارة تقديم وحجز طالب جديد (Public Admission)',
                                  style: GoogleFonts.cairo(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.5,
                                    color: const Color(0xFF1E40AF),
                                  ),
                                ),
                                Text(
                                  'للطلاب وأولياء الأمور لتسجيل طلبات القيد بالسنتر',
                                  style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey[700]),
                                ),
                              ],
                            ),
                          ),
                          const Icon(LucideIcons.chevronLeft, color: Color(0xFF3B82F6), size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginCard(BuildContext context, dynamic branding, dynamic auth) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('تسجيل الدخول للنظام', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),

            TextField(
              controller: _loginUserCtrl,
              decoration: const InputDecoration(
                labelText: 'اسم المستخدم أو البريد أو الهاتف',
                prefixIcon: Icon(LucideIcons.user, size: 20),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _loginPassCtrl,
              obscureText: _loginObscure,
              decoration: InputDecoration(
                labelText: 'كلمة المرور',
                prefixIcon: const Icon(LucideIcons.lock, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(_loginObscure ? LucideIcons.eyeOff : LucideIcons.eye, size: 18),
                  onPressed: () => setState(() => _loginObscure = !_loginObscure),
                ),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _centerCodeCtrl,
              decoration: const InputDecoration(
                labelText: 'كود أو نطاق السنتر (Tenant Code)',
                prefixIcon: Icon(LucideIcons.building, size: 20),
                isDense: true,
              ),
            ),

            const SizedBox(height: 6),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      activeColor: branding.primaryColor,
                      onChanged: (val) => setState(() => _rememberMe = val ?? true),
                    ),
                    Text('تذكر بياناتي', style: GoogleFonts.cairo(fontSize: 12)),
                  ],
                ),
                TextButton(
                  onPressed: () => _showForgotPasswordDialog(context, branding),
                  child: Text(
                    'نسيت كلمة المرور؟',
                    style: GoogleFonts.cairo(fontSize: 12, color: branding.primaryColor),
                  ),
                ),
              ],
            ),

            if (auth.errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(auth.errorMessage!, style: GoogleFonts.cairo(color: Colors.red, fontSize: 11.5)),
            ],

            const SizedBox(height: 16),

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
                            .login(_loginUserCtrl.text, _loginPassCtrl.text);
                        if (success && mounted) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (ctx) => const MainShellScreen()),
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

            const SizedBox(height: 20),

            // Demo Accounts Fast Login Buttons
            Text(
              'أو الدخول المباشر بحساب تجريبي حسب الدور:',
              style: GoogleFonts.cairo(fontSize: 11.5, color: Colors.grey),
            ),
            const SizedBox(height: 8),

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
                    child: Text('👑 الأدمن', style: GoogleFonts.cairo(fontSize: 11.5)),
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
                    child: Text('💼 المساعد', style: GoogleFonts.cairo(fontSize: 11.5)),
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
                    child: Text('👨‍🏫 المعلم', style: GoogleFonts.cairo(fontSize: 11.5)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterCard(BuildContext context, dynamic branding, dynamic auth) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _regFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('تسجيل سنتر أو معلم جديد', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                'احصل على بيئة عمل متكاملة مخصصة باسم سنترك وشعارك فوراً',
                style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _regCenterNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'اسم السنتر أو الأكاديمية *',
                  prefixIcon: Icon(LucideIcons.building, size: 20),
                  isDense: true,
                ),
                validator: (v) => v == null || v.isEmpty ? 'يرجى إدخال اسم السنتر' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _regOwnerNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'اسم المدير أو صاحب السنتر *',
                  prefixIcon: Icon(LucideIcons.user, size: 20),
                  isDense: true,
                ),
                validator: (v) => v == null || v.isEmpty ? 'يرجى إدخال الاسم' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _regPhoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'رقم الهاتف للتواصل وتفعيل الحساب *',
                  prefixIcon: Icon(LucideIcons.phone, size: 20),
                  isDense: true,
                ),
                validator: (v) => v == null || v.length < 10 ? 'يرجى إدخال رقم هاتف صالح' : null,
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: _regOrgType,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'نوع المؤسسة التعليمية',
                  prefixIcon: Icon(LucideIcons.briefcase, size: 20),
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(value: 'سنتر تعليمي متكامل', child: Text('سنتر تعليمي متكامل')),
                  DropdownMenuItem(value: 'مدرس مستقل وفريق مساعديه', child: Text('مدرس مستقل وفريق مساعديه')),
                  DropdownMenuItem(value: 'أكاديمية لغات وتدريب', child: Text('أكاديمية لغات وتدريب')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _regOrgType = val);
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _regPassCtrl,
                obscureText: _regObscure,
                decoration: InputDecoration(
                  labelText: 'كلمة المرور المشفرة *',
                  prefixIcon: const Icon(LucideIcons.lock, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(_regObscure ? LucideIcons.eyeOff : LucideIcons.eye, size: 18),
                    onPressed: () => setState(() => _regObscure = !_regObscure),
                  ),
                  isDense: true,
                ),
                validator: (v) => v == null || v.length < 6 ? 'كلمة المرور يجب أن لا تقل عن 6 خانات' : null,
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  icon: const Icon(LucideIcons.sparkles, size: 18),
                  label: const Text('إنشاء السنتر وتجهيز المنظومة فوراً'),
                  onPressed: () {
                    if (_regFormKey.currentState?.validate() ?? false) {
                      SoundService.successFeedback();
                      // Update branding immediately with the new center name
                      ref
                          .read(brandingProvider.notifier)
                          .updateCenterName(_regCenterNameCtrl.text.trim());

                      ref.read(authProvider.notifier).switchDemoRole(AppConstants.roleOwner);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFF10B981),
                          content: Text(
                            'تم تأسيس منظومة "${_regCenterNameCtrl.text}" وتفعيل صلاحيات المدير بنجاح! 🎉',
                            style: GoogleFonts.cairo(),
                          ),
                        ),
                      );

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (ctx) => const MainShellScreen()),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
