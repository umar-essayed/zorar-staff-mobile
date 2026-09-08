import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/network/edu_api_service.dart';
import '../../core/providers/edu_data_providers.dart';
import '../../core/services/sound_service.dart';
import '../../core/theme/branding_provider.dart';
import '../attendance/attendance_scanner_screen.dart';
import 'group_form_dialog.dart';

class AcademicGroupsScreen extends ConsumerStatefulWidget {
  const AcademicGroupsScreen({super.key});

  @override
  ConsumerState<AcademicGroupsScreen> createState() => _AcademicGroupsScreenState();
}

class _AcademicGroupsScreenState extends ConsumerState<AcademicGroupsScreen> {
  String? _selectedYearFilter;

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(brandingProvider);
    final groupsAsync = ref.watch(liveGroupsProvider);
    final yearsAsync = ref.watch(liveAcademicYearsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'إدارة المجموعات والقاعات',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plus),
            tooltip: 'إضافة مجموعة جديدة',
            onPressed: () {
              SoundService.lightImpact();
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
          // Filter Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.15))),
            ),
            child: yearsAsync.when(
              data: (years) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ChoiceChip(
                        label: Text('جميع المراحل', style: GoogleFonts.cairo(fontSize: 11.5, fontWeight: FontWeight.bold)),
                        selected: _selectedYearFilter == null,
                        selectedColor: branding.primaryColor,
                        labelStyle: TextStyle(color: _selectedYearFilter == null ? Colors.white : Colors.grey[700]),
                        onSelected: (sel) {
                          if (sel) setState(() => _selectedYearFilter = null);
                        },
                      ),
                      ...years.map((y) {
                        final id = y['id'].toString();
                        final isSel = _selectedYearFilter == id;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(y['name'] ?? '', style: GoogleFonts.cairo(fontSize: 11.5)),
                            selected: isSel,
                            selectedColor: branding.primaryColor,
                            labelStyle: TextStyle(color: isSel ? Colors.white : Colors.grey[700]),
                            onSelected: (sel) {
                              setState(() => _selectedYearFilter = sel ? id : null);
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
              loading: () => const SizedBox(height: 32),
              error: (_, __) => const SizedBox(),
            ),
          ),

          // Groups List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(liveGroupsProvider);
              },
              child: groupsAsync.when(
                data: (groups) {
                  final filtered = groups.where((g) {
                    if (_selectedYearFilter != null && g['academicYearId'] != _selectedYearFilter) {
                      return false;
                    }
                    return true;
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.layers, size: 50, color: Colors.grey.withOpacity(0.4)),
                          const SizedBox(height: 12),
                          Text('لا توجد مجموعات دراسية مطابقة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.grey)),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: branding.primaryColor),
                            icon: const Icon(LucideIcons.plus, size: 16),
                            label: const Text('إضافة أول مجموعة الآن'),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => const GroupFormDialog(),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(14),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) {
                      final group = filtered[i];
                      return _buildGroupCard(group, branding);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.alertCircle, color: Colors.red, size: 36),
                      const SizedBox(height: 8),
                      Text('تعذر تحميل المجموعات من السيرفر', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(liveGroupsProvider),
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupCard(Map<String, dynamic> g, dynamic branding) {
    final id = g['id'].toString();
    final name = g['name'] ?? 'مجموعة';
    final yearName = g['academicYear']?['name'] ?? '-';
    final subjectName = g['subject']?['name'] ?? '-';
    final teacherName = g['teacher']?['name'] ?? 'غير محدد';
    final fee = g['monthlyFee'] ?? g['monthlyPrice'] ?? 0;
    final maxStudents = g['maxStudents'] ?? 50;
    final startTime = g['startTime'] ?? '16:00';
    final endTime = g['endTime'] ?? '18:00';

    return Card(
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(LucideIcons.moreVertical, size: 18),
                  onSelected: (action) async {
                    if (action == 'EDIT') {
                      showDialog(
                        context: context,
                        builder: (ctx) => GroupFormDialog(initialGroup: g),
                      );
                    } else if (action == 'DELETE') {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('حذف المجموعة'),
                          content: Text('هل أنت متأكد من رغبتك في حذف $name؟', style: GoogleFonts.cairo()),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('حذف'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await EduApiService().deleteGroup(id);
                        ref.invalidate(liveGroupsProvider);
                      }
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(value: 'EDIT', child: Text('تعديل المجموعة')),
                    const PopupMenuItem(value: 'DELETE', child: Text('حذف المجموعة', style: TextStyle(color: Colors.red))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: branding.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    subjectName,
                    style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold, color: branding.primaryColor),
                  ),
                ),
                const SizedBox(width: 8),
                Text('$yearName • المدرس: $teacherName', style: GoogleFonts.cairo(fontSize: 11.5, color: Colors.grey[700])),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.clock, size: 15, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('$startTime - $endTime', style: GoogleFonts.cairo(fontSize: 11.5, color: Colors.grey[700])),
                    const SizedBox(width: 14),
                    const Icon(LucideIcons.users, size: 15, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('السعة: $maxStudents', style: GoogleFonts.cairo(fontSize: 11.5, color: Colors.grey[700])),
                  ],
                ),
                Text(
                  '$fee ج.م / شهر',
                  style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF10B981)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: branding.primaryColor.withOpacity(0.12),
                  foregroundColor: branding.primaryColor,
                  elevation: 0,
                ),
                icon: const Icon(LucideIcons.qrCode, size: 16),
                label: const Text('بدء مسح حضور هذه المجموعة'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) => AttendanceScannerScreen(initialGroupId: id),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
