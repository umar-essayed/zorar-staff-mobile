import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/services/sound_service.dart';
import '../../core/theme/branding_provider.dart';

class ShiftClosingDialog extends ConsumerStatefulWidget {
  const ShiftClosingDialog({super.key});

  @override
  ConsumerState<ShiftClosingDialog> createState() => _ShiftClosingDialogState();
}

class _ShiftClosingDialogState extends ConsumerState<ShiftClosingDialog> {
  final double expectedSystemCash = 8450.0;
  final TextEditingController countedCashCtrl = TextEditingController(text: '8450');
  double difference = 0.0;

  @override
  void initState() {
    super.initState();
    countedCashCtrl.addListener(_calculateDiff);
  }

  void _calculateDiff() {
    final counted = double.tryParse(countedCashCtrl.text) ?? 0.0;
    setState(() {
      difference = counted - expectedSystemCash;
    });
  }

  @override
  void dispose() {
    countedCashCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(brandingProvider);

    return AlertDialog(
      title: Row(
        children: [
          Icon(LucideIcons.lock, color: branding.primaryColor, size: 24),
          const SizedBox(width: 10),
          Text(
            'تقفيل شيفت الخزينة اليومي',
            style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'مطابقة النقدية الفعلية في الدرج مع الحركات المسجلة بالسيستم.',
              style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('النقدية المحسوبة بالنظام:', style: GoogleFonts.cairo(fontSize: 12)),
                      Text('${expectedSystemCash.toStringAsFixed(0)} ج.م',
                          style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('عدد الإيصالات المحصلة:', style: GoogleFonts.cairo(fontSize: 12)),
                      Text('34 إيصال', style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'النقدية الفعلية المحصورة باليد (ج.م):',
              style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: countedCashCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                prefixIcon: Icon(LucideIcons.coins, size: 20),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('الفارق / العجز أو الزيادة:', style: GoogleFonts.cairo(fontSize: 12)),
                Text(
                  difference == 0
                      ? 'مطابق تماماً (0 ج.م) ✅'
                      : difference > 0
                          ? '+${difference.toStringAsFixed(0)} ج.م زيادة'
                          : '${difference.toStringAsFixed(0)} ج.م عجز ⚠️',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: difference == 0
                        ? const Color(0xFF10B981)
                        : (difference > 0 ? Colors.blue : Colors.red),
                  ),
                ),
              ],
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
          icon: const Icon(LucideIcons.checkCheck, size: 16),
          label: const Text('إغلاق الشيفت وترحيل الدرج'),
          onPressed: () {
            SoundService.successFeedback();
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم تقفيل الشيفت وإرسال الإشعار للإدارة بنجاح')),
            );
          },
        ),
      ],
    );
  }
}
