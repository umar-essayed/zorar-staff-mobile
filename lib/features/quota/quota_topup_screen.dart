import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../core/network/api_client.dart';
import '../../core/providers/edu_data_providers.dart';
import '../../core/services/sound_service.dart';
import '../../core/theme/branding_provider.dart';
import '../../core/utils/numeric_utils.dart';

final quotaPricingProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  try {
    final res = await ApiClient().dio.get('/tenants/quota/pricing');
    return (res.data as Map<String, dynamic>?) ?? {};
  } catch (e) {
    return {
      'currency': 'EGP',
      'pricing': {
        'standardPerStudentEgp': 2.0,
        'proPerStudentEgp': 5.0,
      },
    };
  }
});

final quotaRequestsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  try {
    final res = await ApiClient().dio.get('/tenants/quota/requests');
    return (res.data as List<dynamic>?) ?? [];
  } catch (e) {
    return [];
  }
});

class QuotaTopupScreen extends ConsumerStatefulWidget {
  const QuotaTopupScreen({super.key});

  @override
  ConsumerState<QuotaTopupScreen> createState() => _QuotaTopupScreenState();
}

class _QuotaTopupScreenState extends ConsumerState<QuotaTopupScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPlan = 'PRO';
  int _quantity = 100;
  final TextEditingController _customQtyCtrl = TextEditingController(text: '100');
  final TextEditingController _notesCtrl = TextEditingController();
  String _paymentMethod = 'INSTAPAY_OR_WALLET';
  bool _isSubmitting = false;

  final List<int> _quickAmounts = [50, 100, 250, 500, 1000];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _customQtyCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _onQuickQtySelected(int qty) {
    SoundService.lightImpact();
    setState(() {
      _quantity = qty;
      _customQtyCtrl.text = qty.toString();
    });
  }

  Future<void> _submitTopupRequest(double unitPrice, dynamic branding) async {
    if (_quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('يرجى إدخال عدد طلاب أكبر من صفر', style: GoogleFonts.cairo()), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    SoundService.lightImpact();

    try {
      final res = await ApiClient().dio.post(
        '/tenants/quota/request',
        data: {
          'type': _selectedPlan,
          'quantity': _quantity,
          'paymentMethod': _paymentMethod,
          'notes': _notesCtrl.text.trim(),
        },
      );

      SoundService.successFeedback();
      ref.invalidate(quotaRequestsProvider);
      ref.invalidate(liveTenantDetailsProvider);

      if (mounted) {
        setState(() => _isSubmitting = false);
        _notesCtrl.clear();
        _tabController.animateTo(2); // Move to requests tab

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Row(
              children: [
                const Icon(LucideIcons.checkCircle2, color: Color(0xFF10B981), size: 24),
                const SizedBox(width: 8),
                Text('تم تقديم الطلب', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
              ],
            ),
            content: Text(
              'تم تسجيل طلب شحن $_quantity طالب بنجاح كـ Request بالنظام.\nسيتم تفعيل الرصيد فور المراجعة.',
              style: GoogleFonts.cairo(fontSize: 13),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: branding.primaryColor),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('حسناً'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      SoundService.errorFeedback();
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر إرسال الطلب: $e', style: GoogleFonts.cairo()), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(brandingProvider);
    final tenantDetails = ref.watch(liveTenantDetailsProvider).value ?? {};
    final studentsList = ref.watch(liveStudentsProvider).value ?? [];
    final pricingAsync = ref.watch(quotaPricingProvider);
    final requestsAsync = ref.watch(quotaRequestsProvider);

    final currentQuota = parseInt(tenantDetails['quotaBalance'], 10);
    final activeStudents = studentsList.length;
    final currentPlan = tenantDetails['plan']?.toString() ?? 'PRO';

    final pricingData = pricingAsync.value?['pricing'] ?? {};
    final standardPrice = parseDouble(pricingData['standardPerStudentEgp'], 2.0);
    final proPrice = parseDouble(pricingData['proPerStudentEgp'], 5.0);
    final unitPrice = _selectedPlan == 'PRO' ? proPrice : standardPrice;
    final totalPrice = unitPrice * _quantity;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'الرصيد وباقات الشحن',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: branding.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: branding.primaryColor,
          labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(LucideIcons.wallet, size: 18), text: 'شحن رصيد'),
            Tab(icon: Icon(LucideIcons.sparkles, size: 18), text: 'مقارنة الباقات'),
            Tab(icon: Icon(LucideIcons.history, size: 18), text: 'طلبات الشحن'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Current Balance Header Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  branding.primaryColor,
                  branding.secondaryColor,
                ],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.gauge, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'الرصيد المتاح:',
                            style: GoogleFonts.cairo(color: Colors.white70, fontSize: 13),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'باقة $currentPlan',
                              style: GoogleFonts.cairo(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$currentQuota طالب',
                        style: GoogleFonts.cairo(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'إجمالي الطلاب المسجلين بالسنتر: $activeStudents طالب',
                        style: GoogleFonts.cairo(color: Colors.white.withOpacity(0.85), fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Recharge Calculator & Request
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'اختر نوع باقة الرصيد المطلوب شحنها:',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13.5),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _buildPlanSelectionCard(
                              title: 'باقة برو (PRO)',
                              subtitle: 'شاملة كل مميزات المنصة وواتساب',
                              price: '$proPrice ج.م / طالب',
                              isSelected: _selectedPlan == 'PRO',
                              isPro: true,
                              branding: branding,
                              onTap: () => setState(() => _selectedPlan = 'PRO'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildPlanSelectionCard(
                              title: 'باقة عادية (Standard)',
                              subtitle: 'حضور وغياب وخزينة فقط',
                              price: '$standardPrice ج.م / طالب',
                              isSelected: _selectedPlan == 'STANDARD',
                              isPro: false,
                              branding: branding,
                              onTap: () => setState(() => _selectedPlan = 'STANDARD'),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                      Text(
                        'حدد كمية الطلاب المطلوبة:',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13.5),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: _quickAmounts.map((amt) {
                          final isChosen = _quantity == amt;
                          return ChoiceChip(
                            label: Text('+$amt طالب', style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: isChosen ? FontWeight.bold : FontWeight.normal)),
                            selected: isChosen,
                            selectedColor: branding.primaryColor.withOpacity(0.2),
                            onSelected: (_) => _onQuickQtySelected(amt),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 14),
                      TextField(
                        controller: _customQtyCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'أو أدخل عدداً مخصصاً',
                          prefixIcon: const Icon(LucideIcons.users, size: 18),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          isDense: true,
                        ),
                        onChanged: (v) {
                          final parsed = parseInt(v, 0);
                          setState(() => _quantity = parsed);
                        },
                      ),

                      const SizedBox(height: 20),
                      // Summary Calculation Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: branding.primaryColor.withOpacity(0.3)),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('الكمية المختارة:', style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey[700])),
                                Text('$_quantity طالب', style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const Divider(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('سعر الطالب بالباقة:', style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey[700])),
                                Text('$unitPrice جنيه مصري (EGP)', style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const Divider(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('الإجمالي المستحق:', style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold)),
                                Text(
                                  '${totalPrice.toStringAsFixed(1)} ج.م',
                                  style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF10B981)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),
                      Text('طريقة الدفع المفضلة:', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: _paymentMethod,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          isDense: true,
                        ),
                        items: const [
                          DropdownMenuItem(value: 'INSTAPAY_OR_WALLET', child: Text('إنستاباي / محفظة فودافون كاش')),
                          DropdownMenuItem(value: 'BANK_TRANSFER', child: Text('تحويل بنكي مباشر')),
                          DropdownMenuItem(value: 'CASH_AGENT', child: Text('دفع نقدي عبر المندوب')),
                        ],
                        onChanged: (v) => setState(() => _paymentMethod = v ?? 'INSTAPAY_OR_WALLET'),
                      ),

                      const SizedBox(height: 14),
                      TextField(
                        controller: _notesCtrl,
                        decoration: InputDecoration(
                          labelText: 'ملاحظات أو رقم الهاتف المحول منه (اختياري)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          isDense: true,
                        ),
                      ),

                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: branding.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: _isSubmitting
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(LucideIcons.send, size: 18),
                          label: Text(
                            _isSubmitting ? 'جاري تقديم الطلب...' : 'تقديم طلب شحن الرصيد (${totalPrice.toStringAsFixed(0)} ج.م)',
                            style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          onPressed: _isSubmitting ? null : () => _submitTopupRequest(unitPrice, branding),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),

                // Tab 2: Comparison (Standard vs Pro)
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildComparisonHeader(),
                      const SizedBox(height: 16),
                      _buildComparisonRow('دليل وقيد الطلاب وكروت الـ QR', true, true),
                      _buildComparisonRow('تسجيل الحضور السريع والمسح البصري', true, true),
                      _buildComparisonRow('الخزينة اليومية وطباعة الإيصالات', true, true),
                      _buildComparisonRow('إدارة المجموعات والقاعات والجداول', true, true),
                      _buildComparisonRow('منصة الكورسات الإلكترونية والفيديوهات', false, true),
                      _buildComparisonRow('تشفير الفيديو وحمايته ضد التسريب وسرقة الشاشة', false, true),
                      _buildComparisonRow('بوابة واتساب الآلية لإشعارات الغياب والفواتير', false, true),
                      _buildComparisonRow('كوكبيت المدرس ورصد الدرجات والتقييم اللحظي', false, true),
                      _buildComparisonRow('تحليلات متقدمة للأرباح والمصاريف وتقارير السنتر', false, true),
                      _buildComparisonRow('دعم فني خاص ونسخ احتياطي سحابي دائم', false, true),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),

                // Tab 3: Previous Requests
                requestsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('تعذر تحميل الطلبات: $e', style: GoogleFonts.cairo())),
                  data: (requests) {
                    if (requests.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.fileText, size: 48, color: Colors.grey.withOpacity(0.4)),
                            const SizedBox(height: 10),
                            Text('لا توجد طلبات شحن سابقة', style: GoogleFonts.cairo(color: Colors.grey)),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: requests.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (ctx, idx) {
                        final req = requests[idx] as Map<String, dynamic>;
                        final qty = req['quantity'] ?? 0;
                        final type = req['type'] ?? 'PRO';
                        final total = req['totalPriceEgp'] ?? 0;
                        final status = req['status'] ?? 'PENDING';
                        final created = req['createdAt']?.toString() ?? '';

                        Color statusCol = const Color(0xFFF59E0B);
                        String statusLabel = 'قيد المراجعة';
                        if (status == 'APPROVED') {
                          statusCol = const Color(0xFF10B981);
                          statusLabel = 'تم الشحن ✅';
                        } else if (status == 'REJECTED') {
                          statusCol = Colors.red;
                          statusLabel = 'مرفوض ❌';
                        }

                        return Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: statusCol.withOpacity(0.15),
                                  child: Icon(LucideIcons.wallet, color: statusCol, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'طلب شحن $qty طالب ($type)',
                                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13.5),
                                      ),
                                      Text(
                                        'المبلغ: $total ج.م • $created',
                                        style: GoogleFonts.cairo(fontSize: 11.5, color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusCol.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    statusLabel,
                                    style: GoogleFonts.cairo(color: statusCol, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanSelectionCard({
    required String title,
    required String subtitle,
    required String price,
    required bool isSelected,
    required bool isPro,
    required dynamic branding,
    required VoidCallback onTap,
  }) {
    final borderColor = isSelected ? (isPro ? const Color(0xFF8B5CF6) : branding.primaryColor) : Colors.grey.withOpacity(0.2);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? (isPro ? const Color(0xFF8B5CF6).withOpacity(0.08) : branding.primaryColor.withOpacity(0.08)) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(isPro ? LucideIcons.sparkles : LucideIcons.shieldCheck, size: 20, color: isPro ? const Color(0xFF8B5CF6) : branding.primaryColor),
                if (isSelected) const Icon(LucideIcons.checkCircle, size: 18, color: Color(0xFF10B981)),
              ],
            ),
            const SizedBox(height: 8),
            Text(title, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13)),
            Text(subtitle, style: GoogleFonts.cairo(fontSize: 10.5, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text(price, style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: isPro ? const Color(0xFF8B5CF6) : branding.primaryColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('الميزة / الوظيفة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12))),
          Expanded(flex: 1, child: Center(child: Text('عادي', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12)))),
          Expanded(flex: 1, child: Center(child: Text('برو 🌟', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12, color: const Color(0xFF8B5CF6))))),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(String feature, bool inStandard, bool inPro) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(feature, style: GoogleFonts.cairo(fontSize: 12)),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: inStandard
                  ? const Icon(LucideIcons.check, size: 16, color: Color(0xFF10B981))
                  : const Icon(LucideIcons.x, size: 16, color: Colors.grey),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: inPro
                  ? const Icon(LucideIcons.check, size: 16, color: Color(0xFF8B5CF6))
                  : const Icon(LucideIcons.x, size: 16, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
