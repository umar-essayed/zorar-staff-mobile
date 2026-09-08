import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/network/edu_api_service.dart';
import '../../core/providers/edu_data_providers.dart';
import '../../core/services/sound_service.dart';
import '../../core/theme/branding_provider.dart';

import '../../core/services/upload_service.dart';

class BookFormDialog extends ConsumerStatefulWidget {
  const BookFormDialog({super.key});

  @override
  ConsumerState<BookFormDialog> createState() => _BookFormDialogState();
}

class _BookFormDialogState extends ConsumerState<BookFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final titleCtrl = TextEditingController();
  final priceCtrl = TextEditingController(text: '85');
  final stockCtrl = TextEditingController(text: '50');
  String? selectedTeacherId;
  String? selectedYearId;
  String? pdfUrl;
  String? pdfFileName;
  bool _isUploadingPdf = false;
  bool _isSaving = false;

  @override
  void dispose() {
    titleCtrl.dispose();
    priceCtrl.dispose();
    stockCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(brandingProvider);
    final teachersAsync = ref.watch(liveTeachersProvider);
    final yearsAsync = ref.watch(liveAcademicYearsProvider);

    final teachers = teachersAsync.value ?? [];
    final years = yearsAsync.value ?? [];

    if (selectedTeacherId == null && teachers.isNotEmpty) {
      selectedTeacherId = teachers.first['id']?.toString();
    }
    if (selectedYearId == null && years.isNotEmpty) {
      selectedYearId = years.first['id']?.toString();
    }

    return AlertDialog(
      title: Row(
        children: [
          Icon(LucideIcons.bookPlus, color: branding.primaryColor, size: 24),
          const SizedBox(width: 10),
          Text(
            'إضافة ملزمة / مذكرة جديدة',
            style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('عنوان الملزمة أو الكتاب:', style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextFormField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  hintText: 'مثال: ملزمة النحو الشاملة 2026',
                  prefixIcon: Icon(LucideIcons.bookOpen, size: 20),
                  isDense: true,
                ),
                validator: (val) => val == null || val.isEmpty ? 'يرجى إدخال عنوان الملزمة' : null,
              ),
              const SizedBox(height: 12),
              Text('المعلم المسؤول:', style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: selectedTeacherId,
                isExpanded: true,
                decoration: const InputDecoration(isDense: true),
                items: teachers.map((t) {
                  return DropdownMenuItem<String>(
                    value: t['id']?.toString(),
                    child: Text(t['name']?.toString() ?? 'معلم'),
                  );
                }).toList(),
                onChanged: (val) => setState(() => selectedTeacherId = val),
              ),
              const SizedBox(height: 12),
              Text('السنة الدراسية:', style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: selectedYearId,
                isExpanded: true,
                decoration: const InputDecoration(isDense: true),
                items: years.map((y) {
                  return DropdownMenuItem<String>(
                    value: y['id']?.toString(),
                    child: Text(y['name']?.toString() ?? 'سنة دراسية'),
                  );
                }).toList(),
                onChanged: (val) => setState(() => selectedYearId = val),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('سعر البيع (ج.م):', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: priceCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(isDense: true),
                          validator: (val) => val == null || val.isEmpty ? 'السعر مطلوب' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('الكمية المطبوعة:', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: stockCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(isDense: true),
                          validator: (val) => val == null || val.isEmpty ? 'الكمية مطلوبة' : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text('نسخة رقمية من الملزمة (PDF اختياري):',
                  style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              if (pdfUrl != null && pdfUrl!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                          pdfFileName ?? 'ملف الملزمة.pdf',
                          style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.trash2, color: Colors.red, size: 18),
                        onPressed: () => setState(() {
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  icon: _isUploadingPdf
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(LucideIcons.uploadCloud, size: 16),
                  label: Text(_isUploadingPdf ? 'جاري رفع الملف...' : 'رفع نسخة PDF للملزمة',
                      style: GoogleFonts.cairo(fontSize: 12)),
                  onPressed: _isUploadingPdf
                      ? null
                      : () async {
                          setState(() => _isUploadingPdf = true);
                          try {
                            final uploaded = await UploadService.pickAndUploadDocument(
                              allowedExtensions: ['pdf'],
                              folder: 'books',
                            );
                            if (uploaded != null) {
                              setState(() {
                                pdfUrl = uploaded.url;
                                pdfFileName = uploaded.name;
                              });
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('فشل رفع الملف: $e'), backgroundColor: Colors.red),
                              );
                            }
                          } finally {
                            if (mounted) setState(() => _isUploadingPdf = false);
                          }
                        },
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton.icon(
          icon: _isSaving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(LucideIcons.check, size: 16),
          label: const Text('حفظ وإضافة للمخزن'),
          onPressed: _isSaving
              ? null
              : () async {
                  if (_formKey.currentState?.validate() ?? false) {
                    setState(() => _isSaving = true);
                    try {
                      await EduApiService().createBook({
                        'title': titleCtrl.text.trim(),
                        'teacherId': selectedTeacherId,
                        'academicYearId': selectedYearId,
                        'salePrice': double.tryParse(priceCtrl.text) ?? 0.0,
                        'stockQuantity': int.tryParse(stockCtrl.text) ?? 0,
                        'pdfAttachmentUrl': pdfUrl,
                      });
                      ref.invalidate(liveBooksProvider);
                      ref.invalidate(liveLowStockBooksProvider);
                      if (context.mounted) {
                        SoundService.successFeedback();
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF10B981),
                            content: Text('تم إضافة الملزمة ${titleCtrl.text} إلى المخزن بنجاح! ✅'),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        SoundService.errorFeedback();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('تعذر حفظ الملزمة: $e'), backgroundColor: Colors.red),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _isSaving = false);
                    }
                  }
                },
        ),
      ],
    );
  }
}
