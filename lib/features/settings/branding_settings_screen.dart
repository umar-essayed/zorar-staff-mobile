import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_constants.dart';
import '../../core/network/edu_api_service.dart';
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
  late TextEditingController _subdomainController;
  bool _isSaving = false;
  bool _isUploadingLogo = false;
  bool _isUploadingBanner = false;

  final List<Map<String, dynamic>> colorPresets = [
    {'name': 'الأزرق الملكي (Zorar)', 'color': const Color(0xFF0143A3)},
    {'name': 'الزمردي (Emerald)', 'color': const Color(0xFF10B981)},
    {'name': 'البنفسجي (Violet)', 'color': const Color(0xFF8B5CF6)},
    {'name': 'العنبري البرتقالي (Amber)', 'color': const Color(0xFFFF8A00)},
    {'name': 'الأحمر الياقوتي (Crimson)', 'color': const Color(0xFFE11D48)},
    {'name': 'النيلي الداكن (Indigo)', 'color': const Color(0xFF4F46E5)},
  ];

  @override
  void initState() {
    super.initState();
    final branding = ref.read(brandingProvider);
    _nameController = TextEditingController(text: branding.centerName);
    _subdomainController = TextEditingController(text: branding.subdomain);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _subdomainController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage({required bool isLogo}) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (picked == null) return;

      setState(() {
        if (isLogo) _isUploadingLogo = true;
        if (!isLogo) _isUploadingBanner = true;
      });
      SoundService.lightImpact();

      final bytes = await picked.readAsBytes();
      final url = await EduApiService().uploadImageFile(bytes, folder: isLogo ? 'logos' : 'banners');

      if (url != null && url.isNotEmpty) {
        SoundService.successFeedback();
        if (isLogo) {
          ref.read(brandingProvider.notifier).updateLogoUrl(url);
        } else {
          ref.read(brandingProvider.notifier).updateHeroBannerUrl(url);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isLogo ? 'تم رفع الشعار السحابي وتحديثه بنجاح ✅' : 'تم رفع البانر وتحديثه بنجاح ✅', style: GoogleFonts.cairo()),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        }
      } else {
        throw Exception('فشل التخزين السحابي في حفظ الصورة');
      }
    } catch (e) {
      SoundService.errorFeedback();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر رفع الصورة: $e', style: GoogleFonts.cairo()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingLogo = false;
          _isUploadingBanner = false;
        });
      }
    }
  }

  Future<void> _saveAllBranding() async {
    setState(() => _isSaving = true);
    SoundService.lightImpact();

    final branding = ref.read(brandingProvider);
    final newName = _nameController.text.trim();
    final newSub = _subdomainController.text.trim();

    ref.read(brandingProvider.notifier).updateCenterName(newName);
    ref.read(brandingProvider.notifier).updateSubdomain(newSub);

    final payload = {
      'name': newName,
      'subdomain': newSub,
      'brandingConfig': {
        'primaryColor': '#${branding.primaryColor.value.toRadixString(16).substring(2)}',
        'logoUrl': branding.logoUrl,
        'heroBannerUrl': branding.heroBannerUrl,
      },
    };

    await EduApiService().updateBranding(payload);
    SoundService.successFeedback();

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم حفظ وتطبيق كافة إعدادات الهوية والمنصة بنجاح ✅', style: GoogleFonts.cairo()),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(brandingProvider);
    final auth = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'تخصيص الهوية والمنصة (White-Label)',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton.icon(
            icon: _isSaving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(LucideIcons.save, size: 18),
            label: const Text('حفظ الهوية'),
            onPressed: _isSaving ? null : _saveAllBranding,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Badge
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: branding.primaryColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: branding.primaryColor.withOpacity(0.15),
                    child: Icon(LucideIcons.shieldCheck, color: branding.primaryColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(auth.user?.name ?? 'المستخدم', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('حساب موثق بالمنظومة السحابية', style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Section 1: Logo & Banner Uploads (Cloudflare R2)
            Text(
              'الشعار والبانرات المرفوعة (Cloudflare R2):',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                // Logo Upload Card
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: branding.logoUrl != null && branding.logoUrl!.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(branding.logoUrl!, fit: BoxFit.cover),
                                )
                              : Image.asset('assets/images/zorar_icon.png', fit: BoxFit.cover),
                        ),
                        const SizedBox(height: 10),
                        Text('شعار السنتر / المنصة', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: branding.primaryColor.withOpacity(0.12),
                            foregroundColor: branding.primaryColor,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                          icon: _isUploadingLogo
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(LucideIcons.uploadCloud, size: 16),
                          label: const Text('رفع لوجو'),
                          onPressed: _isUploadingLogo ? null : () => _pickAndUploadImage(isLogo: true),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Hero Banner Upload Card
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: branding.heroBannerUrl != null && branding.heroBannerUrl!.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(branding.heroBannerUrl!, fit: BoxFit.cover),
                                )
                              : const Icon(LucideIcons.image, size: 30, color: Colors.grey),
                        ),
                        const SizedBox(height: 10),
                        Text('بانر صفحة الدخول', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF59E0B).withOpacity(0.12),
                            foregroundColor: const Color(0xFFF59E0B),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                          icon: _isUploadingBanner
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(LucideIcons.uploadCloud, size: 16),
                          label: const Text('رفع بانر'),
                          onPressed: _isUploadingBanner ? null : () => _pickAndUploadImage(isLogo: false),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Section 2: Identity Names & Subdomain
            Text(
              'الاسم والنطاق السحابي للمنصة:',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 10),

            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.withOpacity(0.2))),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'اسم السنتر / الأكاديمية الرسمي',
                        prefixIcon: Icon(LucideIcons.building, size: 18),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _subdomainController,
                      decoration: const InputDecoration(
                        labelText: 'النطاق الفرعي السحابي (Subdomain)',
                        prefixIcon: Icon(LucideIcons.globe, size: 18),
                        suffixText: '.eduzorar.com',
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Section 3: Colors
            Text(
              'اللون الرسمي للمنظومة والتطبيق:',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 10),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: colorPresets.map((preset) {
                final Color color = preset['color'];
                final bool isSelected = branding.primaryColor.value == color.value;

                return InkWell(
                  onTap: () {
                    SoundService.lightImpact();
                    ref.read(brandingProvider.notifier).updatePrimaryColor(color);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? color.withOpacity(0.15) : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? color : Colors.grey.withOpacity(0.25),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(radius: 8, backgroundColor: color),
                        const SizedBox(width: 8),
                        Text(
                          preset['name'],
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

            // Dark Mode Toggle
            Card(
              child: SwitchListTile(
                secondary: Icon(
                  branding.isDarkMode ? LucideIcons.moon : LucideIcons.sun,
                  color: branding.primaryColor,
                ),
                title: Text('الوضع الليلي (Dark Mode)', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13.5)),
                subtitle: Text('مظهر مريح للعين في العمل الميداني', style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey)),
                value: branding.isDarkMode,
                onChanged: (_) {
                  SoundService.lightImpact();
                  ref.read(brandingProvider.notifier).toggleDarkMode();
                },
              ),
            ),

            const SizedBox(height: 24),

            // Logout
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                icon: const Icon(LucideIcons.logOut, size: 18),
                label: const Text('تسجيل الخروج من الحساب'),
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
          ],
        ),
      ),
    );
  }
}
