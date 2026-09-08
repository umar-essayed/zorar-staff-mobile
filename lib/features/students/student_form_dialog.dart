import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/services/sound_service.dart';
import '../../core/theme/branding_provider.dart';

class StudentFormDialog extends ConsumerStatefulWidget {
  const StudentFormDialog({super.key});

  @override
  ConsumerState<StudentFormDialog> createState() => _StudentFormDialogState();
}

class _StudentFormDialogState extends ConsumerState<StudentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final parentPhoneCtrl = TextEditingController();
  String selectedGrade = 'الصف الثالث الثانوي';
  String selectedGroup = '3ث لغة عربية (أ) - أ/ أحمد كمال';

  @override
  void dispose() {
    nameCtrl.dispose();
    phoneCtrl.dispose();
    parentPhoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(brandingProvider);

    return AlertDialog(
      title: Row(
        children: [
          Icon(LucideIcons.userPlus, color: branding.primaryColor, size: 24),
          const SizedBox(width: 10),
          Text(
            'تسجيل وقبول طالب جديد',
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
              Text(
                'الاسم الرباعي للطالب:',
                style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  hintText: 'مثال: عبد الرحمن محمد أحمد',
                  prefixIcon: Icon(LucideIcons.user, size: 20),
                  isDense: true,
                ),
                validator: (val) => val == null || val.isEmpty ? 'يرجى إدخال اسم الطالب' : null,
              ),
              const SizedBox(height: 12),
              Text(
                'رقم هاتف الطالب:',
                style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: '010XXXXXXXX',
                  prefixIcon: Icon(LucideIcons.phone, size: 20),
                  isDense: true,
                ),
                validator: (val) => val == null || val.isEmpty ? 'يرجى إدخال الهاتف' : null,
              ),
              const SizedBox(height: 12),
              Text(
                'رقم هاتف ولي الأمر (واتساب):',
                style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: parentPhoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: '01XXXXXXXXX',
                  prefixIcon: Icon(LucideIcons.messageSquare, size: 20),
                  isDense: true,
                ),
                validator: (val) => val == null || val.isEmpty ? 'يرجى إدخال هاتف ولي الأمر' : null,
              ),
              const SizedBox(height: 12),
              Text(
                'المرحلة الدراسية:',
                style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: selectedGrade,
                isExpanded: true,
                decoration: const InputDecoration(isDense: true),
                items: const [
                  DropdownMenuItem(value: 'الصف الأول الثانوي', child: Text('الصف الأول الثانوي')),
                  DropdownMenuItem(value: 'الصف الثاني الثانوي', child: Text('الصف الثاني الثانوي')),
                  DropdownMenuItem(value: 'الصف الثالث الثانوي', child: Text('الصف الثالث الثانوي')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => selectedGrade = val);
                },
              ),
              const SizedBox(height: 12),
              Text(
                'المجموعة الدراسية:',
                style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: selectedGroup,
                isExpanded: true,
                decoration: const InputDecoration(isDense: true),
                items: const [
                  DropdownMenuItem(
                    value: '3ث لغة عربية (أ) - أ/ أحمد كمال',
                    child: Text('3ث لغة عربية (أ) - أ/ أحمد كمال'),
                  ),
                  DropdownMenuItem(
                    value: '2ث كيمياء (ب) - أ/ حسام فؤاد',
                    child: Text('2ث كيمياء (ب) - أ/ حسام فؤاد'),
                  ),
                  DropdownMenuItem(
                    value: '1ث فيزياء (ج) - أ/ محمد إبراهيم',
                    child: Text('1ث فيزياء (ج) - أ/ محمد إبراهيم'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => selectedGroup = val);
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
          icon: const Icon(LucideIcons.printer, size: 16),
          label: const Text('حفظ وطباعة كارت الباركود'),
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              SoundService.successFeedback();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFF10B981),
                  content: Text(
                    'تم إضافة الطالب وتوليد كود STU-1092 وطباعة الكارت بنجاح',
                    style: GoogleFonts.cairo(),
                  ),
                ),
              );
            }
          },
        ),
      ],
    );
  }
}
