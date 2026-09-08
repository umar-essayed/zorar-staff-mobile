import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:dio/dio.dart';
import '../../core/network/edu_api_service.dart';
import '../../core/providers/edu_data_providers.dart';
import '../../core/services/sound_service.dart';
import '../../core/services/upload_service.dart';
import '../../core/theme/branding_provider.dart';
import '../../core/utils/numeric_utils.dart';
import 'online_lessons_management_screen.dart';
import 'platform_analytics_screen.dart';

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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    List<Map<String, dynamic>> groups = [];
    try {
      groups = await EduApiService().getGroups();
    } catch (e) {
      debugPrint('Error fetching groups: $e');
    }

    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    if (groups.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لا توجد مجموعات محلية مسجلة بالسنتر حالياً. يرجى إضافة مجموعة من صفحة المجموعات أولاً.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final selectedGroupIds = <String>{};
    bool isSubmitting = false;

    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (c, setDialogState) {
          int totalAffectedStudents = 0;
          for (final g in groups) {
            final gid = g['id']?.toString() ?? '';
            if (selectedGroupIds.contains(gid)) {
              totalAffectedStudents += (g['_count']?['students'] as num? ?? 0).toInt();
            }
          }

          final allSelected = selectedGroupIds.length == groups.length;

          return AlertDialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(LucideIcons.users, size: 22, color: Color(0xFF10B981)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ربط الكورس بمجموعات السنتر',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 650, maxHeight: 520),
              child: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'حدد المجموعات التي ترغب في إتاحة كورس ($courseTitle) لطلابها مجاناً وتلقائياً على المنصة:',
                      style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            setDialogState(() {
                              if (allSelected) {
                                selectedGroupIds.clear();
                              } else {
                                for (final g in groups) {
                                  final gid = g['id']?.toString();
                                  if (gid != null) selectedGroupIds.add(gid);
                                }
                              }
                            });
                          },
                          icon: Icon(allSelected ? LucideIcons.checkSquare : LucideIcons.square, size: 16),
                          label: Text(allSelected ? 'إلغاء تحديد الكل' : 'تحديد جميع المجموعات',
                              style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.bold)),
                        ),
                        if (selectedGroupIds.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$totalAffectedStudents طالب مختار',
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF059669),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const Divider(height: 12),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: groups.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final g = groups[index];
                          final gid = g['id']?.toString() ?? '';
                          final gName = g['name']?.toString() ?? 'مجموعة';
                          final count = g['_count']?['students'] ?? 0;
                          final isChecked = selectedGroupIds.contains(gid);

                          return CheckboxListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                            value: isChecked,
                            title: Text(gName, style: GoogleFonts.cairo(fontWeight: FontWeight.w600, fontSize: 14)),
                            subtitle: Text('$count طالب مسجل', style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey)),
                            activeColor: const Color(0xFF10B981),
                            onChanged: (bool? val) {
                              setDialogState(() {
                                if (val == true) {
                                  selectedGroupIds.add(gid);
                                } else {
                                  selectedGroupIds.remove(gid);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(c),
                child: const Text('إلغاء'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                icon: const Icon(LucideIcons.checkCheck, size: 18),
                onPressed: isSubmitting || selectedGroupIds.isEmpty
                    ? null
                    : () async {
                        setDialogState(() => isSubmitting = true);
                        try {
                          final res = await EduApiService().grantCourseToGroups(courseId, selectedGroupIds.toList());
                          SoundService.successFeedback();
                          if (mounted) {
                            Navigator.pop(c);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(res?['message']?.toString() ?? 'تم إتاحة الكورس بنجاح لجميع طلاب المجموعات المحددة! ✅'),
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
                label: isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('إتاحة للطلاب المحددين (${selectedGroupIds.length} مجموعة)'),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- Multi-Step Course Creation Modal ---
  Future<void> _showAddCourseDialog(BuildContext context) async {
    final branding = ref.read(brandingProvider);
    final titleCtrl = TextEditingController();
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

    int currentStep = 0;
    String? uploadedThumbnailUrl;
    bool isUploadingImage = false;
    bool isSubmitting = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (c, setDialogState) {
          final stepTitles = ['البيانات الأساسية', 'التسعير والوصف', 'صورة الغلاف'];

          return AlertDialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
            titlePadding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(LucideIcons.bookPlus, color: branding.primaryColor, size: 22),
                        const SizedBox(width: 8),
                        Text('إضافة كورس جديد', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: branding.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'خطوة ${currentStep + 1} من 3',
                        style: GoogleFonts.cairo(fontSize: 11.5, fontWeight: FontWeight.bold, color: branding.primaryColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: List.generate(3, (i) {
                    final isActive = i == currentStep;
                    final isDone = i < currentStep;
                    return Expanded(
                      child: Container(
                        height: 4,
                        margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                        decoration: BoxDecoration(
                          color: isActive
                              ? branding.primaryColor
                              : (isDone ? const Color(0xFF10B981) : Colors.grey.withOpacity(0.25)),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 6),
                Text(
                  stepTitles[currentStep],
                  style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                ),
              ],
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 750),
              child: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: currentStep == 0
                      ? _buildStepOneBasics(
                          titleCtrl,
                          years,
                          subjects,
                          teachers,
                          selectedYearId,
                          selectedSubjectId,
                          selectedTeacherId,
                          setDialogState,
                          (y) => selectedYearId = y,
                          (s) => selectedSubjectId = s,
                          (t) => selectedTeacherId = t,
                        )
                      : currentStep == 1
                          ? _buildStepTwoPricing(descCtrl, priceCtrl, branding, setDialogState)
                          : _buildStepThreeUpload(
                              uploadedThumbnailUrl,
                              isUploadingImage,
                              titleCtrl.text,
                              branding,
                              setDialogState,
                              (url) => uploadedThumbnailUrl = url,
                              (val) => isUploadingImage = val,
                            ),
                ),
              ),
            ),
            actions: [
              if (currentStep > 0)
                TextButton(
                  onPressed: isSubmitting || isUploadingImage
                      ? null
                      : () => setDialogState(() => currentStep--),
                  child: const Text('السابق'),
                )
              else
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(c),
                  child: const Text('إلغاء'),
                ),

              if (currentStep < 2)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: branding.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    if (currentStep == 0) {
                      if (titleCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('يرجى كتابة عنوان الكورس'), backgroundColor: Colors.red),
                        );
                        return;
                      }
                      if (selectedYearId == null || selectedSubjectId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('يرجى اختيار الصف والمادة الدراسية'), backgroundColor: Colors.red),
                        );
                        return;
                      }
                    }
                    SoundService.lightImpact();
                    setDialogState(() => currentStep++);
                  },
                  child: const Text('التالي'),
                )
              else
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isSubmitting || isUploadingImage
                      ? null
                      : () async {
                          setDialogState(() => isSubmitting = true);
                          try {
                            final autoSlug = 'course-${DateTime.now().millisecondsSinceEpoch}';
                            await EduApiService().createCourse({
                              'title': titleCtrl.text.trim(),
                              'slug': autoSlug,
                              'academicYearId': selectedYearId,
                              'subjectId': selectedSubjectId,
                              'teacherId': selectedTeacherId,
                              'thumbnailUrl': uploadedThumbnailUrl,
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
                                  content: Text('تم إنشاء ونشر الكورس بنجاح على المنصة! ✅'),
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
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('فشل الحفظ: $errMsg', style: GoogleFonts.cairo()), backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('إنهاء وحفظ الكورس'),
                ),
            ],
          );
        },
      ),
    );
  }

  // --- Step 1: Basics ---
  Widget _buildStepOneBasics(
    TextEditingController titleCtrl,
    List<dynamic> years,
    List<dynamic> subjects,
    List<dynamic> teachers,
    String? selectedYearId,
    String? selectedSubjectId,
    String? selectedTeacherId,
    StateSetter setDialogState,
    ValueChanged<String?> onYearChanged,
    ValueChanged<String?> onSubjectChanged,
    ValueChanged<String?> onTeacherChanged,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        TextField(
          controller: titleCtrl,
          decoration: const InputDecoration(
            labelText: 'عنوان الكورس أو الشهر *',
            hintText: 'مثال: مراجعة الفيزياء الحديثة - شهر أكتوبر',
            prefixIcon: Icon(LucideIcons.globe, size: 20),
            isDense: true,
          ),
        ),
        const SizedBox(height: 12),

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
            onChanged: (val) => setDialogState(() => onYearChanged(val)),
          )
        else
          Text('يرجى إضافة صفوف دراسية أولاً', style: GoogleFonts.cairo(fontSize: 12, color: Colors.red)),

        const SizedBox(height: 12),

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
            onChanged: (val) => setDialogState(() => onSubjectChanged(val)),
          )
        else
          Text('يرجى إضافة مواد دراسية أولاً', style: GoogleFonts.cairo(fontSize: 12, color: Colors.red)),

        const SizedBox(height: 12),

        if (teachers.isNotEmpty)
          DropdownButtonFormField<String>(
            value: selectedTeacherId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'المحاضر / المدرس المشرف *',
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
            onChanged: (val) => setDialogState(() => onTeacherChanged(val)),
          ),
      ],
    );
  }

  // --- Step 2: Pricing & Description ---
  Widget _buildStepTwoPricing(
    TextEditingController descCtrl,
    TextEditingController priceCtrl,
    dynamic branding,
    StateSetter setDialogState,
  ) {
    final curPrice = parseDouble(priceCtrl.text, 0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Text('سعر الكورس للطلاب الأونلاين:', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),

        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                label: Text('مجاني / مضمن للسنتر', style: GoogleFonts.cairo(fontSize: 12)),
                selected: curPrice == 0,
                selectedColor: const Color(0xFF10B981).withOpacity(0.2),
                onSelected: (sel) {
                  if (sel) {
                    setDialogState(() => priceCtrl.text = '0');
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ChoiceChip(
                label: Text('اشتراك مدفوع (EGP)', style: GoogleFonts.cairo(fontSize: 12)),
                selected: curPrice > 0,
                selectedColor: Colors.amber.withOpacity(0.25),
                onSelected: (sel) {
                  if (sel && curPrice == 0) {
                    setDialogState(() => priceCtrl.text = '150');
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        TextField(
          controller: priceCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'السعر (جنيه مصري)',
            suffixText: 'ج.م',
            prefixIcon: Icon(LucideIcons.wallet, size: 18),
            isDense: true,
          ),
          onChanged: (_) => setDialogState(() {}),
        ),
        const SizedBox(height: 16),

        TextField(
          controller: descCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'الوصف ومحتوى الكورس (اختياري)',
            hintText: 'أهم نقاط المحاضرات، حل الواجبات، ومواعيد نزول الشرح...',
            prefixIcon: Icon(LucideIcons.fileText, size: 18),
            isDense: true,
          ),
        ),
      ],
    );
  }

  // --- Step 3: Real Image Upload & Review ---
  Widget _buildStepThreeUpload(
    String? uploadedThumbnailUrl,
    bool isUploadingImage,
    String title,
    dynamic branding,
    StateSetter setDialogState,
    ValueChanged<String?> onUrlChanged,
    ValueChanged<bool> onUploadingChanged,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 8),
        Text('صورة غلاف الكورس (Thumbnail):',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13.5)),
        const SizedBox(height: 12),

        if (uploadedThumbnailUrl != null && uploadedThumbnailUrl.isNotEmpty)
          Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  uploadedThumbnailUrl,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 140,
                    color: Colors.grey.withOpacity(0.2),
                    alignment: Alignment.center,
                    child: const Icon(LucideIcons.image, size: 40, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    icon: const Icon(LucideIcons.trash2, size: 16),
                    label: const Text('حذف الصورة'),
                    onPressed: () => setDialogState(() => onUrlChanged(null)),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: branding.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(LucideIcons.imagePlus, size: 16),
                    label: const Text('تغيير الصورة'),
                    onPressed: () => _pickAndUploadThumbnail(setDialogState, onUrlChanged, onUploadingChanged),
                  ),
                ],
              ),
            ],
          )
        else
          InkWell(
            onTap: isUploadingImage
                ? null
                : () => _pickAndUploadThumbnail(setDialogState, onUrlChanged, onUploadingChanged),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                color: branding.primaryColor.withOpacity(0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: branding.primaryColor.withOpacity(0.35),
                  style: BorderStyle.solid,
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isUploadingImage)
                    const CircularProgressIndicator()
                  else ...[
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: branding.primaryColor.withOpacity(0.12),
                      child: Icon(LucideIcons.uploadCloud, color: branding.primaryColor, size: 28),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'اضغط هنا لرفع صورة الغلاف من جهازك',
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: branding.primaryColor,
                      ),
                    ),
                    Text(
                      'JPG أو PNG • يتم التخزين السحابي فوراً',
                      style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _pickAndUploadThumbnail(
    StateSetter setDialogState,
    ValueChanged<String?> onUrlChanged,
    ValueChanged<bool> onUploadingChanged,
  ) async {
    setDialogState(() => onUploadingChanged(true));
    try {
      final url = await UploadService.pickAndUploadImage(folder: 'courses');
      if (url != null) {
        setDialogState(() => onUrlChanged(url));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل رفع الصورة: $e', style: GoogleFonts.cairo()), backgroundColor: Colors.red),
        );
      }
    } finally {
      setDialogState(() => onUploadingChanged(false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(brandingProvider);
    final coursesAsync = ref.watch(liveCoursesProvider);
    final subjectsAsync = ref.watch(liveSubjectsProvider);
    final yearsAsync = ref.watch(liveAcademicYearsProvider);

    final subjects = subjectsAsync.value ?? [];
    final years = yearsAsync.value ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text('المنصة الإلكترونية والكورسات', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.barChart2),
            tooltip: 'تحليلات المنصة',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => const PlatformAnalyticsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(LucideIcons.listVideo),
            tooltip: 'إدارة الحصص والكويزات',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => const OnlineLessonsManagementScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(LucideIcons.refreshCw),
            tooltip: 'تحديث الكورسات',
            onPressed: () => ref.invalidate(liveCoursesProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          // Top Search & Cascading Filter Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: Theme.of(context).cardColor,
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'البحث باسم الكورس أو المدرس...',
                    prefixIcon: const Icon(LucideIcons.search, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(LucideIcons.x, size: 18),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                    isDense: true,
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedSubjectFilter,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'المادة',
                          prefixIcon: Icon(LucideIcons.bookOpen, size: 16),
                          isDense: true,
                        ),
                        items: [
                          const DropdownMenuItem<String>(value: 'الكل', child: Text('جميع المواد')),
                          ...subjects.map((s) => DropdownMenuItem<String>(
                                value: s['name']?.toString() ?? '',
                                child: Text(s['name']?.toString() ?? '', style: GoogleFonts.cairo(fontSize: 12)),
                              )),
                        ],
                        onChanged: (val) => setState(() => _selectedSubjectFilter = val ?? 'الكل'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedYearFilter,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'الصف الدراسي',
                          prefixIcon: Icon(LucideIcons.graduationCap, size: 16),
                          isDense: true,
                        ),
                        items: [
                          const DropdownMenuItem<String>(value: 'الكل', child: Text('جميع الصفوف')),
                          ...years.map((y) => DropdownMenuItem<String>(
                                value: y['name']?.toString() ?? '',
                                child: Text(y['name']?.toString() ?? '', style: GoogleFonts.cairo(fontSize: 12)),
                              )),
                        ],
                        onChanged: (val) => setState(() => _selectedYearFilter = val ?? 'الكل'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Course List
          Expanded(
            child: coursesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.alertCircle, color: Colors.red, size: 48),
                    const SizedBox(height: 8),
                    Text('حدث خطأ في تحميل الكورسات', style: GoogleFonts.cairo(color: Colors.red)),
                    TextButton(onPressed: () => ref.invalidate(liveCoursesProvider), child: const Text('إعادة المحاولة')),
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
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.globe, size: 54, color: Colors.grey.withOpacity(0.4)),
                        const SizedBox(height: 12),
                        Text('لا توجد كورسات مطابقة للفلاتر الحالية', style: GoogleFonts.cairo(color: Colors.grey, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final course = filtered[index];
                    final courseId = course['id'].toString();
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
                      margin: const EdgeInsets.only(bottom: 14),
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
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
                                      width: 54,
                                      height: 54,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => CircleAvatar(
                                        backgroundColor: branding.primaryColor.withOpacity(0.12),
                                        child: Icon(LucideIcons.video, color: branding.primaryColor, size: 20),
                                      ),
                                    ),
                                  )
                                else
                                  CircleAvatar(
                                    radius: 26,
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
                                Wrap(
                                  spacing: 6,
                                  children: [
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: branding.primaryColor,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      ),
                                      icon: const Icon(LucideIcons.listVideo, size: 15),
                                      label: const Text('إدارة الحصص'),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (c) => OnlineLessonsManagementScreen(initialCourseId: courseId),
                                          ),
                                        );
                                      },
                                    ),
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(0xFF10B981),
                                        side: const BorderSide(color: Color(0xFF10B981)),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      ),
                                      icon: const Icon(LucideIcons.link2, size: 15),
                                      label: const Text('ربط بمجموعات السنتر'),
                                      onPressed: () => _showGrantCourseDialog(context, courseId, title),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: branding.primaryColor,
        icon: const Icon(LucideIcons.plus, color: Colors.white),
        label: Text('إضافة كورس', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => _showAddCourseDialog(context),
      ),
    );
  }
}
