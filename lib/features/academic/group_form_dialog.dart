import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/network/edu_api_service.dart';
import '../../core/providers/edu_data_providers.dart';
import '../../core/services/sound_service.dart';
import '../../core/theme/branding_provider.dart';

class GroupFormDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic>? initialGroup;
  const GroupFormDialog({super.key, this.initialGroup});

  @override
  ConsumerState<GroupFormDialog> createState() => _GroupFormDialogState();
}

class _GroupFormDialogState extends ConsumerState<GroupFormDialog> {
  int _currentStep = 0;
  bool _isSubmitting = false;

  // Step 1: Basic Info
  final _nameCtrl = TextEditingController();
  String? _selectedYearId;
  String? _selectedSubjectId;
  String? _selectedTeacherId;
  final _classroomCtrl = TextEditingController(text: 'قاعة 1');

  // Step 2: Schedule & Days
  final List<int> _selectedDays = [6, 2]; // 6: Saturday, 2: Tuesday
  final _startTimeCtrl = TextEditingController(text: '16:00');
  final _endTimeCtrl = TextEditingController(text: '18:00');
  final _capacityCtrl = TextEditingController(text: '50');

  // Step 3: Financials & Policy
  final _monthlyFeeCtrl = TextEditingController(text: '450');
  final _sessionPriceCtrl = TextEditingController(text: '120');
  final _sessionsPerMonthCtrl = TextEditingController(text: '4');
  final _graceMinutesCtrl = TextEditingController(text: '30');
  final _allowedGraceSessionsCtrl = TextEditingController(text: '1');

