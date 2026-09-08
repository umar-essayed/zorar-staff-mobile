import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/services/sound_service.dart';
import '../../core/theme/branding_provider.dart';

class StudentGradingItem {
  final String code;
  final String name;
  bool isPresent;
  int oralScore; // 0-10
  String homeworkStatus; // 'كامل', 'جزئي', 'لم يحل'
  String note;

  StudentGradingItem({
    required this.code,
    required this.name,
    this.isPresent = true,
    this.oralScore = 10,
    this.homeworkStatus = 'كامل',
    this.note = '',
  });
}

class LiveClassCockpitScreen extends ConsumerStatefulWidget {
  final String groupName;
  final int sessionNumber;

  const LiveClassCockpitScreen({
    super.key,
    required this.groupName,
    required this.sessionNumber,
  });

  @override
  ConsumerState<LiveClassCockpitScreen> createState() => _LiveClassCockpitScreenState();
}

class _LiveClassCockpitScreenState extends ConsumerState<LiveClassCockpitScreen> {
  late final List<StudentGradingItem> students = [
    StudentGradingItem(code: 'STU-1004', name: 'محمود عبد الرازق حسن', oralScore: 10, homeworkStatus: 'كامل'),
    StudentGradingItem(code: 'STU-1022', name: 'سلمى إبراهيم خليل', oralScore: 9, homeworkStatus: 'كامل'),
    StudentGradingItem(code: 'STU-1088', name: 'عمر خالد المنشاوي', oralScore: 7, homeworkStatus: 'جزئي'),
    StudentGradingItem(code: 'STU-1011', name: 'يوسف مصطفى إبراهيم', oralScore: 10, homeworkStatus: 'كامل'),
    StudentGradingItem(code: 'STU-1055', name: 'مريم أحمد الشناوي', oralScore: 8, homeworkStatus: 'كامل'),
    StudentGradingItem(code: 'STU-1064', name: 'كريم طارق البنا', oralScore: 5, homeworkStatus: 'لم يحل'),
    StudentGradingItem(code: 'STU-1073', name: 'فاطمة علي الدسوقي', oralScore: 9, homeworkStatus: 'كامل'),
  ];

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(brandingProvider);
    final presentCount = students.where((s) => s.isPresent).length;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.groupName, style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold)),
            Text('الحصة رقم (${widget.sessionNumber}) • رصد التسميع والواجب',
                style: GoogleFonts.cairo(fontSize: 11.5, color: Colors.grey)),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: branding.primaryColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.users, size: 16, color: branding.primaryColor),
                const SizedBox(width: 6),
                Text(
                  '$presentCount / ${students.length} حاضر',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: branding.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(14),
        itemCount: students.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (ctx, idx) {
          final student = students[idx];
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(14.0),
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
                            student.name,
                            style: GoogleFonts.cairo(fontSize: 14.5, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            student.code,
                            style: GoogleFonts.cairo(fontSize: 11.5, color: Colors.grey),
                          ),
                        ],
                      ),
                      // Presence switch
                      FilterChip(
                        label: Text(student.isPresent ? 'حاضر ✅' : 'غائب ❌'),
                        selected: student.isPresent,
                        selectedColor: branding.primaryColor.withOpacity(0.2),
                        onSelected: (val) {
                          setState(() => student.isPresent = val);
                        },
                      ),
                    ],
                  ),
                  const Divider(height: 20),

                  // Oral Grade (درجة التسميع الشفوي)
                  Row(
                    children: [
                      Text(
                        'درجة التسميع: ',
                        style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: branding.primaryColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${student.oralScore} / 10',
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: branding.primaryColor,
                          ),
                        ),
                      ),
                      const Spacer(),
                      IconButton.filledTonal(
                        icon: const Icon(LucideIcons.minus, size: 14),
                        onPressed: student.oralScore > 0
                            ? () {
                                SoundService.successFeedback();
                                setState(() => student.oralScore--);
                              }
                            : null,
                      ),
                      const SizedBox(width: 6),
                      IconButton.filled(
                        icon: const Icon(LucideIcons.plus, size: 14),
                        onPressed: student.oralScore < 10
                            ? () {
                                SoundService.successFeedback();
                                setState(() => student.oralScore++);
                              }
                            : null,
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Homework Assessment (تقييم الواجب)
                  Row(
                    children: [
                      Text(
                        'حالة الواجب: ',
                        style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 8),
                      _buildHwChip(student, 'كامل', const Color(0xFF10B981)),
                      const SizedBox(width: 6),
                      _buildHwChip(student, 'جزئي', const Color(0xFFF59E0B)),
                      const SizedBox(width: 6),
                      _buildHwChip(student, 'لم يحل', const Color(0xFFEF4444)),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            icon: const Icon(LucideIcons.save, size: 18),
            label: const Text('حفظ تقرير الحصة وإرسال إشعارات لأولياء الأمور'),
            onPressed: () {
              SoundService.successFeedback();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Color(0xFF10B981),
                  content: Text('تم حفظ درجات الحصة وإرسال تقارير التسميع بنجاح!'),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHwChip(StudentGradingItem student, String status, Color color) {
    final isSelected = student.homeworkStatus == status;
    return InkWell(
      onTap: () {
        SoundService.successFeedback();
        setState(() => student.homeworkStatus = status);
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          status,
          style: GoogleFonts.cairo(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : color,
          ),
        ),
      ),
    );
  }
}
