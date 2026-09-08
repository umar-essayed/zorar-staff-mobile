import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/providers/edu_data_providers.dart';
import '../../core/services/export_service.dart';
import '../../core/services/sound_service.dart';
import '../../core/theme/branding_provider.dart';

class PaymentTransaction {
  final String id;
  final String studentName;
  final String studentCode;
  final String groupName;
  final String teacherName;
  final String academicYear;
  final String paymentType;
  final double amount;
  final String paymentMethod;
  final String assistantName;
  final DateTime timestamp;

  PaymentTransaction({
    required this.id,
    required this.studentName,
    required this.studentCode,
    required this.groupName,
    required this.teacherName,
    required this.academicYear,
    required this.paymentType,
    required this.amount,
    required this.paymentMethod,
    required this.assistantName,
    required this.timestamp,
  });

  factory PaymentTransaction.fromMap(Map<String, dynamic> map) {
    String methodArabic = 'كاش';
    final m = map['method']?.toString().toUpperCase() ?? '';
    if (m.contains('VODAFONE') || m.contains('WALLET')) {
      methodArabic = 'فودافون كاش';
    } else if (m.contains('INSTAPAY')) {
      methodArabic = 'إنستاباي';
    } else if (m.contains('CARD')) {
      methodArabic = 'فيزا / بطاقة';
    }

    String typeArabic = 'سداد مالي';
    final t = map['type']?.toString().toUpperCase() ?? '';
    if (t.contains('MONTHLY')) {
      typeArabic = 'اشتراك شهر';
    } else if (t.contains('SESSION')) {
      typeArabic = 'رسوم حصة';
    } else if (t.contains('BOOK')) {
      typeArabic = 'ملزمة دراسية';
    } else if (map['notes'] != null && map['notes'].toString().isNotEmpty) {
      typeArabic = map['notes'].toString();
    }

    DateTime parsedDate = DateTime.now();
    if (map['createdAt'] != null) {
      try {
        parsedDate = DateTime.parse(map['createdAt'].toString());
      } catch (_) {}
    }

    return PaymentTransaction(
      id: map['receiptNumber']?.toString() ?? map['id']?.toString() ?? 'REC',
      studentName: map['student']?['name']?.toString() ?? 'طالب سنتر',
      studentCode: map['student']?['studentCode']?.toString() ?? '',
      groupName: map['group']?['name']?.toString() ?? 'مجموعة عامة',
      teacherName: map['teacher']?['name']?.toString() ?? 'السنتر',
      academicYear: map['academicYear']?['name']?.toString() ?? '',
      paymentType: typeArabic,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: methodArabic,
      assistantName: map['assistant']?['name']?.toString() ?? 'الاستقبال',
      timestamp: parsedDate,
    );
  }
}

class FinancialLedgerScreen extends ConsumerStatefulWidget {
  const FinancialLedgerScreen({super.key});

  @override
  ConsumerState<FinancialLedgerScreen> createState() => _FinancialLedgerScreenState();
}

class _FinancialLedgerScreenState extends ConsumerState<FinancialLedgerScreen> {
  String selectedFilterMethod = 'الكل';
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(brandingProvider);
    final transactionsAsync = ref.watch(liveTransactionsProvider);
    final financeOverviewAsync = ref.watch(liveFinanceOverviewProvider);

    final rawList = (transactionsAsync.value?['items'] as List?) ?? [];
    final transactions = rawList.map((m) => PaymentTransaction.fromMap(m as Map<String, dynamic>)).toList();

    final filtered = transactions.where((t) {
      if (selectedFilterMethod != 'الكل' && t.paymentMethod != selectedFilterMethod) {
        return false;
      }
      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        return t.studentName.toLowerCase().contains(q) ||
            t.studentCode.toLowerCase().contains(q) ||
            t.id.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    final totalAmount = filtered.fold<double>(0.0, (acc, item) => acc + item.amount);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'سجل وجرد المدفوعات المالي',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.fileSpreadsheet),
            tooltip: 'تصدير ملخص الخزينة',
            onPressed: () {
              final totalExpenses = ((financeOverviewAsync.value?['todayExpenses'] ?? 0.0) as num).toDouble();
              ExportService.exportFinancialSummary(
                context: context,
                centerName: branding.centerName,
                totalIncome: totalAmount,
                totalExpenses: totalExpenses,
                netProfit: totalAmount - totalExpenses,
                totalTransactions: filtered.length,
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          SoundService.lightImpact();
          ref.invalidate(liveTransactionsProvider);
          ref.invalidate(liveFinanceOverviewProvider);
        },
        child: Column(
          children: [
            // Filter & Search Header
            Container(
              padding: const EdgeInsets.all(14),
              color: Theme.of(context).cardColor,
              child: Column(
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      hintText: 'ابحث باسم الطالب، الكود، أو رقم الإيصال...',
                      prefixIcon: Icon(LucideIcons.search, size: 20),
                      isDense: true,
                    ),
                    onChanged: (val) {
                      setState(() => searchQuery = val);
                    },
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('طريقة الدفع: الكل', 'الكل'),
                        const SizedBox(width: 8),
                        _buildFilterChip('كاش 💵', 'كاش'),
                        const SizedBox(width: 8),
                        _buildFilterChip('إنستاباي ⚡', 'إنستاباي'),
                        const SizedBox(width: 8),
                        _buildFilterChip('فودافون كاش 📱', 'فودافون كاش'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Total Summary Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: branding.primaryColor.withOpacity(0.12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'إجمالي المقبوضات (${filtered.length} عملية):',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Text(
                    '${totalAmount.toStringAsFixed(0)} ج.م',
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: branding.primaryColor,
                    ),
                  ),
                ],
              ),
            ),

            // Transactions List
            Expanded(
              child: transactionsAsync.when(
                loading: () => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: CircularProgressIndicator(color: branding.primaryColor),
                  ),
                ),
                error: (err, _) => Center(
                  child: Text('تعذر تحميل السجل: $err', style: GoogleFonts.cairo(color: Colors.red)),
                ),
                data: (_) {
                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.receipt, size: 48, color: Colors.grey.withOpacity(0.5)),
                          const SizedBox(height: 8),
                          Text(
                            'لا توجد عمليات مسجلة بالسجل المالي حالياً',
                            style: GoogleFonts.cairo(color: Colors.grey, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, idx) {
                      final item = filtered[idx];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: branding.primaryColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          item.id,
                                          style: GoogleFonts.cairo(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: branding.primaryColor,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        item.studentCode,
                                        style: GoogleFonts.cairo(
                                          fontSize: 11.5,
                                          color: Colors.grey,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '+${item.amount.toStringAsFixed(0)} ج.م',
                                    style: GoogleFonts.cairo(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF10B981),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item.studentName,
                                style: GoogleFonts.cairo(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${item.groupName} • ${item.teacherName}',
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${item.paymentType} (${item.paymentMethod})',
                                    style: GoogleFonts.cairo(
                                      fontSize: 11.5,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  Text(
                                    'بواسطة: ${item.assistantName}',
                                    style: GoogleFonts.cairo(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = selectedFilterMethod == value;
    final branding = ref.watch(brandingProvider);

    return FilterChip(
      label: Text(
        label,
        style: GoogleFonts.cairo(
          fontSize: 11.5,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : null,
        ),
      ),
      selected: isSelected,
      selectedColor: branding.primaryColor,
      onSelected: (_) {
        setState(() => selectedFilterMethod = value);
      },
    );
  }
}
