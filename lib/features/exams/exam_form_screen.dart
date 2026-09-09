import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/network/edu_api_service.dart';
import '../../core/providers/edu_data_providers.dart';
import '../../core/services/sound_service.dart';
import '../../core/theme/branding_provider.dart';

class ExamFormScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? initialExam;

  const ExamFormScreen({super.key, this.initialExam});

  @override
  ConsumerState<ExamFormScreen> createState() => _ExamFormScreenState();
}

class _ExamFormScreenState extends ConsumerState<ExamFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _instructionsCtrl;
  late TextEditingController _durationCtrl;
  late TextEditingController _totalMarksCtrl;
  late TextEditingController _passingMarksCtrl;
  late TextEditingController _maxAttemptsCtrl;

  String? _selectedGroupId;
  String? _selectedSubjectId;
  String? _selectedTeacherId;
  String? _selectedAcademicYearId;

  DateTime? _availableFrom;
  DateTime? _availableUntil;

  bool _isPublished = true;
  bool _shuffleQuestions = false;
  bool _showModelAnswers = true;

  bool _isLoading = false;

  // Question list
  List<Map<String, dynamic>> _questions = [];

  @override
  void initState() {
    super.initState();
    final e = widget.initialExam;
    _titleCtrl = TextEditingController(text: e?['title']?.toString() ?? '');
    _descCtrl = TextEditingController(text: e?['description']?.toString() ?? '');
    _instructionsCtrl = TextEditingController(text: e?['instructions']?.toString() ?? '');
    _durationCtrl = TextEditingController(text: (e?['duration'] ?? 60).toString());
    _totalMarksCtrl = TextEditingController(text: (e?['totalMarks'] ?? 100).toString());
    _passingMarksCtrl = TextEditingController(text: (e?['passingMarks'] ?? 50).toString());
    _maxAttemptsCtrl = TextEditingController(text: (e?['maxAttempts'] ?? 1).toString());

    _selectedGroupId = e?['groupId']?.toString();
    _selectedSubjectId = e?['subjectId']?.toString();
    _selectedTeacherId = e?['teacherId']?.toString();
    _selectedAcademicYearId = e?['academicYearId']?.toString();

    if (e?['availableFrom'] != null) {
      _availableFrom = DateTime.tryParse(e!['availableFrom'].toString());
    }
    if (e?['availableUntil'] != null) {
      _availableUntil = DateTime.tryParse(e!['availableUntil'].toString());
    }

    _isPublished = e?['isPublished'] ?? true;
    _shuffleQuestions = e?['shuffleQuestions'] ?? false;
    _showModelAnswers = e?['showModelAnswers'] ?? true;

    if (e?['questions'] != null && e!['questions'] is List) {
      _questions = List<Map<String, dynamic>>.from(
        (e['questions'] as List).map((q) => {
          'id': q['id']?.toString(),
          'text': q['text']?.toString() ?? '',
          'type': q['type']?.toString() ?? 'MCQ',
          'points': (q['points'] ?? 1).toString(),
          'options': (q['options'] is List)
              ? List<String>.from((q['options'] as List).map((o) => o.toString()))
              : ['أ', 'ب', 'ج', 'د'],
          'correctAnswer': q['correctAnswer']?.toString() ?? 'أ',
          'explanation': q['explanation']?.toString() ?? '',
        }),
      );
    }

    if (_questions.isEmpty) {
      _addNewQuestion();
    }
  }

  void _addNewQuestion() {
    setState(() {
      _questions.add({
        'text': '',
        'type': 'MCQ',
        'points': '1',
        'options': ['أ', 'ب', 'ج', 'د'],
        'correctAnswer': 'أ',
        'explanation': '',
      });
    });
  }

  void _removeQuestion(int index) {
    if (_questions.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('يجب أن يحتوي الامتحان على سؤال واحد على الأقل', style: GoogleFonts.cairo()),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    setState(() {
      _questions.removeAt(index);
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _instructionsCtrl.dispose();
    _durationCtrl.dispose();
    _totalMarksCtrl.dispose();
    _passingMarksCtrl.dispose();
    _maxAttemptsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime({required bool isFrom}) async {
    final now = DateTime.now();
    final initialDate = (isFrom ? _availableFrom : _availableUntil) ?? now;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 365)),
    );

    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
      );

      if (pickedTime != null) {
        final combined = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        setState(() {
          if (isFrom) {
            _availableFrom = combined;
          } else {
            _availableUntil = combined;
          }
        });
      }
    }
  }

  Future<void> _saveExam() async {
    if (!_formKey.currentState!.validate()) {
      SoundService().playError();
      return;
    }

    // Validate questions
    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      if ((q['text'] as String).trim().isEmpty) {
        SoundService().playError();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('يرجى كتابة نص السؤال رقم ${i + 1}', style: GoogleFonts.cairo()),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final data = {
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'instructions': _instructionsCtrl.text.trim(),
        'duration': int.tryParse(_durationCtrl.text) ?? 60,
        'totalMarks': double.tryParse(_totalMarksCtrl.text) ?? 100,
        'passingMarks': double.tryParse(_passingMarksCtrl.text) ?? 50,
        'maxAttempts': int.tryParse(_maxAttemptsCtrl.text) ?? 1,
        'groupId': _selectedGroupId,
        'subjectId': _selectedSubjectId,
        'teacherId': _selectedTeacherId,
        'academicYearId': _selectedAcademicYearId,
        'availableFrom': _availableFrom?.toIso8601String(),
        'availableUntil': _availableUntil?.toIso8601String(),
        'isPublished': _isPublished,
        'shuffleQuestions': _shuffleQuestions,
        'showModelAnswers': _showModelAnswers,
        'questions': _questions.map((q) => {
          if (q['id'] != null) 'id': q['id'],
          'text': (q['text'] as String).trim(),
          'type': q['type'] ?? 'MCQ',
          'points': double.tryParse(q['points'].toString()) ?? 1,
          'options': q['options'],
          'correctAnswer': q['correctAnswer'],
          'explanation': q['explanation'],
        }).toList(),
      };

      if (widget.initialExam != null) {
        await EduApiService().updateExam(widget.initialExam!['id'].toString(), data);
      } else {
        await EduApiService().createExam(data);
      }

      SoundService().playSuccess();
      ref.invalidate(liveExamsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.initialExam != null ? 'تم تعديل الامتحان بنجاح' : 'تم إنشاء الامتحان ونشره بنجاح',
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      SoundService().playError();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء الحفظ: $e', style: GoogleFonts.cairo()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(brandingProvider);
    final groupsAsync = ref.watch(liveGroupsProvider);
    final subjectsAsync = ref.watch(liveSubjectsProvider);
    final teachersAsync = ref.watch(liveTeachersProvider);
    final yearsAsync = ref.watch(liveAcademicYearsProvider);

    final groups = groupsAsync.value ?? [];
    final subjects = subjectsAsync.value ?? [];
    final teachers = teachersAsync.value ?? [];
    final years = yearsAsync.value ?? [];

    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initialExam != null ? 'تعديل الامتحان' : 'إنشاء امتحان إلكتروني',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.check),
            onPressed: _isLoading ? null : _saveExam,
            tooltip: 'حفظ الامتحان',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 1. Basic Information Card
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(LucideIcons.fileText, color: branding.primaryColor, size: 20),
                              const SizedBox(width: 8),
                              Text('البيانات الأساسية للامتحان', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                          const Divider(height: 20),
                          TextFormField(
                            controller: _titleCtrl,
                            decoration: InputDecoration(
                              labelText: 'عنوان الامتحان *',
                              hintText: 'مثال: اختبار الشهر الأول - فيزياء تالته ثانوي',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              prefixIcon: const Icon(LucideIcons.heading, size: 18),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'عنوان الامتحان مطلوب' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _descCtrl,
                            maxLines: 2,
                            decoration: InputDecoration(
                              labelText: 'وصف الامتحان (اختياري)',
                              hintText: 'وصف مختصر أو تنويهات عن موضوعات الامتحان',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              prefixIcon: const Icon(LucideIcons.alignLeft, size: 18),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _instructionsCtrl,
                            maxLines: 2,
                            decoration: InputDecoration(
                              labelText: 'تعليمات الطالب قبل بدء الامتحان',
                              hintText: 'مثال: يرجى عدم الخروج من الصفحة، مدة الاختبار دقيقة واحدة لكل سؤال...',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              prefixIcon: const Icon(LucideIcons.alertCircle, size: 18),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. Linkings (Group, Subject, Teacher, Year)
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(LucideIcons.users, color: branding.primaryColor, size: 20),
                              const SizedBox(width: 8),
                              Text('الربط بالمجموعات والمدرسين', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                          const Divider(height: 20),

                          // Target Group
                          DropdownButtonFormField<String?>(
                            value: _selectedGroupId,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'المجموعة المستهدفة',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              prefixIcon: const Icon(LucideIcons.users, size: 18),
                            ),
                            items: [
                              const DropdownMenuItem<String?>(value: null, child: Text('عام (متاح لجميع المجموعات)')),
                              ...groups.map((g) => DropdownMenuItem<String?>(
                                    value: g['id'].toString(),
                                    child: Text(g['name']?.toString() ?? '', overflow: TextOverflow.ellipsis),
                                  )),
                            ],
                            onChanged: (val) => setState(() => _selectedGroupId = val),
                          ),
                          const SizedBox(height: 12),

                          // Subject & Year in a Row
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String?>(
                                  value: _selectedSubjectId,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    labelText: 'المادة الدراسية',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  items: [
                                    const DropdownMenuItem<String?>(value: null, child: Text('غير محدد')),
                                    ...subjects.map((s) => DropdownMenuItem<String?>(
                                          value: s['id'].toString(),
                                          child: Text(s['name']?.toString() ?? '', overflow: TextOverflow.ellipsis),
                                        )),
                                  ],
                                  onChanged: (val) => setState(() => _selectedSubjectId = val),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<String?>(
                                  value: _selectedAcademicYearId,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    labelText: 'السنة الدراسية',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  items: [
                                    const DropdownMenuItem<String?>(value: null, child: Text('غير محدد')),
                                    ...years.map((y) => DropdownMenuItem<String?>(
                                          value: y['id'].toString(),
                                          child: Text(y['name']?.toString() ?? '', overflow: TextOverflow.ellipsis),
                                        )),
                                  ],
                                  onChanged: (val) => setState(() => _selectedAcademicYearId = val),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Teacher
                          DropdownButtonFormField<String?>(
                            value: _selectedTeacherId,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'المعلم المسؤول',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              prefixIcon: const Icon(LucideIcons.userCheck, size: 18),
                            ),
                            items: [
                              const DropdownMenuItem<String?>(value: null, child: Text('السنتر / غير محدد')),
                              ...teachers.map((t) => DropdownMenuItem<String?>(
                                    value: t['id'].toString(),
                                    child: Text(t['name']?.toString() ?? '', overflow: TextOverflow.ellipsis),
                                  )),
                            ],
                            onChanged: (val) => setState(() => _selectedTeacherId = val),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3. Timing, Attempts & Availability Window
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(LucideIcons.clock, color: branding.primaryColor, size: 20),
                              const SizedBox(width: 8),
                              Text('التوقيت ونافذة الإتاحة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                          const Divider(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _durationCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'المدة (بالدقائق) *',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    suffixText: 'دقيقة',
                                  ),
                                  validator: (v) => (v == null || int.tryParse(v) == null) ? 'أدخل رقم صحيح' : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _maxAttemptsCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'عدد المحاولات المسموحة',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    suffixText: 'مرة',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Availability Date Range
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(LucideIcons.calendar, size: 16),
                                  label: Text(
                                    _availableFrom == null
                                        ? 'متاح من (الآن)'
                                        : 'من: ${dateFormat.format(_availableFrom!)}',
                                    style: GoogleFonts.cairo(fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onPressed: () => _pickDateTime(isFrom: true),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(LucideIcons.calendarCheck, size: 16),
                                  label: Text(
                                    _availableUntil == null
                                        ? 'متاح حتى (دائماً)'
                                        : 'حتى: ${dateFormat.format(_availableUntil!)}',
                                    style: GoogleFonts.cairo(fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onPressed: () => _pickDateTime(isFrom: false),
                                ),
                              ),
                            ],
                          ),
                          if (_availableFrom != null || _availableUntil != null)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton(
                                onPressed: () => setState(() {
                                  _availableFrom = null;
                                  _availableUntil = null;
                                }),
                                child: Text('إلغاء قيود التواريخ (متاح دائماً)', style: GoogleFonts.cairo(fontSize: 12, color: Colors.orange)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 4. Grading & Rules
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(LucideIcons.award, color: branding.primaryColor, size: 20),
                              const SizedBox(width: 8),
                              Text('الدرجات والإعدادات', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                          const Divider(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _totalMarksCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'الدرجة الكلية *',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  validator: (v) => (v == null || double.tryParse(v) == null) ? 'مطلوب' : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _passingMarksCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'درجة النجاح *',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  validator: (v) => (v == null || double.tryParse(v) == null) ? 'مطلوب' : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text('نشر الامتحان (متاح للطلاب فوراً)', style: GoogleFonts.cairo(fontSize: 14)),
                            value: _isPublished,
                            activeColor: branding.primaryColor,
                            onChanged: (val) => setState(() => _isPublished = val),
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text('ترتيب عشوائي للأسئلة لكل طالب', style: GoogleFonts.cairo(fontSize: 14)),
                            value: _shuffleQuestions,
                            activeColor: branding.primaryColor,
                            onChanged: (val) => setState(() => _shuffleQuestions = val),
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text('عرض الإجابات النموذجية بعد الإرسال', style: GoogleFonts.cairo(fontSize: 14)),
                            value: _showModelAnswers,
                            activeColor: branding.primaryColor,
                            onChanged: (val) => setState(() => _showModelAnswers = val),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 5. Questions Builder
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(LucideIcons.helpCircle, color: branding.primaryColor, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'بنك أسئلة الامتحان (${_questions.length})',
                                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ],
                              ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: branding.primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                ),
                                icon: const Icon(LucideIcons.plus, size: 16),
                                label: Text('إضافة سؤال', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12)),
                                onPressed: _addNewQuestion,
                              ),
                            ],
                          ),
                          const Divider(height: 20),

                          // Questions list
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _questions.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 16),
                            itemBuilder: (ctx, index) {
                              final q = _questions[index];
                              final options = (q['options'] as List).cast<String>();

                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Theme.of(context).dividerColor),
                                  color: Theme.of(context).cardColor,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Question Header
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        CircleAvatar(
                                          radius: 14,
                                          backgroundColor: branding.primaryColor.withOpacity(0.15),
                                          child: Text(
                                            '${index + 1}',
                                            style: GoogleFonts.cairo(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: branding.primaryColor,
                                            ),
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            // Points Input
                                            SizedBox(
                                              width: 75,
                                              height: 36,
                                              child: TextFormField(
                                                initialValue: q['points'].toString(),
                                                keyboardType: TextInputType.number,
                                                textAlign: TextAlign.center,
                                                decoration: InputDecoration(
                                                  isDense: true,
                                                  contentPadding: const EdgeInsets.symmetric(vertical: 6),
                                                  suffixText: 'درجة',
                                                  suffixStyle: GoogleFonts.cairo(fontSize: 10),
                                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                                ),
                                                onChanged: (val) => q['points'] = val,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            IconButton(
                                              icon: const Icon(LucideIcons.trash2, color: Colors.red, size: 18),
                                              onPressed: () => _removeQuestion(index),
                                              tooltip: 'حذف السؤال',
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),

                                    // Question Text
                                    TextFormField(
                                      initialValue: q['text']?.toString() ?? '',
                                      maxLines: 2,
                                      decoration: InputDecoration(
                                        labelText: 'نص السؤال *',
                                        hintText: 'اكتب نص السؤال هنا...',
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      onChanged: (val) => q['text'] = val,
                                    ),
                                    const SizedBox(height: 12),

                                    // MCQ Options
                                    Text('الخيارات (حدد الخيار الصحيح بالضغط عليه):', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 6),

                                    ...List.generate(options.length, (optIdx) {
                                      final isCorrect = q['correctAnswer'] == options[optIdx];
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 6),
                                        child: Row(
                                          children: [
                                            InkWell(
                                              onTap: () => setState(() => q['correctAnswer'] = options[optIdx]),
                                              child: Container(
                                                padding: const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: isCorrect ? Colors.green : Colors.transparent,
                                                  border: Border.all(color: isCorrect ? Colors.green : Colors.grey),
                                                ),
                                                child: Icon(
                                                  isCorrect ? LucideIcons.check : LucideIcons.circle,
                                                  size: 14,
                                                  color: isCorrect ? Colors.white : Colors.grey,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: TextFormField(
                                                initialValue: options[optIdx],
                                                decoration: InputDecoration(
                                                  isDense: true,
                                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                                  prefixText: '${String.fromCharCode(65 + optIdx)}: ',
                                                  prefixStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                                                ),
                                                onChanged: (val) {
                                                  final wasCorrect = q['correctAnswer'] == options[optIdx];
                                                  options[optIdx] = val;
                                                  if (wasCorrect) q['correctAnswer'] = val;
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),

                                    const SizedBox(height: 6),
                                    // Explanation / Model answer note
                                    TextFormField(
                                      initialValue: q['explanation']?.toString() ?? '',
                                      decoration: InputDecoration(
                                        isDense: true,
                                        labelText: 'تفسير الإجابة النموذجية (اختياري)',
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      onChanged: (val) => q['explanation'] = val,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 12),
                          Center(
                            child: OutlinedButton.icon(
                              icon: const Icon(LucideIcons.plus, size: 18),
                              label: Text('إضافة سؤال آخر', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                              onPressed: _addNewQuestion,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Submit Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: branding.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isLoading ? null : _saveExam,
                    child: Text(
                      widget.initialExam != null ? 'حفظ تعديلات الامتحان' : 'إنشاء ونشر الامتحان الآن',
                      style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}
