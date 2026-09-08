import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/services/sound_service.dart';
import '../../core/theme/branding_provider.dart';

class StaffFormDialog extends ConsumerStatefulWidget {
  const StaffFormDialog({super.key});

  @override
  ConsumerState<StaffFormDialog> createState() => _StaffFormDialogState();
}

class _StaffFormDialogState extends ConsumerState<StaffFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  String selectedRole = 'مساعد / سكرتارية واستقبال';

  bool canCollectCash = true;
  bool canViewPhones = true;
  bool canOpenEmergency = false;

  @override
  void dispose() {
    nameCtrl.dispose();
    phoneCtrl.dispose();
    emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(brandingProvider);

    return AlertDialog(
      title: Row(
        children: [
          Icon(LucideIcons.userCheck, color: branding.primaryColor, size: 24),
          const SizedBox(width: 10),
          Text(
            'إضافة موظف / مساعد جديد',
            style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('الاسم الكامل:', style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  hintText: 'مثال: سارة أحمد محمود',
                  prefixIcon: Icon(LucideIcons.user, size: 20),
                  isDense: true,
                ),
                validator: (val) => val == null || val.isEmpty ? 'يرجى إدخال الاسم' : null,
              ),
              const SizedBox(height: 12),
              Text('الرتبة الوظيفية:', style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: selectedRole,
                isExpanded: true,
                decoration: const InputDecoration(isDense: true),
                items: const [
                  DropdownMenuItem(value: 'مساعد / سكرتارية واستقبال', child: Text('مساعد / سكرتارية واستقبال')),
                  DropdownMenuItem(value: 'كاشير مالي معتمد', child: Text('كاشير مالي معتمد')),
                  DropdownMenuItem(value: 'مشرف قاعات وبوابة', child: Text('مشرف قاعات وبوابة')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => selectedRole = val);
                },
              ),
              const SizedBox(height: 12),
              Text('رقم الهاتف:', style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextFormField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: '01XXXXXXXXX',
                  prefixIcon: Icon(LucideIcons.phone, size: 20),
                  isDense: true,
                ),
                validator: (val) => val == null || val.isEmpty ? 'يرجى إدخال رقم الهاتف' : null,
              ),
              const SizedBox(height: 14),
              Text('الصلاحيات الممنوعة والمسموحة:',
                  style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('تحصيل النقدية وإصدار الإيصالات', style: GoogleFonts.cairo(fontSize: 12)),
                value: canCollectCash,
                activeColor: branding.primaryColor,
                onChanged: (val) => setState(() => canCollectCash = val ?? false),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('رؤية أرقام هواتف الطلاب وأولياء الأمور', style: GoogleFonts.cairo(fontSize: 12)),
                value: canViewPhones,
                activeColor: branding.primaryColor,
                onChanged: (val) => setState(() => canViewPhones = val ?? false),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('فتح جلسات حضور استثنائية', style: GoogleFonts.cairo(fontSize: 12)),
                value: canOpenEmergency,
                activeColor: branding.primaryColor,
                onChanged: (val) => setState(() => canOpenEmergency = val ?? false),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton.icon(
          icon: const Icon(LucideIcons.check, size: 16),
          label: const Text('إضافة وتفعيل الحساب'),
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              SoundService.successFeedback();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFF10B981),
                  content: Text('تم إنشاء حساب الموظف ${nameCtrl.text} بنجاح!'),
                ),
              );
            }
          },
        ),
      ],
    );
  }
}
