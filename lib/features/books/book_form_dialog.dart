import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/services/sound_service.dart';
import '../../core/theme/branding_provider.dart';

class BookFormDialog extends ConsumerStatefulWidget {
  const BookFormDialog({super.key});

  @override
  ConsumerState<BookFormDialog> createState() => _BookFormDialogState();
}

class _BookFormDialogState extends ConsumerState<BookFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final titleCtrl = TextEditingController();
  final priceCtrl = TextEditingController(text: '85');
  final stockCtrl = TextEditingController(text: '100');
  String selectedTeacher = 'أ/ أحمد كمال (لغة عربية)';
  String selectedGrade = 'الصف الثالث الثانوي';

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
                value: selectedTeacher,
                isExpanded: true,
                decoration: const InputDecoration(isDense: true),
                items: const [
                  DropdownMenuItem(value: 'أ/ أحمد كمال (لغة عربية)', child: Text('أ/ أحمد كمال (لغة عربية)')),
                  DropdownMenuItem(value: 'أ/ حسام فؤاد (كيمياء)', child: Text('أ/ حسام فؤاد (كيمياء)')),
                  DropdownMenuItem(value: 'أ/ محمد إبراهيم (فيزياء)', child: Text('أ/ محمد إبراهيم (فيزياء)')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => selectedTeacher = val);
                },
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
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('الكمية الأولية:', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: stockCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(isDense: true),
                        ),
                      ],
                    ),
                  ),
                ],
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
          icon: const Icon(LucideIcons.check, size: 16),
          label: const Text('حفظ وإضافة للمخزن'),
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              SoundService.successFeedback();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFF10B981),
                  content: Text('تم إضافة الملزمة ${titleCtrl.text} إلى المخزن بنجاح!'),
                ),
              );
            }
          },
        ),
      ],
    );
  }
}
