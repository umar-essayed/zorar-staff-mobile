import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/network/edu_api_service.dart';
import '../../core/providers/edu_data_providers.dart';
import '../../core/services/sound_service.dart';
import '../../core/services/upload_service.dart';
import '../../core/theme/branding_provider.dart';
import '../../core/utils/numeric_utils.dart';

class OnlineLessonsManagementScreen extends ConsumerStatefulWidget {
  final String? initialCourseId;
  const OnlineLessonsManagementScreen({super.key, this.initialCourseId});

  @override
  ConsumerState<OnlineLessonsManagementScreen> createState() =>
      _OnlineLessonsManagementScreenState();
}

class _OnlineLessonsManagementScreenState
    extends ConsumerState<OnlineLessonsManagementScreen> {
  String? _selectedYearId;
  String? _selectedSubjectId;
  String? _selectedCourseId;

  bool _isLoadingCourse = false;
  Map<String, dynamic>? _courseDetails;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedCourseId = widget.initialCourseId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_selectedCourseId != null) {
        _loadCourseDetails(_selectedCourseId!);
      }
    });
  }

  Future<void> _loadCourseDetails(String courseId) async {
    setState(() {
      _isLoadingCourse = true;
      _errorMessage = null;
    });
    try {
      final details = await EduApiService().getCourseDetails(courseId);
      if (mounted) {
        setState(() {
          _courseDetails = details;
          _isLoadingCourse = false;
          if (details != null) {
            _selectedYearId = details["academicYearId"]?.toString();
            _selectedSubjectId = details["subjectId"]?.toString();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "تعذر تحميل بيانات الكورس: $e";
          _isLoadingCourse = false;
        });
      }
    }
  }

  String _extractYouTubeId(String input) {
    final trimmed = input.trim();
    if (trimmed.contains("v=")) {
      final parts = trimmed.split("v=");
      final afterV = parts[1].split("&")[0];
      return afterV;
    }
    if (trimmed.contains("youtu.be/")) {
      final parts = trimmed.split("youtu.be/");
      return parts[1].split("?")[0];
    }
    return trimmed;
  }

  Future<void> _showAddChapterDialog() async {
    if (_selectedCourseId == null) return;
    final branding = ref.read(brandingProvider);
    final titleCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
        title: Row(
          children: [
            Icon(LucideIcons.folderPlus, color: branding.primaryColor, size: 22),
            const SizedBox(width: 8),
            Text("إضافة فصل / أسبوع جديد",
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: SizedBox(
            width: double.maxFinite,
            child: TextField(
              controller: titleCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: "عنوان الفصل أو الأسبوع (مثال: الأسبوع الأول - المقدمة)",
                prefixIcon: Icon(LucideIcons.bookmark, size: 18),
                isDense: true,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("إلغاء")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: branding.primaryColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final title = titleCtrl.text.trim();
              if (title.isEmpty) return;
              Navigator.pop(ctx);
              try {
                final chapters = (_courseDetails?["chapters"] as List?) ?? [];
                await EduApiService().addChapter(_selectedCourseId!, {
                  "title": title,
                  "orderIndex": chapters.length + 1,
                });
                SoundService.successFeedback();
                _loadCourseDetails(_selectedCourseId!);
              } catch (e) {
                SoundService.errorFeedback();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("فشل إضافة الفصل: $e", style: GoogleFonts.cairo()), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text("إضافة"),
          ),
        ],
      ),
    );
  }

  Future<void> _showLessonDialog({required String chapterId, Map<String, dynamic>? existingLesson}) async {
    final branding = ref.read(brandingProvider);
    final isEditing = existingLesson != null;

    final titleCtrl = TextEditingController(text: existingLesson?["title"]?.toString() ?? "");
    final videoCtrl = TextEditingController();
    final durationCtrl = TextEditingController(
      text: isEditing
          ? ((parseInt(existingLesson["durationSeconds"], 0)) ~/ 60).toString()
          : "45",
    );
    bool isFreePreview = existingLesson?["isFreePreview"] == true;
    String? pdfUrl = existingLesson?["pdfAttachmentUrl"]?.toString();
    String? pdfFileName = pdfUrl != null && pdfUrl.isNotEmpty ? pdfUrl.split("/").last : null;
    bool isUploadingPdf = false;
    bool isSaving = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (c, setDialogState) => AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
          title: Row(
            children: [
              Icon(isEditing ? LucideIcons.edit : LucideIcons.video, color: branding.primaryColor, size: 22),
              const SizedBox(width: 8),
              Text(
                isEditing ? "تعديل بيانات الحصة" : "إضافة حصة أونلاين جديدة",
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 750),
            child: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: "عنوان الحصة أو المحاضرة *",
                    hintText: "مثال: شرح أجهزة القياس وتدريبات عملية",
                    prefixIcon: Icon(LucideIcons.fileVideo, size: 18),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: videoCtrl,
                  decoration: InputDecoration(
                    labelText: isEditing ? "كود أو رابط يوتيوب (اتركه فارغاً للاحتفاظ بالحالي)" : "كود أو رابط فيديو يوتيوب *",
                    hintText: "dQw4w9WgXcQ أو رابط كامل",
                    prefixIcon: const Icon(LucideIcons.video, size: 18),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: durationCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "مدة الحصة التقديرية (بالدقائق)",
                    suffixText: "دقيقة",
                    prefixIcon: Icon(LucideIcons.clock, size: 18),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 14),

                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: isFreePreview,
                  activeColor: branding.primaryColor,
                  title: Text("معاينة مجانية (Free Preview)", style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: Text("يمكن للطلبة غير المشتركين مشاهدة هذه الحصة كعينة", style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey)),
                  onChanged: (val) => setDialogState(() => isFreePreview = val),
                ),
                const Divider(),

                Text("ملزمة أو ملخص الحصة (PDF):", style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                if (pdfUrl != null && pdfUrl!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.fileText, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            pdfFileName ?? "ملزمة الحصة.pdf",
                            style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.trash2, color: Colors.red, size: 18),
                          onPressed: () => setDialogState(() {
                            pdfUrl = null;
                            pdfFileName = null;
                          }),
                        ),
                      ],
                    ),
                  )
                else
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: branding.primaryColor,
                      side: BorderSide(color: branding.primaryColor.withOpacity(0.5)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    icon: isUploadingPdf
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(LucideIcons.uploadCloud, size: 18),
                    label: Text(isUploadingPdf ? "جاري رفع الملف..." : "رفع ملزمة الحصة (PDF)", style: GoogleFonts.cairo(fontSize: 12.5)),
                    onPressed: isUploadingPdf
                        ? null
                        : () async {
                            setDialogState(() => isUploadingPdf = true);
                            try {
                              final uploaded = await UploadService.pickAndUploadDocument(
                                allowedExtensions: ["pdf"],
                                folder: "lessons",
                              );
                              if (uploaded != null) {
                                setDialogState(() {
                                  pdfUrl = uploaded.url;
                                  pdfFileName = uploaded.name;
                                });
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("فشل رفع الملف: $e", style: GoogleFonts.cairo()), backgroundColor: Colors.red),
                                );
                              }
                            } finally {
                              setDialogState(() => isUploadingPdf = false);
                            }
                          },
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(c),
              child: const Text("إلغاء"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: branding.primaryColor,
                foregroundColor: Colors.white,
              ),
              onPressed: isSaving
                  ? null
                  : () async {
                      final title = titleCtrl.text.trim();
                      if (title.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("يرجى كتابة عنوان الحصة"), backgroundColor: Colors.red),
                        );
                        return;
                      }

                      final rawVideo = _extractYouTubeId(videoCtrl.text.trim());
                      if (!isEditing && rawVideo.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("يرجى إدخال كود فيديو يوتيوب"), backgroundColor: Colors.red),
                        );
                        return;
                      }

                      setDialogState(() => isSaving = true);
                      try {
                        final durationMinutes = parseInt(durationCtrl.text, 45);
                        final durationSeconds = durationMinutes * 60;

                        if (isEditing) {
                          final payload = <String, dynamic>{
                            "title": title,
                            "durationSeconds": durationSeconds,
                            "isFreePreview": isFreePreview,
                            "pdfAttachmentUrl": pdfUrl,
                          };
                          if (rawVideo.isNotEmpty) {
                            payload["rawYouTubeId"] = rawVideo;
                          }
                          await EduApiService().updateLesson(existingLesson["id"].toString(), payload);
                        } else {
                          await EduApiService().addLesson(chapterId, {
                            "title": title,
                            "rawYouTubeId": rawVideo,
                            "durationSeconds": durationSeconds,
                            "isFreePreview": isFreePreview,
                            "pdfAttachmentUrl": pdfUrl,
                            "orderIndex": 99,
                          });
                        }

                        SoundService.successFeedback();
                        if (mounted) {
                          Navigator.pop(c);
                          _loadCourseDetails(_selectedCourseId!);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isEditing ? "تم تحديث بيانات الحصة بنجاح ✅" : "تمت إضافة الحصة بنجاح ✅", style: GoogleFonts.cairo()),
                              backgroundColor: const Color(0xFF10B981),
                            ),
                          );
                        }
                      } catch (e) {
                        SoundService.errorFeedback();
                        setDialogState(() => isSaving = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("حدث خطأ: $e", style: GoogleFonts.cairo()), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
              child: Text(isEditing ? "حفظ التعديلات" : "إضافة الحصة"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showQuizManagementDialog({required Map<String, dynamic> lesson}) async {
    final branding = ref.read(brandingProvider);
    final lessonTitle = lesson["title"]?.toString() ?? "الحصة";

    final exams = (_courseDetails?["exams"] as List?) ?? [];
    Map<String, dynamic>? matchingExam;
    for (final ex in exams) {
      if (ex["title"]?.toString().contains(lessonTitle) == true) {
        matchingExam = ex;
        break;
      }
    }

    final examTitleCtrl = TextEditingController(
      text: matchingExam != null ? matchingExam["title"] : "كويز: $lessonTitle",
    );
    final durationCtrl = TextEditingController(
      text: matchingExam != null ? matchingExam["durationMinutes"]?.toString() ?? "15" : "15",
    );
    final passScoreCtrl = TextEditingController(
      text: matchingExam != null ? matchingExam["passingScore"]?.toString() ?? "5" : "5",
    );

    List<Map<String, dynamic>> questions = [];
    if (matchingExam != null && matchingExam["questions"] is List) {
      questions = List<Map<String, dynamic>>.from(matchingExam["questions"].map((q) {
        final opts = (q["options"] as List?) ?? [];
        return {
          "id": q["id"]?.toString(),
          "text": q["text"]?.toString() ?? "",
          "points": parseInt(q["points"], 1),
          "optA": opts.length > 0 ? opts[0]["text"]?.toString() ?? "" : "",
          "optB": opts.length > 1 ? opts[1]["text"]?.toString() ?? "" : "",
          "optC": opts.length > 2 ? opts[2]["text"]?.toString() ?? "" : "",
          "optD": opts.length > 3 ? opts[3]["text"]?.toString() ?? "" : "",
          "correctOption": q["correctOption"]?.toString() ?? "A",
          "explanation": q["explanation"]?.toString() ?? "",
        };
      }));
    }

    if (questions.isEmpty) {
      questions.add({
        "text": "",
        "points": 1,
        "optA": "",
        "optB": "",
        "optC": "",
        "optD": "",
        "correctOption": "A",
        "explanation": "",
      });
    }

    bool isSaving = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (c, setQuizState) => AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
          title: Row(
            children: [
              Icon(LucideIcons.checkSquare, color: branding.primaryColor, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text("إدارة كويز الحصة ($lessonTitle)",
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 750),
            child: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: examTitleCtrl,
                    decoration: const InputDecoration(
                      labelText: "عنوان الكويز أو الاختبار *",
                      prefixIcon: Icon(LucideIcons.fileQuestion, size: 18),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: durationCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: "المدة (بالدقائق)",
                            suffixText: "دقيقة",
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: passScoreCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: "درجة النجاح",
                            suffixText: "درجة",
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "أسئلة الكويز (${questions.length}):",
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13.5),
                      ),
                      TextButton.icon(
                        icon: const Icon(LucideIcons.plus, size: 16),
                        label: const Text("إضافة سؤال"),
                        onPressed: () => setQuizState(() {
                          questions.add({
                            "text": "",
                            "points": 1,
                            "optA": "",
                            "optB": "",
                            "optC": "",
                            "optD": "",
                            "correctOption": "A",
                            "explanation": "",
                          });
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  ...questions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final q = entry.value;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("السؤال #${index + 1}",
                                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: branding.primaryColor)),
                                if (questions.length > 1)
                                  IconButton(
                                    icon: const Icon(LucideIcons.trash2, color: Colors.red, size: 18),
                                    onPressed: () => setQuizState(() => questions.removeAt(index)),
                                  ),
                              ],
                            ),
                            TextFormField(
                              initialValue: q["text"],
                              decoration: const InputDecoration(
                                labelText: "نص السؤال *",
                                hintText: "اكتب نص السؤال هنا...",
                                isDense: true,
                              ),
                              onChanged: (val) => q["text"] = val,
                            ),
                            const SizedBox(height: 10),
                            Text("الخيارات والإجابة الصحيحة:", style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),

                            Row(
                              children: [
                                Radio<String>(
                                  value: "A",
                                  groupValue: q["correctOption"],
                                  activeColor: Colors.green,
                                  onChanged: (val) => setQuizState(() => q["correctOption"] = val!),
                                ),
                                Expanded(
                                  child: TextFormField(
                                    initialValue: q["optA"],
                                    decoration: const InputDecoration(labelText: "الخيار (A)", isDense: true),
                                    onChanged: (val) => q["optA"] = val,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),

                            Row(
                              children: [
                                Radio<String>(
                                  value: "B",
                                  groupValue: q["correctOption"],
                                  activeColor: Colors.green,
                                  onChanged: (val) => setQuizState(() => q["correctOption"] = val!),
                                ),
                                Expanded(
                                  child: TextFormField(
                                    initialValue: q["optB"],
                                    decoration: const InputDecoration(labelText: "الخيار (B)", isDense: true),
                                    onChanged: (val) => q["optB"] = val,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),

                            Row(
                              children: [
                                Radio<String>(
                                  value: "C",
                                  groupValue: q["correctOption"],
                                  activeColor: Colors.green,
                                  onChanged: (val) => setQuizState(() => q["correctOption"] = val!),
                                ),
                                Expanded(
                                  child: TextFormField(
                                    initialValue: q["optC"],
                                    decoration: const InputDecoration(labelText: "الخيار (C)", isDense: true),
                                    onChanged: (val) => q["optC"] = val,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),

                            Row(
                              children: [
                                Radio<String>(
                                  value: "D",
                                  groupValue: q["correctOption"],
                                  activeColor: Colors.green,
                                  onChanged: (val) => setQuizState(() => q["correctOption"] = val!),
                                ),
                                Expanded(
                                  child: TextFormField(
                                    initialValue: q["optD"],
                                    decoration: const InputDecoration(labelText: "الخيار (D)", isDense: true),
                                    onChanged: (val) => q["optD"] = val,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ),
        actions: [
            if (matchingExam != null)
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (d) => AlertDialog(
                      title: const Text("حذف الكويز"),
                      content: const Text("هل أنت متأكد من رغبتك في حذف هذا الكويز نهائياً؟"),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(d, false), child: const Text("إلغاء")),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                          onPressed: () => Navigator.pop(d, true),
                          child: const Text("حذف"),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await EduApiService().deleteExam(matchingExam!["id"].toString());
                    SoundService.successFeedback();
                    if (mounted) {
                      Navigator.pop(c);
                      _loadCourseDetails(_selectedCourseId!);
                    }
                  }
                },
                child: const Text("حذف الكويز"),
              ),
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(c),
              child: const Text("إغلاق"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: branding.primaryColor,
                foregroundColor: Colors.white,
              ),
              onPressed: isSaving
                  ? null
                  : () async {
                      final title = examTitleCtrl.text.trim();
                      if (title.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("يرجى كتابة عنوان الكويز"), backgroundColor: Colors.red),
                        );
                        return;
                      }

                      final validQuestions = questions.where((q) => q["text"].toString().trim().isNotEmpty).toList();
                      if (validQuestions.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("يرجى إضافة سؤال واحد على الأقل"), backgroundColor: Colors.red),
                        );
                        return;
                      }

                      setQuizState(() => isSaving = true);
                      try {
                        final formattedQuestions = validQuestions.map((q) => {
                          "text": q["text"],
                          "points": q["points"] ?? 1,
                          "options": [
                            {"id": "A", "text": q["optA"] ?? ""},
                            {"id": "B", "text": q["optB"] ?? ""},
                            {"id": "C", "text": q["optC"] ?? ""},
                            {"id": "D", "text": q["optD"] ?? ""},
                          ],
                          "correctOption": q["correctOption"] ?? "A",
                          "explanation": q["explanation"] ?? "",
                        }).toList();

                        final examPayload = {
                          "title": title,
                          "courseId": _selectedCourseId,
                          "durationMinutes": parseInt(durationCtrl.text, 15),
                          "passingScore": parseInt(passScoreCtrl.text, 5),
                          "questions": formattedQuestions,
                          "shuffleQuestions": true,
                        };

                        if (matchingExam != null) {
                          await EduApiService().updateExam(matchingExam["id"].toString(), examPayload);
                        } else {
                          await EduApiService().createExam(examPayload);
                        }

                        SoundService.successFeedback();
                        if (mounted) {
                          Navigator.pop(c);
                          _loadCourseDetails(_selectedCourseId!);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("تم حفظ وتفعيل كويز الحصة بنجاح ✅"),
                              backgroundColor: Color(0xFF10B981),
                            ),
                          );
                        }
                      } catch (e) {
                        SoundService.errorFeedback();
                        setQuizState(() => isSaving = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("فشل حفظ الكويز: $e", style: GoogleFonts.cairo()), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
              child: const Text("حفظ ونشر الكويز"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _moveLesson(String chapterId, List<dynamic> lessons, int currentIndex, int targetIndex) async {
    if (targetIndex < 0 || targetIndex >= lessons.length) return;
    SoundService.lightImpact();

    final reordered = List<dynamic>.from(lessons);
    final moved = reordered.removeAt(currentIndex);
    reordered.insert(targetIndex, moved);

    final lessonIds = reordered.map((l) => l["id"].toString()).toList();

    try {
      await EduApiService().reorderLessons(chapterId, lessonIds);
      _loadCourseDetails(_selectedCourseId!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("تعذر إعادة الترتيب: $e", style: GoogleFonts.cairo()), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(brandingProvider);
    final yearsAsync = ref.watch(liveAcademicYearsProvider);
    final subjectsAsync = ref.watch(liveSubjectsProvider);
    final coursesAsync = ref.watch(liveCoursesProvider);

    final years = yearsAsync.value ?? [];
    final subjects = subjectsAsync.value ?? [];
    final allCourses = coursesAsync.value ?? [];

    final availableCourses = allCourses.where((c) {
      if (_selectedYearId != null && c["academicYearId"]?.toString() != _selectedYearId) {
        return false;
      }
      if (_selectedSubjectId != null && c["subjectId"]?.toString() != _selectedSubjectId) {
        return false;
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "إدارة الحصص والكويزات الأونلاين",
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw),
            tooltip: "تحديث",
            onPressed: () {
              ref.invalidate(liveCoursesProvider);
              if (_selectedCourseId != null) _loadCourseDetails(_selectedCourseId!);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedYearId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: "1. الصف الدراسي",
                          prefixIcon: Icon(LucideIcons.graduationCap, size: 16),
                          isDense: true,
                        ),
                        items: [
                          const DropdownMenuItem<String>(value: null, child: Text("جميع الصفوف")),
                          ...years.map((y) => DropdownMenuItem<String>(
                                value: y["id"]?.toString(),
                                child: Text(y["name"]?.toString() ?? "", style: GoogleFonts.cairo(fontSize: 12.5)),
                              )),
                        ],
                        onChanged: (val) => setState(() {
                          _selectedYearId = val;
                          _selectedCourseId = null;
                          _courseDetails = null;
                        }),
                      ),
                    ),
                    const SizedBox(width: 8),

                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedSubjectId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: "2. المادة",
                          prefixIcon: Icon(LucideIcons.bookOpen, size: 16),
                          isDense: true,
                        ),
                        items: [
                          const DropdownMenuItem<String>(value: null, child: Text("جميع المواد")),
                          ...subjects.map((s) => DropdownMenuItem<String>(
                                value: s["id"]?.toString(),
                                child: Text(s["name"]?.toString() ?? "", style: GoogleFonts.cairo(fontSize: 12.5)),
                              )),
                        ],
                        onChanged: (val) => setState(() {
                          _selectedSubjectId = val;
                          _selectedCourseId = null;
                          _courseDetails = null;
                        }),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                DropdownButtonFormField<String>(
                  value: _selectedCourseId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: "3. اختر الكورس أو الشهر لإدارة حصصه *",
                    prefixIcon: Icon(LucideIcons.video, size: 18),
                    isDense: true,
                  ),
                  items: availableCourses.map((c) {
                    final id = c["id"]?.toString() ?? "";
                    final title = c["title"]?.toString() ?? "";
                    final teacher = c["teacher"]?["name"]?.toString();
                    return DropdownMenuItem<String>(
                      value: id,
                      child: Text(
                        "$title ${teacher != null ? "($teacher)" : ""}",
                        style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedCourseId = val);
                      _loadCourseDetails(val);
                    }
                  },
                ),
              ],
            ),
          ),

          Expanded(
            child: _selectedCourseId == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.mousePointerClick, size: 48, color: Colors.grey.withOpacity(0.4)),
                        const SizedBox(height: 12),
                        Text(
                          "يرجى اختيار الكورس من القائمة أعلاه لعرض وإدارة حصصه",
                          style: GoogleFonts.cairo(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : _isLoadingCourse
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(LucideIcons.alertTriangle, color: Colors.red, size: 44),
                                const SizedBox(height: 8),
                                Text(_errorMessage!, style: GoogleFonts.cairo(color: Colors.red)),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: () => _loadCourseDetails(_selectedCourseId!),
                                  child: const Text("إعادة المحاولة"),
                                ),
                              ],
                            ),
                          )
                        : _buildCourseManagementView(branding),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseManagementView(dynamic branding) {
    final chapters = (_courseDetails?["chapters"] as List?) ?? [];
    final courseTitle = _courseDetails?["title"]?.toString() ?? "";
    final teacherName = _courseDetails?["teacher"]?["name"]?.toString() ?? "";
    final exams = (_courseDetails?["exams"] as List?) ?? [];

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: branding.primaryColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: branding.primaryColor.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: branding.primaryColor,
                child: const Icon(LucideIcons.bookOpen, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      courseTitle,
                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(
                      "المحاضر: ${teacherName.isNotEmpty ? teacherName : "غير محدد"} • عدد الفصول: ${chapters.length} • الكويزات المنشورة: ${exams.length}",
                      style: GoogleFonts.cairo(fontSize: 11.5, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: branding.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                icon: const Icon(LucideIcons.folderPlus, size: 16),
                label: const Text("فصل جديد"),
                onPressed: _showAddChapterDialog,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (chapters.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            alignment: Alignment.center,
            child: Column(
              children: [
                Icon(LucideIcons.layers, size: 48, color: Colors.grey.withOpacity(0.4)),
                const SizedBox(height: 12),
                Text("لا توجد فصول أو أسابيع دراسية في هذا الكورس بعد", style: GoogleFonts.cairo(color: Colors.grey)),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: const Icon(LucideIcons.plus, size: 18),
                  label: const Text("إضافة الفصل الأول"),
                  onPressed: _showAddChapterDialog,
                ),
              ],
            ),
          )
        else
          ...chapters.map((ch) {
            final chapterId = ch["id"].toString();
            final chapterTitle = ch["title"]?.toString() ?? "فصل";
            final lessons = (ch["lessons"] as List?) ?? [];

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ExpansionTile(
                initiallyExpanded: true,
                leading: CircleAvatar(
                  backgroundColor: branding.primaryColor.withOpacity(0.12),
                  child: Icon(LucideIcons.folder, color: branding.primaryColor, size: 18),
                ),
                title: Text(
                  chapterTitle,
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14.5),
                ),
                subtitle: Text(
                  "يحتوي على ${lessons.length} حصة",
                  style: GoogleFonts.cairo(fontSize: 11.5, color: Colors.grey),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(LucideIcons.plusCircle, color: Color(0xFF10B981), size: 20),
                      tooltip: "إضافة حصة لهذا الفصل",
                      onPressed: () => _showLessonDialog(chapterId: chapterId),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.trash2, color: Colors.red, size: 18),
                      tooltip: "حذف الفصل",
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (d) => AlertDialog(
                            title: const Text("حذف الفصل"),
                            content: Text("هل تريد حذف فصل ($chapterTitle) بجميع حصصه؟"),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(d, false), child: const Text("إلغاء")),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                onPressed: () => Navigator.pop(d, true),
                                child: const Text("حذف"),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await EduApiService().deleteChapter(chapterId);
                          SoundService.successFeedback();
                          _loadCourseDetails(_selectedCourseId!);
                        }
                      },
                    ),
                  ],
                ),
                children: [
                  if (lessons.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text("لا توجد حصص في هذا الفصل بعد. اضغط (+) بالأعلى لإضافة حصة.",
                          style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey)),
                    )
                  else
                    ...lessons.asMap().entries.map((lEntry) {
                      final lIndex = lEntry.key;
                      final lesson = lEntry.value;
                      final lessonTitle = lesson["title"]?.toString() ?? "حصة";
                      final durationMin = (parseInt(lesson["durationSeconds"], 0)) ~/ 60;
                      final isFree = lesson["isFreePreview"] == true;
                      final hasPdf = lesson["pdfAttachmentUrl"] != null &&
                          lesson["pdfAttachmentUrl"].toString().isNotEmpty;

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.withOpacity(0.15)),
                        ),
                        child: Row(
                          children: [
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  onTap: lIndex > 0
                                      ? () => _moveLesson(chapterId, lessons, lIndex, lIndex - 1)
                                      : null,
                                  child: Icon(LucideIcons.chevronUp,
                                      size: 18, color: lIndex > 0 ? Colors.grey[800] : Colors.grey[300]),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: branding.primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text("#${lIndex + 1}",
                                      style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                                InkWell(
                                  onTap: lIndex < lessons.length - 1
                                      ? () => _moveLesson(chapterId, lessons, lIndex, lIndex + 1)
                                      : null,
                                  child: Icon(LucideIcons.chevronDown,
                                      size: 18, color: lIndex < lessons.length - 1 ? Colors.grey[800] : Colors.grey[300]),
                                ),
                              ],
                            ),
                            const SizedBox(width: 10),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          lessonTitle,
                                          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13.5),
                                        ),
                                      ),
                                      if (isFree)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF10B981).withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text("عينة مجانية",
                                              style: GoogleFonts.cairo(
                                                  color: const Color(0xFF10B981),
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 8,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      Text(
                                        "⏱ $durationMin دقيقة",
                                        style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey[600]),
                                      ),
                                      if (hasPdf)
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(LucideIcons.fileText, size: 12, color: Colors.red),
                                            const SizedBox(width: 2),
                                            Text("ملزمة PDF",
                                                style: GoogleFonts.cairo(
                                                    fontSize: 11,
                                                    color: Colors.red,
                                                    fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(LucideIcons.checkSquare, color: Colors.amber, size: 20),
                                  tooltip: "إدارة كويز الحصة",
                                  onPressed: () => _showQuizManagementDialog(lesson: lesson),
                                ),
                                IconButton(
                                  icon: const Icon(LucideIcons.edit2, size: 18),
                                  tooltip: "تعديل بيانات الحصة",
                                  onPressed: () => _showLessonDialog(
                                    chapterId: chapterId,
                                    existingLesson: lesson,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(LucideIcons.trash2, color: Colors.red, size: 18),
                                  tooltip: "حذف الحصة",
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (d) => AlertDialog(
                                        title: const Text("حذف الحصة"),
                                        content: Text("هل تريد حذف حصة ($lessonTitle)؟"),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text("إلغاء")),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                            onPressed: () => Navigator.pop(d, true),
                                            child: const Text("حذف"),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await EduApiService().deleteLesson(lesson["id"].toString());
                                      SoundService.successFeedback();
                                      _loadCourseDetails(_selectedCourseId!);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  const SizedBox(height: 8),
                ],
              ),
            );
          }).toList(),
      ],
    );
  }
}
