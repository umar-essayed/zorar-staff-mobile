import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/network/edu_api_service.dart';
import '../../core/providers/edu_data_providers.dart';
import '../../core/services/sound_service.dart';
import '../../core/services/whatsapp_service.dart';
import '../../core/theme/branding_provider.dart';
import 'teacher_form_dialog.dart';
import 'teacher_profile_detail_screen.dart';

class TeachersManagementScreen extends ConsumerStatefulWidget {
  const TeachersManagementScreen({super.key});

  @override
  ConsumerState<TeachersManagementScreen> createState() => _TeachersManagementScreenState();
}

class _TeachersManagementScreenState extends ConsumerState<TeachersManagementScreen> {
  String _searchQuery = '';
  String _selectedSubjectFilter = 'الكل';

  Future<void> _openResetPasswordDialog(Map<String, dynamic> teacher) async {
    final passCtrl = TextEditingController();
    bool obscure = true;
    bool isSubmitting = false;
    final branding = ref.read(brandingProvider);

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (c, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(LucideIcons.key, color: branding.primaryColor, size: 22),
                const SizedBox(width: 8),
                Text('إدارة حساب ودخول المعلم', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'المعلم: ${teacher['name']}',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  'رقم الدخول: ${teacher['phone']}',
                  style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey[700]),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: passCtrl,
                  obscureText: obscure,
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور الجديدة',
                    prefixIcon: const Icon(LucideIcons.lock, size: 18),
                    suffixIcon: IconButton(
                      icon: Icon(obscure ? LucideIcons.eyeOff : LucideIcons.eye, size: 18),
                      onPressed: () => setDialogState(() => obscure = !obscure),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    isDense: true,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('إلغاء', style: GoogleFonts.cairo()),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: branding.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: isSubmitting
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(LucideIcons.check, size: 16),
                label: Text('تعيين كلمة المرور', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final p = passCtrl.text.trim();
                        if (p.length < 4) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('كلمة المرور يجب أن لا تقل عن 4 خانات')),
                          );
                          return;
                        }

                        setDialogState(() => isSubmitting = true);
                        try {
                          await EduApiService().resetTeacherPassword(teacher['id'].toString(), p);
                          ref.invalidate(liveTeachersProvider);
                          SoundService.successFeedback();
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('تم تعيين كلمة المرور بنجاح للمعلم ✅', style: GoogleFonts.cairo()),
                                backgroundColor: const Color(0xFF10B981),
                              ),
                            );
                          }
                        } catch (e) {
                          SoundService.errorFeedback();
                          setDialogState(() => isSubmitting = false);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('فشل تعيين كلمة المرور: $e'), backgroundColor: Colors.red),
                            );
                          }
                        }
                      },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDeleteTeacher(Map<String, dynamic> teacher) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(LucideIcons.alertTriangle, color: Colors.redAccent, size: 22),
            const SizedBox(width: 8),
            Text('تأكيد حذف المعلم', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text(
          'هل أنت متأكد من رغبتك في حذف أو إلغاء تفعيل المعلم (${teacher['name']})؟',
          style: GoogleFonts.cairo(fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('إلغاء', style: GoogleFonts.cairo())),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('حذف المعلم', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await EduApiService().deleteTeacher(teacher['id'].toString());
        ref.invalidate(liveTeachersProvider);
        SoundService.successFeedback();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم حذف المعلم بنجاح', style: GoogleFonts.cairo()),
              backgroundColor: Colors.black87,
            ),
          );
        }
      } catch (e) {
        SoundService.errorFeedback();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('فشل الحذف: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(brandingProvider);
    final teachersAsync = ref.watch(liveTeachersProvider);
    final subjectsAsync = ref.watch(liveSubjectsProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'إدارة المدرسين والمعلمين',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(LucideIcons.refreshCw, size: 18),
              tooltip: 'تحديث البيانات',
              onPressed: () => ref.invalidate(liveTeachersProvider),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: branding.primaryColor,
          foregroundColor: Colors.white,
          icon: const Icon(LucideIcons.userPlus),
          label: Text('إضافة معلم جديد', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          onPressed: () async {
            final res = await showDialog<bool>(
              context: context,
              builder: (_) => const TeacherFormDialog(),
            );
            if (res == true) ref.invalidate(liveTeachersProvider);
          },
        ),
        body: Column(
          children: [
            // Search and Subject Filter Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.15))),
              ),
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'بحث باسم المعلم أو رقم الهاتف...',
                      prefixIcon: const Icon(LucideIcons.search, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
                  ),
                  const SizedBox(height: 10),

                  // Subject Filter Chips
                  subjectsAsync.when(
                    data: (subjects) {
                      final subjectNames = ['الكل', ...subjects.map((s) => s['name']?.toString() ?? '').where((s) => s.isNotEmpty)];
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: subjectNames.map((subj) {
                            final isSelected = _selectedSubjectFilter == subj;
                            return Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: ChoiceChip(
                                label: Text(subj, style: GoogleFonts.cairo(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                                selected: isSelected,
                                selectedColor: branding.primaryColor.withOpacity(0.2),
                                onSelected: (_) => setState(() => _selectedSubjectFilter = subj),
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    },
                    loading: () => const SizedBox(),
                    error: (_, __) => const SizedBox(),
                  ),
                ],
              ),
            ),

            // Teachers List
            Expanded(
              child: teachersAsync.when(
                data: (allTeachers) {
                  // Filter by search & subject
                  final filtered = allTeachers.where((t) {
                    final name = (t['name'] ?? '').toString().toLowerCase();
                    final phone = (t['phone'] ?? '').toString();
                    final subj = (t['subject']?['name'] ?? '').toString();

                    final matchesSearch = _searchQuery.isEmpty || name.contains(_searchQuery) || phone.contains(_searchQuery);
                    final matchesSubj = _selectedSubjectFilter == 'الكل' || subj == _selectedSubjectFilter;
                    return matchesSearch && matchesSubj;
                  }).toList();

                  // Stats Bar
                  final totalTeachers = filtered.length;
                  int totalGroups = 0;
                  int totalStudents = 0;
                  for (final t in filtered) {
                    final groups = (t['groups'] as List<dynamic>?) ?? [];
                    totalGroups += groups.length;
                    for (final g in groups) {
                      totalStudents += (g['_count']?['students'] as num? ?? 0).toInt();
                    }
                  }

                  return Column(
                    children: [
                      // Quick Summary Counters
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        color: branding.primaryColor.withOpacity(0.05),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _counterCard('$totalTeachers', 'معلم بالسنتر', LucideIcons.users, branding.primaryColor),
                            _counterCard('$totalGroups', 'مجموعة دراسية', LucideIcons.layers, Colors.indigo),
                            _counterCard('$totalStudents', 'طالب مسجل', LucideIcons.graduationCap, const Color(0xFF10B981)),
                          ],
                        ),
                      ),

                      // List
                      Expanded(
                        child: filtered.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(LucideIcons.userX, size: 54, color: Colors.grey[400]),
                                    const SizedBox(height: 12),
                                    Text('لا يوجد معلمون مطابقون للبحث', style: GoogleFonts.cairo(color: Colors.grey, fontSize: 13)),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (ctx, idx) {
                                  final t = filtered[idx];
                                  return _buildTeacherCard(t, branding);
                                },
                              ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, __) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.alertCircle, color: Colors.red, size: 48),
                        const SizedBox(height: 12),
                        Text('فشل تحميل المعلمين: $e', textAlign: TextAlign.center, style: GoogleFonts.cairo()),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => ref.invalidate(liveTeachersProvider),
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
      ),
    );
  }

  Widget _counterCard(String value, String label, IconData icon, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
            Text(label, style: GoogleFonts.cairo(fontSize: 10.5, color: Colors.grey[700])),
          ],
        ),
      ],
    );
  }

  Widget _buildTeacherCard(Map<String, dynamic> t, BrandingState branding) {
    final name = t['name'] ?? 'معلم';
    final phone = t['phone'] ?? '';
    final subject = t['subject']?['name'] ?? 'عام';
    final avatarUrl = t['avatarUrl']?.toString();
    final bio = t['bio']?.toString() ?? '';
    final groups = (t['groups'] as List<dynamic>?) ?? [];
    final hasUser = t['user'] != null;

    final commType = t['commissionType'] ?? 'PERCENTAGE';
    final centerPct = (t['centerPercentage'] as num?)?.toDouble() ?? 20.0;
    final teacherPct = 100.0 - centerPct;
    final fixedFee = (t['fixedCenterFee'] as num?)?.toDouble() ?? 0.0;

    int studentsCount = 0;
    for (final g in groups) {
      studentsCount += (g['_count']?['students'] as num? ?? 0).toInt();
    }

    // Extract grades taught
    final gradesTaught = <String>{};
    for (final g in groups) {
      final yName = g['academicYear']?['name']?.toString() ?? '';
      if (yName.isNotEmpty) gradesTaught.add(yName);
    }
    if (gradesTaught.isEmpty && bio.contains('الصفوف:')) {
      final sub = bio.split('الصفوف:').last.split('|').first.trim();
      if (sub.isNotEmpty) gradesTaught.add(sub);
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1.5,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Avatar, Name, Phone, Account Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: branding.primaryColor.withOpacity(0.12),
                  backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl == null || avatarUrl.isEmpty
                      ? Icon(LucideIcons.user, size: 28, color: branding.primaryColor)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ),
                          if (hasUser)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(LucideIcons.key, size: 11, color: Color(0xFF10B981)),
                                  const SizedBox(width: 4),
                                  Text('حساب مفعل', style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF10B981))),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: branding.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(subject, style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold, color: branding.primaryColor)),
                          ),
                          const SizedBox(width: 8),
                          Text(phone, style: GoogleFonts.firaCode(fontSize: 11.5, color: Colors.grey[700])),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Row 2: Grades & Stages Taught
            if (gradesTaught.isNotEmpty) ...[
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: gradesTaught.map((g) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.09),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(g, style: GoogleFonts.cairo(fontSize: 10.5, color: Colors.grey[800])),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
            ],

            // Row 3: Metrics & Commission
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.04),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.layers, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text('${groups.length} مجموعات', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 10),
                      Icon(LucideIcons.users, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text('$studentsCount طالب', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: branding.primaryColor)),
                    ],
                  ),
                  Text(
                    commType == 'PERCENTAGE'
                        ? 'أتعاب: ${teacherPct.toStringAsFixed(0)}% (السنتر ${centerPct.toStringAsFixed(0)}%)'
                        : 'رسم السنتر: $fixedFee ج.م/طالب',
                    style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey[700], fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Row 4: Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: branding.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    icon: const Icon(LucideIcons.userCheck, size: 15),
                    label: Text('البروفايل والطلاب', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TeacherProfileDetailScreen(teacherId: t['id'].toString()),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(LucideIcons.phone, size: 18, color: Colors.blue),
                  tooltip: 'اتصال هاتف',
                  onPressed: () => launchUrl(Uri.parse('tel:$phone')),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.messageCircle, size: 18, color: Color(0xFF10B981)),
                  tooltip: 'واتساب',
                  onPressed: () {
                    WhatsAppService.launchWhatsApp(
                      context: context,
                      phone: phone,
                      message: 'مرحباً أستاذ $name، نتواصل معك من إدارة السنتر.',
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(LucideIcons.key, size: 18, color: Colors.amber),
                  tooltip: 'إدارة كلمة المرور',
                  onPressed: () => _openResetPasswordDialog(t),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(LucideIcons.moreVertical, size: 18),
                  onSelected: (action) async {
                    if (action == 'edit') {
                      final updated = await showDialog<bool>(
                        context: context,
                        builder: (_) => TeacherFormDialog(teacher: t),
                      );
                      if (updated == true) ref.invalidate(liveTeachersProvider);
                    } else if (action == 'delete') {
                      _confirmDeleteTeacher(t);
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(LucideIcons.edit, size: 16),
                          const SizedBox(width: 8),
                          Text('تعديل البيانات', style: GoogleFonts.cairo()),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(LucideIcons.trash2, size: 16, color: Colors.red),
                          const SizedBox(width: 8),
                          Text('حذف المعلم', style: GoogleFonts.cairo(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
