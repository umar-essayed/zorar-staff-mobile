import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/network/edu_api_service.dart';
import '../../core/providers/edu_data_providers.dart';
import '../../core/services/sound_service.dart';
import '../../core/services/whatsapp_service.dart';
import '../../core/theme/branding_provider.dart';
import '../../core/utils/numeric_utils.dart';

class MobilePosScreen extends ConsumerStatefulWidget {
  final String? initialStudentCode;
  const MobilePosScreen({super.key, this.initialStudentCode});

  @override
  ConsumerState<MobilePosScreen> createState() => _MobilePosScreenState();
}

class _MobilePosScreenState extends ConsumerState<MobilePosScreen> {
  Map<String, dynamic>? selectedStudentObj;
  String selectedItem = 'دفع مخصص وملاحظات (مبلغ حر)';
  String paymentMethod = 'كاش';
  double amount = 350.0;
  double discount = 0.0;
  bool _isProcessing = false;
  bool _isCustomAmount = true;

  final _customAmountCtrl = TextEditingController(text: '350');
  final _customNotesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _customAmountCtrl.dispose();
    _customNotesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(brandingProvider);
    final studentsAsync = ref.watch(liveStudentsProvider);
    final booksAsync = ref.watch(liveBooksProvider);
    final netTotal = (amount - discount).clamp(0.0, 999999.0);

    final studentsList = studentsAsync.value ?? [];
    if (selectedStudentObj == null && studentsList.isNotEmpty) {
      if (widget.initialStudentCode != null && widget.initialStudentCode!.isNotEmpty) {
        selectedStudentObj = studentsList.firstWhere(
          (s) => (s['studentCode'] ?? s['code']) == widget.initialStudentCode,
          orElse: () => studentsList.first,
        );
      } else {
        selectedStudentObj = studentsList.first;
      }
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

            Builder(
              builder: (context) {
                // Build dynamic charge items
                final List<Map<String, dynamic>> chargeOptions = [];

                // 1. Unpaid Monthly Subscriptions
                final monthlySubs = (selectedStudentObj?['monthlySubs'] as List?) ?? [];
                for (final sub in monthlySubs) {
                  if (sub is Map && sub['isPaid'] == false) {
                    final mName = sub['monthName']?.toString() ?? 'اشتراك شهر';
                    final mAmount = parseDouble(sub['amount'], 350.0);
                    chargeOptions.add({
                      'label': 'سداد $mName (${mAmount.toInt()} ج.م)',
                      'amount': mAmount,
                      'type': 'MONTHLY_SUBSCRIPTION',
                      'isCustom': false,
                    });
                  }
                }

                // 2. Group Session Fees
                if (groupsList != null && groupsList.isNotEmpty) {
                  for (final g in groupsList) {
                    if (g is Map && g['group'] is Map) {
                      final gMap = g['group'] as Map;
                      final gName = gMap['name']?.toString() ?? 'المجموعة';
                      final sPrice = parseDouble(gMap['pricePerSession'], 50.0);
                      final mFee = parseDouble(gMap['monthlyFee'], 350.0);
                      chargeOptions.add({
                        'label': 'رسوم حصة مفردة [$gName] (${sPrice.toInt()} ج.م)',
                        'amount': sPrice,
                        'type': 'LESSON_SESSION_FEE',
                        'isCustom': false,
                      });
                      if (monthlySubs.isEmpty) {
                        chargeOptions.add({
                          'label': 'اشتراك شهر جديد [$gName] (${mFee.toInt()} ج.م)',
                          'amount': mFee,
                          'type': 'MONTHLY_SUBSCRIPTION',
                          'isCustom': false,
                        });
                      }
                    }
                  }
                }

                // 3. Available Books
                final booksList = booksAsync.value ?? [];
                for (final b in booksList) {
                  final bTitle = b['title']?.toString() ?? 'كتاب';
                  final bPrice = parseDouble(b['salePrice'], 85.0);
                  chargeOptions.add({
                    'label': 'شراء ملزمة: $bTitle (${bPrice.toInt()} ج.م)',
                    'amount': bPrice,
                    'type': 'BOOK_NOTE_PURCHASE',
                    'isCustom': false,
                  });
                }

                // 4. Custom Payment (Always available)
                chargeOptions.add({
                  'label': 'دفع مخصص وملاحظات (مبلغ حر)',
                  'amount': parseDouble(_customAmountCtrl.text, 100.0),
                  'type': 'OTHER_INCOME',
                  'isCustom': true,
                });

                // Ensure selectedItem is present in items list
                final validLabels = chargeOptions.map((c) => c['label'] as String).toList();
                if (!validLabels.contains(selectedItem)) {
                  selectedItem = validLabels.first;
                  final firstOpt = chargeOptions.first;
                  amount = parseDouble(firstOpt['amount']);
                  _isCustomAmount = firstOpt['isCustom'] as bool;
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedItem,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(LucideIcons.tag, size: 20),
                      ),
                      items: chargeOptions.map((opt) {
                        return DropdownMenuItem<String>(
                          value: opt['label'] as String,
                          child: Text(
                            opt['label'] as String,
                            style: GoogleFonts.cairo(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            selectedItem = val;
                            final match = chargeOptions.firstWhere((c) => c['label'] == val, orElse: () => chargeOptions.last);
                            _isCustomAmount = match['isCustom'] as bool;
                            if (!_isCustomAmount) {
                              amount = parseDouble(match['amount']);
                              _customAmountCtrl.text = amount.toInt().toString();
                            } else {
                              amount = parseDouble(_customAmountCtrl.text, 100.0);
                            }
                          });
                        }
                      },
                    ),

                    if (_isCustomAmount) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _customAmountCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'المبلغ المطلوب تحصيله بالجنيه (ج.م)',
                          prefixIcon: Icon(LucideIcons.coins, size: 18),
                          isDense: true,
                        ),
                        onChanged: (val) {
                          setState(() {
                            amount = parseDouble(val);
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _customNotesCtrl,
                        decoration: const InputDecoration(
                          labelText: 'ملاحظات وبيان الدفع بالخزينة (مطلوب)',
                          hintText: 'مثال: سداد متبقي، رسوم إضافية، ملزمة مراجعة...',
                          prefixIcon: Icon(LucideIcons.fileText, size: 18),
                          isDense: true,
                        ),
                      ),
                    ],
                  ],
                );
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
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: _isProcessing
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(LucideIcons.printer, size: 20),
                label: Text(
                  _isProcessing ? 'جاري تسجيل الحركة بالخزينة...' : 'تأكيد الدفع وطباعة الإيصال',
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

                        if (netTotal <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('يرجى تحديد مبلغ صحيح أكبر من الصفر')),
                          );
                          return;
                        }

