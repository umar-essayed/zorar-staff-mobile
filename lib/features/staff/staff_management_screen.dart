import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/services/sound_service.dart';
import '../../core/theme/branding_provider.dart';
import 'staff_form_dialog.dart';

class StaffMember {
  final String id;
  final String name;
  final String role;
  final String phone;
  bool isActive;
  final List<String> permissions;

  StaffMember({
    required this.id,
    required this.name,
    required this.role,
    required this.phone,
    required this.isActive,
    required this.permissions,
  });
}

class StaffManagementScreen extends ConsumerStatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  ConsumerState<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends ConsumerState<StaffManagementScreen> {
  late final List<StaffMember> staff = [
    StaffMember(
      id: 'STF-01',
      name: 'سارة أحمد محمود',
      role: 'مساعد / سكرتارية واستقبال',
      phone: '01111111112',
      isActive: true,
      permissions: ['التحصيل المالي (POS)', 'رؤية الهواتف'],
    ),
    StaffMember(
      id: 'STF-02',
      name: 'أحمد سعيد عبد الفتاح',
      role: 'كاشير مالي معتمد',
      phone: '01222222221',
      isActive: true,
      permissions: ['التحصيل المالي (POS)', 'تقفيل الخزينة', 'رؤية الهواتف'],
    ),
    StaffMember(
      id: 'STF-03',
      name: 'كريم وائل المنياوي',
      role: 'مشرف بوابات وقاعات',
      phone: '01033333334',
      isActive: true,
      permissions: ['ماسح الحضور فقط'],
    ),
    StaffMember(
      id: 'STF-04',
      name: 'مها إبراهيم سالم',
      role: 'مساعد استقبال مسائي',
      phone: '01544444445',
      isActive: false,
      permissions: ['التحصيل المالي'],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(brandingProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'فريق العمل وإدارة الصلاحيات',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.userPlus),
            tooltip: 'إضافة موظف جديد',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => const StaffFormDialog(),
              );
            },
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(14),
        itemCount: staff.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (ctx, idx) {
          final member = staff[idx];

          return Card(
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
                            child: Icon(LucideIcons.user, color: branding.primaryColor),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                member.name,
                                style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${member.role} • ${member.phone}',
                                style: GoogleFonts.cairo(fontSize: 11.5, color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Switch(
                        value: member.isActive,
                        activeColor: branding.primaryColor,
                        onChanged: (val) {
                          SoundService.successFeedback();
                          setState(() => member.isActive = val);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: member.permissions.map((p) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.withOpacity(0.2)),
                        ),
                        child: Text(
                          p,
                          style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey[800]),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
