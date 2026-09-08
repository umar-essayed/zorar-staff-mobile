import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/network/edu_api_service.dart';
import '../../core/providers/edu_data_providers.dart';
import '../../core/services/sound_service.dart';
import '../../core/theme/branding_provider.dart';

class AcademicYearsManagementScreen extends ConsumerStatefulWidget {
  const AcademicYearsManagementScreen({super.key});

  @override
  ConsumerState<AcademicYearsManagementScreen> createState() => _AcademicYearsManagementScreenState();
}

class _AcademicYearsManagementScreenState extends ConsumerState<AcademicYearsManagementScreen> {
  Future<void> _showSyncStagesDialog(BuildContext context) async {
    final branding = ref.read(brandingProvider);
    final selectedStages = <String>{'SECONDARY', 'BACCALAUREATE'};
    bool isSyncing = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (c, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(c).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.sparkles, color: branding.primaryColor, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    'تخصيص المراحل وتوليد الصفوف تلقائياً',
                    style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'حدد المراحل التعليمية العاملة بالسنتر لتوليد كافة الصفوف الدراسية في النظام تلقائياً دون الحاجة لإدخالها يدوياً:',
                style: GoogleFonts.cairo(fontSize: 12.5, color: Colors.grey),
              ),
              const SizedBox(height: 16),

              _buildStageCheckbox(
                title: 'الثانوي العام',
                subtitle: 'أولى ثانوي، ثانية ثانوي، ثالثة ثانوي',
                key: 'SECONDARY',
                selectedStages: selectedStages,
                setSheetState: setSheetState,
                branding: branding,
              ),
              _buildStageCheckbox(
                title: 'نظام البكالوريا (Baccalauréat)',
                subtitle: 'أولى بكالوريا (1ère Bac)، ثانية بكالوريا، ثالثة بكالوريا (Terminale)',
                key: 'BACCALAUREATE',
                selectedStages: selectedStages,
                setSheetState: setSheetState,
                branding: branding,
              ),
              _buildStageCheckbox(
                title: 'المرحلة الإعدادية',
                subtitle: 'أولى إعدادي، ثانية إعدادي، ثالثة إعدادي',
                key: 'PREPARATORY',
                selectedStages: selectedStages,
                setSheetState: setSheetState,
                branding: branding,
              ),
              _buildStageCheckbox(
                title: 'المرحلة الابتدائية',
                subtitle: 'من الصف الأول وحتى السادس الابتدائي',
                key: 'PRIMARY',
                selectedStages: selectedStages,
                setSheetState: setSheetState,
                branding: branding,
              ),

              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: branding.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: isSyncing
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(LucideIcons.checkCheck, size: 20),
                label: Text(
                  isSyncing ? 'جاري التوليد والمزامنة...' : 'توليد ومزامنة الصفوف فوراً ⚡',
                  style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                onPressed: isSyncing || selectedStages.isEmpty
                    ? null
                    : () async {
                        setSheetState(() => isSyncing = true);
                        try {
                          await EduApiService().syncStages(selectedStages.toList());
                          SoundService.successFeedback();
                          if (mounted) {
                            Navigator.pop(c);
                            ref.invalidate(liveAcademicYearsProvider);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('تم توليد ومزامنة الصفوف الدراسية بنجاح!'),
                                backgroundColor: Color(0xFF10B981),
                              ),
                            );
                          }
                        } catch (e) {
                          setSheetState(() => isSyncing = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('تعذر مزامنة الصفوف: $e'), backgroundColor: Colors.red),
                          );
                        }
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStageCheckbox({
    required String title,
    required String subtitle,
    required String key,
    required Set<String> selectedStages,
    required StateSetter setSheetState,
    required dynamic branding,
  }) {
    final isChecked = selectedStages.contains(key);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isChecked ? branding.primaryColor : Colors.grey.withOpacity(0.2),
          width: isChecked ? 1.5 : 1,
        ),
      ),
      child: CheckboxListTile(
        value: isChecked,
        activeColor: branding.primaryColor,
        title: Text(title, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13.5)),
        subtitle: Text(subtitle, style: GoogleFonts.cairo(fontSize: 11.5, color: Colors.grey)),
        onChanged: (val) {
          setSheetState(() {
            if (val == true) {
              selectedStages.add(key);
            } else {
              selectedStages.remove(key);
            }
          });
        },
      ),
    );
  }

  Future<void> _showAddCustomYearDialog(BuildContext context) async {
    final nameCtrl = TextEditingController();
    bool isSubmitting = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (c, setDialogState) => AlertDialog(
          title: Text('إضافة سنة دراسية يدوياً', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
          content: TextField(
            controller: nameCtrl,
            decoration: const InputDecoration(
              labelText: 'اسم الصف الدراسي (مثال: أولى ثانوي)',
              prefixIcon: Icon(LucideIcons.graduationCap, size: 20),
            ),
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
                        await EduApiService().createAcademicYear({'name': name});
                        SoundService.successFeedback();
                        if (mounted) {
                          Navigator.pop(c);
                          ref.invalidate(liveAcademicYearsProvider);
                        }
                      } catch (e) {
                        setDialogState(() => isSubmitting = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('تعذر إضافة السنة الدراسية: $e'), backgroundColor: Colors.red),
                        );
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('إضافة'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(brandingProvider);
    final yearsAsync = ref.watch(liveAcademicYearsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'الصفوف والمراحل الدراسية',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 20),
            onPressed: () => ref.invalidate(liveAcademicYearsProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          // Stages Quick Setup Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: branding.primaryColor.withOpacity(0.08),
              border: Border(bottom: BorderSide(color: branding.primaryColor.withOpacity(0.2))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'إعداد المراحل والنظام التعليمي',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        'توليد صفوف الثانوي والبكالوريا والإعدادي تلقائياً بنقرة واحدة.',
                        style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: branding.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  icon: const Icon(LucideIcons.wand2, size: 16),
                  label: const Text('تخصيص المراحل'),
                  onPressed: () => _showSyncStagesDialog(context),
                ),
              ],
            ),
          ),

          // Academic Years List
          Expanded(
            child: yearsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.alertCircle, size: 48, color: Colors.amber),
                    const SizedBox(height: 12),
                    Text('تعذر تحميل الصفوف: $err', style: GoogleFonts.cairo()),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(liveAcademicYearsProvider),
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
              data: (years) {
                if (years.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.graduationCap, size: 54, color: Colors.grey.withOpacity(0.4)),
                          const SizedBox(height: 14),
                          Text(
                            'لم يتم تحديد أي صفوف دراسية حتى الآن',
                            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'اضغط على زر "تخصيص المراحل" بالأعلى لتوليد الصفوف التلقائية بما فيها الثانوي والبكالوريا.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cairo(color: Colors.grey, fontSize: 12.5),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: branding.primaryColor, foregroundColor: Colors.white),
                            icon: const Icon(LucideIcons.wand2, size: 18),
                            label: const Text('توليد الصفوف الآن'),
                            onPressed: () => _showSyncStagesDialog(context),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(liveAcademicYearsProvider),
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(14),
                    itemCount: years.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, idx) {
                      final yr = years[idx];
                      final id = yr['id']?.toString() ?? '';
                      final name = yr['name']?.toString() ?? 'صف دراسي';
                      final groupsCount = (yr['groups'] as List?)?.length ?? 0;

                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: branding.primaryColor.withOpacity(0.12),
                            child: Icon(LucideIcons.graduationCap, color: branding.primaryColor, size: 20),
                          ),
                          title: Text(name, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text('المجموعات التابعة: $groupsCount مجموعة', style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey)),
                          trailing: IconButton(
                            icon: const Icon(LucideIcons.trash2, size: 18, color: Colors.red),
                            tooltip: 'حذف الصف الدراسي',
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (c) => AlertDialog(
                                  title: const Text('تأكيد الحذف'),
                                  content: Text('هل تريد حذف صف ($name)؟'),
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
                                final ok = await EduApiService().deleteAcademicYear(id);
                                if (ok) {
                                  SoundService.successFeedback();
                                  ref.invalidate(liveAcademicYearsProvider);
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: branding.primaryColor,
        foregroundColor: Colors.white,
        tooltip: 'إضافة صف مخصص يدوياً',
        onPressed: () => _showAddCustomYearDialog(context),
        child: const Icon(LucideIcons.plus),
      ),
    );
  }
}
