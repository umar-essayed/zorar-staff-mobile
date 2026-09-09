import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/sound_service.dart';
import '../../core/theme/branding_provider.dart';
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

  // Login Controllers (Clean & Empty)
  final _loginUserCtrl = TextEditingController();
  final _loginPassCtrl = TextEditingController();
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
  final Set<String> _selectedStages = {'SECONDARY', 'BACCALAUREATE'};
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
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool('zorar_remember_me') ?? false;
    final savedPhone = prefs.getString('zorar_saved_phone');
    final savedPass = prefs.getString('zorar_saved_password');
    if (rememberMe && mounted) {
      setState(() {
        _rememberMe = true;
        if (savedPhone != null && savedPhone.isNotEmpty) {
          _loginUserCtrl.text = savedPhone;
        }
        if (savedPass != null && savedPass.isNotEmpty) {
          _loginPassCtrl.text = savedPass;
        }
      });
    }
  }

  @override
  void dispose() {
    _loginUserCtrl.dispose();
    _loginPassCtrl.dispose();
    _regCenterNameCtrl.dispose();
    _regPhoneCtrl.dispose();
    _regOwnerNameCtrl.dispose();
    _regEmailCtrl.dispose();
    _regPassCtrl.dispose();
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
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                onPressed: auth.isLoading ? null : _handleLogin,
                child: auth.isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        'دخول إلى النظام',
                        style: GoogleFonts.cairo(fontSize: 15.5, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    final phone = _loginUserCtrl.text.trim();
    final pass = _loginPassCtrl.text.trim();

    if (phone.isEmpty) {
      SoundService.errorFeedback();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('يرجى إدخال رقم الهاتف أو البريد الإلكتروني للمتابعة', style: GoogleFonts.cairo()),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (pass.isEmpty) {
      SoundService.errorFeedback();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('يرجى إدخال كلمة المرور', style: GoogleFonts.cairo()),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final success = await ref
        .read(authProvider.notifier)
        .login(phone, pass);

    if (success && mounted) {
      SoundService.successFeedback();
      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await prefs.setBool('zorar_remember_me', true);
        await prefs.setString('zorar_saved_phone', phone);
        await prefs.setString('zorar_saved_password', pass);
      } else {
        await prefs.remove('zorar_remember_me');
        await prefs.remove('zorar_saved_phone');
        await prefs.remove('zorar_saved_password');
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (ctx) => const MainShellScreen()),
      );
    } else if (mounted) {
      SoundService.errorFeedback();
      final err = ref.read(authProvider).errorMessage ?? 'بيانات الدخول غير صحيحة';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err, style: GoogleFonts.cairo()),
          backgroundColor: Colors.redAccent,
        ),
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

  // Step 3: Stages & Branding
  Widget _buildStep3BrandingAndDomain(dynamic branding) {
    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('المراحل الدراسية وهويتك التجارية', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 6),
        Text('حدد كافة المراحل التي يعمل بها السنتر (يمكن اختيار أكثر من مسار):', style: GoogleFonts.cairo(fontSize: 11.5, color: Colors.grey[600])),
        const SizedBox(height: 12),

        // Multi-select Stages Chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildStageChip('SECONDARY', 'المرحلة الثانوية العامة', branding),
            _buildStageChip('BACCALAUREATE', 'شهادة البكالوريا', branding),
            _buildStageChip('PREPARATORY', 'المرحلة الإعدادية', branding),
            _buildStageChip('PRIMARY', 'المرحلة الابتدائية', branding),
          ],
        ),
        const SizedBox(height: 18),

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

  Widget _buildStageChip(String stageCode, String title, dynamic branding) {
    final isSelected = _selectedStages.contains(stageCode);
    return FilterChip(
      selected: isSelected,
      label: Text(
        title,
        style: GoogleFonts.cairo(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : null,
        ),
      ),
      backgroundColor: Colors.grey.withOpacity(0.1),
      selectedColor: branding.primaryColor,
      checkmarkColor: Colors.white,
      onSelected: (selected) {
        SoundService.lightImpact();
        setState(() {
          if (selected) {
            _selectedStages.add(stageCode);
          } else {
            if (_selectedStages.length > 1) {
              _selectedStages.remove(stageCode);
            }
          }
        });
      },
    );
  }

  Future<void> _handleStepNext() async {
    SoundService.lightImpact();

    if (_currentRegStep == 0) {
      final centerName = _regCenterNameCtrl.text.trim();
      final phone = _regPhoneCtrl.text.trim();

      if (centerName.isEmpty) {
        SoundService.errorFeedback();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _orgType == 'CENTER' ? 'يرجى كتابة اسم السنتر أو المؤسسة للمتابعة' : 'يرجى كتابة اسم المعلم أو الأكاديمية للمتابعة',
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      if (phone.isEmpty || phone.length < 10) {
        SoundService.errorFeedback();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('يرجى كتابة رقم هاتف رسمي صحيح (10 إلى 11 رقم)', style: GoogleFonts.cairo()),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      setState(() => _currentRegStep = 1);
    } else if (_currentRegStep == 1) {
      final ownerName = _regOwnerNameCtrl.text.trim();
      final email = _regEmailCtrl.text.trim();
      final pass = _regPassCtrl.text.trim();

      if (ownerName.isEmpty || ownerName.length < 3) {
        SoundService.errorFeedback();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('يرجى كتابة اسم المدير أو المالك ثلاثي', style: GoogleFonts.cairo()),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (email.isEmpty || !emailRegex.hasMatch(email)) {
        SoundService.errorFeedback();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('يرجى كتابة بريد إلكتروني صالح وموثوق', style: GoogleFonts.cairo()),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      if (pass.isEmpty || pass.length < 6) {
        SoundService.errorFeedback();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('كلمة المرور يجب أن لا تقل عن 6 أحرف أو أرقام', style: GoogleFonts.cairo()),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      setState(() => _currentRegStep = 2);
    } else {
      if (_selectedStages.isEmpty) {
        SoundService.errorFeedback();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('يرجى اختيار مرحلة دراسية واحدة على الأقل', style: GoogleFonts.cairo()),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Step 2 Finished -> Submit Registration
      SoundService.successFeedback();

      // Update local branding color with chosen color
      ref.read(brandingProvider.notifier).updatePrimaryColor(_selectedPrimaryColor);
      ref.read(brandingProvider.notifier).updateCenterName(_regCenterNameCtrl.text.trim());

      final success = await ref.read(authProvider.notifier).registerTenant(
            orgType: _orgType,
            centerName: _regCenterNameCtrl.text.trim(),
            ownerName: _regOwnerNameCtrl.text.trim(),
            phone: _regPhoneCtrl.text.trim(),
            email: _regEmailCtrl.text.trim(),
            password: _regPassCtrl.text.trim(),
            stages: _selectedStages.toList(),
          );

      if (success && mounted) {
        SoundService.successFeedback();
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
      } else if (mounted) {
        SoundService.errorFeedback();
        final err = ref.read(authProvider).errorMessage ?? 'تعذر إنشاء السنتر أو الحساب، يرجى مراجعة البيانات';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err, style: GoogleFonts.cairo()),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}
