import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/network/edu_api_service.dart';
import '../../core/providers/edu_data_providers.dart';
import '../../core/services/sound_service.dart';
import '../../core/theme/branding_provider.dart';

class SubjectsManagementScreen extends ConsumerStatefulWidget {
  const SubjectsManagementScreen({super.key});

  @override
  ConsumerState<SubjectsManagementScreen> createState() => _SubjectsManagementScreenState();
}

class _SubjectsManagementScreenState extends ConsumerState<SubjectsManagementScreen> {
  String _searchQuery = '';

  Future<void> _showAddSubjectDialog(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    bool isSubmitting = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (c, setDialogState) => AlertDialog(
          title: Text('إضافة مادة دراسية جديدة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'اسم المادة (مثال: الفيزياء، اللغة الفرنسية)',
                  prefixIcon: Icon(LucideIcons.bookOpen, size: 20),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: codeCtrl,
                decoration: const InputDecoration(
                  labelText: 'كود المادة (اختياري، مثل: PHYS-01)',
                  prefixIcon: Icon(LucideIcons.hash, size: 20),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(c),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final name = nameCtrl.text.trim();
                      if (name.isEmpty) return;

                      setDialogState(() => isSubmitting = true);
                      try {
                        final code = codeCtrl.text.trim().isNotEmpty
                            ? codeCtrl.text.trim()
                            : 'SUB-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

                        await EduApiService().createSubject({
                          'name': name,
                          'code': code,
                        });
                        SoundService.successFeedback();
                        if (mounted) {
                          Navigator.pop(c);
                          ref.invalidate(liveSubjectsProvider);
                        }
                      } catch (e) {
                        setDialogState(() => isSubmitting = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('تعذر إضافة المادة: $e'), backgroundColor: Colors.red),
                        );
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('إضافة المادة'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(brandingProvider);
    final subjectsAsync = ref.watch(liveSubjectsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'المواد الدراسية',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 20),
            onPressed: () => ref.invalidate(liveSubjectsProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: branding.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(LucideIcons.plus, size: 20),
        label: Text('إضافة مادة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        onPressed: () => _showAddSubjectDialog(context),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            color: Theme.of(context).cardColor,
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'البحث عن مادة دراسية...',
                prefixIcon: const Icon(LucideIcons.search, size: 20),
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          Expanded(
            child: subjectsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.alertCircle, size: 48, color: Colors.amber),
                    const SizedBox(height: 12),
                    Text('تعذر تحميل المواد: $err', style: GoogleFonts.cairo()),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(liveSubjectsProvider),
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
              data: (subjects) {
                final filtered = subjects.where((s) {
                  final name = (s['name']?.toString() ?? '').toLowerCase();
                  final code = (s['code']?.toString() ?? '').toLowerCase();
                  return _searchQuery.isEmpty || name.contains(_searchQuery) || code.contains(_searchQuery);
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.bookOpen, size: 54, color: Colors.grey.withOpacity(0.4)),
                        const SizedBox(height: 12),
                        Text('لا توجد مواد دراسية مسجلة', style: GoogleFonts.cairo(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(liveSubjectsProvider),
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(14),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, idx) {
                      final sub = filtered[idx];
                      final id = sub['id']?.toString() ?? '';
                      final name = sub['name']?.toString() ?? 'مادة';
                      final code = sub['code']?.toString() ?? '';

                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: branding.primaryColor.withOpacity(0.12),
                            child: Icon(LucideIcons.bookOpen, color: branding.primaryColor, size: 20),
                          ),
                          title: Text(name, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text('كود المادة: $code', style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey)),
                          trailing: IconButton(
                            icon: const Icon(LucideIcons.trash2, size: 18, color: Colors.red),
                            tooltip: 'حذف المادة',
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (c) => AlertDialog(
                                  title: const Text('تأكيد الحذف'),
                                  content: Text('هل تريد حذف مادة ($name)؟'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                      onPressed: () => Navigator.pop(c, true),
                                      child: const Text('حذف', style: TextStyle(color: Colors.white)),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                final ok = await EduApiService().deleteSubject(id);
                                if (ok) {
                                  SoundService.successFeedback();
                                  ref.invalidate(liveSubjectsProvider);
                                }
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
