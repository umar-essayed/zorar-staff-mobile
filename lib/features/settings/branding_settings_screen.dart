import 'dart:async';
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
  bool _isSwitchingIcon = false;

  bool _isCheckingSlug = false;
  bool? _isSlugAvailable;
  String? _slugStatusMessage;
  Timer? _debounceTimer;

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
    _debounceTimer?.cancel();
    _nameController.dispose();
    _subdomainController.dispose();
    super.dispose();
  }

  void _onSlugChanged(String value) {
    _debounceTimer?.cancel();
    final slug = value.trim().toLowerCase();
    if (slug.isEmpty || slug.length < 3) {
      setState(() {
        _isCheckingSlug = false;
        _isSlugAvailable = null;
        _slugStatusMessage = 'أدخل 3 أحرف إنجليزية على الأقل (مثال: al-magd)';
      });
      return;
    }

    setState(() {
      _isCheckingSlug = true;
      _isSlugAvailable = null;
      _slugStatusMessage = 'جاري التحقق من توفر الرابط...';
    });

    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      try {
        final res = await EduApiService().checkSubdomainAvailability(slug);
        if (!mounted) return;
        final isAvail = res['available'] == true;
        final isCurrent = res['isCurrent'] == true;
        setState(() {
          _isCheckingSlug = false;
          _isSlugAvailable = isAvail;
          if (isCurrent) {
            _slugStatusMessage = 'هذا هو الرابط المعتمد الخاص بك حالياً ✅';
          } else if (isAvail) {
            _slugStatusMessage = 'الرابط متاح ومتوفر للحجز فوراً! ✨';
          } else {
            _slugStatusMessage = 'عذراً، هذا الرابط مستخدم بالفعل من قِبل سنتر آخر ❌';
          }
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isCheckingSlug = false;
          _isSlugAvailable = null;
          _slugStatusMessage = null;
        });
      }
    });
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
        'primaryColor': '#${branding.primaryColor.value.toRadixString(16).padLeft(8, '0').substring(2)}',
        'secondaryColor': '#${branding.secondaryColor.value.toRadixString(16).padLeft(8, '0').substring(2)}',
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
              'الاسم والمعرّف المخصص للمنصة:',
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
                      onChanged: _onSlugChanged,
                      decoration: InputDecoration(
                        labelText: 'معرّف الرابط المخصص (Slug) للمنصة أو المعلم',
                        hintText: 'مثال: al-magd أو mr-ahmed',
                        prefixIcon: const Icon(LucideIcons.link2, size: 18),
                        suffixIcon: _isCheckingSlug
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                              )
                            : _isSlugAvailable == true
                                ? const Icon(LucideIcons.checkCircle2, color: Color(0xFF10B981), size: 20)
                                : _isSlugAvailable == false
                                    ? const Icon(LucideIcons.alertCircle, color: Colors.red, size: 20)
                                    : null,
                        helperText: _slugStatusMessage ?? 'معرّف المنصة أو المعلم (حروف وأرقام إنجليزية وبدون مسافات)',
                        helperMaxLines: 2,
                        helperStyle: TextStyle(
                          color: _isSlugAvailable == true
                              ? const Color(0xFF059669)
                              : _isSlugAvailable == false
                                  ? Colors.red
                                  : Colors.grey[600],
                          fontWeight: _isSlugAvailable != null ? FontWeight.bold : FontWeight.normal,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Section 3: Colors (Primary & Secondary)
            Text(
              'ألوان المنظومة والتطبيق الميداني:',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                // Primary Color Card
                Expanded(
                  child: InkWell(
                    onTap: () => _openColorPicker(context, isPrimary: true),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: branding.primaryColor.withOpacity(0.4), width: 1.5),
                        boxShadow: [
                          BoxShadow(color: branding.primaryColor.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(radius: 12, backgroundColor: branding.primaryColor),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text('اللون الأساسي', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '#${branding.primaryColor.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
                            style: GoogleFonts.firaCode(fontSize: 12, fontWeight: FontWeight.bold, color: branding.primaryColor),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(LucideIcons.pipette, size: 14, color: branding.primaryColor),
                              const SizedBox(width: 4),
                              Text('تغيير / كود اللون', style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Secondary Color Card
                Expanded(
                  child: InkWell(
                    onTap: () => _openColorPicker(context, isPrimary: false),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: branding.secondaryColor.withOpacity(0.4), width: 1.5),
                        boxShadow: [
                          BoxShadow(color: branding.secondaryColor.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(radius: 12, backgroundColor: branding.secondaryColor),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text('اللون الفرعي', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '#${branding.secondaryColor.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
                            style: GoogleFonts.firaCode(fontSize: 12, fontWeight: FontWeight.bold, color: branding.secondaryColor),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(LucideIcons.pipette, size: 14, color: branding.secondaryColor),
                              const SizedBox(width: 4),
                              Text('تغيير / كود اللون', style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Section 4: App Launcher Icon
            Text(
              'أيقونة وهوية التطبيق الرسمية:',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 10),

            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.withOpacity(0.2)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'شعار وهوية السنتر المخصصة المعتمدة للتطبيق بالكامل:',
                      style: GoogleFonts.cairo(fontSize: 12.5, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 14),

                    // Center Custom Logo Option (Selected & Prioritized)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: branding.primaryColor.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: branding.primaryColor.withOpacity(0.4), width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: (branding.logoUrl != null && branding.logoUrl!.isNotEmpty)
                                  ? Image.network(
                                      branding.logoUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Image.asset('assets/images/zorar_icon.png', fit: BoxFit.cover),
                                    )
                                  : Image.asset('assets/images/zorar_icon.png', fit: BoxFit.cover),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'شعار السنتر المخصص',
                                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'الأيقونة المعتمدة ✅',
                                        style: GoogleFonts.cairo(fontSize: 10, color: Colors.green[800], fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  (branding.logoUrl != null && branding.logoUrl!.isNotEmpty)
                                      ? 'شعار سنتر ${branding.centerName} معتمد ومطبق كأيقونة وهوية رئيسية للتطبيق والتقارير'
                                      : 'لم يتم رفع شعار مخصص بعد، اضغط لرفع شعار السنتر الآن',
                                  style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: branding.primaryColor,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            ),
                            icon: const Icon(LucideIcons.uploadCloud, size: 16),
                            label: Text(
                              (branding.logoUrl != null && branding.logoUrl!.isNotEmpty) ? 'تغيير' : 'رفع اللوجو',
                              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            onPressed: _isUploadingLogo ? null : () => _pickAndUploadImage(isLogo: true),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // EduZorar Classic Fallback
                    _buildIconOption(
                      title: 'الافتراضية - EduZorar Classic',
                      subtitle: 'الأيقونة العامة لمنظومة زُرار كود التعليمية',
                      iconColor: const Color(0xFF0143A3),
                      alias: null,
                      currentAlias: branding.selectedIconAlias,
                    ),

                    if (_isSwitchingIcon) ...[
                      const SizedBox(height: 12),
                      const Center(child: CircularProgressIndicator()),
                    ],
                  ],
                ),
              ),
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

  Widget _buildIconOption({
    required String title,
    required String subtitle,
    required Color iconColor,
    required String? alias,
    required String? currentAlias,
  }) {
    final isSelected = alias == currentAlias;
    return InkWell(
      onTap: _isSwitchingIcon
          ? null
          : () async {
              setState(() => _isSwitchingIcon = true);
              SoundService.lightImpact();
              try {
                final success = await ref
                    .read(brandingProvider.notifier)
                    .updateAppIcon(alias);
                if (mounted) {
                  if (success) {
                    SoundService.successFeedback();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'تم تطبيق أيقونة التطبيق بنجاح! ستظهر على شاشة جوالك الآن ✅',
                          style: GoogleFonts.cairo(),
                        ),
                        backgroundColor: const Color(0xFF10B981),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'تغيير الأيقونة يحتاج إذن واجهة الهاتف أو أن مشغل التطبيقات الحالي لا يدعمها',
                          style: GoogleFonts.cairo(),
                        ),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('تعذر تغيير الأيقونة: $e', style: GoogleFonts.cairo()),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } finally {
                if (mounted) setState(() => _isSwitchingIcon = false);
              }
            },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: iconColor.withOpacity(0.4)),
              ),
              child: Icon(LucideIcons.sparkles, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isSelected ? iconColor : null,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(LucideIcons.checkCircle2, color: iconColor, size: 22)
            else
              const Icon(LucideIcons.circle, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  void _openColorPicker(BuildContext context, {required bool isPrimary}) {
    final branding = ref.read(brandingProvider);
    Color currentColor = isPrimary ? branding.primaryColor : branding.secondaryColor;
    final hexController = TextEditingController(
      text: currentColor.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase(),
    );

    int r = currentColor.red;
    int g = currentColor.green;
    int b = currentColor.blue;

    final palette = [
      const Color(0xFF10B981), // Emerald
      const Color(0xFF059669),
      const Color(0xFF047857),
      const Color(0xFF6366F1), // Indigo
      const Color(0xFF4F46E5),
      const Color(0xFF4338CA),
      const Color(0xFF3B82F6), // Blue
      const Color(0xFF2563EB),
      const Color(0xFF1D4ED8),
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFF0891B2),
      const Color(0xFF0E7490),
      const Color(0xFF14B8A6), // Teal
      const Color(0xFF0D9488),
      const Color(0xFF0F766E),
      const Color(0xFF8B5CF6), // Violet
      const Color(0xFF7C3AED),
      const Color(0xFF6D28D9),
      const Color(0xFFA855F7), // Purple
      const Color(0xFF9333EA),
      const Color(0xFF7E22CE),
      const Color(0xFFEC4899), // Pink
      const Color(0xFFDB2777),
      const Color(0xFFBE185D),
      const Color(0xFFF43F5E), // Rose
      const Color(0xFFE11D48),
      const Color(0xFFBE123C),
      const Color(0xFFEF4444), // Red
      const Color(0xFFDC2626),
      const Color(0xFFB91C1C),
      const Color(0xFFF59E0B), // Amber
      const Color(0xFFD97706),
      const Color(0xFFB45309),
      const Color(0xFFF97316), // Orange
      const Color(0xFFEA580C),
      const Color(0xFFC2410C),
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setPickerState) {
          void updateColor(Color c) {
            currentColor = c;
            r = c.red;
            g = c.green;
            b = c.blue;
            hexController.text = c.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase();
            setPickerState(() {});
          }

          return Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 550),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: currentColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(color: currentColor.withOpacity(0.4), blurRadius: 8),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isPrimary ? 'تخصيص اللون الأساسي' : 'تخصيص اللون الفرعي',
                                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                Text(
                                  'اختر من الباليت أو اضبط المؤشرات أو اكتب كود الـ HEX مباشرة',
                                  style: GoogleFonts.cairo(fontSize: 11.5, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),

                      // Live Hex Code input
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: hexController,
                              style: GoogleFonts.firaCode(fontWeight: FontWeight.bold, fontSize: 15),
                              decoration: InputDecoration(
                                labelText: 'كود اللون (Hex Code)',
                                prefixText: '# ',
                                prefixStyle: GoogleFonts.firaCode(fontWeight: FontWeight.bold, color: currentColor),
                                suffixIcon: Icon(LucideIcons.hash, color: currentColor),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                isDense: true,
                              ),
                              onChanged: (val) {
                                String clean = val.replaceAll('#', '').trim();
                                if (clean.length == 6) {
                                  final parsed = int.tryParse('FF$clean', radix: 16);
                                  if (parsed != null) {
                                    currentColor = Color(parsed);
                                    r = currentColor.red;
                                    g = currentColor.green;
                                    b = currentColor.blue;
                                    setPickerState(() {});
                                  }
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: currentColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.withOpacity(0.3)),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),
                      Text('باليت الألوان المتناسقة المقترحة:', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: palette.map((color) {
                          final isChosen = currentColor.value == color.value;
                          return InkWell(
                            onTap: () {
                              SoundService.lightImpact();
                              updateColor(color);
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isChosen ? Colors.white : Colors.black.withOpacity(0.15),
                                  width: isChosen ? 3 : 1,
                                ),
                                boxShadow: isChosen
                                    ? [BoxShadow(color: color.withOpacity(0.6), blurRadius: 8, spreadRadius: 1)]
                                    : null,
                              ),
                              child: isChosen
                                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 18),
                      Text('ضبط دقيق لدرجات RGB:', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 6),

                      // Red Slider
                      Row(
                        children: [
                          Text('R: $r', style: GoogleFonts.firaCode(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold)),
                          Expanded(
                            child: Slider(
                              value: r.toDouble(),
                              min: 0,
                              max: 255,
                              activeColor: Colors.red,
                              onChanged: (v) {
                                r = v.toInt();
                                updateColor(Color.fromARGB(255, r, g, b));
                              },
                            ),
                          ),
                        ],
                      ),
                      // Green Slider
                      Row(
                        children: [
                          Text('G: $g', style: GoogleFonts.firaCode(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
                          Expanded(
                            child: Slider(
                              value: g.toDouble(),
                              min: 0,
                              max: 255,
                              activeColor: Colors.green,
                              onChanged: (v) {
                                g = v.toInt();
                                updateColor(Color.fromARGB(255, r, g, b));
                              },
                            ),
                          ),
                        ],
                      ),
                      // Blue Slider
                      Row(
                        children: [
                          Text('B: $b', style: GoogleFonts.firaCode(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold)),
                          Expanded(
                            child: Slider(
                              value: b.toDouble(),
                              min: 0,
                              max: 255,
                              activeColor: Colors.blue,
                              onChanged: (v) {
                                b = v.toInt();
                                updateColor(Color.fromARGB(255, r, g, b));
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text('إلغاء', style: GoogleFonts.cairo()),
                          ),
                          const Spacer(),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: currentColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                            icon: const Icon(LucideIcons.check, size: 18),
                            label: Text('تطبيق اللون المختار', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                            onPressed: () {
                              SoundService.successFeedback();
                              if (isPrimary) {
                                ref.read(brandingProvider.notifier).updatePrimaryColor(currentColor);
                              } else {
                                ref.read(brandingProvider.notifier).updateSecondaryColor(currentColor);
                              }
                              Navigator.pop(ctx);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

