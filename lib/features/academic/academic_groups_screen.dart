import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/branding_provider.dart';
import 'group_form_dialog.dart';

class AcademicGroup {
  final String id;
  final String name;
  final String year;
  final String teacher;
  final String room;
  final String schedule;
  final int enrolled;
  final int capacity;
  final double fee;

  AcademicGroup({
    required this.id,
    required this.name,
    required this.year,
    required this.teacher,
    required this.room,
    required this.schedule,
    required this.enrolled,
    required this.capacity,
    required this.fee,
  });
}

class AcademicGroupsScreen extends ConsumerStatefulWidget {
  const AcademicGroupsScreen({super.key});

  @override
  ConsumerState<AcademicGroupsScreen> createState() => _AcademicGroupsScreenState();
}

class _AcademicGroupsScreenState extends ConsumerState<AcademicGroupsScreen> {
  String selectedYearFilter = 'الكل';

  final List<AcademicGroup> groups = [
    AcademicGroup(
      id: 'GRP-101',
      name: '3ث لغة عربية (المجموعة أ)',
      year: 'الصف الثالث الثانوي',
      teacher: 'أ/ أحمد كمال',
      room: 'قاعة (1)',
      schedule: 'السبت والثلاثاء (02:00 م - 04:00 م)',
      enrolled: 42,
      capacity: 45,
      fee: 450,
    ),
    AcademicGroup(
      id: 'GRP-102',
      name: '2ث كيمياء (مجموعة النخبة)',
      year: 'الصف الثاني الثانوي',
      teacher: 'أ/ حسام فؤاد',
      room: 'قاعة (2)',
      schedule: 'الأحد والأربعاء (04:30 م - 06:30 م)',
      enrolled: 34,
      capacity: 40,
      fee: 400,
    ),
    AcademicGroup(
      id: 'GRP-103',
      name: '1ث فيزياء (تأسيس وشرح مكثف)',
      year: 'الصف الأول الثانوي',
      teacher: 'أ/ محمد إبراهيم',
      room: 'قاعة (1)',
      schedule: 'السبت والخميس (07:00 م - 09:00 م)',
      enrolled: 28,
      capacity: 35,
      fee: 380,
    ),
    AcademicGroup(
      id: 'GRP-104',
      name: '3ث أحياء (مراجعة نهائية)',
      year: 'الصف الثالث الثانوي',
      teacher: 'د/ محمود سامي',
      room: 'قاعة (3)',
      schedule: 'الاثنين والخميس (03:00 م - 05:00 م)',
      enrolled: 45,
      capacity: 50,
      fee: 450,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(brandingProvider);

    final filtered = groups.where((g) {
      if (selectedYearFilter == 'الكل') return true;
      return g.year == selectedYearFilter;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'إدارة المجموعات والمراحل الدراسية',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plusCircle),
            tooltip: 'إنشاء مجموعة جديدة',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => const GroupFormDialog(),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter by Academic Year
          Container(
            padding: const EdgeInsets.all(12),
            color: Theme.of(context).cardColor,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildYearChip('الكل (${groups.length})', 'الكل'),
                  const SizedBox(width: 8),
                  _buildYearChip('3ث ثانوي', 'الصف الثالث الثانوي'),
                  const SizedBox(width: 8),
                  _buildYearChip('2ث ثانوي', 'الصف الثاني الثانوي'),
                  const SizedBox(width: 8),
                  _buildYearChip('1ث ثانوي', 'الصف الأول الثانوي'),
                ],
              ),
            ),
          ),

          // Groups List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(14),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, idx) {
                final g = filtered[idx];
                final percentage = (g.enrolled / g.capacity).clamp(0.0, 1.0);
                final isAlmostFull = percentage >= 0.9;

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              g.name,
                              style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: branding.primaryColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${g.fee.toInt()} ج.م / شهر',
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: branding.primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${g.teacher} • ${g.room}',
                          style: GoogleFonts.cairo(fontSize: 12.5, color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(LucideIcons.clock, size: 14, color: Colors.grey),
                            const SizedBox(width: 6),
                            Text(
                              g.schedule,
                              style: GoogleFonts.cairo(fontSize: 11.5, color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Capacity Progress Bar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'نسبة الإشغال: ${g.enrolled} من ${g.capacity} طالب',
                              style: GoogleFonts.cairo(fontSize: 11.5, fontWeight: FontWeight.w600),
                            ),
                            if (isAlmostFull)
                              Text(
                                'أوشكت على الاكتمال 🔥',
                                style: GoogleFonts.cairo(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.bold),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: percentage,
                            backgroundColor: Colors.grey.withOpacity(0.2),
                            valueColor: AlwaysStoppedAnimation(
                              isAlmostFull ? Colors.orange : branding.primaryColor,
                            ),
                            minHeight: 6,
                          ),
                        ),
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

  Widget _buildYearChip(String label, String value) {
    final isSelected = selectedYearFilter == value;
    final branding = ref.watch(brandingProvider);

    return FilterChip(
      label: Text(
        label,
        style: GoogleFonts.cairo(
          fontSize: 11.5,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : null,
        ),
      ),
      selected: isSelected,
      selectedColor: branding.primaryColor,
      onSelected: (_) => setState(() => selectedYearFilter = value),
    );
  }
}
