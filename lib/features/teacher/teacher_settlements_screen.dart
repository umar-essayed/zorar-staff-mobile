import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/network/edu_api_service.dart';
import '../../core/providers/edu_data_providers.dart';
import '../../core/services/sound_service.dart';
import '../../core/theme/branding_provider.dart';
import '../../core/utils/numeric_utils.dart';

class TeacherSettlementsScreen extends ConsumerStatefulWidget {
  const TeacherSettlementsScreen({super.key});

  @override
  ConsumerState<TeacherSettlementsScreen> createState() => _TeacherSettlementsScreenState();
}

class _TeacherSettlementsScreenState extends ConsumerState<TeacherSettlementsScreen> {
  String _searchQuery = '';

  Future<void> _openPayoutDialog(BuildContext context, Map<String, dynamic> teacher) async {
    final branding = ref.read(brandingProvider);
    final teacherId = teacher['id']?.toString() ?? '';
    final teacherName = teacher['name']?.toString() ?? 'المعلم';
    final now = DateTime.now();
    DateTime startDate = DateTime(now.year, now.month, 1);
    DateTime endDate = now;
    final deductionsCtrl = TextEditingController(text: '0');

    bool isCalculating = false;
    Map<String, dynamic>? calculationResult;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'تسوية أرباح: $teacherName',
                    style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 24),
              Text(
                'فترة التسوية (بداية ونهاية الفترة):',
                style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(LucideIcons.calendar, size: 16),
                      label: Text(
                        'من: ${startDate.year}/${startDate.month}/${startDate.day}',
                        style: GoogleFonts.cairo(fontSize: 12),
                      ),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: startDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setModalState(() {
                            startDate = picked;
                            calculationResult = null;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(LucideIcons.calendar, size: 16),
                      label: Text(
                        'إلى: ${endDate.year}/${endDate.month}/${endDate.day}',
                        style: GoogleFonts.cairo(fontSize: 12),
                      ),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: endDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setModalState(() {
                            endDate = picked;
                            calculationResult = null;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: deductionsCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'خصومات أو سلف (ج.م)',
                  labelStyle: GoogleFonts.cairo(fontSize: 13),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 16),
              if (calculationResult != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: branding.primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: branding.primaryColor.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('إجمالي الدخل المحصل:', style: GoogleFonts.cairo(fontSize: 13)),
                          Text(
                            '${(calculationResult!['totalRevenue'] ?? 0)} ج.م',
                            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('حصة السنتر:', style: GoogleFonts.cairo(fontSize: 13)),
                          Text(
                            '${(calculationResult!['centerShare'] ?? 0)} ج.م',
                            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blue[700]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('صافي مستحق المعلم:', style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold)),
                          Text(
                            '${(calculationResult!['netPaid'] ?? calculationResult!['teacherShare'] ?? 0)} ج.م',
                            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16, color: branding.primaryColor),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: branding.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: isCalculating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(LucideIcons.calculator, size: 18),
                label: Text(
                  calculationResult == null ? 'حساب واعتماد التسوية المالية' : 'إعادة احتساب',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                onPressed: isCalculating
                    ? null
                    : () async {
                        setModalState(() => isCalculating = true);
                        try {
                          final deductions = double.tryParse(deductionsCtrl.text.trim()) ?? 0.0;
                          final res = await EduApiService().calculateTeacherPayout({
                            'teacherId': teacherId,
                            'periodStart': startDate.toIso8601String(),
                            'periodEnd': endDate.toIso8601String(),
                            'deductions': deductions,
                          });
                          SoundService.successFeedback();
                          setModalState(() {
                            calculationResult = res;
                          });
                        } catch (e) {
                          SoundService.errorFeedback();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('تعذر إتمام التسوية: $e'), backgroundColor: Colors.red),
                            );
                          }
                        } finally {
                          setModalState(() => isCalculating = false);
                        }
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(brandingProvider);
    final teachersAsync = ref.watch(liveTeachersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'تسويات ونسب المعلمين',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
      ),
      body: teachersAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: branding.primaryColor),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.alertCircle, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text('تعذر تحميل بيانات المعلمين والتسويات', style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(err.toString(), textAlign: TextAlign.center, style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(liveTeachersProvider),
                  icon: const Icon(LucideIcons.refreshCw, size: 18),
                  label: Text('إعادة المحاولة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
        data: (teachers) {
          final filtered = teachers.where((t) {
            if (_searchQuery.isEmpty) return true;
            final q = _searchQuery.toLowerCase();
            final name = (t['name'] ?? '').toString().toLowerCase();
            final subjectName = (t['subject'] is Map ? t['subject']['name'] ?? '' : '').toString().toLowerCase();
            return name.contains(q) || subjectName.contains(q);
          }).toList();

          return RefreshIndicator(
            color: branding.primaryColor,
            onRefresh: () async => ref.invalidate(liveTeachersProvider),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    decoration: InputDecoration(
                      hintText: 'بحث باسم المدرس أو المادة...',
                      hintStyle: GoogleFonts.cairo(fontSize: 13),
                      prefixIcon: const Icon(LucideIcons.search, size: 18),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                            Center(
                              child: Column(
                                children: [
                                  Icon(LucideIcons.graduationCap, size: 48, color: Colors.grey.withOpacity(0.5)),
                                  const SizedBox(height: 12),
                                  Text(
                                    _searchQuery.isEmpty ? 'لا يوجد مدرسون مسجلون حالياً' : 'لم يتم العثور على نتائج للبحث',
                                    style: GoogleFonts.cairo(fontSize: 15, color: Colors.grey[700]),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'قم بإضافة المدرسين عبر لوحة الويب أو الإدارة لتسوية الحسابات',
                                    style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(14),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (ctx, idx) {
                            final teacher = filtered[idx];
                            final name = teacher['name']?.toString() ?? 'بدون اسم';
                            final subjectName = (teacher['subject'] is Map ? teacher['subject']['name'] : null)?.toString() ?? 'عام';
                            final commissionType = teacher['commissionType']?.toString() ?? 'PERCENTAGE';
                            final centerPercentage = (teacher['centerPercentage'] ?? 20).toString();
                            final fixedCenterFee = (teacher['fixedCenterFee'] ?? 0).toString();
                            final groups = (teacher['groups'] as List?) ?? [];
                            final totalGroups = groups.length;

                            int totalStudents = 0;
                            for (final g in groups) {
                              if (g is Map && g['_count'] is Map) {
                                totalStudents += parseInt(g['_count']['students']);
                              }
                            }

                            final commissionDesc = commissionType == 'PERCENTAGE'
                                ? 'نسبة السنتر: $centerPercentage% (المعلم ${100 - (double.tryParse(centerPercentage) ?? 20).toInt()}%)'
                                : 'مبلغ السنتر: $fixedCenterFee ج.م / طالب';

                            return Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(color: Colors.grey.withOpacity(0.15)),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              backgroundColor: branding.primaryColor.withOpacity(0.12),
                                              child: Icon(LucideIcons.userCheck, color: branding.primaryColor),
                                            ),
                                            const SizedBox(width: 12),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  name,
                                                  style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold),
                                                ),
                                                Text(
                                                  subjectName,
                                                  style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey),
                                                ),
                                              ],
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
                                            commissionType == 'PERCENTAGE' ? 'نسبة مئوية' : 'مبلغ ثابت',
                                            style: GoogleFonts.cairo(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.bold,
                                              color: branding.primaryColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 20),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildMiniStat('المجموعات النشطة', '$totalGroups مجموعات'),
                                        ),
                                        Expanded(
                                          child: _buildMiniStat('الطلاب المسجلين', '$totalStudents طالب'),
                                        ),
                                        Expanded(
                                          child: _buildMiniStat('نظام المحاسبة', commissionDesc),
                                        ),
                                      ],
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
                                        icon: const Icon(LucideIcons.calculator, size: 16),
                                        label: Text(
                                          'حساب واعتماد التسوية المالية',
                                          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                        onPressed: () => _openPayoutDialog(context, teacher),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
