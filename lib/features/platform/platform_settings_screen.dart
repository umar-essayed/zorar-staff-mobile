import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/network/edu_api_service.dart';
import '../../core/services/sound_service.dart';
import '../../core/theme/branding_provider.dart';

class PlatformSettingsScreen extends ConsumerStatefulWidget {
  const PlatformSettingsScreen({super.key});

  @override
  ConsumerState<PlatformSettingsScreen> createState() => _PlatformSettingsScreenState();
}

class _PlatformSettingsScreenState extends ConsumerState<PlatformSettingsScreen> {
  bool enableOnlineVideos = true;
  bool enableOnlineQuizzes = true;
  bool enableOnlineBookStore = true;
  bool enableOnlinePayments = true;

  final hotlineCtrl = TextEditingController();
  final whatsappCtrl = TextEditingController();
  final heroTitleCtrl = TextEditingController();

  String _loadedPlatformUrl = '';
  bool _isSaving = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final currentTenant = await EduApiService().getCurrentTenant();
      if (currentTenant != null && currentTenant['platformUrl'] != null && currentTenant['platformUrl'].toString().isNotEmpty) {
        _loadedPlatformUrl = currentTenant['platformUrl'].toString();
      }

      final branding = ref.read(brandingProvider);
      final host = branding.subdomain.isNotEmpty ? branding.subdomain : 'main';
      final storefront = await EduApiService().getPublicStorefront(host);
      if (storefront != null && mounted) {
        if (storefront['platformUrl'] != null && storefront['platformUrl'].toString().isNotEmpty) {
          _loadedPlatformUrl = storefront['platformUrl'].toString();
        }
        final features = storefront['portalFeatures'];
        if (features is Map) {
          enableOnlineVideos = features['enableOnlineVideos'] != false;
          enableOnlineQuizzes = features['enableOnlineQuizzes'] != false;
          enableOnlineBookStore = features['enableOnlineBookStore'] != false;
          enableOnlinePayments = features['enableOnlinePayments'] != false;
        }
        final config = storefront['config'] ?? storefront;
        if (config is Map) {
          heroTitleCtrl.text = config['heroTitle']?.toString() ?? '';
          final social = config['socialLinks'];
          if (social is Map) {
            whatsappCtrl.text = social['whatsapp']?.toString() ?? '';
            hotlineCtrl.text = social['hotline']?.toString() ?? '';
          }
        }
      }
    } catch (_) {
      // Graceful fallback to empty fields
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    hotlineCtrl.dispose();
    whatsappCtrl.dispose();
    heroTitleCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      final payload = {
        'heroTitle': heroTitleCtrl.text.trim().isNotEmpty ? heroTitleCtrl.text.trim() : null,
        'socialLinks': {
          if (whatsappCtrl.text.trim().isNotEmpty) 'whatsapp': whatsappCtrl.text.trim(),
          if (hotlineCtrl.text.trim().isNotEmpty) 'hotline': hotlineCtrl.text.trim(),
        },
        'portalFeatures': {
          'enableOnlineVideos': enableOnlineVideos,
          'enableOnlineQuizzes': enableOnlineQuizzes,
          'enableOnlineBookStore': enableOnlineBookStore,
          'enableOnlinePayments': enableOnlinePayments,
        },
      };

      final success = await EduApiService().updateStorefrontConfig(payload);
      if (success) {
        SoundService.successFeedback();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Color(0xFF10B981),
              content: Text('تم حفظ إعدادات المنصة وبوابة الطلاب بنجاح! ✅'),
            ),
          );
        }
      } else {
        throw Exception('فشل تحديث البيانات في الخادم');
      }
    } catch (e) {
      SoundService.errorFeedback();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر حفظ الإعدادات: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(brandingProvider);
    final platformUrl = _loadedPlatformUrl.isNotEmpty
        ? _loadedPlatformUrl
        : 'https://${branding.subdomain.isNotEmpty ? branding.subdomain : "portal"}.eduzorar.com';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'إعدادات المنصة وبوابة الطلاب',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton.icon(
            onPressed: _isSaving ? null : _saveSettings,
            icon: _isSaving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(LucideIcons.check, size: 18),
            label: Text('حفظ', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: branding.primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Portal Link Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [branding.primaryColor, branding.primaryColor.withOpacity(0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'رابط المنصة الإلكترونية للطلاب 🌐',
                              style: GoogleFonts.cairo(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'LIVE',
                                style: GoogleFonts.cairo(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          platformUrl,
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontSize: 14,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: branding.primaryColor,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              ),
                              icon: const Icon(LucideIcons.copy, size: 16),
                              label: const Text('نسخ الرابط'),
                              onPressed: () {
                                SoundService.successFeedback();
                                Clipboard.setData(ClipboardData(text: platformUrl));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('تم نسخ رابط المنصة الإلكترونية إلى الحافظة')),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text('عنوان واجهة المنصة', style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: heroTitleCtrl,
                        decoration: const InputDecoration(
                          labelText: 'عنوان الترحيب بالطلاب في المنصة الإلكترونية',
                          hintText: 'مثال: مرحباً بكم في المنصة الرسمية',
                          prefixIcon: Icon(LucideIcons.globe, size: 20),
                          isDense: true,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text('ميزات بوابة الطلاب التفاعلية', style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),

                  Card(
                    child: Column(
                      children: [
                        SwitchListTile(
                          secondary: const Icon(LucideIcons.video, color: Color(0xFF3B82F6)),
                          title: Text('مشاهدة المحاضرات أونلاين (DRM)', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13.5)),
                          subtitle: Text('بث مشفر بعلامة مائية متحركة لمنع السرقة', style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey)),
                          value: enableOnlineVideos,
                          activeColor: branding.primaryColor,
                          onChanged: (val) => setState(() => enableOnlineVideos = val),
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          secondary: const Icon(LucideIcons.fileQuestion, color: Color(0xFF8B5CF6)),
                          title: Text('بنك الأسئلة والامتحانات الإلكترونية', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13.5)),
                          subtitle: Text('اختبارات تفاعلية بتصحيح آلي فوري', style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey)),
                          value: enableOnlineQuizzes,
                          activeColor: branding.primaryColor,
                          onChanged: (val) => setState(() => enableOnlineQuizzes = val),
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          secondary: const Icon(LucideIcons.bookOpen, color: Color(0xFFF59E0B)),
                          title: Text('ملازم وكتب المنصة الإلكترونية', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13.5)),
                          subtitle: Text('إتاحة طلب المذكرات واستلامها من السنتر أو شحنها', style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey)),
                          value: enableOnlineBookStore,
                          activeColor: branding.primaryColor,
                          onChanged: (val) => setState(() => enableOnlineBookStore = val),
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          secondary: const Icon(LucideIcons.wallet, color: Color(0xFF10B981)),
                          title: Text('سداد الاشتراكات والمحفظة أونلاين', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13.5)),
                          subtitle: Text('الدفع عبر المحافظ الإلكترونية وبطاقات الدفع', style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey)),
                          value: enableOnlinePayments,
                          activeColor: branding.primaryColor,
                          onChanged: (val) => setState(() => enableOnlinePayments = val),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text('قنوات التواصل على المنصة الإلكترونية', style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          TextField(
                            controller: hotlineCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'الخط الساخن أو هاتف السنتر',
                              hintText: 'أدخل رقم الهاتف...',
                              prefixIcon: Icon(LucideIcons.phone, size: 20),
                              isDense: true,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: whatsappCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'رقم واتساب خدمة أولياء الأمور والطلاب',
                              hintText: 'أدخل رقم واتساب (مثال: 01012345678)...',
                              prefixIcon: Icon(LucideIcons.messageSquare, size: 20),
                              isDense: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: branding.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: _isSaving
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(LucideIcons.save, size: 18),
                      label: Text(
                        'حفظ إعدادات المنصة',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      onPressed: _isSaving ? null : _saveSettings,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
