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
import 'student_detail_screen.dart';
import 'student_form_dialog.dart';

class StudentsListScreen extends ConsumerStatefulWidget {
  const StudentsListScreen({super.key});

  @override
  ConsumerState<StudentsListScreen> createState() => _StudentsListScreenState();
}

class _StudentsListScreenState extends ConsumerState<StudentsListScreen> {
  final _searchCtrl = TextEditingController();
  String _statusFilter = 'ALL';
  bool _isTableView = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(brandingProvider);
    final studentsAsync = ref.watch(liveStudentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'دليل وقيد الطلاب',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(_isTableView ? LucideIcons.layoutGrid : LucideIcons.tableProperties),
            tooltip: _isTableView ? 'عرض البطاقات' : 'عرض الجدول التفصيلي',
            onPressed: () {
              SoundService.lightImpact();
              setState(() => _isTableView = !_isTableView);
            },
          ),
          IconButton(
            icon: const Icon(LucideIcons.userPlus),
            tooltip: 'إضافة طالب جديد',
            onPressed: () {
              SoundService.lightImpact();
              showDialog(
                context: context,
                builder: (ctx) => const StudentFormDialog(),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.15))),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  onChanged: (val) {
                    ref.read(studentsSearchQueryProvider.notifier).state = val.trim();
                  },
                  decoration: InputDecoration(
                    hintText: 'ابحث بالاسم، الكود، هاتف الطالب أو ولي الأمر...',
                    prefixIcon: const Icon(LucideIcons.search, size: 18),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(LucideIcons.x, size: 16),
                            onPressed: () {
                              _searchCtrl.clear();
                              ref.read(studentsSearchQueryProvider.notifier).state = '';
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('الكل', 'ALL', branding),
                      const SizedBox(width: 8),
                      _buildFilterChip('مسدد', 'PAID', branding),
                      const SizedBox(width: 8),
                      _buildFilterChip('سماح', 'GRACE', branding),
                      const SizedBox(width: 8),
                      _buildFilterChip('متأخرات', 'LATE', branding),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Students Data List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(liveStudentsProvider);
              },
              child: studentsAsync.when(
                data: (students) {
                  // Filter by status if applied
                  final filtered = students.where((s) {
                    if (_statusFilter == 'ALL') return true;
                    final balance = parseDouble(s['walletBalance']);
                    if (_statusFilter == 'LATE' && balance < 0) return true;
                    if (_statusFilter == 'PAID' && balance >= 0) return true;
                    return true;
                  }).toList();

                  if (filtered.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
                      children: [
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.users, size: 54, color: Colors.grey.withOpacity(0.4)),
                              const SizedBox(height: 12),
                              Text(
                                'لا يوجد طلاب مطابقين للبحث',
                                style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(backgroundColor: branding.primaryColor),
                                icon: const Icon(LucideIcons.userPlus, size: 16),
                                label: const Text('تسجيل أول طالب الآن'),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => const StudentFormDialog(),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  if (_isTableView) {
                    return _buildHorizontalScrollViewTable(filtered, branding);
                  }

                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(14),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) {
                      final student = filtered[i];
                      return _buildStudentCard(student, branding);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
                  children: [
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(LucideIcons.alertCircle, color: Colors.red, size: 40),
                          const SizedBox(height: 8),
                          Text('تعذر تحميل بيانات الطلاب من السيرفر', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => ref.invalidate(liveStudentsProvider),
                            child: const Text('إعادة المحاولة'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, dynamic branding) {
    final isSelected = _statusFilter == value;
    return ChoiceChip(
      label: Text(label, style: GoogleFonts.cairo(fontSize: 11.5, fontWeight: FontWeight.bold)),
      selected: isSelected,
      selectedColor: branding.primaryColor,
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.grey[700]),
      onSelected: (sel) {
        if (sel) {
          SoundService.lightImpact();
          setState(() => _statusFilter = value);
        }
      },
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student, dynamic branding) {
    final name = student['name'] ?? 'بدون اسم';
    final code = student['studentCode'] ?? student['code'] ?? 'STU-000';
    final phone = student['phone'] ?? '';
    final guardianPhone = student['guardianPhone'] ?? phone;
    final yearName = student['academicYear']?['name'] ?? 'غير محدد';
    final balance = parseDouble(student['walletBalance']);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showStudentActionsModal(context, student, branding),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: branding.primaryColor.withOpacity(0.12),
                    child: Text(
                      name.isNotEmpty ? name[0] : 'ط',
                      style: GoogleFonts.cairo(
                        color: branding.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.cairo(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'كود: $code',
                                style: GoogleFonts.cairo(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              yearName,
                              style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.moreVertical, size: 20),
                    onPressed: () => _showStudentActionsModal(context, student, branding),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.phone, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Text(phone.isNotEmpty ? phone : guardianPhone, style: GoogleFonts.cairo(fontSize: 11.5, color: Colors.grey[700])),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: balance >= 0 ? const Color(0xFF10B981).withOpacity(0.12) : const Color(0xFFEF4444).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          balance >= 0 ? 'مسدد بالكامل' : 'متبقي ${balance.abs()} ج.م',
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: balance >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(LucideIcons.messageCircle, size: 18, color: Color(0xFF10B981)),
                        tooltip: 'واتساب ولي الأمر',
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          if (guardianPhone.isNotEmpty) {
                            WhatsAppService.sendCustomMessage(
                              context,
                              phone: guardianPhone,
                              message: 'السلام عليكم، رسالة من ${branding.centerName} بخصوص الطالب $name.',
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalScrollViewTable(List<Map<String, dynamic>> students, dynamic branding) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.withOpacity(0.2)),
          ),
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(branding.primaryColor.withOpacity(0.08)),
            columns: const [
              DataColumn(label: Text('كود الطالب')),
              DataColumn(label: Text('اسم الطالب')),
              DataColumn(label: Text('السنة الدراسية')),
              DataColumn(label: Text('رقم ولي الأمر')),
              DataColumn(label: Text('الحالة المالية')),
              DataColumn(label: Text('إجراءات')),
            ],
            rows: students.map((s) {
              final name = s['name'] ?? '';
              final code = s['studentCode'] ?? s['code'] ?? '';
              final year = s['academicYear']?['name'] ?? '-';
              final guardian = s['guardianPhone'] ?? s['phone'] ?? '';
              final balance = parseDouble(s['walletBalance']);

              return DataRow(
                cells: [
                  DataCell(Text(code, style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Text(name)),
                  DataCell(Text(year)),
                  DataCell(Text(guardian)),
                  DataCell(
                    Text(
                      balance >= 0 ? 'مسدد' : 'متأخر',
                      style: TextStyle(
                        color: balance >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(LucideIcons.eye, size: 18),
                          tooltip: 'عرض الملف الكامل',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (ctx) => StudentDetailScreen(studentCode: code, studentName: name),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.wallet, size: 18),
                          tooltip: 'تحصيل بالخزينة',
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
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _showStudentActionsModal(BuildContext context, Map<String, dynamic> student, dynamic branding) {
    final name = student['name'] ?? 'طالب';
    final code = student['studentCode'] ?? student['code'] ?? '';
    final phone = student['phone'] ?? '';
    final guardianPhone = student['guardianPhone'] ?? phone;
    final yearName = student['academicYear']?['name'] ?? 'غير محدد';
    final balance = parseDouble(student['walletBalance']);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: branding.primaryColor.withOpacity(0.12),
                    child: Text(
                      name.isNotEmpty ? name[0] : 'ط',
                      style: GoogleFonts.cairo(
                        fontSize: 18,
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
                        Text(name, style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text('كود: $code • $yearName', style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: balance >= 0 ? const Color(0xFF10B981).withOpacity(0.12) : const Color(0xFFEF4444).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      balance >= 0 ? 'مسدد' : 'متبقي ${balance.abs()} ج.م',
                      style: GoogleFonts.cairo(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: balance >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(height: 1),
              const SizedBox(height: 14),

              // Action 1: View Full Profile
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: branding.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(LucideIcons.user, color: branding.primaryColor, size: 20),
                ),
                title: Text('عرض الملف الأكاديمي والمالي الشامل', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13.5)),
                subtitle: Text('بيانات الكارت الذكي QR، سجل الحضور، واشتراكات الشهور', style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey)),
                trailing: const Icon(LucideIcons.chevronLeft, size: 18),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (c) => StudentDetailScreen(studentCode: code, studentName: name),
                    ),
                  );
                },
              ),

              // Action 2: Collect Money via POS
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(LucideIcons.receipt, color: Color(0xFF10B981), size: 20),
                ),
                title: Text('تحصيل اشتراك أو رسوم (نقطة البيع POS)', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13.5)),
                subtitle: Text('فتح شاشة الكاشير لسداد المصروفات وطباعة الإيصال', style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey)),
                trailing: const Icon(LucideIcons.chevronLeft, size: 18),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (c) => MobilePosScreen(initialStudentCode: code),
                    ),
                  );
                },
              ),

              // Action 3: WhatsApp Guardian
              if (guardianPhone.isNotEmpty)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(LucideIcons.messageCircle, color: Color(0xFF25D366), size: 20),
                  ),
                  title: Text('مراسلة ولي الأمر عبر واتساب', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  subtitle: Text(guardianPhone, style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey)),
                  trailing: const Icon(LucideIcons.chevronLeft, size: 18),
                  onTap: () {
                    Navigator.pop(ctx);
                    WhatsAppService.sendCustomMessage(
                      context,
                      phone: guardianPhone,
                      message: 'السلام عليكم، رسالة من إدارة ${branding.centerName} بخصوص الطالب $name.',
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
