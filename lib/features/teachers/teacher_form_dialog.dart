import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/network/edu_api_service.dart';
import '../../core/providers/edu_data_providers.dart';
import '../../core/services/sound_service.dart';
import '../../core/services/upload_service.dart';
import '../../core/theme/branding_provider.dart';

class TeacherFormDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic>? teacher;

  const TeacherFormDialog({super.key, this.teacher});

  @override
  ConsumerState<TeacherFormDialog> createState() => _TeacherFormDialogState();
}

class _TeacherFormDialogState extends ConsumerState<TeacherFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _bioCtrl;
  late TextEditingController _commissionCtrl;
  late TextEditingController _passwordCtrl;

  String? _selectedSubjectId;
  String _commissionType = 'PERCENTAGE';
  String? _avatarUrl;
  bool _enableLoginAccount = false;
  bool _obscurePassword = true;
  bool _isUploadingAvatar = false;
  bool _isSubmitting = false;

  final Set<String> _selectedGrades = {};

  final List<String> _availableGrades = [
    'ابتدائي',
    'أولى إعدادي',
    'ثانية إعدادي',
    'ثالثة إعدادي',
    'أولى ثانوي',
    'ثانية ثانوي',
    'ثالثة ثانوي',
    'أولى بكالوريا',
    'ثانية بكالوريا',
    'ثالثة بكالوريا',
  ];

  @override
  void initState() {
    super.initState();
    final t = widget.teacher;
    _nameCtrl = TextEditingController(text: t?['name'] ?? '');
    _phoneCtrl = TextEditingController(text: t?['phone'] ?? '');
    _bioCtrl = TextEditingController(text: t?['bio'] ?? '');
    _avatarUrl = t?['avatarUrl'];

    final hasUser = t?['user'] != null || t?['userId'] != null;
    _enableLoginAccount = hasUser;
    _passwordCtrl = TextEditingController();

    _commissionType = t?['commissionType'] ?? 'PERCENTAGE';
    if (_commissionType == 'PERCENTAGE') {
      final centerPct = (t?['centerPercentage'] as num?)?.toDouble() ?? 20.0;
      final teacherPct = 100.0 - centerPct;
      _commissionCtrl = TextEditingController(text: teacherPct.toStringAsFixed(0));
    } else {
      final fee = (t?['fixedCenterFee'] as num?)?.toDouble() ?? 0.0;
      _commissionCtrl = TextEditingController(text: fee.toStringAsFixed(0));
    }

    _selectedSubjectId = t?['subjectId'] ?? t?['subject']?['id'];

    // Parse grades from bio or groups
    final bio = t?['bio']?.toString() ?? '';
    for (final grade in _availableGrades) {
      if (bio.contains(grade)) {
        _selectedGrades.add(grade);
      }
    }
    if (t?['groups'] is List) {
      for (final g in (t!['groups'] as List)) {
        final yearName = g['academicYear']?['name']?.toString() ?? '';
        for (final grade in _availableGrades) {
          if (yearName.contains(grade)) {
            _selectedGrades.add(grade);
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _bioCtrl.dispose();
    _commissionCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    setState(() => _isUploadingAvatar = true);
    try {
      final url = await UploadService.pickAndUploadImage(folder: 'teachers');
      if (url != null) {
        setState(() => _avatarUrl = url);
        SoundService.successFeedback();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل رفع الصورة: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_enableLoginAccount && widget.teacher == null && _passwordCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى كتابة كلمة مرور لحساب المعلم الجديد'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final val = double.tryParse(_commissionCtrl.text.trim()) ?? 80.0;
      double centerPercentage = 20.0;
      double fixedCenterFee = 0.0;

      if (_commissionType == 'PERCENTAGE') {
        centerPercentage = val > 50 ? (100.0 - val) : val;
      } else {
        fixedCenterFee = val;
      }

      // Build bio with selected grades
      String finalBio = _bioCtrl.text.trim();
      if (_selectedGrades.isNotEmpty) {
        final gradesStr = 'الصفوف: ${_selectedGrades.join('، ')}';
        if (finalBio.isEmpty) {
          finalBio = gradesStr;
        } else if (!finalBio.contains('الصفوف:')) {
          finalBio = '$finalBio | $gradesStr';
        }
      }

      final payload = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'subjectId': _selectedSubjectId,
        'commissionType': _commissionType,
        'commissionValue': val,
        'centerPercentage': centerPercentage,
        'fixedCenterFee': fixedCenterFee,
        'bio': finalBio,
        'avatarUrl': _avatarUrl,
      };

      if (_enableLoginAccount && _passwordCtrl.text.trim().isNotEmpty) {
        payload['password'] = _passwordCtrl.text.trim();
      }

      if (widget.teacher == null) {
        await EduApiService().createTeacher(payload);
      } else {
        await EduApiService().updateTeacher(widget.teacher!['id'].toString(), payload);
      }

      ref.invalidate(liveTeachersProvider);
      SoundService.successFeedback();

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.teacher == null ? 'تمت إضافة المعلم بنجاح ✅' : 'تم تحديث بيانات المعلم بنجاح ✅',
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      SoundService.errorFeedback();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر حفظ البيانات: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(brandingProvider);
    final subjectsAsync = ref.watch(liveSubjectsProvider);
    final isEdit = widget.teacher != null;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 750),
        child: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: branding.primaryColor.withOpacity(0.08),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: branding.primaryColor.withOpacity(0.2),
                      child: Icon(
                        isEdit ? LucideIcons.userCheck : LucideIcons.userPlus,
                        color: branding.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEdit ? 'تعديل بيانات المعلم' : 'إضافة معلم جديد للسنتر',
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: branding.primaryColor,
                            ),
                          ),
                          Text(
                            'تحديد التخصص، الصفوف التي يدرسها، ونظام المحاسبة والأمان',
                            style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(LucideIcons.x, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Scrollable Form Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(18),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar Picker
                        Center(
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              CircleAvatar(
                                radius: 44,
                                backgroundColor: branding.primaryColor.withOpacity(0.12),
                                backgroundImage: _avatarUrl != null && _avatarUrl!.isNotEmpty
                                    ? NetworkImage(_avatarUrl!)
                                    : null,
                                child: _avatarUrl == null || _avatarUrl!.isEmpty
                                    ? Icon(LucideIcons.user, size: 40, color: branding.primaryColor)
                                    : null,
                              ),
                              InkWell(
                                onTap: _isUploadingAvatar ? null : _pickAvatar,
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: branding.primaryColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: _isUploadingAvatar
                                      ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                        )
                                      : Icon(LucideIcons.camera, size: 14, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Section 1: Basic Info
                        Text(
                          '1. البيانات الأساسية والتواصل:',
                          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13, color: branding.primaryColor),
                        ),
                        const SizedBox(height: 8),

                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _nameCtrl,
                                decoration: InputDecoration(
                                  labelText: 'اسم المدرس *',
                                  prefixIcon: Icon(LucideIcons.user, size: 18),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  isDense: true,
                                ),
                                validator: (v) => v == null || v.trim().isEmpty ? 'اسم المدرس مطلوب' : null,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: _phoneCtrl,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  labelText: 'رقم هاتف المدرس *',
                                  prefixIcon: Icon(LucideIcons.phone, size: 18),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  isDense: true,
                                ),
                                validator: (v) => v == null || v.trim().isEmpty ? 'رقم الهاتف مطلوب' : null,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Subject Dropdown
                        subjectsAsync.when(
                          data: (subjects) {
                            final items = subjects.map((s) {
                              return DropdownMenuItem<String>(
                                value: s['id']?.toString(),
                                child: Text(s['name'] ?? '', style: GoogleFonts.cairo(fontSize: 13)),
                              );
                            }).toList();

                            return DropdownButtonFormField<String>(
                              value: _selectedSubjectId,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: 'المادة الدراسية / التخصص',
                                prefixIcon: Icon(LucideIcons.bookOpen, size: 18),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                isDense: true,
                              ),
                              items: items,
                              onChanged: (val) => setState(() => _selectedSubjectId = val),
                            );
                          },
                          loading: () => const LinearProgressIndicator(),
                          error: (_, __) => const SizedBox(),
                        ),

                        const SizedBox(height: 18),

                        // Section 2: Stages & Grades Taught
                        Text(
                          '2. الصفوف والمراحل الدراسية التي يدرسها المعلم:',
                          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13, color: branding.primaryColor),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'حدد كل الصفوف التي يدرسها هذا المعلم بالسنتر لتصنيف مجموعاته وكورساته تلقائياً:',
                          style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),

                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: _availableGrades.map((grade) {
                            final isSelected = _selectedGrades.contains(grade);
                            return FilterChip(
                              label: Text(
                                grade,
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? Colors.white : null,
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: branding.primaryColor,
                              checkmarkColor: Colors.white,
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedGrades.add(grade);
                                  } else {
                                    _selectedGrades.remove(grade);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _bioCtrl,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: 'نبذة تعريفية أو تفاصيل إضافية عن المعلم',
                            hintText: 'مثال: معلم أول الفيزياء للثانوية العامة والبكالوريا بالسنتر',
                            prefixIcon: Icon(LucideIcons.fileText, size: 18),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            isDense: true,
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Section 3: Commission Agreement
                        Text(
                          '3. اتفاقية الأتعاب ونظام المحاسبة مع السنتر:',
                          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13, color: branding.primaryColor),
                        ),
                        const SizedBox(height: 8),

                        Row(
                          children: [
                            Expanded(
                              child: RadioListTile<String>(
                                title: Text('نسبة مئوية (%)', style: GoogleFonts.cairo(fontSize: 12.5)),
                                value: 'PERCENTAGE',
                                groupValue: _commissionType,
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                onChanged: (v) => setState(() => _commissionType = v!),
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<String>(
                                title: Text('مبلغ ثابت لكل طالب', style: GoogleFonts.cairo(fontSize: 12.5)),
                                value: 'FIXED_PER_STUDENT',
                                groupValue: _commissionType,
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                onChanged: (v) => setState(() => _commissionType = v!),
                              ),
                            ),
                          ],
                        ),

                        TextFormField(
                          controller: _commissionCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: _commissionType == 'PERCENTAGE'
                                ? 'نسبة المعلم من قيمة الحصة (%)'
                                : 'مبلغ السنتر الثابت لكل طالب بالحصة (ج.م)',
                            prefixIcon: Icon(
                              _commissionType == 'PERCENTAGE' ? LucideIcons.percent : LucideIcons.coins,
                              size: 18,
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            isDense: true,
                            helperText: _commissionType == 'PERCENTAGE'
                                ? 'إذا كانت نسبة المعلم 80%، فإن نسبة السنتر هي 20%'
                                : 'يتم خصم هذا المبلغ للسنتر عن كل طالب حاضر بالحصة',
                            helperStyle: GoogleFonts.cairo(fontSize: 11, color: Colors.grey[600]),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Section 4: Login Account & Password
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.withOpacity(0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SwitchListTile(
                                title: Text(
                                  'حساب دخول المعلم للمنصة والتطبيق',
                                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                subtitle: Text(
                                  'يتيح للمعلم تسجيل الدخول ومتابعة طلابه وجدول حصصه وتقييماتهم',
                                  style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey),
                                ),
                                value: _enableLoginAccount,
                                contentPadding: EdgeInsets.zero,
                                activeColor: branding.primaryColor,
                                onChanged: (val) => setState(() => _enableLoginAccount = val),
                              ),

                              if (_enableLoginAccount) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: branding.primaryColor.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(LucideIcons.info, size: 16, color: branding.primaryColor),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'اسم المستخدم للدخول هو رقم هاتف المعلم.',
                                          style: GoogleFonts.cairo(fontSize: 11.5, color: branding.primaryColor),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                TextFormField(
                                  controller: _passwordCtrl,
                                  obscureText: _obscurePassword,
                                  decoration: InputDecoration(
                                    labelText: isEdit ? 'تغيير كلمة المرور (اتركه فارغاً للإبقاء على الحالية)' : 'كلمة المرور للدخول *',
                                    prefixIcon: Icon(LucideIcons.lock, size: 18),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                                        size: 18,
                                      ),
                                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                    ),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    isDense: true,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Actions Footer
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.15))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                      child: Text('إلغاء', style: GoogleFonts.cairo()),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: branding.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Icon(LucideIcons.check, size: 18),
                      label: Text(
                        isEdit ? 'حفظ التعديلات' : 'إضافة المعلم',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                      ),
                      onPressed: _isSubmitting ? null : _submit,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
