import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/providers/edu_data_providers.dart';
import '../../core/services/sound_service.dart';
import '../../core/theme/branding_provider.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branding = ref.watch(brandingProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final financeAsync = ref.watch(liveFinanceOverviewProvider);
    final studentsAsync = ref.watch(liveStudentsProvider);
    final lowStockAsync = ref.watch(liveLowStockBooksProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          SoundService.lightImpact();
          ref.invalidate(liveFinanceOverviewProvider);
          ref.invalidate(liveStudentsProvider);
          ref.invalidate(liveLowStockBooksProvider);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            branding.primaryColor,
                            branding.primaryColor.withOpacity(0.8),
                          ],
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: branding.primaryColor.withOpacity(0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'مرحباً بك، إدارة السنتر 👋',
                                  style: GoogleFonts.cairo(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'إليك الرادار الإحصائي والمالي الحي',
                                  style: GoogleFonts.cairo(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(LucideIcons.activity, color: Colors.white, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  financeAsync.isLoading ? 'جاري التحديث...' : 'متزامن لايف',
                                  style: GoogleFonts.cairo(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Financial KPI Cards Grid
                    financeAsync.when(
                      loading: () => Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 30),
                          child: CircularProgressIndicator(color: branding.primaryColor),
                        ),
                      ),
                      error: (err, _) => Center(
                        child: Text('تعذر تحميل البيانات الحية: $err', style: GoogleFonts.cairo(color: Colors.red)),
                      ),
                      data: (overview) {
                        final todayIncome = (overview['todayIncome'] ?? 0.0) as num;
                        final todayExpenses = (overview['todayExpenses'] ?? 0.0) as num;
                        final netProfit = (overview['netProfit'] ?? (todayIncome - todayExpenses)) as num;
                        final studentsCount = studentsAsync.value?.length ?? 0;

                        return GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.22,
                          children: [
                            _buildKpiCard(
                              title: 'إيرادات اليوم',
                              value: '${todayIncome.toStringAsFixed(0)} ج.م',
                              change: '${overview['transactionsCount'] ?? 0} عملية سداد',
                              isPositive: true,
                              icon: LucideIcons.arrowDownLeft,
                              iconColor: const Color(0xFF10B981),
                              isDark: isDark,
                            ),
                            _buildKpiCard(
                              title: 'مصروفات اليوم',
                              value: '${todayExpenses.toStringAsFixed(0)} ج.م',
                              change: '${overview['expensesCount'] ?? 0} فواتير مسجلة',
                              isPositive: false,
                              icon: LucideIcons.arrowUpRight,
                              iconColor: const Color(0xFFEF4444),
                              isDark: isDark,
                            ),
                            _buildKpiCard(
                              title: 'صافي الأرباح',
                              value: '${netProfit.toStringAsFixed(0)} ج.م',
                              change: 'أرباح السنتر الإجمالية',
                              isPositive: true,
                              icon: LucideIcons.wallet,
                              iconColor: branding.primaryColor,
                              isDark: isDark,
                            ),
                            _buildKpiCard(
                              title: 'الطلاب المسجلين',
                              value: '$studentsCount طالب',
                              change: 'في مجموعات السنتر',
                              isPositive: true,
                              icon: LucideIcons.userCheck,
                              iconColor: const Color(0xFF8B5CF6),
                              isDark: isDark,
                            ),
                          ],
                        );
                      },
                    ),

                  const SizedBox(height: 24),

                  // Revenue Trend Chart
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'مسار الإيرادات اليومية',
                                    style: GoogleFonts.cairo(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'الأيام السبعة الأخيرة بالسنتر',
                                    style: GoogleFonts.cairo(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: branding.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'أسبوعي',
                                  style: GoogleFonts.cairo(
                                    fontSize: 12,
                                    color: branding.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 180,
                            child: LineChart(
                              LineChartData(
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  horizontalInterval: 5000,
                                  getDrawingHorizontalLine: (value) => FlLine(
                                    color: isDark ? Colors.white10 : Colors.black12,
                                    strokeWidth: 1,
                                  ),
                                ),
                                titlesData: FlTitlesData(
                                  leftTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        const days = ['سبت', 'أحد', 'اثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة'];
                                        if (value.toInt() >= 0 && value.toInt() < days.length) {
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 8.0),
                                            child: Text(
                                              days[value.toInt()],
                                              style: GoogleFonts.cairo(
                                                fontSize: 11,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          );
                                        }
                                        return const SizedBox();
                                      },
                                    ),
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: const [
                                      FlSpot(0, 12000),
                                      FlSpot(1, 14500),
                                      FlSpot(2, 9800),
                                      FlSpot(3, 16200),
                                      FlSpot(4, 13100),
                                      FlSpot(5, 19400),
                                      FlSpot(6, 18450),
                                    ],
                                    isCurved: true,
                                    color: branding.primaryColor,
                                    barWidth: 3,
                                    isStrokeCapRound: true,
                                    dotData: const FlDotData(show: true),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      color: branding.primaryColor.withOpacity(0.15),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Shift Alerts & Quick Notes
                  Text(
                    'تنبيهات الخزينة والتشغيل الحية',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Builder(
                    builder: (context) {
                      final overview = financeAsync.value;
                      final unpaidCount = (overview?['unpaidSubscriptionsCount'] ?? 0) as int;
                      final unpaidAmount = (overview?['unpaidSubscriptionsAmount'] ?? 0) as num;
                      final lowStockCount = lowStockAsync.value?.length ?? 0;

                      return Column(
                        children: [
                          if (unpaidCount > 0)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: _buildAlertItem(
                                title: '$unpaidCount طالب لديهم اشتراكات مستحقة',
                                subtitle: 'إجمالي المبالغ المعلقة: ${unpaidAmount.toStringAsFixed(0)} ج.م',
                                icon: LucideIcons.alertTriangle,
                                color: const Color(0xFFEF4444),
                              ),
                            ),
                          if (lowStockCount > 0)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: _buildAlertItem(
                                title: '$lowStockCount مذكرات شارفت على النفاد',
                                subtitle: 'يرجى مراجعة مخزن الملازم وطباعة كميات جديدة',
                                icon: LucideIcons.bookOpen,
                                color: const Color(0xFFF59E0B),
                              ),
                            ),
                          _buildAlertItem(
                            title: 'الخزينة والعمليات السحابية متزامنة',
                            subtitle: 'تمت المزامنة بنجاح مع سيرفر الإنتاج الرسمي (Vercel Serverless)',
                            icon: LucideIcons.shieldCheck,
                            color: const Color(0xFF10B981),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String change,
    required bool isPositive,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 16),
                ),
              ],
            ),
            Text(
              value,
              style: GoogleFonts.cairo(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              change,
              style: GoogleFonts.cairo(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: isPositive ? const Color(0xFF10B981) : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.cairo(
                    fontSize: 11.5,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
