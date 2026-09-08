import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/network/edu_api_service.dart';
import '../../core/providers/edu_data_providers.dart';
import '../../core/services/sound_service.dart';
import '../../core/services/whatsapp_service.dart';
import '../../core/theme/branding_provider.dart';

class AdmissionsScreen extends ConsumerStatefulWidget {
  const AdmissionsScreen({super.key});

  @override
  ConsumerState<AdmissionsScreen> createState() => _AdmissionsScreenState();
}

class _AdmissionsScreenState extends ConsumerState<AdmissionsScreen> {
  String _activeFilter = 'ALL'; // 'ALL', 'PENDING', 'APPROVED', 'REJECTED'

  Future<void> _handleApprove(Map<String, dynamic> app) async {
    final branding = ref.read(brandingProvider);
    final years = await EduApiService().getAcademicYears();
    final groups = await EduApiService().getGroups();
    String? selectedYearId = years.isNotEmpty ? years.first['id'].toString() : null;
    String? selectedGroupId = groups.isNotEmpty ? groups.first['id'].toString() : null;

    if (!mounted) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('قبول وتسكين الطالب', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('المتقدم: ${app['studentName']}', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text('اختر السنة الدراسية:', style: GoogleFonts.cairo(fontSize: 12)),
              DropdownButtonFormField<String>(
                value: selectedYearId,
                isExpanded: true,
                items: years.map((y) => DropdownMenuItem(value: y['id'].toString(), child: Text(y['name'] ?? ''))).toList(),
                onChanged: (v) => setDialogState(() => selectedYearId = v),
              ),
              const SizedBox(height: 10),
              Text('اختر المجموعة الدراسية:', style: GoogleFonts.cairo(fontSize: 12)),
              DropdownButtonFormField<String>(
                value: selectedGroupId,
                isExpanded: true,
                items: groups.map((g) => DropdownMenuItem(value: g['id'].toString(), child: Text(g['name'] ?? ''))).toList(),
                onChanged: (v) => setDialogState(() => selectedGroupId = v),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('تأكيد القبول والقيد'),
            ),
          ],
        ),
      ),
    );

    if (result == true && selectedYearId != null) {
      final success = await EduApiService().approveAdmissionSubmission(
        app['id'].toString(),
        selectedYearId!,
        groupIds: selectedGroupId != null ? [selectedGroupId!] : [],
      );

      if (success) {
        SoundService.successFeedback();
        ref.invalidate(liveAdmissionsProvider);
        ref.invalidate(liveStudentsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم قبول الطالب بنجاح وإضافته لدليل الطلاب ✅'), backgroundColor: Color(0xFF10B981)),
          );
        }
      }
    }
  }

  Future<void> _handleReject(Map<String, dynamic> app) async {
    final reasonCtrl = TextEditingController(text: 'اكتمال الطاقة الاستيعابية للقاعات');
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('رفض طلب التقديم'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الطالب: ${app['studentName']}', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(controller: reasonCtrl, decoration: const InputDecoration(labelText: 'سبب الرفض')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('تأكيد الرفض'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await EduApiService().rejectAdmissionSubmission(app['id'].toString(), reason: reasonCtrl.text.trim());
      SoundService.warningFeedback();
      ref.invalidate(liveAdmissionsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(brandingProvider);
    final admissionsAsync = ref.watch(liveAdmissionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'طلبات التقديم والحجز الإلكتروني',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.15))),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('الكل', 'ALL', branding),
                  const SizedBox(width: 8),
                  _buildFilterChip('طلبات قيد المراجعة', 'PENDING', branding),
                  const SizedBox(width: 8),
                  _buildFilterChip('المقبولين', 'APPROVED', branding),
                  const SizedBox(width: 8),
                  _buildFilterChip('المرفوضين', 'REJECTED', branding),
                ],
              ),
            ),
          ),

          // Submissions List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(liveAdmissionsProvider);
              },
              child: admissionsAsync.when(
                data: (submissions) {
                  final filtered = submissions.where((s) {
                    final status = s['status'] ?? 'PENDING';
                    if (_activeFilter == 'ALL') return true;
                    return status == _activeFilter;
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.inbox, size: 50, color: Colors.grey.withOpacity(0.4)),
                          const SizedBox(height: 12),
                          Text('لا توجد طلبات تقديم مطابقة حالياً', style: GoogleFonts.cairo(color: Colors.grey, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(14),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, idx) {
                      final item = filtered[idx];
                      return _buildSubmissionCard(item, branding);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.alertCircle, color: Colors.red, size: 36),
                      const SizedBox(height: 8),
                      Text('تعذر تحميل طلبات التقديم', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(liveAdmissionsProvider),
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String val, dynamic branding) {
    final isSelected = _activeFilter == val;
    return ChoiceChip(
      label: Text(label, style: GoogleFonts.cairo(fontSize: 11.5, fontWeight: FontWeight.bold)),
      selected: isSelected,
      selectedColor: branding.primaryColor,
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.grey[700]),
      onSelected: (sel) {
        if (sel) {
          SoundService.lightImpact();
          setState(() => _activeFilter = val);
        }
      },
    );
  }

  Widget _buildSubmissionCard(Map<String, dynamic> item, dynamic branding) {
    final name = item['studentName'] ?? 'بدون اسم';
    final phone = item['phone'] ?? '';
    final guardianPhone = item['guardianPhone'] ?? phone;
    final status = item['status'] ?? 'PENDING';
    final dateStr = item['createdAt'] != null
        ? item['createdAt'].toString().split('T').first
        : 'اليوم';

    Color statusColor;
    String statusTitle;
    switch (status) {
      case 'APPROVED':
        statusColor = const Color(0xFF10B981);
        statusTitle = 'مقبول وقُيد بالسنتر';
        break;
      case 'REJECTED':
        statusColor = const Color(0xFFEF4444);
        statusTitle = 'مرفوض';
        break;
      default:
        statusColor = const Color(0xFFF59E0B);
        statusTitle = 'قيد المراجعة';
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(name, style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusTitle,
                    style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('تاريخ التقديم: $dateStr • هاتف الطالب: $phone', style: GoogleFonts.cairo(fontSize: 11.5, color: Colors.grey[700])),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(LucideIcons.messageCircle, size: 16, color: Color(0xFF10B981)),
                    label: const Text('واتساب ولي الأمر'),
                    onPressed: () {
                      WhatsAppService.sendCustomMessage(
                        context,
                        phone: guardianPhone,
                        message: 'مرحباً بخصوص طلب التقديم للطالب $name في السنتر.',
                      );
                    },
                  ),
                ),
                if (status == 'PENDING') ...[
                  const SizedBox(width: 8),
                  IconButton.filled(
                    style: IconButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                    icon: const Icon(LucideIcons.check, size: 18),
                    tooltip: 'قبول وتسكين',
                    onPressed: () => _handleApprove(item),
                  ),
                  const SizedBox(width: 6),
                  IconButton.filled(
                    style: IconButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
                    icon: const Icon(LucideIcons.x, size: 18),
                    tooltip: 'رفض',
                    onPressed: () => _handleReject(item),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
