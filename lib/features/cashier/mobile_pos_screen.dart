import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/network/edu_api_service.dart';
import '../../core/providers/edu_data_providers.dart';
import '../../core/services/sound_service.dart';
import '../../core/services/whatsapp_service.dart';
import '../../core/theme/branding_provider.dart';

class MobilePosScreen extends ConsumerStatefulWidget {
  const MobilePosScreen({super.key});

  @override
  ConsumerState<MobilePosScreen> createState() => _MobilePosScreenState();
}

class _MobilePosScreenState extends ConsumerState<MobilePosScreen> {
  Map<String, dynamic>? selectedStudentObj;
  String selectedItem = 'اشتراك شهر جديد - 450 ج.م';
  String paymentMethod = 'كاش';
  double amount = 450.0;
  double discount = 0.0;
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(brandingProvider);
    final studentsAsync = ref.watch(liveStudentsProvider);
    final netTotal = (amount - discount).clamp(0.0, 999999.0);

    final studentsList = studentsAsync.value ?? [];
    if (selectedStudentObj == null && studentsList.isNotEmpty) {
      selectedStudentObj = studentsList.first;
    }

    final studentName = selectedStudentObj?['name']?.toString() ?? 'اختر طالباً';
    final studentCode = selectedStudentObj?['studentCode']?.toString() ?? '';
    final studentPhone = selectedStudentObj?['phone']?.toString() ?? '';
    final guardianPhone = selectedStudentObj?['guardianPhone']?.toString() ?? studentPhone;
    String groupName = 'طالب مسجل بالسنتر';
    final groupsList = selectedStudentObj?['groups'] as List?;
    if (groupsList != null && groupsList.isNotEmpty) {
      final firstGroup = groupsList[0];
      if (firstGroup is Map && firstGroup['group'] is Map) {
        groupName = firstGroup['group']['name']?.toString() ?? 'مجموعة عامة';
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'نقطة البيع والخزينة POS',
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
                          '$studentName ${studentCode.isNotEmpty ? '($studentCode)' : ''}',
                          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          groupName,
                          style: GoogleFonts.cairo(fontSize: 11.5, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.arrowRightLeft, size: 20),
                    tooltip: 'تغيير الطالب',
                    onPressed: () {
                      _showStudentPickerModal(context, studentsList);
                    },
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
                icon: _isProcessing
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(LucideIcons.printer, size: 20),
                label: Text(
                  _isProcessing ? 'جاري تسجيل الحركة بالخزينة...' : 'تأكيد الدفع والطباعة',
                  style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                onPressed: _isProcessing
                    ? null
                    : () async {
                        if (studentCode.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('يرجى اختيار طالب أولاً')),
                          );
                          return;
                        }
                        setState(() => _isProcessing = true);
                        try {
                          String methodBackend = 'CASH';
                          if (paymentMethod == 'فودافون كاش') methodBackend = 'VODAFONE_CASH';
                          if (paymentMethod == 'إنستاباي') methodBackend = 'INSTAPAY';

                          final res = await EduApiService().createTransaction({
                            'studentCode': studentCode,
                            'amount': netTotal,
                            'method': methodBackend,
                            'type': selectedItem.contains('شهر') ? 'MONTHLY_SUBSCRIPTION' : selectedItem.contains('حصة') ? 'SINGLE_SESSION' : 'BOOK_PURCHASE',
                            'notes': selectedItem,
                          });

                          ref.invalidate(liveTransactionsProvider);
                          ref.invalidate(liveFinanceOverviewProvider);

                          final recNo = res?['receiptNumber']?.toString() ?? 'REC-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
                          SoundService.successFeedback();
                          if (context.mounted) {
                            _showReceiptDialog(
                              context,
                              branding.centerName,
                              netTotal,
                              receiptNo: recNo,
                              studentName: studentName,
                              parentPhone: guardianPhone,
                            );
                          }
                        } catch (e) {
                          SoundService.errorFeedback();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('تعذر تسجيل عملية الدفع: $e'), backgroundColor: Colors.red),
                            );
                          }
                        } finally {
                          if (mounted) setState(() => _isProcessing = false);
                        }
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStudentPickerModal(BuildContext context, List<Map<String, dynamic>> students) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        String query = '';
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final filtered = students.where((s) {
              if (query.isEmpty) return true;
              final q = query.toLowerCase();
              return (s['name']?.toString().toLowerCase().contains(q) ?? false) ||
                  (s['studentCode']?.toString().toLowerCase().contains(q) ?? false) ||
                  (s['phone']?.toString().contains(q) ?? false);
            }).toList();

            return Container(
              padding: const EdgeInsets.all(16),
              height: MediaQuery.of(context).size.height * 0.75,
              child: Column(
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 12),
                  Text('اختر طالباً للتحصيل', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'ابحث باسم الطالب، الكود، أو رقم الهاتف...',
                      prefixIcon: const Icon(LucideIcons.search, size: 20),
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onChanged: (val) => setModalState(() => query = val),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(child: Text('لا يوجد طلاب يطابقون البحث', style: GoogleFonts.cairo(color: Colors.grey)))
                        : ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (ctx, idx) {
                              final st = filtered[idx];
                              return ListTile(
                                leading: const CircleAvatar(child: Icon(LucideIcons.user, size: 18)),
                                title: Text(st['name']?.toString() ?? '', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13.5)),
                                subtitle: Text('كود: ${st['studentCode'] ?? ''} • ${st['phone'] ?? ''}', style: GoogleFonts.cairo(fontSize: 11.5)),
                                onTap: () {
                                  setState(() => selectedStudentObj = st);
                                  Navigator.pop(ctx);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
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

  void _showReceiptDialog(
    BuildContext context,
    String centerName,
    double total, {
    required String receiptNo,
    required String studentName,
    required String parentPhone,
  }) {
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
            Text('الطالب: $studentName', style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('البند: $selectedItem', style: GoogleFonts.cairo(fontSize: 12)),
            const SizedBox(height: 4),
            Text('طريقة الدفع: $paymentMethod', style: GoogleFonts.cairo(fontSize: 12)),
            const SizedBox(height: 4),
            Text('المبلغ المحصل: ${total.toStringAsFixed(0)} ج.م',
                style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF10B981))),
            const Divider(),
            Text('رقم الإيصال: $receiptNo', style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey)),
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
                parentPhone: parentPhone,
                studentName: studentName,
                itemTitle: selectedItem,
                amount: total,
                receiptNumber: receiptNo,
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
