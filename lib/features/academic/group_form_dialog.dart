import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/services/sound_service.dart';
import '../../core/theme/branding_provider.dart';

class GroupFormDialog extends ConsumerStatefulWidget {
  const GroupFormDialog({super.key});

  @override
  ConsumerState<GroupFormDialog> createState() => _GroupFormDialogState();
}

class _GroupFormDialogState extends ConsumerState<GroupFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController();
  final roomCtrl = TextEditingController(text: 'قاعة 1');
  final feeCtrl = TextEditingController(text: '450');
  final capacityCtrl = TextEditingController(text: '50');
  String selectedYear = 'الصف الثالث الثانوي';
  String selectedTeacher = 'أ/ أحمد كمال';
  String selectedDays = 'السبت والثلاثاء (02:00 م - 04:00 م)';

  @override
  void dispose() {
    nameCtrl.dispose();
    roomCtrl.dispose();
    feeCtrl.dispose();
    capacityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(brandingProvider);

    return AlertDialog(
      title: Row(
        children: [
          Icon(LucideIcons.layers, color: branding.primaryColor, size: 24),
          const SizedBox(width: 10),
          Text(
            'إنشاء مجموعة دراسية جديدة',
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
              Text('اسم المجموعة:', style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  hintText: 'مثال: 3ث لغة عربية (المجموعة ب)',
                  prefixIcon: Icon(LucideIcons.bookOpen, size: 20),
                  isDense: true,
                ),
                validator: (val) => val == null || val.isEmpty ? 'يرجى إدخال اسم المجموعة' : null,
              ),
              const SizedBox(height: 12),
              Text('المرحلة الدراسية:', style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: selectedYear,
                isExpanded: true,
                decoration: const InputDecoration(isDense: true),
                items: const [
                  DropdownMenuItem(value: 'الصف الأول الثانوي', child: Text('الصف الأول الثانوي')),
                  DropdownMenuItem(value: 'الصف الثاني الثانوي', child: Text('الصف الثاني الثانوي')),
                  DropdownMenuItem(value: 'الصف الثالث الثانوي', child: Text('الصف الثالث الثانوي')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => selectedYear = val);
                },
              ),
              const SizedBox(height: 12),
              Text('المدرس المسؤول:', style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: selectedTeacher,
                isExpanded: true,
                decoration: const InputDecoration(isDense: true),
                items: const [
                  DropdownMenuItem(value: 'أ/ أحمد كمال', child: Text('أ/ أحمد كمال (لغة عربية)')),
                  DropdownMenuItem(value: 'أ/ حسام فؤاد', child: Text('أ/ حسام فؤاد (كيمياء)')),
                  DropdownMenuItem(value: 'أ/ محمد إبراهيم', child: Text('أ/ محمد إبراهيم (فيزياء)')),
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
                        Text('القاعة:', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: roomCtrl,
                          decoration: const InputDecoration(isDense: true),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('السعة القصوى:', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: capacityCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(isDense: true),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('الاشتراك (ج.م):', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: feeCtrl,
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
          label: const Text('إنشاء المجموعة'),
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              SoundService.successFeedback();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFF10B981),
                  content: Text('تم إنشاء المجموعة ${nameCtrl.text} بنجاح!'),
                ),
              );
            }
          },
        ),
      ],
    );
  }
}
