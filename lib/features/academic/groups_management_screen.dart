import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/network/edu_api_service.dart';
import '../../core/providers/edu_data_providers.dart';
import '../../core/services/sound_service.dart';
import '../../core/theme/branding_provider.dart';
import '../../core/utils/numeric_utils.dart';
import '../students/students_list_screen.dart';
import '../teacher/live_class_cockpit_screen.dart';
import 'group_form_dialog.dart';

class GroupsManagementScreen extends ConsumerStatefulWidget {
  const GroupsManagementScreen({super.key});

  @override
  ConsumerState<GroupsManagementScreen> createState() => _GroupsManagementScreenState();
}

class _GroupsManagementScreenState extends ConsumerState<GroupsManagementScreen> {
  String _searchQuery = '';
  String _selectedSubjectFilter = 'الكل';
  String _selectedTeacherFilter = 'الكل';

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(brandingProvider);
    final groupsAsync = ref.watch(liveGroupsProvider);
    final subjectsAsync = ref.watch(liveSubjectsProvider);
    final teachersAsync = ref.watch(liveTeachersProvider);

    final subjectsList = ['الكل', ...(subjectsAsync.value?.map((s) => s['name']?.toString() ?? '') ?? [])];
    final teachersList = ['الكل', ...(teachersAsync.value?.map((t) => t['name']?.toString() ?? '') ?? [])];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'إدارة المجموعات والقاعات',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 20),
            onPressed: () => ref.invalidate(liveGroupsProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: branding.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(LucideIcons.plus, size: 20),
        label: Text('إضافة مجموعة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        onPressed: () async {
          final res = await showDialog<bool>(
            context: context,
            builder: (ctx) => const GroupFormDialog(),
          );
          if (res == true) {
            ref.invalidate(liveGroupsProvider);
          }
        },
      ),
      body: Column(
        children: [
          // Filter Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Theme.of(context).cardColor,
            child: Column(
              children: [
                // Search Input
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'البحث عن اسم المجموعة...',
                    prefixIcon: const Icon(LucideIcons.search, size: 20),
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    // Subject Filter
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: subjectsList.contains(_selectedSubjectFilter) ? _selectedSubjectFilter : 'الكل',
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'المادة',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        items: subjectsList.map((s) => DropdownMenuItem(value: s, child: Text(s, style: GoogleFonts.cairo(fontSize: 12), overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: (val) => setState(() => _selectedSubjectFilter = val ?? 'الكل'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Teacher Filter
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: teachersList.contains(_selectedTeacherFilter) ? _selectedTeacherFilter : 'الكل',
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'المحاضر',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        items: teachersList.map((t) => DropdownMenuItem(value: t, child: Text(t, style: GoogleFonts.cairo(fontSize: 12), overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: (val) => setState(() => _selectedTeacherFilter = val ?? 'الكل'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Groups List
          Expanded(
            child: groupsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.alertCircle, size: 48, color: Colors.amber),
                    const SizedBox(height: 12),
                    Text('تعذر تحميل المجموعات: $err', style: GoogleFonts.cairo()),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(liveGroupsProvider),
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
              data: (groups) {
                final filtered = groups.where((g) {
                  final name = (g['name']?.toString() ?? '').toLowerCase();
                  final subjectName = g['subject']?['name']?.toString() ?? '';
                  final teacherName = g['teacher']?['name']?.toString() ?? '';

                  final matchesSearch = _searchQuery.isEmpty || name.contains(_searchQuery);
                  final matchesSubject = _selectedSubjectFilter == 'الكل' || subjectName == _selectedSubjectFilter;
                  final matchesTeacher = _selectedTeacherFilter == 'الكل' || teacherName == _selectedTeacherFilter;

                  return matchesSearch && matchesSubject && matchesTeacher;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.layers, size: 54, color: Colors.grey.withOpacity(0.4)),
                        const SizedBox(height: 12),
                        Text('لا توجد مجموعات مطابقة', style: GoogleFonts.cairo(color: Colors.grey, fontSize: 14)),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(liveGroupsProvider),
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(14),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, idx) {
                      final group = filtered[idx];
                      final id = group['id']?.toString() ?? '';
                      final name = group['name']?.toString() ?? 'مجموعة';
                      final subjectName = group['subject']?['name']?.toString() ?? 'مادة عامة';
                      final teacherName = group['teacher']?['name']?.toString() ?? 'المحاضر';
                      final yearName = group['academicYear']?['name']?.toString() ?? '';
                      final roomName = group['classroom']?['name']?.toString() ?? 'قاعة 1';
                      final monthlyFee = parseDouble(group['monthlyFee']);
                      final studentsCount = parseInt(group['_count']?['students']);
                      final capacity = parseInt(group['capacity'], 50);

                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                        Text(
                                          '$subjectName • $teacherName',
                                          style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    onSelected: (action) async {
                                      if (action == 'edit') {
                                        final res = await showDialog<bool>(
                                          context: context,
                                          builder: (c) => GroupFormDialog(initialGroup: group),
                                        );
                                        if (res == true) ref.invalidate(liveGroupsProvider);
                                      } else if (action == 'students') {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (c) => StudentsListScreen(initialGroupId: id),
                                          ),
                                        );
                                      } else if (action == 'cockpit') {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (c) => LiveClassCockpitScreen(
                                              groupName: name,
                                              groupId: id,
                                              sessionNumber: 1,
                                            ),
                                          ),
                                        );
                                      } else if (action == 'delete') {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (c) => AlertDialog(
                                            title: const Text('حذف المجموعة'),
                                            content: Text('هل أنت متأكد من رغبتك في أرشفة مجموعة ($name)؟'),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                                onPressed: () => Navigator.pop(c, true),
                                                child: const Text('أرشفة', style: TextStyle(color: Colors.white)),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirm == true) {
                                          final ok = await EduApiService().deleteGroup(id);
                                          if (ok) {
                                            SoundService.successFeedback();
                                            ref.invalidate(liveGroupsProvider);
                                          }
                                        }
                                      }
                                    },
                                    itemBuilder: (c) => [
                                      const PopupMenuItem(
                                        value: 'students',
                                        child: Row(children: [Icon(LucideIcons.users, size: 16), SizedBox(width: 8), Text('قائمة طلاب المجموعة')]),
                                      ),
                                      const PopupMenuItem(
                                        value: 'cockpit',
                                        child: Row(children: [Icon(LucideIcons.penTool, size: 16), SizedBox(width: 8), Text('رصد درجات الحصة والواجب')]),
                                      ),
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Row(children: [Icon(LucideIcons.pencil, size: 16), SizedBox(width: 8), Text('تعديل المجموعة')]),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(children: [Icon(LucideIcons.trash2, size: 16, color: Colors.red), SizedBox(width: 8), Text('أرشفة المجموعة', style: TextStyle(color: Colors.red))]),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const Divider(height: 18),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(LucideIcons.users, size: 16, color: branding.primaryColor),
                                      const SizedBox(width: 6),
                                      Text('$studentsCount / $capacity طالب', style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      const Icon(LucideIcons.mapPin, size: 15, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(roomName, style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey)),
                                    ],
                                  ),
                                  Text(
                                    '${monthlyFee.toStringAsFixed(0)} ج.م / شهر',
                                    style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.bold, color: const Color(0xFF10B981)),
                                  ),
                                ],
                              ),
                              if (yearName.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(yearName, style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey[800])),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