                        setState(() => _isProcessing = true);
                        try {
                          String methodBackend = 'CASH';
                          if (paymentMethod == 'فودافون كاش') methodBackend = 'VODAFONE_CASH';
                          if (paymentMethod == 'إنستاباي') methodBackend = 'INSTAPAY';

                          String typeBackend = 'OTHER_INCOME';
                          if (selectedItem.contains('اشتراك شهر') || selectedItem.contains('سداد')) {
                            typeBackend = 'MONTHLY_SUBSCRIPTION';
                          } else if (selectedItem.contains('حصة')) {
                            typeBackend = 'LESSON_SESSION_FEE';
                          } else if (selectedItem.contains('ملزمة') || selectedItem.contains('كتاب')) {
                            typeBackend = 'BOOK_NOTE_PURCHASE';
                          }

                          String noteText = selectedItem;
                          if (_isCustomAmount && _customNotesCtrl.text.trim().isNotEmpty) {
                            noteText = _customNotesCtrl.text.trim();
                          }

                          final payload = <String, dynamic>{
                            'studentCode': studentCode,
                            'amount': netTotal,
                            'method': methodBackend,
                            'type': typeBackend,
                            'description': noteText,
                          };

                          if (groupsList != null && groupsList.isNotEmpty) {
                            final g0 = groupsList[0];
                            if (g0 is Map) {
                              payload['groupId'] = g0['groupId'] ?? g0['group']?['id'];
                              payload['teacherId'] = g0['group']?['teacherId'];
                              payload['subjectId'] = g0['group']?['subjectId'];
                            }
                          }
                          if (selectedStudentObj?['academicYearId'] != null) {
                            payload['academicYearId'] = selectedStudentObj!['academicYearId'];
                          }

                          final res = await EduApiService().createTransaction(payload);

                          ref.invalidate(liveTransactionsProvider);
                          ref.invalidate(liveFinanceOverviewProvider);
                          ref.invalidate(liveStudentsProvider);

                          final recNo = res?['receiptNo']?.toString() ??
                              res?['receiptNumber']?.toString() ??
                              'REC-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
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
                            String err = 'تعذر تسجيل عملية الدفع: $e';
                            if (e is DioException && e.response?.data?['message'] != null) {
                              final m = e.response!.data['message'];
                              err = m is List ? m.join(', ') : m.toString();
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(err), backgroundColor: Colors.red),
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
