import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/network/edu_api_service.dart';
import '../../core/providers/edu_data_providers.dart';
import '../../core/services/sound_service.dart';
import '../../core/services/whatsapp_service.dart';
import '../../core/theme/branding_provider.dart';

class LiveClassCockpitScreen extends ConsumerStatefulWidget {
  final String? groupName;
  final String? groupId;
  final int sessionNumber;

  const LiveClassCockpitScreen({
    super.key,
    this.groupName,
    this.groupId,
    this.sessionNumber = 1,
  });

  @override
  ConsumerState<LiveClassCockpitScreen> createState() => _LiveClassCockpitScreenState();
}

class _LiveClassCockpitScreenState extends ConsumerState<LiveClassCockpitScreen> {
  String? _selectedGroupId;
  List<Map<String, dynamic>> _students = [];
  bool _isLoadingStudents = false;
  final Map<String, int> _scores = {};
  final Map<String, String> _homeworkStatus = {}; // 'DONE', 'INCOMPLETE', 'NOT_DONE'
  final Map<String, TextEditingController> _notesControllers = {};
  final Set<String> _savingStudentIds = {};
  final Set<String> _savedStudentIds = {};

  @override
  void initState() {
    super.initState();
    _selectedGroupId = widget.groupId;
    if (_selectedGroupId != null && _selectedGroupId!.isNotEmpty) {
      _loadStudents(_selectedGroupId!);
    }
  }

