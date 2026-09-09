import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/network/edu_api_service.dart';
import '../../core/providers/edu_data_providers.dart';
import '../../core/theme/branding_provider.dart';
import '../../core/utils/numeric_utils.dart';
import '../auth/auth_provider.dart';

class TeacherEarningsScreen extends ConsumerStatefulWidget {
  final String? teacherId;
  final String? teacherName;

  const TeacherEarningsScreen({
    super.key,
    this.teacherId,
    this.teacherName,
  });

  @override
  ConsumerState<TeacherEarningsScreen> createState() => _TeacherEarningsScreenState();
}

class _TeacherEarningsScreenState extends ConsumerState<TeacherEarningsScreen> {
  Map<String, dynamic>? _portalStats;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadPortalStats();
  }

  Future<void> _loadPortalStats() async {
    setState(() => _isLoadingStats = true);
    try {
      final user = ref.read(authProvider).user;
      final resolvedTeacherId = widget.teacherId ?? user?.teacherId;
      final res = await EduApiService().getTeacherPortalStats(
        teacherId: resolvedTeacherId,
      );
      if (mounted) setState(() => _portalStats = res);
    } catch (_) {}
    if (mounted) setState(() => _isLoadingStats = false);
  }

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(brandingProvider);
    final user = ref.watch(authProvider).user;
    final txAsync = ref.watch(liveTransactionsProvider);
    final groupsAsync = ref.watch(liveGroupsProvider);

    final resolvedTeacherId = widget.teacherId ?? user?.teacherId;
    final currentTeacherName = widget.teacherName ?? user?.name ?? 'المعلم';

    final txData = txAsync.value ?? {};
    final txList = (txData['transactions'] as List?) ?? [];

    // Filter transactions for this teacher if teacherId is known
    final filteredTxs = resolvedTeacherId != null && resolvedTeacherId.isNotEmpty
        ? txList.where((tx) {
            final tId = tx['teacherId']?.toString() ?? tx['teacher']?['id']?.toString();
            final gTeacherId = tx['group']?['teacherId']?.toString();
            if (tId != null && tId.isNotEmpty) return tId == resolvedTeacherId;
            if (gTeacherId != null && gTeacherId.isNotEmpty) return gTeacherId == resolvedTeacherId;
            return false;
          }).toList()
        : txList;

    // Use walletBalance from portal stats (authoritative) — fallback to sum of filtered txs
    final portalStats = (_portalStats?['stats'] as Map<String, dynamic>?) ?? {};
    final rawWalletBalance = parseDouble(portalStats['walletBalance']);
    final unsettledEarnings = parseDouble(portalStats['unsettledEarnings']);
    final totalEarnings = parseDouble(portalStats['totalEarnings']);
    final totalRevenueCollected = parseDouble(portalStats['totalRevenueCollected']);
    final totalPaidOut = parseDouble(portalStats['totalPaidOut']);

    // Fallback if portal stats not loaded or 0
    double totalCollected = 0.0;
    for (final tx in filteredTxs) {
      totalCollected += parseDouble(tx['amount']);
    }

    double displayBalance = 0.0;
    if (rawWalletBalance > 0) {
      displayBalance = rawWalletBalance;
    } else if (unsettledEarnings > 0) {
      displayBalance = unsettledEarnings;
    } else if (totalEarnings > 0) {
      displayBalance = (totalEarnings - totalPaidOut).clamp(0.0, 9999999.0);
    } else {
      displayBalance = totalCollected;
    }

    final myGroups = (groupsAsync.value ?? []).where((g) {
      if (resolvedTeacherId != null && resolvedTeacherId.isNotEmpty) {
        return g['teacherId']?.toString() == resolvedTeacherId;
      }
      return true;
    }).toList();

    int totalStudents = 0;
    for (final g in myGroups) {
      totalStudents += parseInt(g['studentsCount'] ?? g['_count']?['students']);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'مستحقات وكشف حساب $currentTeacherName',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 20),
            onPressed: () {
              _loadPortalStats();
              ref.invalidate(liveTransactionsProvider);
              ref.invalidate(liveGroupsProvider);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Net Earnings Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [branding.primaryColor.withOpacity(0.9), branding.primaryColor],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: _isLoadingStats
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'صافي المستحقات غير المستلمة',
                          style: GoogleFonts.cairo(color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${displayBalance.toStringAsFixed(0)} ج.م',
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (totalRevenueCollected > 0 || totalPaidOut > 0)
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'إجمالي التحصيل: ${totalRevenueCollected.toStringAsFixed(0)} ج.م',
                                  style: GoogleFonts.cairo(
                                    color: Colors.white,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'مصروف: ${totalPaidOut.toStringAsFixed(0)} ج.م',
                                style: GoogleFonts.cairo(color: Colors.white70, fontSize: 11.5),
                              ),
                            ],
                          )
                        else
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'المجموعات المفعلة: ${myGroups.length}',
                                  style: GoogleFonts.cairo(
                                    color: const Color(0xFF10B981),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'إجمالي الطلاب: $totalStudents طالب',
                                style: GoogleFonts.cairo(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                      ],
                    ),
            ),

            const SizedBox(height: 24),
            Text(
              'سجل المعاملات والتحصيلات الأخيرة',
              style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            if (filteredTxs.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(LucideIcons.receipt, size: 48, color: Colors.grey.withOpacity(0.4)),
                      const SizedBox(height: 12),
                      Text('لا توجد حركات تحصيل مسجلة بعد', style: GoogleFonts.cairo(color: Colors.grey)),
                    ],
                  ),
                ),
              )
            else
              ...filteredTxs.map((tx) {
                final desc = tx['description']?.toString() ?? 'تحصيل مالي';
                final amount = parseDouble(tx['amount']);
                final date = tx['createdAt']?.toString().split('T').first ?? '';
                final recNo = tx['receiptNo']?.toString() ?? '';
                final method = tx['method']?.toString() ?? 'CASH';

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF10B981).withOpacity(0.12),
                      child: const Icon(LucideIcons.receipt, color: Color(0xFF10B981), size: 20),
                    ),
                    title: Text(desc, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13.5)),
                    subtitle: Text('$recNo • $method • $date', style: GoogleFonts.cairo(fontSize: 11.5, color: Colors.grey)),
                    trailing: Text(
                      '${amount.toStringAsFixed(0)} ج.م',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF10B981)),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
