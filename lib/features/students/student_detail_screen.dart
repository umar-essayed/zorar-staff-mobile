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
import '../cashier/mobile_pos_screen.dart';

class StudentDetailScreen extends ConsumerStatefulWidget {
  final String studentCode;
  final String studentName;
  final String? studentId;

  const StudentDetailScreen({
    super.key,
    required this.studentCode,
    required this.studentName,
    this.studentId,
  });

  @override
  ConsumerState<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends ConsumerState<StudentDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _effectiveStudentId;
  bool _isLoadingId = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _effectiveStudentId = widget.studentId;

    if (_effectiveStudentId == null || _effectiveStudentId!.isEmpty) {
      _resolveStudentId();
    }
  }

  Future<void> _resolveStudentId() async {
    setState(() => _isLoadingId = true);
    try {
      final students = await EduApiService().getStudents(search: widget.studentCode);
      if (students.isNotEmpty) {
        final match = students.firstWhere(
          (s) => s['studentCode']?.toString() == widget.studentCode,
          orElse: () => students.first,
        );
        if (mounted) {
          setState(() {
            _effectiveStudentId = match['id']?.toString();
            _isLoadingId = false;
          });
        }
        return;
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoadingId = false);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(brandingProvider);

    if (_isLoadingId) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.studentName, style: GoogleFonts.cairo(fontWeight: FontWeight.bold))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final targetId = _effectiveStudentId ?? '';
    final profileAsync = targetId.isNotEmpty
        ? ref.watch(liveStudentProfileProvider(targetId))
        : const AsyncValue.data(null);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'الملف الشامل للطالب',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 20),
            tooltip: 'تحديث البيانات',
            onPressed: () {
              if (targetId.isNotEmpty) {
                ref.invalidate(liveStudentProfileProvider(targetId));
              }
            },
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.alertCircle, size: 48, color: Colors.amber),
              const SizedBox(height: 12),
              Text('تعذر تحميل بيانات الطالب: $err', style: GoogleFonts.cairo(fontSize: 14)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(liveStudentProfileProvider(targetId)),
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
        data: (profile) {
          final student = profile ?? {};
          final name = student['name']?.toString() ?? widget.studentName;
          final code = student['studentCode']?.toString() ?? widget.studentCode;
          final gradeName = student['academicYear']?['name']?.toString() ?? 'غير محدد';
          final phone = student['phone']?.toString() ?? '-';
          final guardianPhone = student['guardianPhone']?.toString() ?? '-';
          final schoolName = student['schoolName']?.toString() ?? 'غير مسجل';
          final walletBalance = parseDouble(student['walletBalance']);
          final points = parseInt(student['points']);
          final groups = (student['groups'] as List?) ?? [];
          final monthlySubs = (student['monthlySubs'] as List?) ?? [];
          final transactions = (student['transactions'] as List?) ?? [];
          final attendances = (student['attendances'] as List?) ?? [];
          final assessments = (student['assessments'] as List?) ?? [];

          return Column(
            children: [
              // Student Header Card
              Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).cardColor,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: branding.primaryColor.withOpacity(0.15),
                      child: Text(
                        name.isNotEmpty ? name[0] : 'ط',
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
                          Text(
                            name,
                            style: GoogleFonts.cairo(fontSize: 15.5, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: branding.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  code,
                                  style: GoogleFonts.cairo(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: branding.primaryColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  gradeName,
                                  style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        backgroundColor: branding.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(LucideIcons.receipt, size: 16),
                      label: const Text('سداد POS'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (ctx) => MobilePosScreen(initialStudentCode: code),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // 4 Sub-Tabs
              TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: branding.primaryColor,
                unselectedLabelColor: Colors.grey,
                indicatorColor: branding.primaryColor,
                labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12),
                unselectedLabelStyle: GoogleFonts.cairo(fontSize: 11.5),
                tabs: const [
                  Tab(text: 'نظرة عامة', icon: Icon(LucideIcons.user, size: 18)),
                  Tab(text: 'المجموعات', icon: Icon(LucideIcons.layers, size: 18)),
                  Tab(text: 'الماليات والفواتير', icon: Icon(LucideIcons.wallet, size: 18)),
                  Tab(text: 'الحضور والدرجات', icon: Icon(LucideIcons.calendarCheck, size: 18)),
                ],
              ),

              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(
                      context: context,
                      phone: phone,
                      guardianPhone: guardianPhone,
                      schoolName: schoolName,
                      studentName: name,
                      studentCode: code,
                      gradeName: gradeName,
                      points: points,
                      walletBalance: walletBalance,
                      primaryColor: branding.primaryColor,
                      centerName: branding.centerName,
                      videoWatchLogs: (student['videoWatchLogs'] as List?) ?? [],
                      examSubmissions: (student['examSubmissions'] as List?) ?? [],
                    ),
                    _buildGroupsTab(groups, branding.primaryColor),
                    _buildFinancesTab(monthlySubs, transactions, walletBalance, branding.primaryColor, code),
                    _buildAttendanceTab(attendances, assessments, branding.primaryColor),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOverviewTab({
    required BuildContext context,
    required String phone,
    required String guardianPhone,
    required String schoolName,
    required String studentName,
    required String studentCode,
    required String gradeName,
    required int points,
    required double walletBalance,
    required Color primaryColor,
    required String centerName,
    List videoWatchLogs = const [],
    List examSubmissions = const [],
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Balance & Points Strip
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primaryColor.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.award, color: primaryColor, size: 24),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('نقاط الالتزام', style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey)),
                          Text('$points نقطة', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: primaryColor)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.wallet, color: Color(0xFF10B981), size: 24),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('رصيد المحفظة', style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey)),
                          Text('${walletBalance.toStringAsFixed(0)} ج.م', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF10B981))),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildInfoTile('هاتف الطالب المباشر', phone, LucideIcons.phone),
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(LucideIcons.messageSquare, size: 20, color: Color(0xFF10B981)),
              title: Text('واتساب ولي الأمر', style: GoogleFonts.cairo(fontSize: 11.5, color: Colors.grey)),
              subtitle: Text(guardianPhone, style: GoogleFonts.cairo(fontSize: 13.5, fontWeight: FontWeight.bold)),
              trailing: IconButton(
                icon: const Icon(LucideIcons.send, color: Color(0xFF10B981), size: 20),
                tooltip: 'إرسال رسالة واتساب لولي الأمر',
                onPressed: () {
                  WhatsAppService.sendAbsenceAlert(
                    context: context,
                    parentPhone: guardianPhone,
                    studentName: studentName,
                    subjectName: 'المتابعة الدورية',
                    groupName: gradeName,
                    centerName: centerName,
                  );
                },
              ),
            ),
          ),
          _buildInfoTile('المدرسة المقيد بها', schoolName, LucideIcons.building2),
          _buildInfoTile('المرحلة / الصف الدراسي', gradeName, LucideIcons.graduationCap),
          const SizedBox(height: 16),

          // Digital Platform & Video Watch Logs Card (سجل مشاهدات المنصة الرقمية والكويزات)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: primaryColor.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(LucideIcons.video, color: primaryColor, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'سجل مشاهدة المحاضرات الرقمية 🎥',
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${videoWatchLogs.length} حصة',
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (videoWatchLogs.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'لم يسجل الطالب مشاهدات للمحاضرات على المنصة بعد.',
                      style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey),
                    ),
                  )
                else
                  ...videoWatchLogs.take(5).map((log) {
                    final l = log['lesson'] is Map ? log['lesson'] : {};
                    final lTitle = l['title']?.toString() ?? 'محاضرة';
                    final durSec = (l['durationSeconds'] as num?)?.toInt() ?? 0;
                    final watchedSec = (log['watchedSeconds'] as num?)?.toInt() ?? 0;
                    final isCompleted = log['isCompleted'] == true;
                    final pct = durSec > 0 ? ((watchedSec / durSec) * 100).round().clamp(0, 100) : (isCompleted ? 100 : 0);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? const Color(0xFF10B981).withOpacity(0.06)
                            : Colors.grey.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isCompleted
                              ? const Color(0xFF10B981).withOpacity(0.2)
                              : Colors.grey.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  lTitle,
                                  style: GoogleFonts.cairo(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isCompleted
                                      ? const Color(0xFF10B981).withOpacity(0.15)
                                      : Colors.amber.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isCompleted ? 'حضور معتمد (40%+) ✅' : 'قيد المشاهدة ⏱️ ($pct%)',
                                  style: GoogleFonts.cairo(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: isCompleted ? const Color(0xFF10B981) : Colors.amber[800],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: pct / 100.0,
                              minHeight: 4,
                              backgroundColor: Colors.black12,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isCompleted ? const Color(0xFF10B981) : primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
          const SizedBox(height: 16),


          // Digital ID Card Preview Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF0F172A), const Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: primaryColor.withOpacity(0.4)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('كارت الهوية الرقمي للسنتر',
                        style: GoogleFonts.cairo(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                    Icon(LucideIcons.sparkles, color: primaryColor, size: 18),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(LucideIcons.qrCode, color: Colors.black, size: 75),
                      const SizedBox(height: 6),
                      Text(
                        studentCode,
                        style: GoogleFonts.cairo(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  studentName,
                  style: GoogleFonts.cairo(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                ),
                Text(
                  gradeName,
                  style: GoogleFonts.cairo(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupsTab(List groups, Color primaryColor) {
    if (groups.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.layers, size: 48, color: Colors.grey.withOpacity(0.5)),
            const SizedBox(height: 12),
            Text('الطالب غير مقيد في أي مجموعة حالياً', style: GoogleFonts.cairo(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: groups.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, idx) {
        final item = groups[idx];
        final g = item['group'] is Map ? item['group'] : item;
        final groupName = g['name']?.toString() ?? 'مجموعة دراسية';
        final teacherName = g['teacher']?['name']?.toString() ?? 'المحاضر';
        final subjectName = g['subject']?['name']?.toString() ?? 'المادة';
        final monthlyFee = parseDouble(g['monthlyFee'] ?? g['pricePerSession']);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        groupName,
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'مقيد ومفعل',
                        style: GoogleFonts.cairo(fontSize: 11, color: const Color(0xFF10B981), fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('$subjectName • المحاضر: $teacherName', style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey)),
                const Divider(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'الاشتراك الشهري: ${monthlyFee.toStringAsFixed(0)} ج.م',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12.5, color: primaryColor),
                    ),
                    const Icon(LucideIcons.checkCircle2, color: Color(0xFF10B981), size: 18),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFinancesTab(
    List monthlySubs,
    List transactions,
    double walletBalance,
    Color primaryColor,
    String studentCode,
  ) {
    final unpaidSubs = monthlySubs.where((s) => s['isPaid'] != true).toList();

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        // Status Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: unpaidSubs.isEmpty
                ? const Color(0xFF10B981).withOpacity(0.12)
                : Colors.amber.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: unpaidSubs.isEmpty
                  ? const Color(0xFF10B981).withOpacity(0.3)
                  : Colors.amber.withOpacity(0.4),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                unpaidSubs.isEmpty
                    ? 'الموقف المالي: مسدد بالكامل ✅'
                    : 'يوجد ${unpaidSubs.length} اشتراك شهري غير مسدد ⚠️',
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: unpaidSubs.isEmpty ? const Color(0xFF10B981) : Colors.amber[800],
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (ctx) => MobilePosScreen(initialStudentCode: studentCode)),
                  );
                },
                child: const Text('سداد'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (unpaidSubs.isNotEmpty) ...[
          Text('الاشتراكات الشهرية المستحقة للسداد', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13.5)),
          const SizedBox(height: 8),
          ...unpaidSubs.map((sub) {
            final grpName = sub['group']?['name']?.toString() ?? 'اشتراك شهري';
            final monthNo = sub['monthNumber']?.toString() ?? '1';
            final fee = parseDouble(sub['group']?['monthlyFee']);
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(LucideIcons.alertTriangle, color: Colors.amber),
                title: Text('$grpName (شهر $monthNo)', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Text('حالة السداد: غير مسدد ❌', style: GoogleFonts.cairo(fontSize: 11, color: Colors.red)),
                trailing: Text('${fee.toStringAsFixed(0)} ج.م', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13.5, color: Colors.red)),
              ),
            );
          }),
          const SizedBox(height: 12),
        ],

        Text('سجل المعاملات والإيصالات المسددة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        if (transactions.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('لا توجد معاملات مسجلة حتى الآن', style: GoogleFonts.cairo(color: Colors.grey)),
            ),
          )
        else
          ...transactions.map((tx) {
            final recNo = tx['receiptNo']?.toString() ?? 'REC';
            final desc = tx['description']?.toString() ?? 'سداد رسوم';
            final method = tx['method']?.toString() ?? 'CASH';
            final amount = parseDouble(tx['amount']);
            final dateStr = tx['createdAt']?.toString().split('T').first ?? '';

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(LucideIcons.receipt, color: Color(0xFF10B981)),
                title: Text(desc, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Text('$recNo • $method • $dateStr', style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey)),
                trailing: Text(
                  '${amount.toStringAsFixed(0)} ج.م',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF10B981)),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildAttendanceTab(List attendances, List assessments, Color primaryColor) {
    if (attendances.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.calendarX, size: 48, color: Colors.grey.withOpacity(0.5)),
            const SizedBox(height: 12),
            Text('لا توجد سجلات حضور مسجلة حتى الآن', style: GoogleFonts.cairo(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: attendances.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, idx) {
        final att = attendances[idx];
        final grpName = att['group']?['name']?.toString() ?? 'حصة دراسية';
        final sessionNum = att['session']?['sessionNumber'] ?? att['sessionNumber'];
        final sessionTopic = att['session']?['topic']?.toString();
        final sessionTitle = sessionNum != null
            ? 'حصة $sessionNum ${sessionTopic != null && sessionTopic.isNotEmpty ? "• $sessionTopic" : ""}'
            : '';
        final scannedAt = att['scannedAt']?.toString().split('T').first ?? '';
        final status = att['status']?.toString().toUpperCase() ?? 'PRESENT';
        final isPresent = status == 'PRESENT';
        final isLate = status == 'LATE';
        final isGrace = att['isGraceSession'] == true;
        final assessment = att['assessment'] as Map<String, dynamic>?;

        Color badgeColor;
        Color textColor;
        String badgeText;
        if (isGrace) {
          badgeColor = Colors.amber.withOpacity(0.15);
          textColor = Colors.amber[800]!;
          badgeText = 'حصة سماح ⚠️';
        } else if (isLate) {
          badgeColor = Colors.orange.withOpacity(0.15);
          textColor = Colors.orange[800]!;
          badgeText = 'حاضر متأخر ⚠️';
        } else if (isPresent) {
          badgeColor = const Color(0xFF10B981).withOpacity(0.12);
          textColor = const Color(0xFF10B981);
          badgeText = 'حاضر ✅';
        } else {
          badgeColor = Colors.red.withOpacity(0.12);
          textColor = Colors.red;
          badgeText = 'غائب ❌';
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(grpName, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13.5)),
                          if (sessionTitle.isNotEmpty)
                            Text(sessionTitle, style: GoogleFonts.cairo(fontSize: 11.5, color: Colors.grey[700])),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badgeText,
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('تاريخ الحضور: $scannedAt', style: GoogleFonts.cairo(fontSize: 11.5, color: Colors.grey)),
                if (assessment != null) ...[
                  const Divider(height: 16),
                  Row(
                    children: [
                      if (assessment['homeworkStatus'] != null) ...[
                        Text(
                          'الواجب: ${assessment['homeworkStatus'] == 'DONE' ? 'كامل وممتاز ⭐' : assessment['homeworkStatus'] == 'INCOMPLETE' ? 'ناقص ⚠️' : 'لم يسلم ❌'}',
                          style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 14),
                      ],
                      if (assessment['quizScore'] != null) ...[
                        Text(
                          'التسميع: ${assessment['quizScore']} / ${assessment['quizTotal'] ?? 10}',
                          style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor),
                        ),
                      ],
                    ],
                  ),
                  if (assessment['behaviorNotes'] != null && assessment['behaviorNotes'].toString().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'ملاحظة المعلم: ${assessment['behaviorNotes']}',
                      style: GoogleFonts.cairo(fontSize: 11.5, color: Colors.grey[700]),
                    ),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoTile(String title, String value, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, size: 20, color: Colors.grey),
        title: Text(title, style: GoogleFonts.cairo(fontSize: 11.5, color: Colors.grey)),
        subtitle: Text(value, style: GoogleFonts.cairo(fontSize: 13.5, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
