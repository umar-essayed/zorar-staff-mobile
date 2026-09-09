import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/network/edu_api_service.dart';
import '../../core/theme/branding_provider.dart';
import '../../core/utils/numeric_utils.dart';

class AssistantProfileDetailScreen extends ConsumerStatefulWidget {
  final String staffId;
  final String? initialName;
  final String? initialRole;
  final String? initialPhone;

  const AssistantProfileDetailScreen({
    super.key,
    required this.staffId,
    this.initialName,
    this.initialRole,
    this.initialPhone,
  });

  @override
  ConsumerState<AssistantProfileDetailScreen> createState() => _AssistantProfileDetailScreenState();
}

class _AssistantProfileDetailScreenState extends ConsumerState<AssistantProfileDetailScreen> with SingleTickerProviderStateMixin {
  String _selectedRange = 'today';
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _profileData;
  late TabController _tabController;

  final Map<String, String> _ranges = {
    'today': 'اليوم',
    'week': 'آخر 7 أيام',
    'month': 'هذا الشهر',
    'all': 'منذ البداية',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await EduApiService().getStaffActivityProfile(
        widget.staffId,
        timeRange: _selectedRange,
      );
      if (mounted) {
        setState(() {
          _profileData = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _formatRole(String? role) {
    switch (role?.toUpperCase()) {
      case 'ADMIN':
        return 'مدير النظام';
      case 'ASSISTANT':
        return 'مساعد إداري وميداني';
      case 'CASHIER':
        return 'أمين خزينة وكاشير';
      case 'DATA_ENTRY':
        return 'مدخل بيانات';
      default:
        return 'عضو فريق';
    }
  }

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(brandingProvider);
    final staff = _profileData?['staff'] as Map<String, dynamic>?;
    final stats = _profileData?['stats'] as Map<String, dynamic>?;

    final displayName = staff?['name'] ?? widget.initialName ?? 'الموظف';
    final role = _formatRole(staff?['role'] ?? widget.initialRole);
    final phone = staff?['phone'] ?? widget.initialPhone ?? '-';
    final isActive = staff?['isActive'] ?? true;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'الملف الوظيفي وسجل النشاط',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 20),
            tooltip: 'تحديث',
            onPressed: _loadProfile,
          ),
        ],
      ),
      body: _isLoading && _profileData == null
          ? Center(child: CircularProgressIndicator(color: branding.primaryColor))
          : _errorMessage != null && _profileData == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.alertCircle, size: 48, color: Colors.red),
                        const SizedBox(height: 12),
                        Text(
                          'تعذر تحميل الملف الوظيفي',
                          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadProfile,
                          icon: const Icon(LucideIcons.refreshCw, size: 18),
                          label: Text('إعادة المحاولة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                )
              : NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [
                      SliverToBoxAdapter(
                        child: Column(
                          children: [
                            // 1. Staff Header Banner
                            Container(
                              margin: const EdgeInsets.all(16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.withOpacity(0.15)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.02),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 28,
                                        backgroundColor: branding.primaryColor.withOpacity(0.12),
                                        child: Text(
                                          displayName.isNotEmpty ? displayName[0] : 'U',
                                          style: GoogleFonts.cairo(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: branding.primaryColor,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    displayName,
                                                    style: GoogleFonts.cairo(fontSize: 17, fontWeight: FontWeight.bold),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: isActive ? Colors.green.withOpacity(0.12) : Colors.red.withOpacity(0.12),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    isActive ? 'نشط' : 'معطّل',
                                                    style: GoogleFonts.cairo(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: isActive ? Colors.green : Colors.red,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '$role • $phone',
                                              style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey[700]),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  // Time Range Filter Bar
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: _ranges.entries.map((entry) {
                                        final isSelected = _selectedRange == entry.key;
                                        return Padding(
                                          padding: const EdgeInsets.only(left: 8.0),
                                          child: ChoiceChip(
                                            label: Text(
                                              entry.value,
                                              style: GoogleFonts.cairo(
                                                fontSize: 12,
                                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                color: isSelected ? Colors.white : Colors.grey[800],
                                              ),
                                            ),
                                            selected: isSelected,
                                            selectedColor: branding.primaryColor,
                                            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                                            onSelected: (selected) {
                                              if (selected && _selectedRange != entry.key) {
                                                setState(() => _selectedRange = entry.key);
                                                _loadProfile();
                                              }
                                            },
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // 2. KPI Summary Grid
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final isTablet = constraints.maxWidth > 500;
                                  return Wrap(
                                    spacing: 12,
                                    runSpacing: 12,
                                    children: [
                                      _buildKpiCard(
                                        context,
                                        title: 'حضور الطلاب',
                                        value: '${stats?['attendanceScans'] ?? 0} طالب',
                                        subtitle: 'تم مسح بطاقاتهم',
                                        icon: LucideIcons.qrCode,
                                        iconColor: const Color(0xFF3B82F6),
                                        width: isTablet ? (constraints.maxWidth - 24) / 3 : (constraints.maxWidth - 12) / 2,
                                      ),
                                      _buildKpiCard(
                                        context,
                                        title: 'تحصيلات الخزينة',
                                        value: '${NumericUtils.formatCurrency(stats?['cashCollected'] ?? 0)} ج.م',
                                        subtitle: '${stats?['posInvoicesCount'] ?? 0} فاتورة مقبوضة',
                                        icon: LucideIcons.banknote,
                                        iconColor: const Color(0xFF10B981),
                                        width: isTablet ? (constraints.maxWidth - 24) / 3 : (constraints.maxWidth - 12) / 2,
                                      ),
                                      _buildKpiCard(
                                        context,
                                        title: 'الخصومات الممنوحة',
                                        value: '${NumericUtils.formatCurrency(stats?['discountsGiven'] ?? 0)} ج.م',
                                        subtitle: 'تخفيضات استثنائية',
                                        icon: LucideIcons.badgePercent,
                                        iconColor: const Color(0xFFF59E0B),
                                        width: isTablet ? (constraints.maxWidth - 24) / 3 : (constraints.maxWidth - 12) / 2,
                                      ),
                                      _buildKpiCard(
                                        context,
                                        title: 'المصروفات المسجلة',
                                        value: '${NumericUtils.formatCurrency(stats?['expensesRecorded'] ?? 0)} ج.م',
                                        subtitle: 'سحبيات ونثريات',
                                        icon: LucideIcons.receipt,
                                        iconColor: const Color(0xFFEF4444),
                                        width: isTablet ? (constraints.maxWidth - 24) / 3 : (constraints.maxWidth - 12) / 2,
                                      ),
                                      _buildKpiCard(
                                        context,
                                        title: 'العمليات اللحظية',
                                        value: '${stats?['auditActionsCount'] ?? 0} عملية',
                                        subtitle: 'سجل نشاط حي',
                                        icon: LucideIcons.activity,
                                        iconColor: const Color(0xFF8B5CF6),
                                        width: isTablet ? (constraints.maxWidth - 24) / 3 : (constraints.maxWidth - 12) / 2,
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _TabBarHeaderDelegate(
                          TabBar(
                            controller: _tabController,
                            indicatorColor: branding.primaryColor,
                            labelColor: branding.primaryColor,
                            unselectedLabelColor: Colors.grey,
                            labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
                            unselectedLabelStyle: GoogleFonts.cairo(fontSize: 12),
                            tabs: const [
                              Tab(text: 'حضور المجموعات'),
                              Tab(text: 'التحصيلات والخصم'),
                              Tab(text: 'سجل العمليات'),
                              Tab(text: 'المصروفات والبيانات'),
                            ],
                          ),
                          Theme.of(context).scaffoldBackgroundColor,
                        ),
                      ),
                    ];
                  },
                  body: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildGroupsScannedTab(),
                      _buildCollectionsTab(),
                      _buildAuditTimelineTab(),
                      _buildExpensesAndInfoTab(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildKpiCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.cairo(fontSize: 11.5, color: Colors.grey[700]),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.cairo(fontSize: 10.5, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupsScannedTab() {
    final groups = (_profileData?['groupsScanned'] as List?) ?? [];
    if (groups.isEmpty) {
      return _buildEmptyState(
        icon: LucideIcons.calendarX,
        title: 'لا يوجد حضور مسجل في هذه الفترة',
        subtitle: 'لم يقم الموظف بمسح أي كروت أو أكواد في المجموعات خلال الفترة المحددة.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: groups.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, idx) {
        final g = groups[idx] as Map<String, dynamic>;
        final groupName = g['name'] ?? 'مجموعة بدون اسم';
        final teacherName = g['teacher']?['name'] ?? 'غير محدد';
        final grade = g['academicYear']?['name'] ?? '';
        final scanCount = g['scanCount'] ?? 0;

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.withOpacity(0.15)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(LucideIcons.users, color: Color(0xFF3B82F6), size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(groupName, style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold)),
                      Text(
                        'المعلم: $teacherName ${grade.isNotEmpty ? '• $grade' : ''}',
                        style: GoogleFonts.cairo(fontSize: 11.5, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$scanCount',
                        style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF3B82F6)),
                      ),
                      Text('طالب حاضر', style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCollectionsTab() {
    final invoices = (_profileData?['recentInvoices'] as List?) ?? [];
    final discounts = (_profileData?['discountsList'] as List?) ?? [];

    if (invoices.isEmpty && discounts.isEmpty) {
      return _buildEmptyState(
        icon: LucideIcons.receipt,
        title: 'لا توجد فواتير أو تحصيلات مسجلة',
        subtitle: 'لم يقم هذا الموظف بتحصيل أي رسوم أو منح خصومات خلال الفترة المحددة.',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (discounts.isNotEmpty) ...[
          Text(
            'تنبيه: سجل الخصومات والتخفيضات الممنوحة',
            style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFFF59E0B)),
          ),
          const SizedBox(height: 8),
          ...discounts.map((d) {
            final studentName = d['studentName'] ?? 'طالب';
            final discountVal = d['discount'] ?? 0;
            final invoiceNumber = d['invoiceNumber'] ?? '';
            final paidAt = d['paidAt'] != null ? DateFormat('hh:mm a - yyyy/MM/dd').format(DateTime.parse(d['paidAt'])) : '';

            return Card(
              color: Colors.amber.withOpacity(0.05),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.amber.withOpacity(0.3)),
              ),
              child: ListTile(
                leading: const Icon(LucideIcons.badgePercent, color: Color(0xFFF59E0B)),
                title: Text(studentName, style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold)),
                subtitle: Text('فاتورة #$invoiceNumber • $paidAt', style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey)),
                trailing: Text(
                  'خصم: $discountVal ج.م',
                  style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.red),
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
        ],

        Text(
          'أحدث الفواتير والمقبوضات',
          style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...invoices.map((inv) {
          final invoiceNumber = inv['invoiceNumber'] ?? '';
          final total = inv['total'] ?? 0;
          final studentName = inv['studentName'] ?? 'غير معروف';
          final method = inv['paymentMethod'] ?? 'CASH';
          final paidAt = inv['paidAt'] != null ? DateFormat('hh:mm a - yyyy/MM/dd').format(DateTime.parse(inv['paidAt'])) : '';

          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: Colors.grey.withOpacity(0.15)),
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(LucideIcons.checkCircle2, color: Color(0xFF10B981), size: 18),
              ),
              title: Text('$studentName • #$invoiceNumber', style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold)),
              subtitle: Text('$method • $paidAt', style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey)),
              trailing: Text(
                '${NumericUtils.formatCurrency(total)} ج.م',
                style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF10B981)),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAuditTimelineTab() {
    final logs = (_profileData?['auditTimeline'] as List?) ?? [];
    if (logs.isEmpty) {
      return _buildEmptyState(
        icon: LucideIcons.shieldAlert,
        title: 'لا توجد سجلات عمليات لحظية',
        subtitle: 'لم يتم تسجيل إجراءات في سجل التدقيق للموظف في هذا النطاق الزمني.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: logs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, idx) {
        final item = logs[idx] as Map<String, dynamic>;
        final action = item['action']?.toString() ?? 'إجراء';
        final entity = item['entity']?.toString() ?? '';
        final createdAt = item['createdAt'] != null
            ? DateFormat('hh:mm:ss a - yyyy/MM/dd').format(DateTime.parse(item['createdAt']))
            : '';

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: Colors.grey.withOpacity(0.15)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(LucideIcons.activity, size: 16, color: Colors.purple),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(action, style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold)),
                      if (entity.isNotEmpty)
                        Text('الكيان: $entity', style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey[700])),
                    ],
                  ),
                ),
                Text(
                  createdAt,
                  style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExpensesAndInfoTab() {
    final expenses = (_profileData?['expensesList'] as List?) ?? [];
    final staff = _profileData?['staff'] as Map<String, dynamic>?;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (expenses.isNotEmpty) ...[
          Text('المصروفات والسحبيات المسجلة', style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...expenses.map((e) {
            final desc = e['description'] ?? 'مصروف';
            final amount = e['amount'] ?? 0;
            final date = e['paidAt'] != null ? DateFormat('yyyy/MM/dd').format(DateTime.parse(e['paidAt'])) : '';

            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.red.withOpacity(0.2)),
              ),
              child: ListTile(
                leading: const Icon(LucideIcons.receipt, color: Colors.red),
                title: Text(desc, style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold)),
                subtitle: Text(date, style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey)),
                trailing: Text(
                  '${NumericUtils.formatCurrency(amount)} ج.م',
                  style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.red),
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
        ],

        Text('معلومات الحساب والصلاحيات', style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.withOpacity(0.15)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                _buildInfoRow('معرّف الموظف (ID)', staff?['id']?.toString() ?? widget.staffId),
                const Divider(),
                _buildInfoRow('رقم الهاتف للتواصل', staff?['phone']?.toString() ?? widget.initialPhone ?? '-'),
                const Divider(),
                _buildInfoRow('المسمى الوظيفي', _formatRole(staff?['role'] ?? widget.initialRole)),
                const Divider(),
                _buildInfoRow(
                  'تاريخ الانضمام',
                  staff?['createdAt'] != null
                      ? DateFormat('yyyy/MM/dd').format(DateTime.parse(staff!['createdAt']))
                      : 'غير مسجل',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey[700])),
          Text(value, style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Colors.grey.withOpacity(0.4)),
            const SizedBox(height: 12),
            Text(title, style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[800])),
            const SizedBox(height: 6),
            Text(subtitle, textAlign: TextAlign.center, style: GoogleFonts.cairo(fontSize: 11.5, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _TabBarHeaderDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  final Color _bgColor;

  _TabBarHeaderDelegate(this._tabBar, this._bgColor);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: _bgColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarHeaderDelegate oldDelegate) {
    return false;
  }
}
