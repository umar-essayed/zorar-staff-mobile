import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/services/sound_service.dart';
import '../../core/services/whatsapp_service.dart';
import '../../core/theme/branding_provider.dart';

class MobilePosScreen extends ConsumerStatefulWidget {
  const MobilePosScreen({super.key});

  @override
  ConsumerState<MobilePosScreen> createState() => _MobilePosScreenState();
}

class _MobilePosScreenState extends ConsumerState<MobilePosScreen> {
  String selectedStudent = 'محمود عبد الرازق حسن (STU-1004)';
  String selectedItem = 'اشتراك شهر سبتمبر (4 حصص) - 450 ج.م';
  String paymentMethod = 'كاش';
  double amount = 450.0;
  double discount = 0.0;

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(brandingProvider);
    final netTotal = (amount - discount).clamp(0.0, 999999.0);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'نقطة البيع والخزينة',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student Selector
            Text(
              'بيانات الطالب',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: branding.primaryColor.withOpacity(0.12),
                    child: Icon(LucideIcons.user, color: branding.primaryColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedStudent,
                          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          '3ث لغة عربية • مجموعة (أ) • أ/ أحمد كمال',
                          style: GoogleFonts.cairo(fontSize: 11.5, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.arrowRightLeft, size: 20),
                    tooltip: 'تغيير الطالب',
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Item to charge
            Text(
              'بند التحصيل',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedItem,
              decoration: const InputDecoration(
                prefixIcon: Icon(LucideIcons.tag, size: 20),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'اشتراك شهر سبتمبر (4 حصص) - 450 ج.م',
                  child: Text('اشتراك شهر سبتمبر (4 حصص) - 450 ج.م'),
                ),
                DropdownMenuItem(
                  value: 'رسوم حصة مفردة / تجريبية - 120 ج.م',
                  child: Text('رسوم حصة مفردة / تجريبية - 120 ج.م'),
                ),
                DropdownMenuItem(
                  value: 'ملزمة النحو والتدريبات 2026 - 85 ج.م',
                  child: Text('ملزمة النحو والتدريبات 2026 - 85 ج.م'),
                ),
                DropdownMenuItem(
                  value: 'كتاب الشرح وبنك الأسئلة - 150 ج.م',
                  child: Text('كتاب الشرح وبنك الأسئلة - 150 ج.م'),
                ),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    selectedItem = val;
                    if (val.contains('450')) amount = 450.0;
                    if (val.contains('120')) amount = 120.0;
                    if (val.contains('85')) amount = 85.0;
                    if (val.contains('150')) amount = 150.0;
                  });
                }
              },
            ),

            const SizedBox(height: 20),

            // Payment Method Selection
            Text(
              'طريقة السداد',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildMethodChip('كاش 💵', 'كاش', branding.primaryColor),
                const SizedBox(width: 8),
                _buildMethodChip('إنستاباي ⚡', 'إنستاباي', branding.primaryColor),
                const SizedBox(width: 8),
                _buildMethodChip('فودافون كاش 📱', 'فودافون كاش', branding.primaryColor),
              ],
            ),

            const SizedBox(height: 24),

            // Bill Breakdown Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('المبلغ الأساسي', style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey)),
                      Text('${amount.toStringAsFixed(0)} ج.م',
                          style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('الخصم / الإعفاء', style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey)),
                      Text('${discount.toStringAsFixed(0)} ج.م',
                          style: GoogleFonts.cairo(fontSize: 14, color: Colors.red)),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('صافي المطلوب تحصيله',
                          style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold)),
                      Text(
                        '${netTotal.toStringAsFixed(0)} ج.م',
                        style: GoogleFonts.cairo(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: branding.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                icon: const Icon(LucideIcons.printer, size: 20),
                label: Text(
                  'تأكيد الدفع والطباعة',
                  style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  SoundService.successFeedback();
                  _showReceiptDialog(context, branding.centerName, netTotal);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodChip(String label, String value, Color primaryColor) {
    final isSelected = paymentMethod == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => paymentMethod = value),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor.withOpacity(0.15) : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? primaryColor : Colors.grey.withOpacity(0.2),
              width: isSelected ? 1.8 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? primaryColor : null,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showReceiptDialog(BuildContext context, String centerName, double total) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Center(
          child: Column(
            children: [
              const Icon(LucideIcons.checkCircle2, color: Color(0xFF10B981), size: 48),
              const SizedBox(height: 8),
              Text(
                'تم تحصيل المبلغ بنجاح!',
                style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                centerName,
                style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(),
            Text('الطالب: $selectedStudent', style: GoogleFonts.cairo(fontSize: 12.5)),
            const SizedBox(height: 4),
            Text('البند: $selectedItem', style: GoogleFonts.cairo(fontSize: 12)),
            const SizedBox(height: 4),
            Text('طريقة الدفع: $paymentMethod', style: GoogleFonts.cairo(fontSize: 12)),
            const SizedBox(height: 4),
            Text('المبلغ المحصل: ${total.toStringAsFixed(0)} ج.م',
                style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF10B981))),
            const Divider(),
            Text('رقم الإيصال: REC-2026-0811', style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(LucideIcons.share2, size: 16),
            label: const Text('إرسال واتساب'),
            onPressed: () {
              Navigator.pop(ctx);
              WhatsAppService.sendParentReceipt(
                context: context,
                parentPhone: '01012345678',
                studentName: selectedStudent,
                itemTitle: selectedItem,
                amount: total,
                receiptNumber: 'REC-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                centerName: centerName,
              );
            },
          ),
          ElevatedButton.icon(
            icon: const Icon(LucideIcons.printer, size: 16),
            label: const Text('طباعة بلوتوث'),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('جاري إرسال الإيصال إلى طابعة البلوتوث المحمولة...')),
              );
            },
          ),
        ],
      ),
    );
  }
}