  Future<void> _loadStudents(String grpId) async {
    setState(() => _isLoadingStudents = true);
    try {
      final list = await EduApiService().getStudents(groupId: grpId);
      if (mounted) {
        setState(() {
          _students = list;
          _isLoadingStudents = false;
          for (final s in list) {
            final sId = s['id']?.toString() ?? '';
            if (!_scores.containsKey(sId)) _scores[sId] = 10;
            if (!_homeworkStatus.containsKey(sId)) _homeworkStatus[sId] = 'DONE';
            if (!_notesControllers.containsKey(sId)) _notesControllers[sId] = TextEditingController();
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingStudents = false);
    }
  }

  Future<void> _saveAssessment(String studentId, String studentName) async {
    if (_selectedGroupId == null) return;
    setState(() => _savingStudentIds.add(studentId));

    try {
      final score = _scores[studentId] ?? 10;
      final hw = _homeworkStatus[studentId] ?? 'DONE';
      final notes = _notesControllers[studentId]?.text.trim() ?? '';

      await EduApiService().recordAssessment({
        'studentId': studentId,
        'groupId': _selectedGroupId,
        'quizScore': score,
        'quizTotal': 10,
        'homeworkStatus': hw,
        'behaviorNotes': notes,
        'sendWhatsAppReport': true,
      });

      SoundService.successFeedback();
      if (mounted) {
        setState(() {
          _savingStudentIds.remove(studentId);
          _savedStudentIds.add(studentId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم رصد درجات وواجب الطالب ($studentName) بنجاح ✅'),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _savingStudentIds.remove(studentId));
        SoundService.errorFeedback();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر حفظ التقييم: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    for (final ctrl in _notesControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(brandingProvider);
    final groupsAsync = ref.watch(liveGroupsProvider);
    final groups = groupsAsync.value ?? [];

    if (_selectedGroupId == null && groups.isNotEmpty) {
      _selectedGroupId = groups.first['id']?.toString();
      if (_selectedGroupId != null) {
        _loadStudents(_selectedGroupId!);
      }
    }

    final selectedGroup = groups.firstWhere(
      (g) => g['id']?.toString() == _selectedGroupId,
      orElse: () => {},
    );
    final title = widget.groupName ?? selectedGroup['name']?.toString() ?? 'قمرة رصد درجات الحصة';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold)),
            Text('الحصة (${widget.sessionNumber}) • رصد التسميع والواجب الميداني',
                style: GoogleFonts.cairo(fontSize: 11.5, color: Colors.grey)),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: branding.primaryColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.users, size: 16, color: branding.primaryColor),
                const SizedBox(width: 6),
                Text(
                  '${_students.length} طالب',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: branding.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (groups.isNotEmpty && widget.groupId == null)
            Container(
              padding: const EdgeInsets.all(12),
              color: Theme.of(context).cardColor,
              child: DropdownButtonFormField<String>(
                value: _selectedGroupId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'اختر المجموعة الدراسية',
                  prefixIcon: Icon(LucideIcons.layers, size: 20),
                  isDense: true,
                ),
                items: groups.map((g) {
                  return DropdownMenuItem<String>(
                    value: g['id']?.toString(),
                    child: Text(g['name']?.toString() ?? 'مجموعة', style: GoogleFonts.cairo(fontSize: 13)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedGroupId = val);
                    _loadStudents(val);
                  }
                },
              ),
            ),

          Expanded(
            child: _isLoadingStudents
                ? const Center(child: CircularProgressIndicator())
                : _students.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.userX, size: 54, color: Colors.grey.withOpacity(0.4)),
                            const SizedBox(height: 12),
                            Text('لا يوجد طلاب مسجلين في هذه المجموعة حتى الآن', style: GoogleFonts.cairo(color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(14),
                        itemCount: _students.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (ctx, idx) {
                          final student = _students[idx];
                          final sId = student['id']?.toString() ?? '';
                          final name = student['name']?.toString() ?? 'طالب';
                          final code = student['studentCode']?.toString() ?? '';
                          final score = _scores[sId] ?? 10;
                          final hw = _homeworkStatus[sId] ?? 'DONE';
                          final isSaving = _savingStudentIds.contains(sId);
                          final isSaved = _savedStudentIds.contains(sId);
                          final phone = student['parentPhone']?.toString() ?? student['phone']?.toString() ?? '';

                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(
                                color: isSaved ? const Color(0xFF10B981) : Colors.grey.withOpacity(0.15),
                                width: isSaved ? 1.5 : 1,
                              ),
                            ),
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
                                            Text(name, style: GoogleFonts.cairo(fontSize: 14.5, fontWeight: FontWeight.bold)),
                                            Text('كود الطالب: $code', style: GoogleFonts.cairo(fontSize: 11.5, color: Colors.grey)),
                                          ],
                                        ),
                                      ),
                                      if (isSaved)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF10B981).withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(LucideIcons.check, size: 14, color: Color(0xFF10B981)),
                                              const SizedBox(width: 4),
                                              Text('تم الرصد', style: GoogleFonts.cairo(fontSize: 11, color: const Color(0xFF10B981), fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                  const Divider(height: 18),

                                  // Score Slider / Selector
                                  Row(
                                    children: [
                                      Text('درجة التسميع / الكويز:', style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.bold)),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: branding.primaryColor.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '$score / 10',
                                          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13, color: branding.primaryColor),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Slider(
                                    value: score.toDouble(),
                                    min: 0,
                                    max: 10,
                                    divisions: 10,
                                    activeColor: branding.primaryColor,
                                    onChanged: (val) {
                                      setState(() {
                                        _scores[sId] = val.toInt();
                                        _savedStudentIds.remove(sId);
                                      });
                                    },
                                  ),

                                  // Homework Status Buttons
                                  Text('حالة الواجب المنزلي:', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      _buildHwOption(sId, 'DONE', 'كامل ⭐', Colors.green),
                                      const SizedBox(width: 8),
                                      _buildHwOption(sId, 'INCOMPLETE', 'ناقص ⚠️', Colors.amber),
                                      const SizedBox(width: 8),
                                      _buildHwOption(sId, 'NOT_DONE', 'لم يحل ❌', Colors.red),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // Notes Field
                                  TextField(
                                    controller: _notesControllers[sId],
                                    decoration: InputDecoration(
                                      hintText: 'ملاحظات المعلم السلوكية أو الأكاديمية (اختياري)...',
                                      hintStyle: GoogleFonts.cairo(fontSize: 11.5),
                                      isDense: true,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Save & WhatsApp Actions
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: isSaved ? Colors.grey[700] : branding.primaryColor,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            padding: const EdgeInsets.symmetric(vertical: 10),
                                          ),
                                          icon: isSaving
                                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                              : const Icon(LucideIcons.save, size: 16),
                                          label: Text(
                                            isSaving ? 'جاري الحفظ...' : (isSaved ? 'تحديث التقييم' : 'حفظ التقييم'),
                                            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                          onPressed: isSaving ? null : () => _saveAssessment(sId, name),
                                        ),
                                      ),
                                      if (phone.isNotEmpty) ...[
                                        const SizedBox(width: 8),
                                        IconButton(
                                          style: IconButton.styleFrom(
                                            backgroundColor: const Color(0xFF25D366),
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            padding: const EdgeInsets.all(10),
                                          ),
                                          tooltip: 'إرسال تقرير الحصة واتساب لولي الأمر',
                                          icon: const Icon(LucideIcons.messageCircle, size: 18),
                                          onPressed: () {
                                            WhatsAppService.sendSessionAssessmentReport(
                                              context: context,
                                              parentPhone: phone,
                                              studentName: name,
                                              groupName: title,
                                              score: score,
                                              maxScore: 10,
                                              homeworkStatus: hw,
                                              centerName: branding.centerName,
                                              behaviorNotes: _notesControllers[sId]?.text.trim(),
                                            );
                                          },
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildHwOption(String studentId, String value, String label, MaterialColor color) {
    final isSelected = (_homeworkStatus[studentId] ?? 'DONE') == value;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _homeworkStatus[studentId] = value;
            _savedStudentIds.remove(studentId);
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : Colors.grey.withOpacity(0.25),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? color[800] : Colors.grey[700],
            ),
          ),
        ),
      ),
    );
  }
}
