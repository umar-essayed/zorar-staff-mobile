import '../../core/network/edu_api_service.dart';
import '../../core/providers/edu_data_providers.dart';
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
  final passwordCtrl = TextEditingController(text: '123456');
  String selectedRole = 'مساعد / سكرتارية واستقبال';
  bool _isSaving = false;

  bool canCollectCash = true;
  bool canViewPhones = true;
  bool canOpenEmergency = false;

  @override
  void dispose() {
    nameCtrl.dispose();
    phoneCtrl.dispose();
    passwordCtrl.dispose();
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
              Text('رقم الهاتف (لتسجيل الدخول):', style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.bold)),
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
              const SizedBox(height: 12),
              Text('كلمة المرور المؤقتة:', style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextFormField(
                controller: passwordCtrl,
                decoration: const InputDecoration(
                  prefixIcon: Icon(LucideIcons.lock, size: 20),
                  isDense: true,
                ),
                validator: (val) => val == null || val.isEmpty ? 'كلمة المرور مطلوبة' : null,
              ),
              const SizedBox(height: 14),
              Text('الصلاحيات الممنوحة:',
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
          icon: _isSaving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(LucideIcons.check, size: 16),
          label: const Text('إضافة وتفعيل الحساب'),
          onPressed: _isSaving
              ? null
              : () async {
                  if (_formKey.currentState?.validate() ?? false) {
                    setState(() => _isSaving = true);
                    try {
                      await EduApiService().createStaff({
                        'name': nameCtrl.text.trim(),
                        'phone': phoneCtrl.text.trim(),
                        'password': passwordCtrl.text.trim(),
                        'role': 'ASSISTANT',
                        'permissions': {
                          'canCollectCash': canCollectCash,
                          'canViewPhones': canViewPhones,
                          'canOpenEmergency': canOpenEmergency,
                        },
                      });
                      ref.invalidate(liveStaffProvider);
                      if (context.mounted) {
                        SoundService.successFeedback();
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF10B981),
                            content: Text('تم إنشاء حساب الموظف ${nameCtrl.text} بنجاح! ✅'),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        SoundService.errorFeedback();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('تعذر إضافة الموظف: $e'), backgroundColor: Colors.red),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _isSaving = false);
                    }
                  }
                },
        ),
      ],
    );
  }
}
