import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/network/edu_api_service.dart';
import '../../core/providers/edu_data_providers.dart';
import '../../core/services/sound_service.dart';
import '../../core/theme/branding_provider.dart';
import 'staff_form_dialog.dart';

class StaffManagementScreen extends ConsumerStatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  ConsumerState<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends ConsumerState<StaffManagementScreen> {
  String _searchQuery = '';

  String _formatRole(String? role) {
    switch (role) {
      case 'TENANT_ADMIN':
        return 'مدير النظام (Admin)';
      case 'TEACHER':
        return 'مدرس / محاضر';
      case 'ASSISTANT':
        return 'مساعد / سكرتارية';
      default:
        return role ?? 'موظف';
    }
  }

  List<String> _extractPermissions(dynamic permissions) {
    if (permissions == null) return [];
    if (permissions is List) return permissions.map((e) => e.toString()).toList();
    if (permissions is Map) {
      final list = <String>[];
      if (permissions['canCollectCash'] == true) list.add('التحصيل المالي (POS)');
      if (permissions['canScanQR'] == true) list.add('مسح الحضور (QR)');
      if (permissions['canGradeHomework'] == true) list.add('رصد الواجبات');
      if (permissions['canManageInventory'] == true) list.add('إدارة الملازم');
      if (permissions['canViewPhones'] == true) list.add('رؤية الهواتف');
      if (permissions['canOpenEmergency'] == true) list.add('صلاحيات طوارئ');
      return list;
    }
    return [];
  }

  Future<void> _toggleStatus(String id, bool newStatus) async {
    try {
      SoundService.successFeedback();
      await EduApiService().updateStaff(id, {'isActive': newStatus});
      ref.invalidate(liveStaffProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF10B981),
            content: Text(newStatus ? 'تم تفعيل حساب الموظف' : 'تم تعطيل حساب الموظف'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        SoundService.errorFeedback();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر تعديل الحالة: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تأكيد حذف الموظف', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        content: Text('هل أنت متأكد من رغبتك في حذف حساب "$name"؟ لا يمكن التراجع عن هذا الإجراء.', style: GoogleFonts.cairo()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('إلغاء', style: GoogleFonts.cairo()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('حذف نهائي', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await EduApiService().deleteStaff(id);
        ref.invalidate(liveStaffProvider);
        if (mounted) {
          SoundService.successFeedback();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF10B981),
              content: Text('تم حذف حساب الموظف "$name" بنجاح'),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          SoundService.errorFeedback();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تعذر حذف الموظف: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(brandingProvider);
    final staffAsync = ref.watch(liveStaffProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'فريق العمل والمساعدين',
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
      body: staffAsync.when(
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
                Text(
                  'تعذر تحميل قائمة الموظفين',
                  style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  err.toString(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(liveStaffProvider),
                  icon: const Icon(LucideIcons.refreshCw, size: 18),
                  label: Text('إعادة المحاولة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
        data: (staffList) {
          final filtered = staffList.where((m) {
            if (_searchQuery.isEmpty) return true;
            final q = _searchQuery.toLowerCase();
            final name = (m['name'] ?? '').toString().toLowerCase();
            final phone = (m['phone'] ?? '').toString().toLowerCase();
            return name.contains(q) || phone.contains(q);
          }).toList();

          return RefreshIndicator(
            color: branding.primaryColor,
            onRefresh: () async => ref.invalidate(liveStaffProvider),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    decoration: InputDecoration(
                      hintText: 'بحث بالاسم أو رقم الهاتف...',
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
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(LucideIcons.users, size: 48, color: Colors.grey.withOpacity(0.5)),
                                  const SizedBox(height: 12),
                                  Text(
                                    _searchQuery.isEmpty ? 'لا يوجد موظفون مضافون حالياً' : 'لم يتم العثور على نتائج للبحث',
                                    style: GoogleFonts.cairo(fontSize: 15, color: Colors.grey[700]),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _searchQuery.isEmpty ? 'اضغط على زر الإضافة أعلى الشاشة لإضافة مساعد' : 'جرب البحث باسم آخر',
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
                            final member = filtered[idx];
                            final id = member['id']?.toString() ?? '';
                            final name = member['name']?.toString() ?? 'بدون اسم';
                            final phone = member['phone']?.toString() ?? '-';
                            final role = _formatRole(member['role']?.toString());
                            final isActive = member['isActive'] == true;
                            final permissions = _extractPermissions(member['permissions']);

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
                                        Expanded(
                                          child: Row(
                                            children: [
                                              CircleAvatar(
                                                backgroundColor: branding.primaryColor.withOpacity(0.12),
                                                child: Icon(LucideIcons.user, color: branding.primaryColor),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      name,
                                                      style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    Text(
                                                      '$role • $phone',
                                                      style: GoogleFonts.cairo(fontSize: 11.5, color: Colors.grey),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Switch(
                                              value: isActive,
                                              activeColor: branding.primaryColor,
                                              onChanged: (val) => _toggleStatus(id, val),
                                            ),
                                            IconButton(
                                              icon: const Icon(LucideIcons.trash2, size: 18, color: Colors.redAccent),
                                              tooltip: 'حذف الموظف',
                                              onPressed: () => _confirmDelete(context, id, name),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    if (permissions.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: permissions.map((p) {
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
}
