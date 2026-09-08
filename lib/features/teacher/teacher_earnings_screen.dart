import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/branding_provider.dart';

class TeacherEarningsScreen extends ConsumerWidget {
  const TeacherEarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branding = ref.watch(brandingProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'كشف حساب ومستحقات المعلم',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Net Earnings Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF0F172A),
                    const Color(0xFF1E293B),
                  ],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: branding.primaryColor.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'إجمالي مستحقاتك عن الشهر الجاري (سبتمبر 2026)',
                    style: GoogleFonts.cairo(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '29,400 ج.م',
                    style: GoogleFonts.cairo(
                      color: branding.primaryColor,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'نسبة المعلم المعتمدة: 70%',
                          style: GoogleFonts.cairo(
                            color: const Color(0xFF10B981),
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '16 حصة • 185 طالب',
                        style: GoogleFonts.cairo(color: Colors.white60, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'سجل الحصص المنعقدة وتفاصيل الحضور',
              style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            _buildSessionItem(
              sessionTitle: 'حصة 5: مراجعة البلاغة والنصوص المتحررة',
              groupName: '3ث لغة عربية (أ)',
              date: 'السبت 5 سبتمبر 2026',
              attendance: '42 حاضر من 45',
              earnings: '2,646 ج.م',
              isSettled: false,
              primaryColor: branding.primaryColor,
            ),
            const SizedBox(height: 10),
            _buildSessionItem(
              sessionTitle: 'حصة 4: تدريبات النحو الشاملة',
              groupName: '3ث لغة عربية (أ)',
              date: 'الخميس 3 سبتمبر 2026',
              attendance: '44 حاضر من 45',
              earnings: '2,772 ج.م',
              isSettled: true,
              primaryColor: branding.primaryColor,
            ),
            const SizedBox(height: 10),
            _buildSessionItem(
              sessionTitle: 'حصة 3: مدرسة الإحياء والبعث',
              groupName: '3ث لغة عربية (أ)',
              date: 'السبت 29 أغسطس 2026',
              attendance: '43 حاضر من 45',
              earnings: '2,709 ج.م',
              isSettled: true,
              primaryColor: branding.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionItem({
    required String sessionTitle,
    required String groupName,
    required String date,
    required String attendance,
    required String earnings,
    required bool isSettled,
    required Color primaryColor,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(LucideIcons.calendarCheck, color: primaryColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sessionTitle,
                    style: GoogleFonts.cairo(fontSize: 13.5, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '$groupName • $date',
                    style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'العدد: $attendance',
                    style: GoogleFonts.cairo(fontSize: 11.5, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  earnings,
                  style: GoogleFonts.cairo(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF10B981),
                  ),
                ),
                Text(
                  isSettled ? 'مسددة ✅' : 'قيد الصرف ⏳',
                  style: GoogleFonts.cairo(
                    fontSize: 10.5,
                    color: isSettled ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
