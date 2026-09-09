import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/network/edu_api_service.dart';
import '../../core/providers/edu_data_providers.dart';
import '../../core/services/sound_service.dart';
import '../../core/theme/branding_provider.dart';
import '../../core/utils/numeric_utils.dart';
import 'exam_form_screen.dart';

class ExamDetailsScreen extends ConsumerStatefulWidget {
  final String examId;

  const ExamDetailsScreen({super.key, required this.examId});

  @override
  ConsumerState<ExamDetailsScreen> createState() => _ExamDetailsScreenState();
}

class _ExamDetailsScreenState extends ConsumerState<ExamDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _exam;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadExam();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadExam() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await EduApiService().getExam(widget.examId);
      if (data != null && mounted) {
        setState(() {
          _exam = data;
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() {
          _errorMessage = 'لم يتم العثور على بيانات الامتحان';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'حدث خطأ أثناء تحميل البيانات: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteExam() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تأكيد حذف الامتحان', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        content: Text('هل أنت متأكد من رغبتك في حذف هذا الامتحان نهائياً؟ سيتم حذف جميع إجابات ودرجات الطلاب المرتبطة به.', style: GoogleFonts.cairo()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('إلغاء', style: GoogleFonts.cairo()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('حذف نهائي', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await EduApiService().deleteExam(widget.examId);
      if (success) {
        SoundService.successFeedback();
        ref.invalidate(liveExamsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تم حذف الامتحان بنجاح', style: GoogleFonts.cairo()), backgroundColor: Colors.green),
          );
          Navigator.pop(context, true);
        }
      } else {
        SoundService.errorFeedback();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('فشل حذف الامتحان', style: GoogleFonts.cairo()), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _togglePublish() async {
    if (_exam == null) return;
    final currentStatus = _exam!['isPublished'] ?? true;
    try {
      final updated = await EduApiService().updateExam(widget.examId, {'isPublished': !currentStatus});
      if (updated != null && mounted) {
        setState(() => _exam = updated);
        ref.invalidate(liveExamsProvider);
        SoundService.successFeedback();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              !currentStatus ? 'تم تفعيل ونشر الامتحان' : 'تم إيقاف نشر الامتحان (تحويل لمسودة)',
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      SoundService.errorFeedback();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل تغيير الحالة: $e', style: GoogleFonts.cairo()), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(brandingProvider);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('تفاصيل الامتحان', style: GoogleFonts.cairo())),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null || _exam == null) {
      return Scaffold(
        appBar: AppBar(title: Text('تفاصيل الامتحان', style: GoogleFonts.cairo())),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.alertTriangle, size: 48, color: Colors.orange),
              const SizedBox(height: 12),
              Text(_errorMessage ?? 'خطأ في التحميل', style: GoogleFonts.cairo(fontSize: 16)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(LucideIcons.refreshCw, size: 16),
                label: Text('إعادة المحاولة', style: GoogleFonts.cairo()),
                onPressed: _loadExam,
              ),
            ],
          ),
        ),
      );
    }

    final e = _exam!;
    final questions = (e['questions'] as List?) ?? [];
    final submissions = (e['submissions'] as List?) ?? [];

    final isPublished = e['isPublished'] ?? true;
    final duration = e['durationMinutes'] ?? e['duration'] ?? 60;
    final totalMarks = e['totalScore'] ?? e['totalMarks'] ?? 100;
    final passingMarks = e['passingScore'] ?? e['passingMarks'] ?? 50;

    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final availableFrom = e['availableFrom'] != null ? DateTime.tryParse(e['availableFrom'].toString()) : null;
    final availableUntil = e['availableUntil'] != null ? DateTime.tryParse(e['availableUntil'].toString()) : null;

    final groupName = e['group']?['name']?.toString() ?? 'جميع المجموعات';
    final subjectName = e['subject']?['name']?.toString() ?? 'غير محدد';
    final teacherName = e['teacher']?['name']?.toString() ?? 'إدارة المركز';

    // Submissions analytics
    final totalSubmissions = submissions.length;
    final passedSubmissions = submissions.where((s) => (s['score'] ?? 0) >= passingMarks).length;
    final double avgScore = totalSubmissions > 0
        ? submissions.fold<double>(0.0, (sum, s) => sum + ((s['score'] is num) ? (s['score'] as num).toDouble() : 0.0)) / totalSubmissions
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(e['title']?.toString() ?? 'تفاصيل الامتحان', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(isPublished ? LucideIcons.eyeOff : LucideIcons.eye),
            tooltip: isPublished ? 'إلغاء النشر' : 'نشر الامتحان',
            onPressed: _togglePublish,
          ),
          IconButton(
            icon: const Icon(LucideIcons.edit, size: 20),
            tooltip: 'تعديل الامتحان',
            onPressed: () async {
              final res = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (ctx) => ExamFormScreen(initialExam: _exam)),
              );
              if (res == true) _loadExam();
            },
          ),
          IconButton(
            icon: const Icon(LucideIcons.trash2, size: 20, color: Colors.red),
            tooltip: 'حذف الامتحان',
            onPressed: _deleteExam,
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).cardColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e['title']?.toString() ?? '',
                            style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          if ((e['description']?.toString() ?? '').isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                e['description'].toString(),
                                style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey[600]),
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isPublished ? Colors.green.withOpacity(0.15) : Colors.orange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isPublished ? Colors.green : Colors.orange),
                      ),
                      child: Text(
                        isPublished ? 'منشور ونشط' : 'مسودة غير منشورة',
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isPublished ? Colors.green[700] : Colors.orange[800],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _buildMetaChip(LucideIcons.users, 'المجموعة: $groupName'),
                    _buildMetaChip(LucideIcons.bookOpen, 'المادة: $subjectName'),
                    _buildMetaChip(LucideIcons.userCheck, 'المعلم: $teacherName'),
                    _buildMetaChip(LucideIcons.clock, 'المدة: $duration دقيقة'),
                    _buildMetaChip(LucideIcons.award, 'الدرجة: $totalMarks (نجاح: $passingMarks)'),
                  ],
                ),
                if (availableFrom != null || availableUntil != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(LucideIcons.calendar, size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        'نافذة الإتاحة: ${availableFrom != null ? dateFormat.format(availableFrom) : 'الآن'} إلى ${availableUntil != null ? dateFormat.format(availableUntil) : 'مفتوح دائماً'}',
                        style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Tabs
          TabBar(
            controller: _tabController,
            labelColor: branding.primaryColor,
            indicatorColor: branding.primaryColor,
            labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.helpCircle, size: 16),
                    const SizedBox(width: 8),
                    Text('الأسئلة والإجابات (${questions.length})'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.users, size: 16),
                    const SizedBox(width: 8),
                    Text('تسليمات الطلاب ($totalSubmissions)'),
                  ],
                ),
              ),
            ],
          ),

          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Questions List
                _buildQuestionsTab(questions, branding.primaryColor),

                // Tab 2: Submissions & Results
                _buildSubmissionsTab(submissions, passingMarks, totalMarks, totalSubmissions, passedSubmissions, avgScore, branding.primaryColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).dividerColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.grey[700]),
          const SizedBox(width: 4),
          Text(text, style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey[800])),
        ],
      ),
    );
  }

  Widget _buildQuestionsTab(List questions, Color primaryColor) {
    if (questions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.helpCircle, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text('لا توجد أسئلة مسجلة في هذا الامتحان', style: GoogleFonts.cairo(color: Colors.grey[600])),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: questions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (ctx, idx) {
        final q = questions[idx];
        final options = (q['options'] is List) ? (q['options'] as List) : [];
        final correctAnswer = q['correctAnswer']?.toString() ?? '';

        return Card(
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
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: primaryColor.withOpacity(0.12),
                          child: Text('${idx + 1}', style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold, color: primaryColor)),
                        ),
                        const SizedBox(width: 8),
                        Text('سؤال (${q['points'] ?? 1} درجات)', style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        q['type']?.toString() ?? 'MCQ',
                        style: GoogleFonts.cairo(fontSize: 10, color: Colors.blue[800], fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  q['text']?.toString() ?? '',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 10),

                // Options
                ...options.asMap().entries.map((entry) {
                  final optObj = entry.value;
                  final optText = (optObj is Map) ? (optObj['text']?.toString() ?? '') : optObj.toString();
                  final optId = (optObj is Map) ? (optObj['id']?.toString() ?? '') : '';
                  final isCorrect = (optText == correctAnswer) ||
                      (optId.isNotEmpty && optId == correctAnswer) ||
                      (q['correctOption'] != null && (optText == q['correctOption'] || optId == q['correctOption']));

                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: isCorrect ? Colors.green.withOpacity(0.1) : Theme.of(context).dividerColor.withOpacity(0.04),
                      border: Border.all(color: isCorrect ? Colors.green : Colors.transparent),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isCorrect ? LucideIcons.checkCircle : LucideIcons.circle,
                          size: 16,
                          color: isCorrect ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            optText,
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              fontWeight: isCorrect ? FontWeight.bold : FontWeight.normal,
                              color: isCorrect ? Colors.green[800] : null,
                            ),
                          ),
                        ),
                        if (isCorrect)
                          Text('(الإجابة الصحيحة)', style: GoogleFonts.cairo(fontSize: 11, color: Colors.green[700])),
                      ],
                    ),
                  );
                }),

                if ((q['explanation']?.toString() ?? '').isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: Colors.amber.withOpacity(0.08),
                      border: Border.all(color: Colors.amber.withOpacity(0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(LucideIcons.lightbulb, size: 14, color: Colors.amber),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'التفسير: ${q['explanation']}',
                            style: GoogleFonts.cairo(fontSize: 11, color: Colors.amber[900]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubmissionsTab(
    List submissions,
    dynamic passingMarks,
    dynamic totalMarks,
    int totalSubmissions,
    int passedSubmissions,
    double avgScore,
    Color primaryColor,
  ) {
    if (submissions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.users, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text('لم يقم أي طالب بأداء هذا الامتحان بعد', style: GoogleFonts.cairo(color: Colors.grey[600])),
          ],
        ),
      );
    }

    final double passRate = totalSubmissions > 0 ? (passedSubmissions / totalSubmissions) * 100 : 0.0;
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Analytics Row
        Row(
          children: [
            Expanded(
              child: _buildMetricCard('إجمالي التسليمات', totalSubmissions.toString(), LucideIcons.send, Colors.blue),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricCard('نسبة النجاح', '${passRate.toStringAsFixed(1)}%', LucideIcons.award, Colors.green),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricCard('متوسط الدرجات', avgScore.toStringAsFixed(1), LucideIcons.trendingUp, primaryColor),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Text('قائمة درجات الطلاب', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),

        ...submissions.map((sub) {
          final student = sub['student'] as Map<String, dynamic>?;
          final studentName = student?['user']?['name']?.toString() ?? 'طالب مجهول';
          final studentCode = student?['code']?.toString() ?? '';
          final score = (sub['score'] is num) ? (sub['score'] as num).toDouble() : 0.0;
          final isPassed = score >= (passingMarks is num ? (passingMarks as num).toDouble() : 50.0);
          final submittedAt = sub['submittedAt'] != null ? DateTime.tryParse(sub['submittedAt'].toString()) : null;

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isPassed ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
                child: Icon(
                  isPassed ? LucideIcons.check : LucideIcons.x,
                  color: isPassed ? Colors.green : Colors.red,
                  size: 18,
                ),
              ),
              title: Text(studentName, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text(
                'كود: $studentCode  |  ${submittedAt != null ? dateFormat.format(submittedAt) : ''}',
                style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey[600]),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${score.toStringAsFixed(0)} / $totalMarks',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14, color: isPassed ? Colors.green[700] : Colors.red[700]),
                  ),
                  Text(
                    isPassed ? 'ناجح' : 'راسب',
                    style: GoogleFonts.cairo(fontSize: 10, color: isPassed ? Colors.green : Colors.red),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
          Text(title, style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey[700]), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
