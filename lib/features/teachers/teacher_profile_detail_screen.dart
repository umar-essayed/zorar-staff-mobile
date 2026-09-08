import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/network/edu_api_service.dart';
import '../../core/providers/edu_data_providers.dart';
import '../../core/services/branding_service.dart';
import '../../core/services/sound_service.dart';
import '../../core/services/whatsapp_service.dart';
import '../../core/theme/branding_provider.dart';
import 'teacher_form_dialog.dart';

class TeacherProfileDetailScreen extends ConsumerStatefulWidget {
  final String teacherId;

  const TeacherProfileDetailScreen({super.key, required this.teacherId});

  @override
  ConsumerState<TeacherProfileDetailScreen> createState() => _TeacherProfileDetailScreenState();
}

class _TeacherProfileDetailScreenState extends ConsumerState<TeacherProfileDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _teacher;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadTeacherData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTeacherData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await EduApiService().getTeacher(widget.teacherId);
      if (mounted) {
        setState(() {
          _teacher = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'تعذر تحميل بيانات المعلم: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openResetPasswordDialog() async {
    final passCtrl = TextEditingController();
    bool obscure = true;
    bool isSubmitting = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (c, setDialogState) {
          final branding = ref.watch(brandingProvider);
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(LucideIcons.key, color: branding.primaryColor, size: 22),
                const SizedBox(width: 10),
                Text('تغيير كلمة مرور المعلم', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'سيتم تعيين كلمة مرور جديدة لحساب المعلم للدخول برقم هاتفه (${_teacher?['phone'] ?? ""}):',
                  style: GoogleFonts.cairo(fontSize: 12.5, color: Colors.grey[700]),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: passCtrl,
                  obscureText: obscure,
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور الجديدة',
                    prefixIcon: Icon(LucideIcons.lock, size: 18),
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
                    : Icon(LucideIcons.check, size: 16),
                label: Text('حفظ التعيين', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
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
                          await EduApiService().resetTeacherPassword(widget.teacherId, p);
                          SoundService.successFeedback();
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('تم تحديث كلمة مرور المعلم بنجاح ✅', style: GoogleFonts.cairo()),
                                backgroundColor: const Color(0xFF10B981),
                              ),
                            );
                            _loadTeacherData();
                          }
                        } catch (e) {
                          SoundService.errorFeedback();
                          setDialogState(() => isSubmitting = false);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('فشل التحديث: $e'), backgroundColor: Colors.red),
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

  Future<void> _openNewPayoutDialog() async {
    final now = DateTime.now();
    DateTime start = DateTime(now.year, now.month, 1);
    DateTime end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    final deductionsCtrl = TextEditingController(text: '0');
    final notesCtrl = TextEditingController();
    bool isSubmitting = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (c, setDialogState) {
          final branding = ref.watch(brandingProvider);
          return AlertDialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(LucideIcons.badgeDollarSign, color: branding.primaryColor, size: 22),
                const SizedBox(width: 8),
                Text('تصفية وحساب أرباح المعلم', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'سيتم حساب حضور طلاب مجموعات المعلم آلياً خلال الفترة وحساب حصة السنتر والأرباح المستحقة:',
                    style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: Icon(LucideIcons.calendar, size: 16),
                          label: Text(
                            'من: ${start.toString().split(' ').first}',
                            style: GoogleFonts.cairo(fontSize: 12),
                          ),
                          onPressed: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: start,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (d != null) setDialogState(() => start = d);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: Icon(LucideIcons.calendar, size: 16),
                          label: Text(
                            'إلى: ${end.toString().split(' ').first}',
                            style: GoogleFonts.cairo(fontSize: 12),
                          ),
                          onPressed: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: end,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (d != null) setDialogState(() => end = d);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: deductionsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'الخصومات (قاعات / ملازم / سلف) ج.م',
                      prefixIcon: Icon(LucideIcons.scissors, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: notesCtrl,
                    decoration: InputDecoration(
                      labelText: 'ملاحظات التسوية',
                      prefixIcon: Icon(LucideIcons.fileText, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      isDense: true,
                    ),
                  ),
                ],
              ),
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
                    : Icon(LucideIcons.checkCheck, size: 16),
                label: Text('تأكيد وحساب التسوية', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        setDialogState(() => isSubmitting = true);
                        try {
                          final ded = double.tryParse(deductionsCtrl.text.trim()) ?? 0.0;
                          await EduApiService().createTeacherPayout({
                            'teacherId': widget.teacherId,
                            'periodStart': start.toIso8601String(),
                            'periodEnd': end.toIso8601String(),
                            'deductions': ded,
                            'notes': notesCtrl.text.trim(),
                          });

                          SoundService.successFeedback();
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('تم تسجيل وحساب التسوية المالية بنجاح ✅', style: GoogleFonts.cairo()),
                                backgroundColor: const Color(0xFF10B981),
                              ),
                            );
                            _loadTeacherData();
                          }
                        } catch (e) {
                          SoundService.errorFeedback();
                          setDialogState(() => isSubmitting = false);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('فشل إنشاء التسوية: $e'), backgroundColor: Colors.red),
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

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(brandingProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _teacher?['name'] ?? 'بروفايل المعلم',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: Icon(LucideIcons.edit, size: 20),
              tooltip: 'تعديل المعلم',
              onPressed: _teacher == null
                  ? null
                  : () async {
                      final updated = await showDialog<bool>(
                        context: context,
                        builder: (_) => TeacherFormDialog(teacher: _teacher),
                      );
                      if (updated == true) _loadTeacherData();
                    },
            ),
            IconButton(
              icon: Icon(LucideIcons.refreshCw, size: 18),
              tooltip: 'تحديث',
              onPressed: _loadTeacherData,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.alertCircle, size: 50, color: Colors.red),
                          const SizedBox(height: 12),
                          Text(_errorMessage!, textAlign: TextAlign.center, style: GoogleFonts.cairo()),
                          const SizedBox(height: 16),
                          ElevatedButton(onPressed: _loadTeacherData, child: const Text('إعادة المحاولة')),
                        ],
                      ),
                    ),
                  )
                : Column(
                    children: [
                      // Header Card
                      _buildHeader(branding),

                      // Tabs
                      Container(
                        color: Theme.of(context).cardColor,
                        child: TabBar(
                          controller: _tabController,
                          labelColor: branding.primaryColor,
                          unselectedLabelColor: Colors.grey,
                          indicatorColor: branding.primaryColor,
                          indicatorWeight: 3,
                          labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
                          isScrollable: true,
                          tabs: const [
                            Tab(icon: Icon(LucideIcons.users, size: 18), text: 'المجموعات والطلاب'),
                            Tab(icon: Icon(LucideIcons.video, size: 18), text: 'الكورسات والمنصة'),
                            Tab(icon: Icon(LucideIcons.receipt, size: 18), text: 'السجل المالي والتسويات'),
                            Tab(icon: Icon(LucideIcons.shieldCheck, size: 18), text: 'الحساب والأمان'),
                          ],
                        ),
                      ),

                      // Tab Views
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildGroupsTab(branding),
                            _buildCoursesTab(branding),
                            _buildPayoutsTab(branding),
                            _buildSecurityTab(branding),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildHeader(BrandingModel branding) {
    final t = _teacher!;
    final name = t['name'] ?? 'معلم';
    final phone = t['phone'] ?? '';
    final subject = t['subject']?['name'] ?? 'عام';
    final avatarUrl = t['avatarUrl']?.toString();
    final bio = t['bio']?.toString() ?? '';
    final hasUser = t['user'] != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.15))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: branding.primaryColor.withOpacity(0.12),
            backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null || avatarUrl.isEmpty
                ? Icon(LucideIcons.user, size: 36, color: branding.primaryColor)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (hasUser)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.key, size: 12, color: Color(0xFF10B981)),
                            const SizedBox(width: 4),
                            Text(
                              'حساب دخول نشط',
                              style: GoogleFonts.cairo(fontSize: 10, color: const Color(0xFF10B981), fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _badge(subject, LucideIcons.bookOpen, branding.primaryColor),
                    _badge(phone, LucideIcons.phone, Colors.blueGrey),
                  ],
                ),
                if (bio.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    bio,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(fontSize: 11.5, color: Colors.grey[600]),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    InkWell(
                      onTap: () => launchUrl(Uri.parse('tel:$phone')),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.phoneCall, size: 14, color: Colors.blue),
                            const SizedBox(width: 6),
                            Text('اتصال', style: GoogleFonts.cairo(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        WhatsAppService.launchWhatsApp(
                          context: context,
                          phone: phone,
                          message: 'مرحباً أستاذ $name، نتواصل معك من إدارة السنتر بخصوص الجداول والطلاب.',
                        );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.messageCircle, size: 14, color: Color(0xFF10B981)),
                            const SizedBox(width: 6),
                            Text('واتساب', style: GoogleFonts.cairo(fontSize: 12, color: const Color(0xFF10B981), fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(text, style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  // TAB 1: Groups & Students
  Widget _buildGroupsTab(BrandingModel branding) {
    final groups = (_teacher?['groups'] as List<dynamic>?) ?? [];

    if (groups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.users, size: 50, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text('لا توجد مجموعات دراسية مسجلة باسم هذا المعلم حالياً', style: GoogleFonts.cairo(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: groups.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (ctx, idx) {
        final g = groups[idx] as Map<String, dynamic>;
        final groupName = g['name'] ?? 'مجموعة';
        final year = g['academicYear']?['name'] ?? 'صف غير محدد';
        final classroom = g['classroom']?['name'] ?? 'القاعة العامة';
        final students = (g['students'] as List<dynamic>?) ?? [];
        final price = g['pricePerSession'] ?? 0;

        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 1,
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: branding.primaryColor.withOpacity(0.12),
              child: Icon(LucideIcons.users, color: branding.primaryColor, size: 20),
            ),
            title: Text(groupName, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Row(
              children: [
                Text(year, style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey[700])),
                const SizedBox(width: 8),
                Text('• $classroom', style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey[700])),
                const SizedBox(width: 8),
                Text('• ${students.length} طالب', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: branding.primaryColor)),
              ],
            ),
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.04),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('قائمة طلاب المجموعة (${students.length}):', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12.5)),
                        Text('سعر الحصة: $price ج.م', style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey[700])),
                      ],
                    ),
                    const Divider(height: 14),
                    if (students.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Center(child: Text('لا يوجد طلاب مسجلين بهذه المجموعة بعد', style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey))),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: students.length,
                        separatorBuilder: (_, __) => const Divider(height: 8),
                        itemBuilder: (c, sIdx) {
                          final item = students[sIdx];
                          final st = item['student'] ?? item;
                          final sName = st['name'] ?? 'طالب';
                          final sCode = st['studentCode'] ?? '';
                          final sPhone = st['phone'] ?? st['guardianPhone'] ?? '';

                          return Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: Colors.grey.withOpacity(0.2),
                                child: Text('${sIdx + 1}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(sName, style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.w600)),
                                    if (sCode.isNotEmpty)
                                      Text('كود: $sCode', style: GoogleFonts.firaCode(fontSize: 11, color: Colors.grey[600])),
                                  ],
                                ),
                              ),
                              if (sPhone.isNotEmpty)
                                IconButton(
                                  icon: Icon(LucideIcons.messageCircle, size: 16, color: Color(0xFF10B981)),
                                  tooltip: 'واتساب',
                                  onPressed: () {
                                    WhatsAppService.launchWhatsApp(
                                      context: context,
                                      phone: sPhone,
                                      message: 'مرحباً $sName، نتواصل معك بخصوص مجموعة أستاذ ${_teacher?['name']}.',
                                    );
                                  },
                                ),
                            ],
                          );
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // TAB 2: Online Courses
  Widget _buildCoursesTab(BrandingModel branding) {
    final courses = (_teacher?['courses'] as List<dynamic>?) ?? [];

    if (courses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.video, size: 50, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text('لا توجد كورسات إلكترونية مسجلة باسم هذا المعلم', style: GoogleFonts.cairo(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: courses.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (ctx, idx) {
        final c = courses[idx] as Map<String, dynamic>;
        final title = c['title'] ?? 'كورس';
        final year = c['academicYear']?['name'] ?? '';
        final enrolled = (c['enrollments'] as List<dynamic>?)?.length ?? 0;
        final chapters = (c['chapters'] as List<dynamic>?) ?? [];
        final totalLessons = chapters.fold<int>(0, (sum, ch) => sum + ((ch['lessons'] as List<dynamic>?)?.length ?? 0));

        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: branding.primaryColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(LucideIcons.playCircle, color: branding.primaryColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14)),
                      if (year.isNotEmpty)
                        Text(year, style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey[700])),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text('$totalLessons حصة فيديو', style: GoogleFonts.cairo(fontSize: 11.5, color: Colors.grey[600])),
                          const SizedBox(width: 10),
                          Text('• $enrolled طالب مشترك', style: GoogleFonts.cairo(fontSize: 11.5, fontWeight: FontWeight.bold, color: branding.primaryColor)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // TAB 3: Payouts & Financials
  Widget _buildPayoutsTab(BrandingModel branding) {
    final t = _teacher!;
    final payouts = (t['payouts'] as List<dynamic>?) ?? [];
    final commType = t['commissionType'] ?? 'PERCENTAGE';
    final centerPct = (t['centerPercentage'] as num?)?.toDouble() ?? 20.0;
    final teacherPct = 100.0 - centerPct;
    final fixedFee = (t['fixedCenterFee'] as num?)?.toDouble() ?? 0.0;

    final totalPaid = payouts.fold<double>(0.0, (sum, p) => sum + (p['netPaid'] as num? ?? 0).toDouble());

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Agreement Card
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('اتفاقية المحاسبة ونسبة السنتر:', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13.5)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: branding.primaryColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        commType == 'PERCENTAGE' ? 'نسبة مئوية' : 'رسم ثابت',
                        style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold, color: branding.primaryColor),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          commType == 'PERCENTAGE' ? '${teacherPct.toStringAsFixed(0)}%' : 'الباقي بعد الرسم',
                          style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF10B981)),
                        ),
                        Text('حصة المعلم', style: GoogleFonts.cairo(fontSize: 11.5, color: Colors.grey[600])),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          commType == 'PERCENTAGE' ? '${centerPct.toStringAsFixed(0)}%' : '$fixedFee ج.م / طالب',
                          style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: branding.primaryColor),
                        ),
                        Text('حصة السنتر', style: GoogleFonts.cairo(fontSize: 11.5, color: Colors.grey[600])),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          '${totalPaid.toStringAsFixed(1)} ج.م',
                          style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                        ),
                        Text('إجمالي المصروف للمعلم', style: GoogleFonts.cairo(fontSize: 11.5, color: Colors.grey[600])),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: branding.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: Icon(LucideIcons.badgePlus, size: 18),
                    label: Text('حساب وإجراء تسوية أرباح جديدة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                    onPressed: _openNewPayoutDialog,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),
        Text('سجل التسويات والمدفوعات السابقة (${payouts.length}):', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13.5)),
        const SizedBox(height: 10),

        if (payouts.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text('لا توجد تسويات مالية سابقة مسجلة للمعلم', style: GoogleFonts.cairo(color: Colors.grey, fontSize: 12.5)),
            ),
          )
        else
          ...payouts.map((p) {
            final net = (p['netPaid'] as num?)?.toDouble() ?? 0.0;
            final total = (p['totalRevenue'] as num?)?.toDouble() ?? 0.0;
            final center = (p['centerShare'] as num?)?.toDouble() ?? 0.0;
            final teacherShare = (p['teacherShare'] as num?)?.toDouble() ?? 0.0;
            final deductions = (p['deductions'] as num?)?.toDouble() ?? 0.0;
            final paidAt = p['paidAt'] != null ? p['paidAt'].toString().split('T').first : '';
            final notes = p['notes']?.toString() ?? '';

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(LucideIcons.receipt, size: 16, color: Color(0xFF10B981)),
                            const SizedBox(width: 6),
                            Text('تسوية بتاريخ: $paidAt', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                        Text(
                          'الصافي: ${net.toStringAsFixed(1)} ج.م',
                          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF10B981)),
                        ),
                      ],
                    ),
                    const Divider(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('إجمالي الدخل: ${total.toStringAsFixed(1)} ج.م', style: GoogleFonts.cairo(fontSize: 11.5, color: Colors.grey[700])),
                        Text('حصة السنتر: ${center.toStringAsFixed(1)} ج.م', style: GoogleFonts.cairo(fontSize: 11.5, color: Colors.grey[700])),
                        Text('أتعاب المعلم: ${teacherShare.toStringAsFixed(1)} ج.م', style: GoogleFonts.cairo(fontSize: 11.5, color: Colors.grey[700])),
                      ],
                    ),
                    if (deductions > 0) ...[
                      const SizedBox(height: 4),
                      Text('الخصومات: -${deductions.toStringAsFixed(1)} ج.م', style: GoogleFonts.cairo(fontSize: 11.5, color: Colors.redAccent)),
                    ],
                    if (notes.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text('ملاحظات: $notes', style: GoogleFonts.cairo(fontSize: 11.5, color: Colors.grey[600])),
                    ],
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  // TAB 4: Security & Login Account
  Widget _buildSecurityTab(BrandingModel branding) {
    final t = _teacher!;
    final user = t['user'] as Map<String, dynamic>?;
    final hasUser = user != null;
    final phone = t['phone'] ?? '';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: hasUser ? const Color(0xFF10B981).withOpacity(0.12) : Colors.orange.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        hasUser ? LucideIcons.shieldCheck : LucideIcons.shieldAlert,
                        color: hasUser ? const Color(0xFF10B981) : Colors.orange,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hasUser ? 'حساب الدخول للمنصة مفعل' : 'لا يوجد حساب دخول مفعل للمعلم',
                            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            hasUser
                                ? 'يمكن للمعلم تسجيل الدخول ومتابعة الطلاب والحصص'
                                : 'قم بتعيين كلمة مرور لإنشاء حساب دخول فوري للمعلم',
                            style: GoogleFonts.cairo(fontSize: 11.5, color: Colors.grey[600]),
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
                    Text('اسم المستخدم للدخول:', style: GoogleFonts.cairo(fontSize: 12.5, color: Colors.grey[700])),
                    Text(phone, style: GoogleFonts.firaCode(fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('صلاحية الحساب:', style: GoogleFonts.cairo(fontSize: 12.5, color: Colors.grey[700])),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('معلم (TEACHER)', style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: branding.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: Icon(LucideIcons.key, size: 18),
                    label: Text(
                      hasUser ? 'تغيير أو إعادة تعيين كلمة المرور' : 'إنشاء حساب وتعيين كلمة المرور',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                    ),
                    onPressed: _openResetPasswordDialog,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
