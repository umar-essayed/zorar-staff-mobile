import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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

  final hotlineCtrl = TextEditingController(text: '01000000001');
  final whatsappCtrl = TextEditingController(text: '01000000001');

  @override
  void dispose() {
    hotlineCtrl.dispose();
    whatsappCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(brandingProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'المنصة والمتجر الإلكتروني (Portal)',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
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
                        'رابط منصة وحجز السنتر العام 🌐',
                        style: GoogleFonts.cairo(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'PRO',
                          style: GoogleFonts.cairo(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'https://zorar.app/p/center-alnoor',
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
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('تم نسخ رابط لاندينج السنتر إلى الحافظة')),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                        icon: const Icon(LucideIcons.share2, size: 16),
                        label: const Text('مشاركة'),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
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
                    title: Text('متجر الملازم والكتب مع التوصيل', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13.5)),
                    subtitle: Text('إتاحة طلب المذكرات واستلامها من السنتر', style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey)),
                    value: enableOnlineBookStore,
                    activeColor: branding.primaryColor,
                    onChanged: (val) => setState(() => enableOnlineBookStore = val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(LucideIcons.wallet, color: Color(0xFF10B981)),
                    title: Text('سداد الاشتراكات والمحفظة أونلاين', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13.5)),
                    subtitle: Text('الدفع عبر فودافون كاش، إنستاباي، وبطاقات ميزة', style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey)),
                    value: enableOnlinePayments,
                    activeColor: branding.primaryColor,
                    onChanged: (val) => setState(() => enableOnlinePayments = val),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Text('قنوات التواصل على لاندينج السنتر', style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold)),
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
                        prefixIcon: Icon(LucideIcons.phone, size: 20),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: whatsappCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'رقم واتساب خدمة أولياء الأمور',
                        prefixIcon: Icon(LucideIcons.messageSquare, size: 20),
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
