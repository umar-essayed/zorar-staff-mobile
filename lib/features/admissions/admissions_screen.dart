import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/services/sound_service.dart';
import '../../core/theme/branding_provider.dart';

class AdmissionApplication {
  final String id;
  final String studentName;
  final String phone;
  final String parentPhone;
  final String academicYear;
  final String requestedGroup;
  final String school;
  final String status; // 'معلق', 'مقبول', 'مرفوض'
  final DateTime appliedAt;

  AdmissionApplication({
    required this.id,
    required this.studentName,
    required this.phone,
    required this.parentPhone,
    required this.academicYear,
    required this.requestedGroup,
    required this.school,
    required this.status,
    required this.appliedAt,
  });
}

class AdmissionsScreen extends ConsumerStatefulWidget {
  const AdmissionsScreen({super.key});

  @override
  ConsumerState<AdmissionsScreen> createState() => _AdmissionsScreenState();
}

class _AdmissionsScreenState extends ConsumerState<AdmissionsScreen> {
  String activeFilter = 'معلق';

  late final List<AdmissionApplication> applications = [
    AdmissionApplication(
      id: 'ADM-201',
      studentName: 'أنس محمد عبد المنعم',
      phone: '01099887766',
      parentPhone: '01122334455',
      academicYear: 'الصف الثالث الثانوي',
      requestedGroup: '3ث لغة عربية (أ) - أ/ أحمد كمال',
      school: 'مدرسة المتفوقين الثانوية',
      status: 'معلق',
      appliedAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    AdmissionApplication(
      id: 'ADM-202',
      studentName: 'روان شريف الصاوي',
      phone: '01233445566',
      parentPhone: '01011223344',
      academicYear: 'الصف الثاني الثانوي',
      requestedGroup: '2ث كيمياء (ب) - أ/ حسام فؤاد',
      school: 'مدرسة الأورمان لغات',
      status: 'معلق',
      appliedAt: DateTime.now().subtract(const Duration(hours: 6)),
    ),
    AdmissionApplication(
      id: 'ADM-203',
      studentName: 'محمود عبد الرازق حسن',
      phone: '01012345678',
      parentPhone: '01198765432',
      academicYear: 'الصف الثالث الثانوي',
      requestedGroup: '3ث لغة عربية (أ)',
      school: 'مدرسة السعيدية',
      status: 'مقبول',
      appliedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    AdmissionApplication(
      id: 'ADM-204',
      studentName: 'ياسين أحمد المهدي',
      phone: '01511223344',
      parentPhone: '01066778899',
      academicYear: 'الصف الأول الثانوي',
      requestedGroup: '1ث فيزياء (ج)',
      school: 'مدرسة النصر',
      status: 'مرفوض',
      appliedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(brandingProvider);

    final filtered = applications.where((a) {
      if (activeFilter == 'الكل') return true;
      return a.status == activeFilter;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'طلبات التقديم والحجز الإلكتروني',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            padding: const EdgeInsets.all(12),
            color: Theme.of(context).cardColor,
            child: Row(
              children: [
                _buildTab('معلق ⏳ (${applications.where((a) => a.status == 'معلق').length})', 'معلق'),
                const SizedBox(width: 8),
                _buildTab('مقبول ✅ (${applications.where((a) => a.status == 'مقبول').length})', 'مقبول'),
                const SizedBox(width: 8),
                _buildTab('مرفوض ❌ (${applications.where((a) => a.status == 'مرفوض').length})', 'مرفوض'),
                const SizedBox(width: 8),
                _buildTab('الكل', 'الكل'),
              ],
            ),
          ),

          // Applications List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      'لا توجد طلبات في هذا القسم',
                      style: GoogleFonts.cairo(color: Colors.grey),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(14),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, idx) {
                      final item = filtered[idx];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: branding.primaryColor.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          item.id,
                                          style: GoogleFonts.cairo(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: branding.primaryColor,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        item.academicYear,
                                        style: GoogleFonts.cairo(
                                          fontSize: 11.5,
                                          color: Colors.grey,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  _buildStatusBadge(item.status),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                item.studentName,
                                style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'المجموعة المطلوبة: ${item.requestedGroup}',
                                style: GoogleFonts.cairo(
                                  fontSize: 12.5,
                                  color: branding.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'المدرسة: ${item.school}',
                                style: GoogleFonts.cairo(fontSize: 11.5, color: Colors.grey),
                              ),
                              const Divider(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'هاتف الطالب: ${item.phone}\nولي الأمر: ${item.parentPhone}',
                                      style: GoogleFonts.cairo(fontSize: 11.5, height: 1.4),
                                    ),
                                  ),
                                  IconButton.filledTonal(
                                    icon: const Icon(LucideIcons.phoneCall, size: 16),
                                    tooltip: 'اتصال هاتفي',
                                    onPressed: () {},
                                  ),
                                  const SizedBox(width: 6),
                                  IconButton.filledTonal(
                                    icon: const Icon(LucideIcons.messageSquare, size: 16),
                                    tooltip: 'مراسلة واتساب',
                                    onPressed: () {},
                                  ),
                                ],
                              ),
                              if (item.status == 'معلق') ...[
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF10B981),
                                          foregroundColor: Colors.white,
                                        ),
                                        icon: const Icon(LucideIcons.check, size: 16),
                                        label: const Text('قبول وتوليد كارت'),
                                        onPressed: () {
                                          SoundService.successFeedback();
                                          setState(() {
                                            applications[applications.indexOf(item)] =
                                                AdmissionApplication(
                                              id: item.id,
                                              studentName: item.studentName,
                                              phone: item.phone,
                                              parentPhone: item.parentPhone,
                                              academicYear: item.academicYear,
                                              requestedGroup: item.requestedGroup,
                                              school: item.school,
                                              status: 'مقبول',
                                              appliedAt: item.appliedAt,
                                            );
                                          });
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              backgroundColor: const Color(0xFF10B981),
                                              content: Text(
                                                'تم قبول الطالب ${item.studentName} وتوليد الكود STU-1095 وطباعة الكارت بنجاح',
                                                style: GoogleFonts.cairo(),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red,
                                        side: const BorderSide(color: Colors.red),
                                      ),
                                      icon: const Icon(LucideIcons.x, size: 16),
                                      label: const Text('رفض'),
                                      onPressed: () {
                                        SoundService.warningFeedback();
                                        setState(() {
                                          applications[applications.indexOf(item)] =
                                              AdmissionApplication(
                                            id: item.id,
                                            studentName: item.studentName,
                                            phone: item.phone,
                                            parentPhone: item.parentPhone,
                                            academicYear: item.academicYear,
                                            requestedGroup: item.requestedGroup,
                                            school: item.school,
                                            status: 'مرفوض',
                                            appliedAt: item.appliedAt,
                                          );
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, String value) {
    final isSelected = activeFilter == value;
    final branding = ref.watch(brandingProvider);

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => activeFilter = value),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? branding.primaryColor : Colors.grey.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : null,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    switch (status) {
      case 'مقبول':
        bg = const Color(0xFF10B981).withOpacity(0.12);
        fg = const Color(0xFF10B981);
        break;
      case 'مرفوض':
        bg = const Color(0xFFEF4444).withOpacity(0.12);
        fg = const Color(0xFFEF4444);
        break;
      default:
        bg = const Color(0xFFF59E0B).withOpacity(0.12);
        fg = const Color(0xFFF59E0B);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        status,
        style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}
