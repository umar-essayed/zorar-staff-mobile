import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:data_table_2/data_table_2.dart';
import '../../core/theme/branding_provider.dart';
import '../cashier/mobile_pos_screen.dart';
import 'student_detail_screen.dart';
import 'student_form_dialog.dart';

class StudentRecord {
  final String code;
  final String name;
  final String phone;
  final String parentPhone;
  final String group;
  final String status; // 'مسدد', 'سماح', 'متأخر'
  final double balance;

  StudentRecord({
    required this.code,
    required this.name,
    required this.phone,
    required this.parentPhone,
    required this.group,
    required this.status,
    required this.balance,
  });
}

class StudentsListScreen extends ConsumerStatefulWidget {
  const StudentsListScreen({super.key});

  @override
  ConsumerState<StudentsListScreen> createState() => _StudentsListScreenState();
}

class _StudentsListScreenState extends ConsumerState<StudentsListScreen> {
  String searchQuery = '';
  String statusFilter = 'الكل';

  // Sample database of students
  late final List<StudentRecord> allStudents = List.generate(120, (index) {
    final codeNum = 1000 + index;
    final names = [
      'محمود عبد الرازق حسن',
      'سلمى إبراهيم خليل',
      'عمر خالد المنشاوي',
      'يوسف مصطفى إبراهيم',
      'مريم أحمد الشناوي',
      'كريم طارق البنا',
      'فاطمة علي الدسوقي',
      'أحمد حسام البدري',
      'نور سامح العوضي',
      'زياد وليد النجار',
    ];
    final groups = ['3ث عربي (أ)', '2ث كيمياء (ب)', '1ث فيزياء (ج)', '3ث أحياء (د)'];
    final statuses = ['مسدد', 'مسدد', 'سماح', 'متأخر'];

    return StudentRecord(
      code: 'STU-$codeNum',
      name: names[index % names.length] + (index > 9 ? ' ($index)' : ''),
      phone: '010${(10000000 + index * 137).toString().substring(0, 8)}',
      parentPhone: '011${(20000000 + index * 149).toString().substring(0, 8)}',
      group: groups[index % groups.length],
      status: statuses[index % statuses.length],
      balance: statuses[index % statuses.length] == 'متأخر' ? 450.0 : 0.0,
    );
  });

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(brandingProvider);

    final filtered = allStudents.where((s) {
      if (statusFilter != 'الكل' && s.status != statusFilter) return false;
      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        return s.name.toLowerCase().contains(q) ||
            s.code.toLowerCase().contains(q) ||
            s.phone.contains(q) ||
            s.parentPhone.contains(q);
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'دليل الطلاب وجداول القيد',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.userPlus),
            tooltip: 'إضافة طالب جديد',
            onPressed: () {
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
            padding: const EdgeInsets.all(12),
            color: Theme.of(context).cardColor,
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'ابحث بالاسم، الكود، هاتف الطالب أو ولي الأمر...',
                    prefixIcon: Icon(LucideIcons.search, size: 20),
                    isDense: true,
                  ),
                  onChanged: (val) => setState(() => searchQuery = val),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildFilterBadge('الكل (${allStudents.length})', 'الكل'),
                    const SizedBox(width: 8),
                    _buildFilterBadge('مسدد بالكامل 🟢', 'مسدد'),
                    const SizedBox(width: 8),
                    _buildFilterBadge('فترة سماح 🟡', 'سماح'),
                    const SizedBox(width: 8),
                    _buildFilterBadge('متأخر 🔴', 'متأخر'),
                  ],
                ),
              ],
            ),
          ),

          // High Performance Data Table with Frozen Columns
          Expanded(
            child: Theme(
              data: Theme.of(context).copyWith(
                dividerColor: Colors.grey.withOpacity(0.15),
              ),
              child: DataTable2(
                columnSpacing: 16,
                horizontalMargin: 12,
                minWidth: 700, // Enables horizontal scrolling while keeping header & first column clean
                fixedLeftColumns: 1, // Frozen First Column for Student Code & Name!
                headingRowColor: WidgetStateProperty.all(
                  branding.primaryColor.withOpacity(0.08),
                ),
                headingTextStyle: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5,
                  color: branding.primaryColor,
                ),
                columns: const [
                  DataColumn2(
                    label: Text('الكود والاسم (ثابت)'),
                    size: ColumnSize.L,
                    fixedWidth: 200,
                  ),
                  DataColumn2(
                    label: Text('المجموعة'),
                    size: ColumnSize.M,
                  ),
                  DataColumn2(
                    label: Text('الحالة المالية'),
                    size: ColumnSize.S,
                  ),
                  DataColumn2(
                    label: Text('هاتف الطالب'),
                    size: ColumnSize.M,
                  ),
                  DataColumn2(
                    label: Text('هاتف ولي الأمر'),
                    size: ColumnSize.M,
                  ),
                  DataColumn2(
                    label: Text('إجراء سريع'),
                    size: ColumnSize.S,
                  ),
                ],
                rows: List<DataRow2>.generate(filtered.length, (index) {
                  final s = filtered[index];
                  return DataRow2(
                    cells: [
                      // Frozen Column: Name + Code
                      DataCell(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              s.name,
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              s.code,
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                color: Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (ctx) => StudentDetailScreen(
                                studentCode: s.code,
                                studentName: s.name,
                              ),
                            ),
                          );
                        },
                      ),
                      DataCell(
                        Text(
                          s.group,
                          style: GoogleFonts.cairo(fontSize: 12),
                        ),
                      ),
                      DataCell(_buildStatusBadge(s.status)),
                      DataCell(
                        Text(
                          s.phone,
                          style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey[700]),
                        ),
                      ),
                      DataCell(
                        Text(
                          s.parentPhone,
                          style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey[700]),
                        ),
                      ),
                      DataCell(
                        IconButton(
                          icon: const Icon(LucideIcons.receipt, size: 18),
                          tooltip: 'تحصيل سريع (POS)',
                          color: branding.primaryColor,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (ctx) => const MobilePosScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBadge(String label, String value) {
    final isSelected = statusFilter == value;
    final branding = ref.watch(brandingProvider);

    return InkWell(
      onTap: () => setState(() => statusFilter = value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? branding.primaryColor : Colors.grey.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : null,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    switch (status) {
      case 'مسدد':
        bg = const Color(0xFF10B981).withOpacity(0.12);
        fg = const Color(0xFF10B981);
        break;
      case 'سماح':
        bg = const Color(0xFFF59E0B).withOpacity(0.12);
        fg = const Color(0xFFF59E0B);
        break;
      default:
        bg = const Color(0xFFEF4444).withOpacity(0.12);
        fg = const Color(0xFFEF4444);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: GoogleFonts.cairo(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }
}
