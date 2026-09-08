import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/services/sound_service.dart';
import '../../core/theme/branding_provider.dart';

class EmergencySessionDialog extends ConsumerStatefulWidget {
  const EmergencySessionDialog({super.key});

  @override
  ConsumerState<EmergencySessionDialog> createState() => _EmergencySessionDialogState();
}

class _EmergencySessionDialogState extends ConsumerState<EmergencySessionDialog> {
  String selectedGroup = 'مجموعة 3ث لغة عربية (أ) - أ/ أحمد كمال';
  int sessionNumber = 5;
  final TextEditingController reasonCtrl = TextEditingController(text: 'جلسة تعويضية لطلاب متغيبين');

  @override
  void dispose() {
    reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(brandingProvider);

    return AlertDialog(
      title: Row(
        children: [
          const Icon(LucideIcons.calendarPlus, color: Color(0xFFF59E0B), size: 24),
          const SizedBox(width: 10),
          Text(
            'فتح جلسة حضور استثنائية',
            style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
              ),
              child: Text(
                'تتيح هذه الميزة فتح تسجيل الحضور لأي حصة خارج جدولها الطبيعي، وسيتم توثيق الاستثناء رسمياً بالنظام.',
                style: GoogleFonts.cairo(fontSize: 11.5, color: Colors.brown),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'المجموعة المستهدفة:',
              style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: selectedGroup,
              isExpanded: true,
              decoration: const InputDecoration(isDense: true),
              items: const [
                DropdownMenuItem(
                  value: 'مجموعة 3ث لغة عربية (أ) - أ/ أحمد كمال',
                  child: Text('مجموعة 3ث لغة عربية (أ) - أ/ أحمد كمال'),
                ),
                DropdownMenuItem(
                  value: 'مجموعة 2ث كيمياء (ب) - أ/ حسام فؤاد',
                  child: Text('مجموعة 2ث كيمياء (ب) - أ/ حسام فؤاد'),
                ),
                DropdownMenuItem(
                  value: 'مجموعة 1ث فيزياء (ج) - أ/ محمد إبراهيم',
                  child: Text('مجموعة 1ث فيزياء (ج) - أ/ محمد إبراهيم'),
                ),
              ],
              onChanged: (val) {
                if (val != null) setState(() => selectedGroup = val);
              },
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'رقم الحصة في الشهر:',
                        style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<int>(
                        value: sessionNumber,
                        decoration: const InputDecoration(isDense: true),
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('الحصة 1')),
                          DropdownMenuItem(value: 2, child: Text('الحصة 2')),
                          DropdownMenuItem(value: 3, child: Text('الحصة 3')),
                          DropdownMenuItem(value: 4, child: Text('الحصة 4')),
                          DropdownMenuItem(value: 5, child: Text('الحصة 5 (إضافية)')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => sessionNumber = val);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'سبب فتح الاستثناء:',
              style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                hintText: 'مثال: حصة تعويضية أو مراجعة إضافية...',
                isDense: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: branding.primaryColor,
            foregroundColor: Colors.white,
          ),
          icon: const Icon(LucideIcons.unlock, size: 16),
          label: const Text('فتح جلسة الحضور الآن'),
          onPressed: () {
            SoundService.successFeedback();
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: const Color(0xFF10B981),
                content: Text(
                  'تم فتح الجلسة الاستثنائية للحصة ($sessionNumber) بنجاح وجاهزة للمسح',
                  style: GoogleFonts.cairo(),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
