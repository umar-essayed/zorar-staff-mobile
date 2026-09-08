import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/sound_service.dart';
import '../../core/theme/branding_provider.dart';
import '../auth/auth_provider.dart';
import '../auth/auth_screen.dart';
import '../onboarding/onboarding_screen.dart';

class BrandingSettingsScreen extends ConsumerStatefulWidget {
  const BrandingSettingsScreen({super.key});

  @override
  ConsumerState<BrandingSettingsScreen> createState() => _BrandingSettingsScreenState();
}

class _BrandingSettingsScreenState extends ConsumerState<BrandingSettingsScreen> {
  late TextEditingController _nameController;

  final List<Map<String, dynamic>> colorPresets = [
    {'name': 'الزمردي الأصلي (Emerald)', 'color': const Color(0xFF10B981)},
    {'name': 'الأزرق الملكي (Royal Blue)', 'color': const Color(0xFF2563EB)},
    {'name': 'البنفسجي الراقي (Violet)', 'color': const Color(0xFF8B5CF6)},
    {'name': 'العنبري الذهبي (Amber)', 'color': const Color(0xFFF59E0B)},
    {'name': 'الأحمر الياقوتي (Crimson)', 'color': const Color(0xFFE11D48)},
    {'name': 'النيلي الداكن (Indigo)', 'color': const Color(0xFF4F46E5)},
  ];

  final List<Map<String, dynamic>> iconOptions = [
    {'name': 'أيقونة زُرار الافتراضية', 'alias': null, 'color': Color(0xFF10B981)},
    {'name': 'أيقونة الأكاديمية الزرقاء', 'alias': 'BlueAcademyIcon', 'color': Color(0xFF2563EB)},
    {'name': 'أيقونة الصرح الذهبية', 'alias': 'GoldInstituteIcon', 'color': Color(0xFFF59E0B)},
  ];

