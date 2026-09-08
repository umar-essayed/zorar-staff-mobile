import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/network/edu_api_service.dart';
import '../../core/providers/edu_data_providers.dart';
import '../../core/services/sound_service.dart';
import '../../core/theme/branding_provider.dart';
import '../../core/utils/numeric_utils.dart';

class OnlinePlatformScreen extends ConsumerStatefulWidget {
  const OnlinePlatformScreen({super.key});

  @override
  ConsumerState<OnlinePlatformScreen> createState() => _OnlinePlatformScreenState();
}

class _OnlinePlatformScreenState extends ConsumerState<OnlinePlatformScreen> {
  String _searchQuery = '';

  Future<void> _showGrantCourseDialog(BuildContext context, String courseId, String courseTitle) async {
    final groupsAsync = ref.read(liveGroupsProvider);
    final groups = groupsAsync.value ?? [];
    String? selectedGroupId = groups.isNotEmpty ? groups.first['id']?.toString() : null;
    bool isSubmitting = false;

    if (groups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد مجموعات محلية مسجلة بالسنتر لإتاحة الكورس لها')),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (c, setDialogState) => AlertDialog(
          title: Row(
            children: [
              const Icon(LucideIcons.users, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'إتاحة الكورس لمجموعة محلية',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'سيتم فتح محتوى ($courseTitle) تلقائياً لجميع طلاب المجموعة المختارة على المنصة:',
                style: GoogleFonts.cairo(fontSize: 12.5, color: Colors.grey),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: selectedGroupId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'اختر المجموعة الميدانية',
                  prefixIcon: Icon(LucideIcons.layers, size: 20),
                ),
                items: groups.map((g) {
                  final gName = g['name']?.toString() ?? 'مجموعة';
                  final count = g['_count']?['students'] ?? 0;
                  return DropdownMenuItem<String>(
                    value: g['id']?.toString(),
                    child: Text('$gName ($count طالب)', style: GoogleFonts.cairo(fontSize: 13)),
                  );
                }).toList(),
                onChanged: (val) => setDialogState(() => selectedGroupId = val),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: isSubmitting ? null : () => Navigator.pop(c), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: isSubmitting || selectedGroupId == null
                  ? null
                  : () async {
                      setDialogState(() => isSubmitting = true);
                      try {
                        final res = await EduApiService().grantCourseToGroup(courseId, selectedGroupId!);
                        SoundService.successFeedback();
                        if (mounted) {
                          Navigator.pop(c);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(res?['message']?.toString() ?? 'تم فتح الكورس بنجاح لطلاب المجموعة!'),
                              backgroundColor: const Color(0xFF10B981),
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isSubmitting = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('تعذر ربط الكورس: $e'), backgroundColor: Colors.red),
                        );
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('إتاحة الكورس فوراً'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddCourseDialog(BuildContext context) async {
    final branding = ref.read(brandingProvider);
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final priceCtrl = TextEditingController(text: '0');

    final yearsAsync = ref.read(liveAcademicYearsProvider);
    final subjectsAsync = ref.read(liveSubjectsProvider);
    final years = yearsAsync.value ?? [];
    final subjects = subjectsAsync.value ?? [];

    String? selectedYearId = years.isNotEmpty ? years.first['id']?.toString() : null;
    String? selectedSubjectId = subjects.isNotEmpty ? subjects.first['id']?.toString() : null;
    bool isSubmitting = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (c, setDialogState) => AlertDialog(
          title: Text('إضافة كورس / شهر على المنصة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'عنوان الكورس (مثال: كورس شهر أكتوبر)',
                    prefixIcon: Icon(LucideIcons.globe, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                if (years.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: selectedYearId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'الصف الدراسي'),
                    items: years.map((y) => DropdownMenuItem<String>(value: y['id']?.toString() ?? '', child: Text(y['name']?.toString() ?? '', style: GoogleFonts.cairo(fontSize: 13)))).toList(),
                    onChanged: (val) => setDialogState(() => selectedYearId = val),
                  ),
                const SizedBox(height: 12),
                if (subjects.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: selectedSubjectId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'المادة الدراسية'),
                    items: subjects.map((s) => DropdownMenuItem<String>(value: s['id']?.toString() ?? '', child: Text(s['name']?.toString() ?? '', style: GoogleFonts.cairo(fontSize: 13)))).toList(),
                    onChanged: (val) => setDialogState(() => selectedSubjectId = val),
                  ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'السعر للطلبة الأونلاين فقط (0 = مجاني أو مضمن)',
                    prefixIcon: Icon(LucideIcons.wallet, size: 20),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: isSubmitting ? null : () => Navigator.pop(c), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: branding.primaryColor, foregroundColor: Colors.white),
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final title = titleCtrl.text.trim();
                      if (title.isEmpty) return;
                      setDialogState(() => isSubmitting = true);
                      try {
                        final slug = 'course-${DateTime.now().millisecondsSinceEpoch}';
                        await EduApiService().createCourse({
                          'title': title,
                          'slug': slug,
                          'academicYearId': selectedYearId,
                          'subjectId': selectedSubjectId,
                          'price': parseDouble(priceCtrl.text),
                        });
                        SoundService.successFeedback();
                        if (mounted) {
                          Navigator.pop(c);
                          ref.invalidate(liveCoursesProvider);
                        }
                      } catch (e) {
                        setDialogState(() => isSubmitting = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('تعذر إنشاء الكورس: $e'), backgroundColor: Colors.red),
                        );
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('حفظ ونشر'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(brandingProvider);
    final coursesAsync = ref.watch(liveCoursesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'إدارة المنصة والكورسات الإلكترونية',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 20),
            onPressed: () => ref.invalidate(liveCoursesProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: branding.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(LucideIcons.plus, size: 20),
        label: Text('إضافة كورس / شهر', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        onPressed: () => _showAddCourseDialog(context),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            color: Theme.of(context).cardColor,
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'البحث عن كورس أو شهر دراسي...',
                prefixIcon: const Icon(LucideIcons.search, size: 20),
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          Expanded(
            child: coursesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.alertCircle, size: 48, color: Colors.amber),
                    const SizedBox(height: 12),
                    Text('تعذر تحميل الكورسات: $err', style: GoogleFonts.cairo()),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(liveCoursesProvider),
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
              data: (courses) {
                final filtered = courses.where((c) {
                  final title = (c['title']?.toString() ?? '').toLowerCase();
                  return _searchQuery.isEmpty || title.contains(_searchQuery);
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.globe, size: 54, color: Colors.grey.withOpacity(0.4)),
                        const SizedBox(height: 12),
                        Text('لا توجد كورسات أو شهور منشورة على المنصة حالياً', style: GoogleFonts.cairo(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(liveCoursesProvider),
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(14),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, idx) {
                      final course = filtered[idx];
                      final courseId = course['id']?.toString() ?? '';
                      final title = course['title']?.toString() ?? 'كورس أونلاين';
                      final yearName = course['academicYear']?['name']?.toString() ?? '';
                      final subjectName = course['subject']?['name']?.toString() ?? '';
                      final chapters = (course['chapters'] as List?) ?? [];
                      int lessonsCount = 0;
                      for (final ch in chapters) {
                        lessonsCount += (ch['lessons'] as List?)?.length ?? 0;
                      }

                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: branding.primaryColor.withOpacity(0.12),
                                    child: Icon(LucideIcons.video, color: branding.primaryColor, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(title, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15)),
                                        Text('$subjectName • $yearName', style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(LucideIcons.playSquare, size: 16, color: Colors.grey),
                                      const SizedBox(width: 6),
                                      Text('$lessonsCount حصة فيديو مشفرة', style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey[700])),
                                    ],
                                  ),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF10B981),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    ),
                                    icon: const Icon(LucideIcons.link2, size: 16),
                                    label: const Text('إتاحة لمجموعة محلية'),
                                    onPressed: () => _showGrantCourseDialog(context, courseId, title),
                                  ),
                                ],
                              ),
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
