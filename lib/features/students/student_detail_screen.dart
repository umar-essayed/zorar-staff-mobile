import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/services/sound_service.dart';
import '../../core/services/whatsapp_service.dart';
import '../../core/theme/branding_provider.dart';
import '../cashier/mobile_pos_screen.dart';

class StudentDetailScreen extends ConsumerStatefulWidget {
  final String studentCode;
  final String studentName;

  const StudentDetailScreen({
    super.key,
    required this.studentCode,
    required this.studentName,
  });

  @override
  ConsumerState<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends ConsumerState<StudentDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(brandingProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'الملف الشامل للطالب',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.messageSquare),
            tooltip: 'إرسال تنبيه واتساب لولي الأمر',
            onPressed: () {
              WhatsAppService.sendAbsenceAlert(
                context: context,
                parentPhone: '01012345678',
                studentName: widget.studentName,
                subjectName: 'اللغة العربية',
                groupName: '3ث لغة عربية (أ)',
                centerName: branding.centerName,
              );
            },
          ),
          IconButton(
            icon: const Icon(LucideIcons.printer),
            tooltip: 'طباعة كارت الطالب',
            onPressed: () {
              SoundService.successFeedback();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFF10B981),
                  content: Text('جاري إرسال كارت ${widget.studentName} إلى طابعة البلوتوث...'),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Student Header Card
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).cardColor,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: branding.primaryColor.withOpacity(0.15),
                  child: Text(
                    widget.studentName.isNotEmpty ? widget.studentName[0] : 'ط',
                    style: GoogleFonts.cairo(
                      fontSize: 24,
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
                        widget.studentName,
                        style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: branding.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              widget.studentCode,
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: branding.primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'الصف الثالث الثانوي',
                            style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  icon: const Icon(LucideIcons.receipt, size: 16),
                  label: const Text('سداد'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (ctx) => const MobilePosScreen()),
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
            labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12.5),
            unselectedLabelStyle: GoogleFonts.cairo(fontSize: 12),
            tabs: const [
              Tab(text: 'نظرة عامة', icon: Icon(LucideIcons.user, size: 18)),
              Tab(text: 'المجموعات', icon: Icon(LucideIcons.layers, size: 18)),
              Tab(text: 'الماليات والمدفوعات', icon: Icon(LucideIcons.wallet, size: 18)),
              Tab(text: 'سجل الحضور', icon: Icon(LucideIcons.calendarCheck, size: 18)),
            ],
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(context, branding.primaryColor),
                _buildGroupsTab(context, branding.primaryColor),
                _buildFinancesTab(context, branding.primaryColor),
                _buildAttendanceTab(context, branding.primaryColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(BuildContext context, Color primaryColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoTile('هاتف الطالب', '01012345678', LucideIcons.phone),
          _buildInfoTile('هاتف ولي الأمر (واتساب)', '01198765432', LucideIcons.messageSquare),
          _buildInfoTile('المدرسة الحالية', 'مدرسة المتفوقين الثانوية بنين', LucideIcons.building2),
          _buildInfoTile('تاريخ القيد بالسنتر', '15 أغسطس 2026', LucideIcons.calendar),
          _buildInfoTile('العنوان / المنطقة', 'مدينة نصر - القاهرة', LucideIcons.mapPin),
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
                      Icon(LucideIcons.qrCode, color: Colors.black, size: 80),
                      const SizedBox(height: 6),
                      Text(
                        widget.studentCode,
                        style: GoogleFonts.cairo(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.studentName,
                  style: GoogleFonts.cairo(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupsTab(BuildContext context, Color primaryColor) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _buildGroupCard(
          groupName: '3ث لغة عربية (المجموعة الأولى)',
          teacher: 'أ/ أحمد كمال',
          schedule: 'السبت والثلاثاء (02:00 م - 04:00 م)',
          room: 'قاعة (1)',
          fee: '450 ج.م / شهر',
          primaryColor: primaryColor,
        ),
        const SizedBox(height: 10),
        _buildGroupCard(
          groupName: '3ث كيمياء (مجموعة المتفوقين)',
          teacher: 'أ/ حسام فؤاد',
          schedule: 'الأحد والأربعاء (04:30 م - 06:30 م)',
          room: 'قاعة (2)',
          fee: '420 ج.م / شهر',
          primaryColor: primaryColor,
        ),
      ],
    );
  }

  Widget _buildFinancesTab(BuildContext context, Color primaryColor) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        // Balance Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الموقف المالي الحالي: مسدد بالكامل ✅',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF10B981)),
              ),
              Text(
                '0.0 ج.م متبقي',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text('سجل الفواتير والإيصالات المسددة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 10),
        _buildReceiptItem('REC-9021', 'اشتراك شهر سبتمبر (4 حصص)', '450 ج.م', 'كاش', '01 سبتمبر 2026'),
        _buildReceiptItem('REC-8840', 'ملزمة النحو الشاملة 2026', '85 ج.م', 'فودافون كاش', '25 أغسطس 2026'),
        _buildReceiptItem('REC-8112', 'رسوم استمارة الحجز والقيد', '100 ج.م', 'كاش', '15 أغسطس 2026'),
      ],
    );
  }

  Widget _buildAttendanceTab(BuildContext context, Color primaryColor) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _buildAttendanceRow('حصة 5: مراجعة النصوص والبلاغة', '05 سبتمبر 2026', 'حاضر (02:04 م)', true),
        _buildAttendanceRow('حصة 4: تدريبات النحو الشاملة', '02 سبتمبر 2026', 'حاضر (02:00 م)', true),
        _buildAttendanceRow('حصة 3: مدرسة الإحياء والبعث', '29 أغسطس 2026', 'حاضر متأخر (02:22 م)', true),
        _buildAttendanceRow('حصة 2: شرح الاستعارة والكناية', '26 أغسطس 2026', 'غائب بعذر (مرضي)', false),
      ],
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

  Widget _buildGroupCard({
    required String groupName,
    required String teacher,
    required String schedule,
    required String room,
    required String fee,
    required Color primaryColor,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(groupName, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 4),
            Text('$teacher • $room', style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(schedule, style: GoogleFonts.cairo(fontSize: 11.5, color: Colors.grey[700])),
            const Divider(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('الاشتراك الشهري: $fee',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12.5, color: primaryColor)),
                const Icon(LucideIcons.checkCircle2, color: Color(0xFF10B981), size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptItem(String id, String title, String amount, String method, String date) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(LucideIcons.receipt, color: Color(0xFF10B981)),
        title: Text(title, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Text('$id • $method • $date', style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey)),
        trailing: Text(amount,
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF10B981))),
      ),
    );
  }

  Widget _buildAttendanceRow(String title, String date, String status, bool isPresent) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          isPresent ? LucideIcons.checkCircle2 : LucideIcons.xCircle,
          color: isPresent ? const Color(0xFF10B981) : Colors.red,
        ),
        title: Text(title, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Text(date, style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey)),
        trailing: Text(status,
            style: GoogleFonts.cairo(
                fontSize: 12, fontWeight: FontWeight.bold, color: isPresent ? const Color(0xFF10B981) : Colors.red)),
      ),
    );
  }
}
