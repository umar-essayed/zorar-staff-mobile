import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/network/edu_api_service.dart';
import '../../core/providers/edu_data_providers.dart';
import '../../core/services/sound_service.dart';
import '../../core/theme/branding_provider.dart';
import '../auth/auth_provider.dart';
import 'exam_details_screen.dart';
import 'exam_form_screen.dart';

class ExamsManagementScreen extends ConsumerStatefulWidget {
  const ExamsManagementScreen({super.key});

  @override
  ConsumerState<ExamsManagementScreen> createState() => _ExamsManagementScreenState();
}

class _ExamsManagementScreenState extends ConsumerState<ExamsManagementScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedGroupId = 'الكل';
  String _statusFilter = 'الكل'; // 'الكل', 'نشط', 'مجدول', 'منتهي', 'مسودة'

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(brandingProvider);
    final user = ref.watch(authProvider).user;
    final examsAsync = ref.watch(liveExamsProvider);
    final groupsAsync = ref.watch(liveGroupsProvider);

    final groups = groupsAsync.value ?? [];
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'مدير الامتحانات الإلكترونية',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 20),
            onPressed: () => ref.invalidate(liveExamsProvider),
            tooltip: 'تحديث القائمة',
          ),
        ],
      ),
      floatingActionButton: (user?.isAdmin == true || user?.isTeacher == true || (user?.isAssistant ?? false))
          ? FloatingActionButton.extended(
              backgroundColor: branding.primaryColor,
              foregroundColor: Colors.white,
              icon: const Icon(LucideIcons.plus, size: 20),
              label: Text('إنشاء امتحان جديد', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
              onPressed: () async {
                final res = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (ctx) => const ExamFormScreen()),
                );
                if (res == true) {
                  ref.invalidate(liveExamsProvider);
                }
              },
            )
          : null,
      body: Column(
        children: [
          // Filter Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Theme.of(context).cardColor,
            child: Column(
              children: [
                // Search field
                TextField(
                  controller: _searchCtrl,
                  onChanged: (val) {
                    ref.read(examsSearchQueryProvider.notifier).state = val.trim();
                  },
                  decoration: InputDecoration(
                    hintText: 'البحث عن اسم الامتحان أو المادة...',
                    prefixIcon: const Icon(LucideIcons.search, size: 18),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(LucideIcons.x, size: 16),
                            onPressed: () {
                              _searchCtrl.clear();
                              ref.read(examsSearchQueryProvider.notifier).state = '';
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 10),

                // Group & Status Dropdowns
                Row(
                  children: [
                    // Group Filter
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<String>(
                        value: _selectedGroupId,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'المجموعة',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        items: [
                          const DropdownMenuItem(value: 'الكل', child: Text('جميع المجموعات', overflow: TextOverflow.ellipsis)),
                          ...groups.map((g) => DropdownMenuItem(
                                value: g['id'].toString(),
                                child: Text(g['name']?.toString() ?? '', overflow: TextOverflow.ellipsis),
                              )),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedGroupId = val);
                            ref.read(examsSelectedGroupFilterProvider.notifier).state = val == 'الكل' ? null : val;
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Status Filter
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: _statusFilter,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'الحالة',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'الكل', child: Text('الكل')),
                          DropdownMenuItem(value: 'نشط', child: Text('نشط')),
                          DropdownMenuItem(value: 'مجدول', child: Text('مجدول')),
                          DropdownMenuItem(value: 'منتهي', child: Text('منتهي')),
                          DropdownMenuItem(value: 'مسودة', child: Text('مسودة')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _statusFilter = val);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Exams List Body
          Expanded(
            child: examsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.alertCircle, size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    Text('فشل تحميل قائمة الامتحانات', style: GoogleFonts.cairo(fontSize: 16)),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      icon: const Icon(LucideIcons.refreshCw, size: 16),
                      label: Text('إعادة المحاولة', style: GoogleFonts.cairo()),
                      onPressed: () => ref.invalidate(liveExamsProvider),
                    ),
                  ],
                ),
              ),
              data: (examsList) {
                // Apply client-side status filter
                final filteredExams = examsList.where((e) {
                  final isPublished = e['isPublished'] ?? true;
                  final availableFrom = e['availableFrom'] != null ? DateTime.tryParse(e['availableFrom'].toString()) : null;
                  final availableUntil = e['availableUntil'] != null ? DateTime.tryParse(e['availableUntil'].toString()) : null;

                  String status = 'نشط';
                  if (!isPublished) {
                    status = 'مسودة';
                  } else if (availableFrom != null && availableFrom.isAfter(now)) {
                    status = 'مجدول';
                  } else if (availableUntil != null && availableUntil.isBefore(now)) {
                    status = 'منتهي';
                  }

                  if (_statusFilter == 'الكل') return true;
                  return status == _statusFilter;
                }).toList();

                if (filteredExams.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.fileQuestion, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text('لا توجد امتحانات مطابقة للمحددات', style: GoogleFonts.cairo(fontSize: 16, color: Colors.grey[600])),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          icon: const Icon(LucideIcons.plus, size: 18),
                          label: Text('إنشاء أول امتحان إلكتروني', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (ctx) => const ExamFormScreen()),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredExams.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, idx) {
                    final exam = filteredExams[idx];
                    return _buildExamCard(context, exam, branding.primaryColor, now);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamCard(BuildContext context, Map<String, dynamic> exam, Color primaryColor, DateTime now) {
    final isPublished = exam['isPublished'] ?? true;
    final questionsCount = exam['questionsCount'] ?? (exam['questions'] is List ? (exam['questions'] as List).length : 0);
    final submissionsCount = exam['submissionsCount'] ?? (exam['submissions'] is List ? (exam['submissions'] as List).length : 0);
    final duration = exam['duration'] ?? 60;
    final totalMarks = exam['totalMarks'] ?? 100;

    final availableFrom = exam['availableFrom'] != null ? DateTime.tryParse(exam['availableFrom'].toString()) : null;
    final availableUntil = exam['availableUntil'] != null ? DateTime.tryParse(exam['availableUntil'].toString()) : null;

    String statusText = 'نشط';
    Color statusColor = Colors.green;
    IconData statusIcon = LucideIcons.checkCircle;

    if (!isPublished) {
      statusText = 'مسودة';
      statusColor = Colors.grey;
      statusIcon = LucideIcons.fileEdit;
    } else if (availableFrom != null && availableFrom.isAfter(now)) {
      statusText = 'مجدول';
      statusColor = Colors.blue;
      statusIcon = LucideIcons.clock;
    } else if (availableUntil != null && availableUntil.isBefore(now)) {
      statusText = 'منتهي';
      statusColor = Colors.red;
      statusIcon = LucideIcons.xCircle;
    }

    final groupName = exam['group']?['name']?.toString() ?? 'جميع المجموعات';
    final subjectName = exam['subject']?['name']?.toString() ?? '';
    final teacherName = exam['teacher']?['name']?.toString() ?? '';

    final dateFormat = DateFormat('yyyy/MM/dd');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          final res = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (ctx) => ExamDetailsScreen(examId: exam['id'].toString()),
            ),
          );
          if (res == true) {
            ref.invalidate(liveExamsProvider);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Title & Status Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exam['title']?.toString() ?? '',
                          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        if (subjectName.isNotEmpty || teacherName.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              [if (subjectName.isNotEmpty) subjectName, if (teacherName.isNotEmpty) teacherName].join(' • '),
                              style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 12, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Badges Row (Group, Questions, Submissions, Duration)
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _buildBadge(LucideIcons.users, groupName, Colors.indigo),
                  _buildBadge(LucideIcons.helpCircle, '$questionsCount سؤال', Colors.teal),
                  _buildBadge(LucideIcons.send, '$submissionsCount تسليم', Colors.purple),
                  _buildBadge(LucideIcons.clock, '$duration دقيقة', Colors.orange),
                  _buildBadge(LucideIcons.award, '$totalMarks درجة', Colors.amber[800]!),
                ],
              ),

              if (availableFrom != null || availableUntil != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(LucideIcons.calendar, size: 13, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      'الإتاحة: ${availableFrom != null ? dateFormat.format(availableFrom) : 'الآن'} - ${availableUntil != null ? dateFormat.format(availableUntil) : 'مفتوح'}',
                      style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}