  final List<Map<String, dynamic>> _daysOptions = [
    {'name': 'السبت', 'val': 6},
    {'name': 'الأحد', 'val': 0},
    {'name': 'الاثنين', 'val': 1},
    {'name': 'الثلاثاء', 'val': 2},
    {'name': 'الأربعاء', 'val': 3},
    {'name': 'الخميس', 'val': 4},
    {'name': 'الجمعة', 'val': 5},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialGroup != null) {
      final g = widget.initialGroup!;
      _nameCtrl.text = g['name'] ?? '';
      _selectedYearId = g['academicYearId']?.toString();
      _selectedSubjectId = g['subjectId']?.toString();
      _selectedTeacherId = g['teacherId']?.toString();
      _startTimeCtrl.text = g['startTime'] ?? '16:00';
      _endTimeCtrl.text = g['endTime'] ?? '18:00';
      _capacityCtrl.text = (g['maxStudents'] ?? 50).toString();
      _monthlyFeeCtrl.text = (g['monthlyFee'] ?? 450).toString();
      _sessionPriceCtrl.text = (g['pricePerSession'] ?? 120).toString();
      _sessionsPerMonthCtrl.text = (g['sessionsPerMonth'] ?? 4).toString();
      _graceMinutesCtrl.text = (g['gracePeriodMinutes'] ?? 30).toString();
      _allowedGraceSessionsCtrl.text = (g['allowedGraceSessions'] ?? 1).toString();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _classroomCtrl.dispose();
    _startTimeCtrl.dispose();
    _endTimeCtrl.dispose();
    _capacityCtrl.dispose();
    _monthlyFeeCtrl.dispose();
    _sessionPriceCtrl.dispose();
    _sessionsPerMonthCtrl.dispose();
    _graceMinutesCtrl.dispose();
    _allowedGraceSessionsCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('يرجى كتابة اسم المجموعة', style: GoogleFonts.cairo()), backgroundColor: Colors.red),
      );
      setState(() => _currentStep = 0);
      return;
    }
    if (_selectedSubjectId == null || _selectedYearId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('يرجى اختيار المادة والسنة الدراسية', style: GoogleFonts.cairo()), backgroundColor: Colors.red),
      );
      setState(() => _currentStep = 0);
      return;
    }

    setState(() => _isSubmitting = true);
    SoundService.lightImpact();

    try {
      final payload = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'academicYearId': _selectedYearId,
        'subjectId': _selectedSubjectId,
        if (_selectedTeacherId != null) 'teacherId': _selectedTeacherId,
        'dayOfWeek': _selectedDays,
        'startTime': _startTimeCtrl.text.trim(),
        'endTime': _endTimeCtrl.text.trim(),
        'maxStudents': int.tryParse(_capacityCtrl.text.trim()) ?? 50,
        'monthlyFee': double.tryParse(_monthlyFeeCtrl.text.trim()) ?? 0,
        'pricePerSession': double.tryParse(_sessionPriceCtrl.text.trim()) ?? 0,
        'sessionsPerMonth': int.tryParse(_sessionsPerMonthCtrl.text.trim()) ?? 4,
        'gracePeriodMinutes': int.tryParse(_graceMinutesCtrl.text.trim()) ?? 30,
        'allowedGraceSessions': int.tryParse(_allowedGraceSessionsCtrl.text.trim()) ?? 1,
      };

      if (widget.initialGroup != null) {
        await EduApiService().updateGroup(widget.initialGroup!['id'], payload);
      } else {
        await EduApiService().createGroup(payload);
      }

      SoundService.successFeedback();
      ref.invalidate(liveGroupsProvider);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حفظ وتسكين المجموعة بنجاح ✅', style: GoogleFonts.cairo()),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      SoundService.errorFeedback();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر حفظ المجموعة: $e', style: GoogleFonts.cairo()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(brandingProvider);
    final yearsAsync = ref.watch(liveAcademicYearsProvider);
    final subjectsAsync = ref.watch(liveSubjectsProvider);
    final teachersAsync = ref.watch(liveTeachersProvider);

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
                    child: Icon(LucideIcons.layers, color: branding.primaryColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.initialGroup != null ? 'تعديل المجموعة الدراسية' : 'إنشاء وتسكين مجموعة دراسية',
                          style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'تحديد المواعيد، الأسعار، وحصص السماح',
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

              // Step Indicator
              Row(
                children: [
                  _buildStepIndicator(0, 'البيانات والمادة', branding),
                  _buildStepDivider(),
                  _buildStepIndicator(1, 'المواعيد والأيام', branding),
                  _buildStepDivider(),
                  _buildStepIndicator(2, 'الرسوم والقواعد', branding),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Step Content
              Expanded(
                child: SingleChildScrollView(
                  child: _currentStep == 0
                      ? _buildStep1Basic(yearsAsync, subjectsAsync, teachersAsync)
                      : _currentStep == 1
                          ? _buildStep2Schedule(branding)
                          : _buildStep3Financials(),
                ),
              ),

              const SizedBox(height: 16),

              // Navigation Buttons
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
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('يرجى كتابة اسم المجموعة'), backgroundColor: Colors.red),
                          );
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
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(LucideIcons.check, size: 18),
                      label: Text(_isSubmitting ? 'جارٍ الحفظ...' : 'حفظ المجموعة'),
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

  Widget _buildStepIndicator(int idx, String title, dynamic branding) {
    final isActive = _currentStep == idx;
    final isDone = _currentStep > idx;
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
                : Text('${idx + 1}', style: GoogleFonts.cairo(fontSize: 11, color: isActive ? Colors.white : Colors.grey, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 4),
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.cairo(fontSize: 10, color: isActive ? branding.primaryColor : Colors.grey, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  Widget _buildStepDivider() {
    return Container(width: 16, height: 1.5, color: Colors.grey.withOpacity(0.3), margin: const EdgeInsets.symmetric(horizontal: 4));
  }

  Widget _buildStep1Basic(
    AsyncValue<List<Map<String, dynamic>>> yearsAsync,
    AsyncValue<List<Map<String, dynamic>>> subjectsAsync,
    AsyncValue<List<Map<String, dynamic>>> teachersAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('اسم المجموعة *', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextField(
          controller: _nameCtrl,
          decoration: const InputDecoration(
            hintText: 'مثال: 3ث لغة عربية (السبت والثلاثاء أ)',
            prefixIcon: Icon(LucideIcons.layers, size: 18),
            isDense: true,
          ),
        ),
        const SizedBox(height: 14),

        Text('السنة الدراسية *', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        yearsAsync.when(
          data: (years) {
            _selectedYearId ??= years.isNotEmpty ? years.first['id'].toString() : null;
            return DropdownButtonFormField<String>(
              value: _selectedYearId,
              isExpanded: true,
              decoration: const InputDecoration(prefixIcon: Icon(LucideIcons.graduationCap, size: 18), isDense: true),
              items: years.map((y) => DropdownMenuItem<String>(value: y['id'].toString(), child: Text(y['name'] ?? ''))).toList(),
              onChanged: (v) => setState(() => _selectedYearId = v),
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (_, __) => const Text('تعذر تحميل السنوات'),
        ),
        const SizedBox(height: 14),

        Text('المادة الدراسية *', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        subjectsAsync.when(
          data: (subjects) {
            _selectedSubjectId ??= subjects.isNotEmpty ? subjects.first['id'].toString() : null;
            return DropdownButtonFormField<String>(
              value: _selectedSubjectId,
              isExpanded: true,
              decoration: const InputDecoration(prefixIcon: Icon(LucideIcons.bookOpen, size: 18), isDense: true),
              items: subjects.map((s) => DropdownMenuItem<String>(value: s['id'].toString(), child: Text(s['name'] ?? ''))).toList(),
              onChanged: (v) => setState(() => _selectedSubjectId = v),
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (_, __) => const Text('تعذر تحميل المواد'),
        ),
        const SizedBox(height: 14),

        Text('المعلم المسؤول', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        teachersAsync.when(
          data: (teachers) {
            return DropdownButtonFormField<String>(
              value: _selectedTeacherId,
              isExpanded: true,
              hint: const Text('اختر المعلم...'),
              decoration: const InputDecoration(prefixIcon: Icon(LucideIcons.userCheck, size: 18), isDense: true),
              items: teachers.map((t) => DropdownMenuItem<String>(value: t['id'].toString(), child: Text(t['name'] ?? ''))).toList(),
              onChanged: (v) => setState(() => _selectedTeacherId = v),
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (_, __) => const Text('تعذر تحميل المعلمين'),
        ),
      ],
    );
  }

  Widget _buildStep2Schedule(dynamic branding) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('أيام انعقاد الحصص أسبوعياً:', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _daysOptions.map((d) {
            final val = d['val'] as int;
            final isSelected = _selectedDays.contains(val);
            return FilterChip(
              label: Text(d['name'] as String, style: GoogleFonts.cairo(fontSize: 11)),
              selected: isSelected,
              selectedColor: branding.primaryColor,
              labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.grey[700]),
              onSelected: (sel) {
                setState(() {
                  if (sel) {
                    _selectedDays.add(val);
                  } else {
                    _selectedDays.remove(val);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('وقت البدء', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _startTimeCtrl,
                    decoration: const InputDecoration(hintText: '16:00', prefixIcon: Icon(LucideIcons.clock, size: 18), isDense: true),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('وقت الانتهاء', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _endTimeCtrl,
                    decoration: const InputDecoration(hintText: '18:00', prefixIcon: Icon(LucideIcons.clock, size: 18), isDense: true),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        Text('الحد الأقصى للطلاب (السعة الاستيعابية)', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextField(
          controller: _capacityCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: '50', prefixIcon: Icon(LucideIcons.users, size: 18), isDense: true),
        ),
      ],
    );
  }

  Widget _buildStep3Financials() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('الاشتراك الشهري (ج.م) *', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _monthlyFeeCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: '450', prefixIcon: Icon(LucideIcons.coins, size: 18), isDense: true),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('سعر الحصة الواحدة (ج.م)', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _sessionPriceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: '120', prefixIcon: Icon(LucideIcons.receipt, size: 18), isDense: true),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('حصص الشهر', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _sessionsPerMonthCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: '4', prefixIcon: Icon(LucideIcons.calendar, size: 18), isDense: true),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('مهلة التأخير (بالدقائق)', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _graceMinutesCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: '30', prefixIcon: Icon(LucideIcons.timer, size: 18), isDense: true),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        Text('حصص السماح المسموحة بدون سداد الاشتراك', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextField(
          controller: _allowedGraceSessionsCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: '1', prefixIcon: Icon(LucideIcons.shieldAlert, size: 18), isDense: true),
        ),
      ],
    );
  }
}
