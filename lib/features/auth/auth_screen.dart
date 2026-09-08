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

class _AuthScreenState extends ConsumerState<AuthScreen> {
  // Mode: 0 = Unified Login, 1 = Multi-Step Registration
  int _activeTab = 0;

  // Login Controllers
  final _loginUserCtrl = TextEditingController(text: '01000000001');
  final _loginPassCtrl = TextEditingController(text: '123456');
  bool _loginObscure = true;
  bool _rememberMe = true;

  // Multi-step Registration State
  int _currentRegStep = 0; // 0, 1, 2
  String _orgType = 'CENTER'; // 'CENTER' or 'TEACHER'
  final _regCenterNameCtrl = TextEditingController();
  final _regPhoneCtrl = TextEditingController();
  final _regOwnerNameCtrl = TextEditingController();
  final _regEmailCtrl = TextEditingController();
  final _regPassCtrl = TextEditingController();
  final _regSubdomainCtrl = TextEditingController();
  String _selectedStage = 'المرحلة الثانوية';
  Color _selectedPrimaryColor = const Color(0xFF0143A3);
  bool _regPassObscure = true;

  final List<Color> _brandPalette = const [
    Color(0xFF0143A3), // Royal Blue (Zorar Code)
    Color(0xFFFF8A00), // Vibrant Orange
    Color(0xFF0D9488), // Emerald Teal
    Color(0xFF7C3AED), // Indigo Purple
    Color(0xFFDC2626), // Crimson Red
  ];

  @override
  void dispose() {
    _loginUserCtrl.dispose();
    _loginPassCtrl.dispose();
    _regCenterNameCtrl.dispose();
    _regPhoneCtrl.dispose();
    _regOwnerNameCtrl.dispose();
    _regEmailCtrl.dispose();
    _regPassCtrl.dispose();
    _regSubdomainCtrl.dispose();
    super.dispose();
  }

