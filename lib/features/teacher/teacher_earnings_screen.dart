import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/providers/edu_data_providers.dart';
import '../../core/theme/branding_provider.dart';
import '../../core/utils/numeric_utils.dart';
import '../auth/auth_provider.dart';

class TeacherEarningsScreen extends ConsumerWidget {
  final String? teacherId;
  final String? teacherName;

  const TeacherEarningsScreen({
    super.key,
    this.teacherId,
    this.teacherName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branding = ref.watch(brandingProvider);
    final user = ref.watch(authProvider).user;
    final txAsync = ref.watch(liveTransactionsProvider);
    final groupsAsync = ref.watch(liveGroupsProvider);

    final currentTeacherName = teacherName ?? user?.name ?? 'المعلم';
    final txData = txAsync.value ?? {};
    final txList = (txData['transactions'] as List?) ?? [];

    // Filter transactions for this teacher if specified
    final filteredTxs = txList.where((tx) {
      if (teacherId != null && teacherId!.isNotEmpty) {
        final tId = tx['teacherId']?.toString() ?? tx['teacher']?['id']?.toString();
        final gTeacherId = tx['group']?['teacherId']?.toString();
        if (tId != null && tId.isNotEmpty) {
          return tId == teacherId;
        }
        if (gTeacherId != null && gTeacherId.isNotEmpty) {
          return gTeacherId == teacherId;
        }
      }
      return true;
    }).toList();

    // Calculate total earnings from transactions
    double totalCollected = 0.0;
    for (final tx in filteredTxs) {
      totalCollected += parseDouble(tx['amount']);
    }

    final myGroups = (groupsAsync.value ?? []).where((g) {
      if (teacherId != null && teacherId!.isNotEmpty) {
        return g['teacherId']?.toString() == teacherId;
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
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: branding.primaryColor.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'إجمالي التحصيلات المسجلة للشهر الجاري',
                    style: GoogleFonts.cairo(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${totalCollected.toStringAsFixed(0)} ج.م',
                    style: GoogleFonts.cairo(
                      color: branding.primaryColor,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
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
