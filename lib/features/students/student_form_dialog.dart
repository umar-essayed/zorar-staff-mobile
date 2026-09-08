import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/network/edu_api_service.dart';
import '../../core/providers/edu_data_providers.dart';
import '../../core/services/sound_service.dart';
import '../../core/theme/branding_provider.dart';

class StudentFormDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic>? initialStudent;
  const StudentFormDialog({super.key, this.initialStudent});

  @override
  ConsumerState<StudentFormDialog> createState() => _StudentFormDialogState();
}

class _StudentFormDialogState extends ConsumerState<StudentFormDialog> {
  int _currentStep = 0; // 0: Personal, 1: Academic, 2: Financial
  bool _isSubmitting = false;

  // Step 1: Personal Info Controllers
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _guardianPhoneCtrl = TextEditingController();
  final _schoolNameCtrl = TextEditingController();
  final _studentCodeCtrl = TextEditingController();

  // Step 2: Academic Selection
  String? _selectedYearId;
  final List<String> _selectedGroupIds = [];

  // Step 3: Financial & Notes
  bool _enableInitialPayment = false;
  final _initialAmountCtrl = TextEditingController(text: '300');
  String _paymentMethod = 'CASH';
  final _notesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialStudent != null) {
      final s = widget.initialStudent!;
      _nameCtrl.text = s['name'] ?? '';
      _phoneCtrl.text = s['phone'] ?? '';
      _guardianPhoneCtrl.text = s['guardianPhone'] ?? '';
      _schoolNameCtrl.text = s['schoolName'] ?? '';
      _studentCodeCtrl.text = s['studentCode'] ?? '';
      _notesCtrl.text = s['notes'] ?? '';
      _selectedYearId = s['academicYearId']?.toString();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _guardianPhoneCtrl.dispose();
    _schoolNameCtrl.dispose();
    _studentCodeCtrl.dispose();
    _initialAmountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_nameCtrl.text.trim().isEmpty) {
      _showErrorSnackBar('يرجى كتابة اسم الطالب رباعي');
      setState(() => _currentStep = 0);
      return;
    }
    if (_guardianPhoneCtrl.text.trim().isEmpty) {
      _showErrorSnackBar('يرجى كتابة رقم ولي الأمر للتواصل والواتساب');
      setState(() => _currentStep = 0);
      return;
    }

    setState(() => _isSubmitting = true);
    SoundService.lightImpact();

    try {
      final payload = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim().isNotEmpty ? _phoneCtrl.text.trim() : _guardianPhoneCtrl.text.trim(),
        'guardianPhone': _guardianPhoneCtrl.text.trim(),
        if (_schoolNameCtrl.text.trim().isNotEmpty) 'schoolName': _schoolNameCtrl.text.trim(),
        if (_studentCodeCtrl.text.trim().isNotEmpty) 'studentCode': _studentCodeCtrl.text.trim(),
        if (_selectedYearId != null) 'academicYearId': _selectedYearId,
        if (_selectedGroupIds.isNotEmpty) 'groupIds': _selectedGroupIds,
        if (_notesCtrl.text.trim().isNotEmpty) 'notes': _notesCtrl.text.trim(),
      };

      if (_enableInitialPayment) {
        final amount = double.tryParse(_initialAmountCtrl.text.trim()) ?? 0;
        if (amount > 0) {
          payload['initialPayment'] = {
            'amount': amount,
            'type': 'REGISTRATION_FEE',
            'method': _paymentMethod,
            'description': 'رسوم قيد أولية وحجز',
          };
        }
      }

      if (widget.initialStudent != null) {
        await EduApiService().updateStudent(widget.initialStudent!['id'], payload);
      } else {
        await EduApiService().createStudent(payload);
      }

      SoundService.successFeedback();
      ref.invalidate(liveStudentsProvider);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.initialStudent != null ? 'تم تحديث بيانات الطالب بنجاح' : 'تم تسجيل وقيد الطالب بنجاح بالسنتر',
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      SoundService.errorFeedback();
      if (mounted) {
        _showErrorSnackBar('حدث خطأ أثناء حفظ البيانات، يرجى المحاولة ثانية: $e');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.cairo()),
        backgroundColor: const Color(0xFFEF4444),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(brandingProvider);
    final yearsAsync = ref.watch(liveAcademicYearsProvider);
    final groupsAsync = ref.watch(liveGroupsProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: branding.primaryColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(LucideIcons.userPlus, color: branding.primaryColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.initialStudent != null ? 'تعديل بيانات الطالب' : 'استمارة قيد طالب جديد',
                          style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'مطابقة تماماً لنظام السنتر والويب',
                          style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Step Progress Indicator
              Row(
                children: [
                  _buildStepIndicator(0, 'البيانات الشخصية', branding),
                  _buildStepDivider(),
                  _buildStepIndicator(1, 'المجموعات والسنة', branding),
                  _buildStepDivider(),
                  _buildStepIndicator(2, 'الرسوم والملاحظات', branding),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Form Steps View
              Expanded(
                child: SingleChildScrollView(
                  child: _currentStep == 0
                      ? _buildStep1Personal()
                      : _currentStep == 1
                          ? _buildStep2Academic(yearsAsync, groupsAsync, branding)
                          : _buildStep3Financial(branding),
                ),
              ),

              const SizedBox(height: 16),

              // Bottom Navigation Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentStep > 0)
                    OutlinedButton.icon(
                      icon: const Icon(LucideIcons.chevronRight, size: 16),
                      label: const Text('السابق'),
                      onPressed: () {
                        SoundService.lightImpact();
                        setState(() => _currentStep--);
                      },
                    )
                  else
                    const SizedBox(width: 80),

                  if (_currentStep < 2)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: branding.primaryColor),
                      icon: const Icon(LucideIcons.chevronLeft, size: 16),
                      label: const Text('التالي'),
                      onPressed: () {
                        if (_currentStep == 0 && _nameCtrl.text.trim().isEmpty) {
                          _showErrorSnackBar('يرجى إدخال اسم الطالب أولاً');
                          return;
                        }
                        SoundService.lightImpact();
                        setState(() => _currentStep++);
                      },
                    )
                  else
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(LucideIcons.check, size: 18),
                      label: Text(_isSubmitting ? 'جارٍ الحفظ...' : 'حفظ وقيد الطالب'),
                      onPressed: _isSubmitting ? null : _handleSubmit,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int stepIndex, String title, dynamic branding) {
    final isActive = _currentStep == stepIndex;
    final isDone = _currentStep > stepIndex;

    return Expanded(
      child: Column(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: isDone
                ? const Color(0xFF10B981)
                : isActive
                    ? branding.primaryColor
                    : Colors.grey.withOpacity(0.2),
            child: isDone
                ? const Icon(LucideIcons.check, size: 14, color: Colors.white)
                : Text(
                    '${stepIndex + 1}',
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: isActive ? Colors.white : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.cairo(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? branding.primaryColor : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepDivider() {
    return Container(
      width: 20,
      height: 1.5,
      color: Colors.grey.withOpacity(0.3),
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Widget _buildStep1Personal() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('اسم الطالب الرباعي *', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextField(
          controller: _nameCtrl,
          decoration: const InputDecoration(
            hintText: 'مثال: محمد حسام عبد الرحمن',
            prefixIcon: Icon(LucideIcons.user, size: 18),
            isDense: true,
          ),
        ),
        const SizedBox(height: 14),

        Text('رقم ولي الأمر (واتساب أساسي) *', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextField(
          controller: _guardianPhoneCtrl,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            hintText: '010XXXXXXXX',
            prefixIcon: Icon(LucideIcons.messageSquare, size: 18),
            isDense: true,
          ),
        ),
        const SizedBox(height: 14),

        Text('رقم هاتف الطالب (اختياري)', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            hintText: '01XXXXXXXXX',
            prefixIcon: Icon(LucideIcons.phone, size: 18),
            isDense: true,
          ),
        ),
        const SizedBox(height: 14),

        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('المدرسة (اختياري)', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _schoolNameCtrl,
                    decoration: const InputDecoration(
                      hintText: 'اسم المدرسة',
                      prefixIcon: Icon(LucideIcons.school, size: 18),
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('كود الطالب (اختياري)', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _studentCodeCtrl,
                    decoration: const InputDecoration(
                      hintText: 'اتركه فارغاً للتوليد',
                      prefixIcon: Icon(LucideIcons.hash, size: 18),
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep2Academic(
    AsyncValue<List<Map<String, dynamic>>> yearsAsync,
    AsyncValue<List<Map<String, dynamic>>> groupsAsync,
    dynamic branding,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('السنة الدراسية المقيد بها', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        yearsAsync.when(
          data: (years) {
            if (years.isEmpty) {
              return Text('لا توجد سنوات دراسية مسجلة حالياً', style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey));
            }
            return DropdownButtonFormField<String>(
              value: _selectedYearId ?? (years.isNotEmpty ? years.first['id'].toString() : null),
              isExpanded: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(LucideIcons.graduationCap, size: 18),
                isDense: true,
              ),
              items: years.map((y) {
                return DropdownMenuItem<String>(
                  value: y['id'].toString(),
                  child: Text(y['name'] ?? '', style: GoogleFonts.cairo(fontSize: 13)),
                );
              }).toList(),
              onChanged: (val) {
                setState(() => _selectedYearId = val);
              },
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (_, __) => const Text('تعذر تحميل السنوات الدراسية'),
        ),

        const SizedBox(height: 18),

        Text('تسكين المجموعات الدراسية (يمكن اختيار أكثر من مجموعة):', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),

        groupsAsync.when(
          data: (groups) {
            if (groups.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text('لا توجد مجموعات متاحة حالياً', style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey)),
                ),
              );
            }

            return Column(
              children: groups.map((g) {
                final id = g['id'].toString();
                final isChecked = _selectedGroupIds.contains(id);
                final groupName = g['name'] ?? 'مجموعة';
                final teacherName = g['teacher']?['name'] ?? '';
                final monthlyFee = g['monthlyFee'] ?? g['monthlyPrice'] ?? 0;

                return Card(
                  elevation: 0,
                  color: isChecked ? branding.primaryColor.withOpacity(0.08) : Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: isChecked ? branding.primaryColor : Colors.grey.withOpacity(0.2),
                    ),
                  ),
                  child: CheckboxListTile(
                    value: isChecked,
                    title: Text(groupName, style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      'المدرس: $teacherName • $monthlyFee ج.م / شهر',
                      style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey),
                    ),
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedGroupIds.add(id);
                        } else {
                          _selectedGroupIds.remove(id);
                        }
                      });
                    },
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Text('تعذر تحميل المجموعات'),
        ),
      ],
    );
  }

  Widget _buildStep3Financial(dynamic branding) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('تحصيل رسوم قيد أو أول اشتراك فوراً', style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold)),
          subtitle: Text('إنشاء سند قبض بالخزينة وإصدار إيصال', style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey)),
          value: _enableInitialPayment,
          onChanged: (val) {
            setState(() => _enableInitialPayment = val);
          },
        ),

        if (_enableInitialPayment) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('المبلغ المحصل (ج.م)', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _initialAmountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(LucideIcons.coins, size: 18),
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('طريقة الدفع', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _paymentMethod,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(LucideIcons.wallet, size: 18),
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'CASH', child: Text('كاش (نقدي)')),
                        DropdownMenuItem(value: 'VODAFONE_CASH', child: Text('محفظة إلكترونية')),
                        DropdownMenuItem(value: 'VISA', child: Text('فيزا / بطاقة')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _paymentMethod = val);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],

        Text('ملاحظات إضافية عن الطالب', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextField(
          controller: _notesCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'أي ملاحظات خاصة بالتفوق أو الحضور أو شروط الدفع...',
            prefixIcon: Icon(LucideIcons.fileText, size: 18),
          ),
        ),
      ],
    );
  }
}
