import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../core/network/api_client.dart';
import '../../core/providers/edu_data_providers.dart';
import '../../core/services/sound_service.dart';
import '../../core/theme/branding_provider.dart';
import 'attendance_scanner_screen.dart';

class EmergencySessionDialog extends ConsumerStatefulWidget {
  final String? initialGroupId;
  const EmergencySessionDialog({super.key, this.initialGroupId});

  @override
  ConsumerState<EmergencySessionDialog> createState() => _EmergencySessionDialogState();
}

class _EmergencySessionDialogState extends ConsumerState<EmergencySessionDialog> {
  String? _selectedGroupId;
  int _sessionNumber = 1;
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _reasonCtrl = TextEditingController(text: 'جلسة تعويضية / مراجعة إضافية');
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedGroupId = widget.initialGroupId;
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitEmergencySession(dynamic branding) async {
    if (_selectedGroupId == null || _selectedGroupId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('يرجى اختيار المجموعة المستهدفة أولاً', style: GoogleFonts.cairo()), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    SoundService.lightImpact();

    try {
      await ApiClient().dio.post(
        '/academic/groups/$_selectedGroupId/emergency-session',
        data: {
          'sessionNumber': _sessionNumber,
          'title': 'جلسة استثنائية (حصة $_sessionNumber)',
          'reason': _reasonCtrl.text.trim(),
          'date': _selectedDate.toIso8601String(),
        },
      );

      SoundService.successFeedback();
      ref.invalidate(liveGroupsProvider);
      ref.invalidate(liveGroupAttendanceProvider(_selectedGroupId!));

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF10B981),
            content: Text(
              'تم فتح الجلسة الاستثنائية للحصة ($_sessionNumber) بنجاح وجاهزة لتسجيل الحضور',
              style: GoogleFonts.cairo(),
            ),
            action: SnackBarAction(
              label: 'فتح السكانر',
              textColor: Colors.white,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (c) => AttendanceScannerScreen(initialGroupId: _selectedGroupId),
                  ),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      SoundService.errorFeedback();
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر فتح الجلسة: $e', style: GoogleFonts.cairo()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(brandingProvider);
    final groupsAsync = ref.watch(liveGroupsProvider);

    return AlertDialog(
      title: Row(
        children: [
          const Icon(LucideIcons.calendarPlus, color: Color(0xFFF59E0B), size: 24),
          const SizedBox(width: 10),
          Text(
            'فتح جلسة حضور استثنائية',
            style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
              ),
              child: Text(
                'تتيح هذه الميزة فتح تسجيل الحضور لأي حصة خارج جدولها الطبيعي، وسيتم توثيق الاستثناء رسمياً بالنظام.',
                style: GoogleFonts.cairo(fontSize: 11.5, color: Colors.brown),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'المجموعة المستهدفة:',
              style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            groupsAsync.when(
              data: (groups) {
                if (groups.isEmpty) {
                  return const Text('لا توجد مجموعات متاحة، يرجى إنشاء مجموعة أولاً');
                }
                _selectedGroupId ??= groups.first['id']?.toString();

                return DropdownButtonFormField<String>(
                  value: _selectedGroupId,
                  isExpanded: true,
                  decoration: const InputDecoration(isDense: true),
                  items: groups.map((g) {
                    final id = g['id']?.toString() ?? '';
                    final name = g['name']?.toString() ?? 'مجموعة';
                    final teacher = g['teacher']?['name']?.toString() ?? '';
                    final label = teacher.isNotEmpty ? '$name ($teacher)' : name;
                    return DropdownMenuItem<String>(
                      value: id,
                      child: Text(label, style: GoogleFonts.cairo(fontSize: 13), overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedGroupId = val);
                  },
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (err, _) => Text('تعذر جلب المجموعات: $err', style: GoogleFonts.cairo(color: Colors.red)),
            ),

            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'رقم الحصة:',
                        style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<int>(
                        value: _sessionNumber,
                        decoration: const InputDecoration(isDense: true),
                        items: List.generate(8, (index) {
                          final num = index + 1;
                          final isExtra = num > 4;
                          return DropdownMenuItem<int>(
                            value: num,
                            child: Text(isExtra ? 'الحصة $num (إضافية)' : 'الحصة $num', style: GoogleFonts.cairo(fontSize: 12)),
                          );
                        }),
                        onChanged: (val) {
                          if (val != null) setState(() => _sessionNumber = val);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تاريخ الانعقاد:',
                        style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 30)),
                            lastDate: DateTime.now().add(const Duration(days: 30)),
                          );
                          if (picked != null) {
                            setState(() => _selectedDate = picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.withOpacity(0.4)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(LucideIcons.calendar, size: 16, color: Colors.grey),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  DateFormat('yyyy-MM-dd').format(_selectedDate),
                                  style: GoogleFonts.cairo(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'سبب فتح الاستثناء أو الملاحظة:',
              style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _reasonCtrl,
              decoration: const InputDecoration(
                hintText: 'مثال: حصة تعويضية أو مراجعة إضافية...',
                isDense: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: branding.primaryColor,
            foregroundColor: Colors.white,
          ),
          icon: _isSubmitting
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(LucideIcons.unlock, size: 16),
          label: Text(_isSubmitting ? 'جاري الفتح...' : 'تأكيد وفتح الجلسة'),
          onPressed: _isSubmitting ? null : () => _submitEmergencySession(branding),
        ),
      ],
    );
  }
}
