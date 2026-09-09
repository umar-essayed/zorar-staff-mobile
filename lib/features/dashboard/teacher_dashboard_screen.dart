import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/network/edu_api_service.dart';
import '../../core/providers/edu_data_providers.dart';
import '../../core/theme/branding_provider.dart';
import '../auth/auth_provider.dart';
import '../teacher/live_class_cockpit_screen.dart';
import '../teacher/teacher_earnings_screen.dart';
import '../platform/platform_analytics_screen.dart';

class TeacherDashboardScreen extends ConsumerStatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  ConsumerState<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends ConsumerState<TeacherDashboardScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _portalData;

  @override
  void initState() {
    super.initState();
    _loadPortalData();
  }

  Future<void> _loadPortalData() async {
    setState(() => _isLoading = true);
    try {
      final res = await EduApiService().getTeacherPortalStats();
      if (mounted) {
        setState(() {
          _portalData = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(brandingProvider);
    final auth = ref.watch(authProvider);
    final teacherName = auth.user?.name ?? 'المعلم';

    final stats = _portalData?['stats'] as Map<String, dynamic>? ?? {};
    final groupsFromApi = (_portalData?['groups'] as List<dynamic>?) ?? [];
    final coursesFromApi = (_portalData?['courses'] as List<dynamic>?) ?? [];

    final fallbackGroups = ref.watch(liveGroupsProvider).value ?? [];
    final displayedGroups = groupsFromApi.isNotEmpty ? groupsFromApi : fallbackGroups;

    final totalStudents = parseInt(stats['totalStudents'] ?? stats['totalStudentsCount']) > 0
        ? parseInt(stats['totalStudents'] ?? stats['totalStudentsCount'])
        : displayedGroups.fold<int>(
            0,
            (sum, g) =>
                sum +
                parseInt(g['studentsCount'] ?? g['_count']?['students'] ?? 0));
    final sessionsThisMonth = parseInt(stats['sessionsThisMonth'] ?? 0);
    final unsettledEarnings = parseDouble(stats['walletBalance'] ?? stats['unsettledEarnings'] ?? stats['earnings'] ?? 0);
    final onlineCoursesCount = parseInt(stats['onlineCoursesCount'] ?? coursesFromApi.length);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'بوابة المعلم الذكية',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.barChart2),
            tooltip: 'إحصائيات طلابي',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PlatformAnalyticsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(LucideIcons.refreshCw),
            tooltip: 'تحديث البيانات',
            onPressed: () {
              _loadPortalData();
              ref.invalidate(liveGroupsProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadPortalData();
          ref.invalidate(liveGroupsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Teacher Welcome Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      branding.primaryColor,
                      const Color(0xFF047857),
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
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: const Icon(LucideIcons.graduationCap, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'أهلاً بك، أ/ $teacherName',
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'متابعة الحصص الميدانية • رصد الواجبات • المنصة',
                            style: GoogleFonts.cairo(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Teacher Live Stats
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'إجمالي طلابي',
                      value: '$totalStudents طالب',
                      icon: LucideIcons.users,
                      color: branding.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatCard(
                      title: 'حصص الشهر',
                      value: '$sessionsThisMonth حصة',
                      icon: LucideIcons.bookOpen,
                      color: const Color(0xFF3B82F6),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatCard(
                      title: 'أرباح مستحقة',
                      value: '${unsettledEarnings.toStringAsFixed(0)} ج.م',
                      icon: LucideIcons.wallet,
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Today's / Active Teaching Groups
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'مجموعاتي الميدانية بالسنتر',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${displayedGroups.length} مجموعة',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (_isLoading && displayedGroups.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (displayedGroups.isEmpty)
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Center(
                      child: Text('لا توجد مجموعات مسجلة باسمك حالياً بالسنتر'),
                    ),
                  ),
                )
              else
                ...displayedGroups.map((group) {
                  final gid = group['id']?.toString() ?? '';
                  final gName = group['name']?.toString() ?? 'مجموعة';
                  final count = parseInt(group['studentsCount'] ?? group['_count']?['students'] ?? 0);
                  final room = group['room']?.toString() ?? 'القاعة الرئيسية';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: branding.primaryColor.withOpacity(0.3), width: 1.2),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: branding.primaryColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'مجموعة نشطة',
                                    style: GoogleFonts.cairo(
                                      color: branding.primaryColor,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Text(
                                  '$count طالب مسجل',
                                  style: GoogleFonts.cairo(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              gName,
                              style: GoogleFonts.cairo(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'مكان الحضور: $room',
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: branding.primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(LucideIcons.checkSquare, size: 18),
                                label: const Text('رصد درجات وواجب الحصة'),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (ctx) => LiveClassCockpitScreen(
                                        groupId: gid,
                                        groupName: gName,
                                        sessionNumber: 1,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

              if (coursesFromApi.isNotEmpty) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'كورساتي على المنصة الأونلاين',
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$onlineCoursesCount كورس',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...coursesFromApi.map((c) {
                  final cTitle = c['title'] ?? 'كورس أونلاين';
                  final lessonsCount = (c['chapters'] as List?)?.fold<int>(
                        0,
                        (sum, ch) => sum + ((ch['lessons'] as List?)?.length ?? 0),
                      ) ??
                      0;

                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFE0E7FF),
                        child: Icon(LucideIcons.video, color: Color(0xFF4338CA), size: 20),
                      ),
                      title: Text(cTitle, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13.5)),
                      subtitle: Text('$lessonsCount حصة فيديو مسجلة', style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey)),
                    ),
                  );
                }),
              ],

              const SizedBox(height: 16),

              // Link to Earnings
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) => const TeacherEarningsScreen(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.fileSpreadsheet, color: Color(0xFFF59E0B), size: 24),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'كشف الأرباح والعمولات والتسويات',
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'عرض الحصص والمبالغ المسددة ونسب السنتر والعمولة',
                              style: GoogleFonts.cairo(
                                fontSize: 11.5,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(LucideIcons.chevronLeft, color: Color(0xFFF59E0B)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.cairo(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              title,
              style: GoogleFonts.cairo(
                fontSize: 10.5,
                color: Colors.grey,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
