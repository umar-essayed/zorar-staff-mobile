import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/branding_provider.dart';
import '../attendance/attendance_scanner_screen.dart';
import '../attendance/emergency_session_dialog.dart';
import '../cashier/mobile_pos_screen.dart';
import '../cashier/shift_closing_dialog.dart';
import '../students/student_form_dialog.dart';

class AssistantDashboardScreen extends ConsumerWidget {
  const AssistantDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branding = ref.watch(brandingProvider);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shift Quick Status Banner
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF1E293B),
                    const Color(0xFF0F172A),
                  ],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: branding.primaryColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: branding.primaryColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(LucideIcons.scanLine, color: branding.primaryColor, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'شيفت الاستقبال مفتوح 🟢',
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'نقدية الدرج الحالية: 8,450 ج.م (34 إيصال)',
                          style: GoogleFonts.cairo(
                            color: Colors.white70,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    icon: const Icon(LucideIcons.lock),
                    tooltip: 'تقفيل الدرج والشيفت',
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => const ShiftClosingDialog(),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // High-Speed Field Action Buttons
            Text(
              'العمليات الميدانية السريعة',
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildActionTile(
                    context: context,
                    title: 'تسجيل الحضور',
                    subtitle: 'مسح QR سريع',
                    icon: LucideIcons.qrCode,
                    color: branding.primaryColor,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (ctx) => const AttendanceScannerScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionTile(
                    context: context,
                    title: 'نقطة البيع',
                    subtitle: 'تحصيل وملازم',
                    icon: LucideIcons.receipt,
                    color: const Color(0xFF3B82F6),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (ctx) => const MobilePosScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildActionTile(
                    context: context,
                    title: 'طالب جديد',
                    subtitle: 'إصدار بطاقة فورية',
                    icon: LucideIcons.userPlus,
                    color: const Color(0xFF8B5CF6),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => const StudentFormDialog(),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionTile(
                    context: context,
                    title: 'حصة إضافية',
                    subtitle: 'جلسة بديلة',
                    icon: LucideIcons.calendarPlus,
                    color: const Color(0xFFF59E0B),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => const EmergencySessionDialog(),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Today's Active Groups in the Center
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'الحصص المنعقدة اليوم بالسنتر',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '4 مجموعات',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            _buildGroupStatusCard(
              groupName: 'مجموعة 3ث لغة عربية (أ)',
              teacherName: 'أ/ أحمد كمال',
              time: '02:00 م - 04:00 م (قاعة 1)',
              attendedCount: 42,
              totalCount: 45,
              statusText: 'منعقدة الآن',
              isLive: true,
              brandingColor: branding.primaryColor,
            ),
            const SizedBox(height: 10),
            _buildGroupStatusCard(
              groupName: 'مجموعة 2ث كيمياء (ب)',
              teacherName: 'أ/ حسام فؤاد',
              time: '04:30 م - 06:30 م (قاعة 2)',
              attendedCount: 0,
              totalCount: 38,
              statusText: 'تبدأ قريباً',
              isLive: false,
              brandingColor: branding.primaryColor,
            ),
            const SizedBox(height: 10),
            _buildGroupStatusCard(
              groupName: 'مجموعة 1ث فيزياء (ج)',
              teacherName: 'أ/ محمد إبراهيم',
              time: '07:00 م - 09:00 م (قاعة 1)',
              attendedCount: 0,
              totalCount: 30,
              statusText: 'تبدأ قريباً',
              isLive: false,
              brandingColor: branding.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.cairo(
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupStatusCard({
    required String groupName,
    required String teacherName,
    required String time,
    required int attendedCount,
    required int totalCount,
    required String statusText,
    required bool isLive,
    required Color brandingColor,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isLive ? brandingColor.withOpacity(0.15) : Colors.grey.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isLive ? LucideIcons.radio : LucideIcons.clock,
                color: isLive ? brandingColor : Colors.grey,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    groupName,
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$teacherName • $time',
                    style: GoogleFonts.cairo(
                      fontSize: 11.5,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$attendedCount / $totalCount',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isLive ? brandingColor : Colors.grey,
                  ),
                ),
                Text(
                  statusText,
                  style: GoogleFonts.cairo(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isLive ? const Color(0xFF10B981) : Colors.grey,
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
