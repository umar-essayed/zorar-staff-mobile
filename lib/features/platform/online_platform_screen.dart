import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:dio/dio.dart';
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
  String _selectedSubjectFilter = 'الكل';
  String _selectedYearFilter = 'الكل';

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
    final thumbCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final priceCtrl = TextEditingController(text: '0');

    final yearsAsync = ref.read(liveAcademicYearsProvider);
    final subjectsAsync = ref.read(liveSubjectsProvider);
    final teachersAsync = ref.read(liveTeachersProvider);

    final years = yearsAsync.value ?? [];
    final subjects = subjectsAsync.value ?? [];
    final teachers = teachersAsync.value ?? [];

    String? selectedYearId = years.isNotEmpty ? years.first['id']?.toString() : null;
    String? selectedSubjectId = subjects.isNotEmpty ? subjects.first['id']?.toString() : null;
    String? selectedTeacherId = teachers.isNotEmpty ? teachers.first['id']?.toString() : null;
    bool isSubmitting = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (c, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(LucideIcons.bookPlus, color: branding.primaryColor, size: 22),
              const SizedBox(width: 8),
              Text('إضافة كورس / شهر دراسي', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title (Required)
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'عنوان الكورس * (مثال: فيزياء كهربية - شهر أكتوبر)',
                    prefixIcon: Icon(LucideIcons.globe, size: 20),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),

                // Academic Year (Required)
                if (years.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: selectedYearId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'الصف الدراسي *',
                      prefixIcon: Icon(LucideIcons.graduationCap, size: 18),
                      isDense: true,
                    ),
                    items: years.map((y) {
                      final id = y['id']?.toString() ?? '';
                      final name = y['name']?.toString() ?? '';
                      return DropdownMenuItem<String>(
                        value: id,
                        child: Text(name, style: GoogleFonts.cairo(fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (val) => setDialogState(() => selectedYearId = val),
                  )
                else
                  Text('يرجى إضافة صفوف دراسية أولاً', style: GoogleFonts.cairo(fontSize: 12, color: Colors.red)),

                const SizedBox(height: 12),

                // Subject (Required)
                if (subjects.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: selectedSubjectId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'المادة الدراسية *',
                      prefixIcon: Icon(LucideIcons.bookOpen, size: 18),
                      isDense: true,
                    ),
                    items: subjects.map((s) {
                      final id = s['id']?.toString() ?? '';
                      final name = s['name']?.toString() ?? '';
                      return DropdownMenuItem<String>(
                        value: id,
                        child: Text(name, style: GoogleFonts.cairo(fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (val) => setDialogState(() => selectedSubjectId = val),
                  )
                else
                  Text('يرجى إضافة مواد دراسية أولاً', style: GoogleFonts.cairo(fontSize: 12, color: Colors.red)),

                const SizedBox(height: 12),

                // Teacher (Required)
                if (teachers.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: selectedTeacherId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'المحاضر / المدرس المسؤول *',
                      prefixIcon: Icon(LucideIcons.userCheck, size: 18),
                      isDense: true,
                    ),
                    items: teachers.map((t) {
                      final id = t['id']?.toString() ?? '';
                      final name = t['name']?.toString() ?? '';
                      return DropdownMenuItem<String>(
                        value: id,
                        child: Text(name, style: GoogleFonts.cairo(fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (val) => setDialogState(() => selectedTeacherId = val),
                  ),

                const SizedBox(height: 12),

                // Thumbnail URL (Optional)
                TextField(
                  controller: thumbCtrl,
                  decoration: const InputDecoration(
                    labelText: 'رابط صورة الغلاف (اختياري)',
                    hintText: 'https://example.com/banner.jpg',
                    prefixIcon: Icon(LucideIcons.image, size: 18),
                    isDense: true,
                  ),
                ),

                const SizedBox(height: 12),

                // Description (Optional)
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'الوصف ومحتوى الكورس (اختياري)',
                    hintText: 'أهم نقاط المحاضرات والواجبات المضمنة...',
                    prefixIcon: Icon(LucideIcons.fileText, size: 18),
                    isDense: true,
                  ),
                ),

                const SizedBox(height: 12),

                // Price in EGP
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'السعر للطلبة الأونلاين فقط (0 = مجاني أو مضمن للسنتر)',
                    suffixText: 'ج.م',
                    prefixIcon: Icon(LucideIcons.wallet, size: 18),
                    isDense: true,
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
                      if (title.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('يرجى كتابة عنوان الكورس'), backgroundColor: Colors.red),
                        );
                        return;
                      }
                      if (selectedYearId == null || selectedSubjectId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('يرجى تحديد السنة الدراسية والمادة'), backgroundColor: Colors.red),
                        );
                        return;
                      }

                      setDialogState(() => isSubmitting = true);
                      try {
                        final autoSlug = 'course-${DateTime.now().millisecondsSinceEpoch}';
                        await EduApiService().createCourse({
                          'title': title,
                          'slug': autoSlug,
                          'academicYearId': selectedYearId,
                          'subjectId': selectedSubjectId,
                          'teacherId': selectedTeacherId,
                          'thumbnailUrl': thumbCtrl.text.trim().isNotEmpty ? thumbCtrl.text.trim() : null,
                          'description': descCtrl.text.trim().isNotEmpty ? descCtrl.text.trim() : null,
                          'price': parseDouble(priceCtrl.text, 0),
                          'isPublished': true,
                        });
                        SoundService.successFeedback();
                        if (mounted) {
                          Navigator.pop(c);
                          ref.invalidate(liveCoursesProvider);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تم حفظ ونشر الكورس بنجاح على المنصة!'),
                              backgroundColor: Color(0xFF10B981),
                            ),
                          );
                        }
                      } catch (e) {
                        SoundService.errorFeedback();
                        setDialogState(() => isSubmitting = false);
                        String errMsg = e.toString();
                        if (e is DioException && e.response?.data != null) {
                          final msg = e.response!.data['message'];
                          errMsg = msg is List ? msg.join(', ') : msg.toString();
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('تعذر إنشاء الكورس: $errMsg'), backgroundColor: Colors.red),
                        );
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
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
    final subjectsAsync = ref.watch(liveSubjectsProvider);
    final yearsAsync = ref.watch(liveAcademicYearsProvider);

    final subjectsList = ['الكل', ...(subjectsAsync.value?.map((s) => s['name']?.toString() ?? '').where((s) => s.isNotEmpty) ?? [])];
    final yearsList = ['الكل', ...(yearsAsync.value?.map((y) => y['name']?.toString() ?? '').where((y) => y.isNotEmpty) ?? [])];

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
          // Filter Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: Theme.of(context).cardColor,
            child: Column(
              children: [
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'البحث باسم الكورس أو المحاضر...',
                    prefixIcon: const Icon(LucideIcons.search, size: 18),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: subjectsList.contains(_selectedSubjectFilter) ? _selectedSubjectFilter : 'الكل',
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'المادة',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        items: subjectsList.map((s) => DropdownMenuItem<String>(value: s, child: Text(s, style: GoogleFonts.cairo(fontSize: 12), overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: (val) => setState(() => _selectedSubjectFilter = val ?? 'الكل'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: yearsList.contains(_selectedYearFilter) ? _selectedYearFilter : 'الكل',
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'الصف الدراسي',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        items: yearsList.map((y) => DropdownMenuItem<String>(value: y, child: Text(y, style: GoogleFonts.cairo(fontSize: 12), overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: (val) => setState(() => _selectedYearFilter = val ?? 'الكل'),
                      ),
                    ),
                  ],
                ),
              ],
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
                  final teacher = (c['teacher']?['name']?.toString() ?? '').toLowerCase();
                  final subject = c['subject']?['name']?.toString() ?? '';
                  final year = c['academicYear']?['name']?.toString() ?? '';

                  if (_searchQuery.isNotEmpty && !title.contains(_searchQuery) && !teacher.contains(_searchQuery)) {
                    return false;
                  }
                  if (_selectedSubjectFilter != 'الكل' && subject != _selectedSubjectFilter) {
                    return false;
                  }
                  if (_selectedYearFilter != 'الكل' && year != _selectedYearFilter) {
                    return false;
                  }
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.globe, size: 54, color: Colors.grey.withOpacity(0.4)),
                        const SizedBox(height: 12),
                        Text('لا توجد كورسات مطابقة للفلاتر الحالية', style: GoogleFonts.cairo(color: Colors.grey, fontWeight: FontWeight.bold)),
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
                      final teacherName = course['teacher']?['name']?.toString() ?? '';
                      final thumbUrl = course['thumbnailUrl']?.toString();
                      final price = parseDouble(course['price'], 0);
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (thumbUrl != null && thumbUrl.isNotEmpty && thumbUrl.startsWith('http'))
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        thumbUrl,
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => CircleAvatar(
                                          backgroundColor: branding.primaryColor.withOpacity(0.12),
                                          child: Icon(LucideIcons.video, color: branding.primaryColor, size: 20),
                                        ),
                                      ),
                                    )
                                  else
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: branding.primaryColor.withOpacity(0.12),
                                      child: Icon(LucideIcons.video, color: branding.primaryColor, size: 22),
                                    ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                title,
                                                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14.5),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: price > 0 ? Colors.amber.withOpacity(0.15) : const Color(0xFF10B981).withOpacity(0.15),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                price > 0 ? '$price ج.م' : 'مجاني',
                                                style: GoogleFonts.cairo(
                                                  color: price > 0 ? Colors.brown : const Color(0xFF10B981),
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '$subjectName • $yearName ${teacherName.isNotEmpty ? "• أ/ $teacherName" : ""}',
                                          style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey[600]),
                                        ),
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