  void _showForgotPasswordDialog(BuildContext context, dynamic branding) {
    final emailCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(LucideIcons.keyRound, color: branding.primaryColor, size: 22),
            const SizedBox(width: 8),
            Text('استعادة الحساب', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'أدخل رقم الهاتف أو البريد المسجل لإرسال كود التأكيد:',
              style: GoogleFonts.cairo(fontSize: 12.5, color: Colors.grey[700]),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(
                hintText: 'رقم الهاتف أو البريد الإلكتروني',
                prefixIcon: Icon(LucideIcons.mail, size: 18),
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
          ElevatedButton(
            onPressed: () {
              SoundService.successFeedback();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم إرسال كود التحقق إلى هاتفك بنجاح'),
                  backgroundColor: Color(0xFF10B981),
                ),
              );
            },
            child: const Text('إرسال الكود'),
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
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Header & Logo
                  _buildHeader(branding),

                  const SizedBox(height: 20),

                  // Segmented Switcher (Login vs Register)
                  _buildTabSwitcher(branding),

                  const SizedBox(height: 18),

                  // Main Card: Login OR Multi-Step Register
                  _activeTab == 0
                      ? _buildUnifiedLoginCard(branding, auth)
                      : _buildMultiStepRegisterCard(branding, auth),

                  const SizedBox(height: 18),

                  // Clean Admission Link
                  _buildPublicAdmissionLink(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(dynamic branding) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: branding.primaryColor.withOpacity(0.25),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.asset(
              'assets/images/zorar_icon.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: BoxDecoration(
                  color: branding.primaryColor,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(LucideIcons.sparkles, color: Colors.white, size: 34),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          branding.centerName,
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'بوابة الدخول الموحدة للسناتر والتعليم',
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(
            fontSize: 12.5,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildTabSwitcher(dynamic branding) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () {
                SoundService.lightImpact();
                setState(() => _activeTab = 0);
              },
              borderRadius: BorderRadius.circular(9),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _activeTab == 0 ? branding.primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Center(
                  child: Text(
                    'تسجيل الدخول',
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _activeTab == 0 ? Colors.white : Colors.grey[700],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () {
                SoundService.lightImpact();
                setState(() {
                  _activeTab = 1;
                  _currentRegStep = 0;
                });
              },
              borderRadius: BorderRadius.circular(9),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _activeTab == 1 ? branding.primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Center(
                  child: Text(
                    'إنشاء سنتر جديد',
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _activeTab == 1 ? Colors.white : Colors.grey[700],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 1. Unified Login Card (Simple like Web)
  // ==========================================
  Widget _buildUnifiedLoginCard(dynamic branding, dynamic auth) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withOpacity(0.18)),
      ),
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

            // Phone / Username
            TextField(
              controller: _loginUserCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'رقم الهاتف أو البريد الإلكتروني',
                prefixIcon: Icon(LucideIcons.user, size: 18),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),

            // Password
            TextField(
              controller: _loginPassCtrl,
              obscureText: _loginObscure,
              decoration: InputDecoration(
                labelText: 'كلمة المرور',
                prefixIcon: const Icon(LucideIcons.lock, size: 18),
                suffixIcon: IconButton(
                  icon: Icon(_loginObscure ? LucideIcons.eyeOff : LucideIcons.eye, size: 18),
                  onPressed: () => setState(() => _loginObscure = !_loginObscure),
                ),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),

            // Remember me + Forgot Password
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: Checkbox(
                        value: _rememberMe,
                        activeColor: branding.primaryColor,
                        onChanged: (val) => setState(() => _rememberMe = val ?? true),
                      ),
                    ),
                    const SizedBox(width: 8),
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
              Text(
                auth.errorMessage!,
                style: GoogleFonts.cairo(color: Colors.redAccent, fontSize: 12),
              ),
            ],

            const SizedBox(height: 16),

            // Login Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: auth.isLoading ? null : _handleLogin,
                child: auth.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        'دخول إلى النظام',
                        style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
              ),
            ),

            const SizedBox(height: 18),
            const Divider(),
            const SizedBox(height: 10),

            // Quick Role Switcher for Live Demo & Testing
            Text(
              'أو دخول سريع للتجربة (يكتشف الدور تلقائياً):',
              style: GoogleFonts.cairo(fontSize: 11.5, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildDemoChip('👑 الإدارة', '01000000001', AppConstants.roleOwner, branding),
                const SizedBox(width: 6),
                _buildDemoChip('💼 مساعد', '01111111112', AppConstants.roleAssistant, branding),
                const SizedBox(width: 6),
                _buildDemoChip('👨‍🏫 معلم', '01222222223', AppConstants.roleTeacher, branding),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDemoChip(String label, String phone, String role, dynamic branding) {
    return Expanded(
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 8),
          side: BorderSide(color: branding.primaryColor.withOpacity(0.3)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: () {
          setState(() {
            _loginUserCtrl.text = phone;
            _loginPassCtrl.text = '123456';
          });
          SoundService.lightImpact();
          _handleLogin();
        },
        child: Text(
          label,
          style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
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
  }

  // ==========================================
  // 2. Multi-Step Registration Wizard
  // ==========================================
  Widget _buildMultiStepRegisterCard(dynamic branding, dynamic auth) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withOpacity(0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress Bar / Steps
            _buildStepIndicator(branding),

            const SizedBox(height: 16),

            // Step Content
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _buildCurrentStepContent(branding),
            ),

            const SizedBox(height: 20),

            // Navigation Buttons (السابق / التالي)
            Row(
              children: [
                if (_currentRegStep > 0) ...[
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        SoundService.lightImpact();
                        setState(() => _currentRegStep--);
                      },
                      child: Text('السابق', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      onPressed: auth.isLoading ? null : _handleStepNext,
                      child: Text(
                        _currentRegStep == 2 ? 'تأكيد وإنشاء السنتر 🚀' : 'التالي ←',
                        style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(dynamic branding) {
    final steps = ['البيانات', 'المدير', 'الهوية'];

    return Row(
      children: List.generate(steps.length, (idx) {
        final isActive = idx == _currentRegStep;
        final isCompleted = idx < _currentRegStep;

        return Expanded(
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? const Color(0xFF10B981)
                      : isActive
                          ? branding.primaryColor
                          : Colors.grey.withOpacity(0.2),
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : Text(
                          '${idx + 1}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isActive ? Colors.white : Colors.grey,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  steps[idx],
                  style: GoogleFonts.cairo(
                    fontSize: 11.5,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    color: isActive ? branding.primaryColor : Colors.grey,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (idx < steps.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    color: isCompleted ? const Color(0xFF10B981) : Colors.grey.withOpacity(0.2),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildCurrentStepContent(dynamic branding) {
    switch (_currentRegStep) {
      case 0:
        return _buildStep1BasicInfo(branding);
      case 1:
        return _buildStep2AdminCredentials(branding);
      case 2:
      default:
        return _buildStep3BrandingAndDomain(branding);
    }
  }

  // Step 1: Entity Type & Name
  Widget _buildStep1BasicInfo(dynamic branding) {
    return Column(
      key: const ValueKey(0),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('نوع الحساب والمنشأة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 10),

        // Type Cards (Center vs Teacher)
        Row(
          children: [
            _buildTypeSelectCard(
              title: 'سنتر تعليمي',
              subtitle: 'متعدد المدرسين',
              icon: LucideIcons.building2,
              isSelected: _orgType == 'CENTER',
              onTap: () => setState(() => _orgType = 'CENTER'),
              branding: branding,
            ),
            const SizedBox(width: 10),
            _buildTypeSelectCard(
              title: 'مدرس مستقل',
              subtitle: 'سنتر شخصي',
              icon: LucideIcons.graduationCap,
              isSelected: _orgType == 'TEACHER',
              onTap: () => setState(() => _orgType = 'TEACHER'),
              branding: branding,
            ),
          ],
        ),

        const SizedBox(height: 14),

        TextField(
          controller: _regCenterNameCtrl,
          decoration: InputDecoration(
            labelText: _orgType == 'CENTER' ? 'اسم السنتر التعليمي' : 'اسم المدرس أو الأكاديمية',
            prefixIcon: const Icon(LucideIcons.building, size: 18),
            isDense: true,
          ),
        ),
        const SizedBox(height: 12),

        TextField(
          controller: _regPhoneCtrl,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'رقم هاتف السنتر الرسمي (واتساب)',
            prefixIcon: Icon(LucideIcons.phone, size: 18),
            isDense: true,
          ),
        ),
      ],
    );
  }

  Widget _buildTypeSelectCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required dynamic branding,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () {
          SoundService.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? branding.primaryColor.withOpacity(0.08) : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? branding.primaryColor : Colors.grey.withOpacity(0.2),
              width: isSelected ? 1.8 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? branding.primaryColor : Colors.grey, size: 24),
              const SizedBox(height: 6),
              Text(
                title,
                style: GoogleFonts.cairo(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? branding.primaryColor : null,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.cairo(fontSize: 10.5, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Step 2: Manager Profile & Password
  Widget _buildStep2AdminCredentials(dynamic branding) {
    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('بيانات المدير وحساب الدخول', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 12),

        TextField(
          controller: _regOwnerNameCtrl,
          decoration: const InputDecoration(
            labelText: 'اسم المدير أو صاحب السنتر',
            prefixIcon: Icon(LucideIcons.user, size: 18),
            isDense: true,
          ),
        ),
        const SizedBox(height: 12),

        TextField(
          controller: _regEmailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'البريد الإلكتروني',
            prefixIcon: Icon(LucideIcons.mail, size: 18),
            isDense: true,
          ),
        ),
        const SizedBox(height: 12),

        TextField(
          controller: _regPassCtrl,
          obscureText: _regPassObscure,
          decoration: InputDecoration(
            labelText: 'كلمة المرور (6 خانات على الأقل)',
            prefixIcon: const Icon(LucideIcons.lock, size: 18),
            suffixIcon: IconButton(
              icon: Icon(_regPassObscure ? LucideIcons.eyeOff : LucideIcons.eye, size: 18),
              onPressed: () => setState(() => _regPassObscure = !_regPassObscure),
            ),
            isDense: true,
          ),
        ),
      ],
    );
  }

  // Step 3: Subdomain & Branding
  Widget _buildStep3BrandingAndDomain(dynamic branding) {
    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('النطاق السحابي والهوية', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 12),

        // Subdomain Input
        TextField(
          controller: _regSubdomainCtrl,
          decoration: const InputDecoration(
            labelText: 'النطاق الفرعي المطلوب',
            hintText: 'مثال: alnoor',
            suffixText: '.eduzorar.com',
            prefixIcon: Icon(LucideIcons.globe, size: 18),
            isDense: true,
          ),
        ),
        const SizedBox(height: 12),

        // Stage Dropdown
        DropdownButtonFormField<String>(
          value: _selectedStage,
          decoration: const InputDecoration(
            labelText: 'المرحلة الدراسية الأساسية',
            prefixIcon: Icon(LucideIcons.bookOpen, size: 18),
            isDense: true,
          ),
          items: const [
            DropdownMenuItem(value: 'المرحلة الثانوية', child: Text('المرحلة الثانوية')),
            DropdownMenuItem(value: 'المرحلة الإعدادية', child: Text('المرحلة الإعدادية')),
            DropdownMenuItem(value: 'المرحلة الابتدائية', child: Text('المرحلة الابتدائية')),
            DropdownMenuItem(value: 'شامل لكافة المراحل', child: Text('شامل لكافة المراحل')),
          ],
          onChanged: (val) => setState(() => _selectedStage = val ?? 'المرحلة الثانوية'),
        ),
        const SizedBox(height: 14),

        // Color Picker
        Text('اللون الرئيسي لعلامتك التجارية:', style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey[700])),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: _brandPalette.map((col) {
            final isChosen = _selectedPrimaryColor == col;
            return InkWell(
              onTap: () {
                SoundService.lightImpact();
                setState(() => _selectedPrimaryColor = col);
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: col,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isChosen ? Colors.white : Colors.transparent,
                    width: 3,
                  ),
                  boxShadow: isChosen
                      ? [BoxShadow(color: col.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 3))]
                      : null,
                ),
                child: isChosen ? const Icon(Icons.check, size: 20, color: Colors.white) : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _handleStepNext() async {
    SoundService.lightImpact();
    if (_currentRegStep == 0) {
      if (_regCenterNameCtrl.text.trim().isEmpty) {
        _regCenterNameCtrl.text = _orgType == 'CENTER' ? 'سنتر الأوائل التعليمي' : 'أكاديمية مستر أحمد';
      }
      if (_regPhoneCtrl.text.trim().isEmpty) {
        _regPhoneCtrl.text = '01012345678';
      }
      setState(() => _currentRegStep = 1);
    } else if (_currentRegStep == 1) {
      if (_regOwnerNameCtrl.text.trim().isEmpty) {
        _regOwnerNameCtrl.text = 'أ/ عمر السيد';
      }
      if (_regEmailCtrl.text.trim().isEmpty) {
        _regEmailCtrl.text = 'owner@zorar.app';
      }
      if (_regPassCtrl.text.trim().isEmpty) {
        _regPassCtrl.text = '123456';
      }
      setState(() => _currentRegStep = 2);
    } else {
      // Step 2 Finished -> Submit Registration
      SoundService.successFeedback();
      final sub = _regSubdomainCtrl.text.trim().isNotEmpty
          ? _regSubdomainCtrl.text.trim()
          : 'el-awael';

      // Update local branding color with chosen color
      ref.read(brandingProvider.notifier).updatePrimaryColor(_selectedPrimaryColor);
      ref.read(brandingProvider.notifier).updateCenterName(_regCenterNameCtrl.text);

      final success = await ref.read(authProvider.notifier).registerTenant(
            orgType: _orgType,
            centerName: _regCenterNameCtrl.text,
            ownerName: _regOwnerNameCtrl.text,
            phone: _regPhoneCtrl.text,
            email: _regEmailCtrl.text,
            password: _regPassCtrl.text,
            subdomain: sub,
          );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إنشاء السنتر وتفعيله بنجاح! مرحباً بك في زُرار كود'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (ctx) => const MainShellScreen()),
        );
      }
    }
  }

  // ==========================================
  // 3. Clean Public Admission Link
  // ==========================================
  Widget _buildPublicAdmissionLink() {
    return InkWell(
      onTap: () {
        SoundService.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (ctx) => const StudentAdmissionPublicScreen(),
          ),
        );
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF0143A3).withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF0143A3).withOpacity(0.18)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.clipboardEdit, color: Color(0xFF0143A3), size: 18),
                const SizedBox(width: 8),
                Text(
                  'استمارة تقديم وقيد طالب جديد',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                    color: const Color(0xFF0143A3),
                  ),
                ),
              ],
            ),
            const Icon(LucideIcons.chevronLeft, color: Color(0xFF0143A3), size: 16),
          ],
        ),
      ),
    );
  }
}
