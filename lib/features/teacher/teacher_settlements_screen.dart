import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/services/sound_service.dart';
import '../../core/theme/branding_provider.dart';

class TeacherSettlementItem {
  final String teacherName;
  final String subject;
  final int totalSessions;
  final int totalStudents;
  final double grossRevenue;
  final double teacherPercentage; // e.g. 70%
  final double teacherCut;
  final double centerCut;
  final bool isPaid;

  TeacherSettlementItem({
    required this.teacherName,
    required this.subject,
    required this.totalSessions,
    required this.totalStudents,
    required this.grossRevenue,
    required this.teacherPercentage,
    required this.teacherCut,
    required this.centerCut,
    required this.isPaid,
  });
}

class TeacherSettlementsScreen extends ConsumerStatefulWidget {
  const TeacherSettlementsScreen({super.key});

  @override
  ConsumerState<TeacherSettlementsScreen> createState() => _TeacherSettlementsScreenState();
}

class _TeacherSettlementsScreenState extends ConsumerState<TeacherSettlementsScreen> {
  late final List<TeacherSettlementItem> settlements = [
    TeacherSettlementItem(
      teacherName: 'أ/ أحمد كمال',
      subject: 'لغة عربية (ثانوية عامة)',
      totalSessions: 16,
      totalStudents: 185,
      grossRevenue: 42000,
      teacherPercentage: 70,
      teacherCut: 29400,
      centerCut: 12600,
      isPaid: false,
    ),
    TeacherSettlementItem(
      teacherName: 'أ/ حسام فؤاد',
      subject: 'كيمياء (أولى وثانية ثانوي)',
      totalSessions: 12,
      totalStudents: 110,
      grossRevenue: 26400,
      teacherPercentage: 65,
      teacherCut: 17160,
      centerCut: 9240,
      isPaid: false,
    ),
    TeacherSettlementItem(
      teacherName: 'أ/ محمد إبراهيم',
      subject: 'فيزياء',
      totalSessions: 8,
      totalStudents: 75,
      grossRevenue: 18000,
      teacherPercentage: 70,
      teacherCut: 12600,
      centerCut: 5400,
      isPaid: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(brandingProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'تسويات ونسب المعلمين',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(14),
        itemCount: settlements.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (ctx, idx) {
          final item = settlements[idx];
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.teacherName,
                            style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            item.subject,
                            style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: item.isPaid
                              ? const Color(0xFF10B981).withOpacity(0.12)
                              : const Color(0xFFF59E0B).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.isPaid ? 'تمت التسوية ✅' : 'مستحق الصرف ⏳',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: item.isPaid ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: _buildMiniStat('إجمالي الدخل', '${item.grossRevenue.toStringAsFixed(0)} ج.م'),
                      ),
                      Expanded(
                        child: _buildMiniStat('نسبة المدرس', '${item.teacherPercentage.toInt()}%'),
                      ),
                      Expanded(
                        child: _buildMiniStat('حصة السنتر', '${item.centerCut.toStringAsFixed(0)} ج.م'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: branding.primaryColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'صافي مستحقات المعلم:',
                          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          '${item.teacherCut.toStringAsFixed(0)} ج.م',
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            color: branding.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (!item.isPaid) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(LucideIcons.checkCheck, size: 16),
                        label: const Text('اعتماد وصرف المستحقات مع سند قبض'),
                        onPressed: () {
                          SoundService.successFeedback();
                          setState(() {
                            settlements[idx] = TeacherSettlementItem(
                              teacherName: item.teacherName,
                              subject: item.subject,
                              totalSessions: item.totalSessions,
                              totalStudents: item.totalStudents,
                              grossRevenue: item.grossRevenue,
                              teacherPercentage: item.teacherPercentage,
                              teacherCut: item.teacherCut,
                              centerCut: item.centerCut,
                              isPaid: true,
                            );
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: const Color(0xFF10B981),
                              content: Text('تم اعتماد صرف مستحقات ${item.teacherName} بنجاح!'),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value, style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