  @override
  void initState() {
    super.initState();
    final currentName = ref.read(brandingProvider).centerName;
    _nameController = TextEditingController(text: currentName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(brandingProvider);
    final auth = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'تخصيص الهوية والإعدادات (White-Label)',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current User & Fast Role Switcher
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: branding.primaryColor.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: branding.primaryColor.withOpacity(0.15),
                            child: Icon(LucideIcons.userCheck, color: branding.primaryColor),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                auth.user?.name ?? 'المستخدم',
                                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: branding.primaryColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  auth.user?.roleArabicTitle ?? 'مدير النظام',
                                  style: GoogleFonts.cairo(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: branding.primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'التبديل الفوري بين حسابات التجربة والفحص:',
                    style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: auth.user?.isAdmin ?? false
                                  ? branding.primaryColor
                                  : Colors.grey.withOpacity(0.3),
                              width: auth.user?.isAdmin ?? false ? 2 : 1,
                            ),
                          ),
                          onPressed: () {
                            SoundService.successFeedback();
                            ref.read(authProvider.notifier).switchDemoRole(AppConstants.roleOwner);
                          },
                          child: Text('👑 الأدمن', style: GoogleFonts.cairo(fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: auth.user?.isAssistant ?? false
                                  ? branding.primaryColor
                                  : Colors.grey.withOpacity(0.3),
                              width: auth.user?.isAssistant ?? false ? 2 : 1,
                            ),
                          ),
                          onPressed: () {
                            SoundService.successFeedback();
                            ref.read(authProvider.notifier).switchDemoRole(AppConstants.roleAssistant);
                          },
                          child: Text('💼 المساعد', style: GoogleFonts.cairo(fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: auth.user?.isTeacher ?? false
                                  ? branding.primaryColor
                                  : Colors.grey.withOpacity(0.3),
                              width: auth.user?.isTeacher ?? false ? 2 : 1,
                            ),
                          ),
                          onPressed: () {
                            SoundService.successFeedback();
                            ref.read(authProvider.notifier).switchDemoRole(AppConstants.roleTeacher);
                          },
                          child: Text('👨‍🏫 المعلم', style: GoogleFonts.cairo(fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Center Name Customization
            Text(
              'اسم السنتر أو المؤسسة التعليمية',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(LucideIcons.building2, size: 20),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    final newName = _nameController.text.trim();
                    if (newName.isNotEmpty) {
                      SoundService.successFeedback();
                      ref.read(brandingProvider.notifier).updateCenterName(newName);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم تحديث اسم السنتر بنجاح')),
                      );
                    }
                  },
                  child: const Text('حفظ'),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Live Primary Color Picker
            Text(
              'اللون الأساسي لهوية التطبيق (Dynamic Theme)',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 6),
            Text(
              'اختر اللون وسيتغير مظهر التطبيق بالكامل لحظياً ليتطابق مع هوية السنتر:',
              style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: colorPresets.map((preset) {
                final color = preset['color'] as Color;
                final isSelected = branding.primaryColor.value == color.value;
                return InkWell(
                  onTap: () {
                    SoundService.successFeedback();
                    ref.read(brandingProvider.notifier).updatePrimaryColor(color);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? color.withOpacity(0.15) : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? color : Colors.grey.withOpacity(0.2),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          preset['name'] as String,
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? color : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Dynamic App Icon Switcher
            Text(
              'أيقونة التطبيق على شاشة الموبايل (Dynamic Launcher Icon)',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 6),
            Text(
              'تغيير أيقونة التطبيق في شاشة الهاتف مباشرة لتعكس شعار وهوية السنتر:',
              style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),

            Column(
              children: iconOptions.map((opt) {
                final alias = opt['alias'] as String?;
                final isSelected = branding.selectedIconAlias == alias;
                final color = opt['color'] as Color;

                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected ? branding.primaryColor : Colors.grey.withOpacity(0.2),
                      width: isSelected ? 1.8 : 1,
                    ),
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(LucideIcons.sparkles, color: Colors.white, size: 20),
                    ),
                    title: Text(
                      opt['name'] as String,
                      style: GoogleFonts.cairo(
                        fontSize: 13.5,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      alias == null ? 'الأيقونة الأصلية للنظام' : 'Alias: $alias',
                      style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey),
                    ),
                    trailing: isSelected
                        ? Icon(LucideIcons.checkCircle2, color: branding.primaryColor)
                        : null,
                    onTap: () async {
                      SoundService.successFeedback();
                      final success = await ref
                          .read(brandingProvider.notifier)
                          .updateAppIcon(alias);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'تم تبديل أيقونة التطبيق بنجاح'
                                  : 'تم حفظ الاختيار (سيتم تفعيل الأيقونة في بيئة الجهاز الحقيقي)',
                            ),
                          ),
                        );
                      }
                    },
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Dark Mode Switch
            Card(
              child: SwitchListTile(
                secondary: Icon(
                  branding.isDarkMode ? LucideIcons.moon : LucideIcons.sun,
                  color: branding.primaryColor,
                ),
                title: Text(
                  'الوضع الليلي (Dark Mode)',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13.5),
                ),
                subtitle: Text(
                  'مظهر داكن ومريح للعين أثناء العمل الميداني',
                  style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey),
                ),
                value: branding.isDarkMode,
                onChanged: (_) {
                  SoundService.successFeedback();
                  ref.read(brandingProvider.notifier).toggleDarkMode();
                },
              ),
            ),

            const SizedBox(height: 16),

            // Onboarding Tour Replay
            Card(
              child: ListTile(
                leading: const Icon(LucideIcons.compass, color: Color(0xFF3B82F6)),
                title: Text(
                  'الجولة التعريفية بالنظام (Onboarding Tour)',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13.5),
                ),
                subtitle: Text(
                  'استعراض شاشات وميزات زُرار برو التفاعلية',
                  style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey),
                ),
                trailing: const Icon(LucideIcons.chevronLeft, size: 18),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (ctx) => const OnboardingScreen()),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // Logout Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
                icon: const Icon(LucideIcons.logOut, size: 18),
                label: const Text('تسجيل الخروج والعودة لشاشة الدخول'),
                onPressed: () async {
                  SoundService.warningFeedback();
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (ctx) => const AuthScreen()),
                      (route) => false,
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
