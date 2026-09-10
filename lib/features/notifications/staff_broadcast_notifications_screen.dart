import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';

import '../../core/network/edu_api_service.dart';
import '../../core/theme/branding_provider.dart';

class StaffBroadcastNotificationsScreen extends ConsumerStatefulWidget {
  const StaffBroadcastNotificationsScreen({super.key});

  @override
  ConsumerState<StaffBroadcastNotificationsScreen> createState() =>
      _StaffBroadcastNotificationsScreenState();
}

class _StaffBroadcastNotificationsScreenState
    extends ConsumerState<StaffBroadcastNotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  String _selectedType = 'GENERAL';
  String _selectedTarget = 'ALL_STUDENTS';
  String? _selectedGroupId;
  bool _isUrgent = false;
  bool _isSubmitting = false;

  List<Map<String, dynamic>> _groups = [];
  bool _isLoadingGroups = false;

  List<Map<String, dynamic>> _history = [];
  bool _isLoadingHistory = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadGroups();
    _loadHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _loadGroups() async {
    setState(() => _isLoadingGroups = true);
    try {
      final groups = await EduApiService().getGroups();
      if (mounted) {
        setState(() {
          _groups = groups;
          _isLoadingGroups = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingGroups = false);
    }
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoadingHistory = true);
    try {
      final list = await EduApiService().getStaffNotifications();
      if (mounted) {
        setState(() {
          _history = list;
          _isLoadingHistory = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  Future<void> _handleSendBroadcast() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTarget == 'GROUP' && _selectedGroupId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('برجاء اختيار المجموعة المستهدفة', style: GoogleFonts.cairo()),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تأكيد إرسال الإشعار', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        content: Text(
          _selectedTarget == 'ALL_STUDENTS'
              ? 'سيتم إرسال هذا التنبيه لجميع طلاب السنتر فوراً. هل تود المتابعة؟'
              : 'سيتم إرسال هذا التنبيه لطلاب المجموعة المحددة فوراً. هل تود المتابعة؟',
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('إلغاء', style: GoogleFonts.cairo()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0143A3)),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('إرسال الآن', style: GoogleFonts.cairo(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSubmitting = true);
    try {
      await EduApiService().sendNotificationBroadcast(
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
        type: _selectedType,
        target: _selectedTarget,
        groupId: _selectedTarget == 'GROUP' ? _selectedGroupId : null,
        isUrgent: _isUrgent,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.circleCheck, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('تم إرسال وبث الإشعار بنجاح! 🚀', style: GoogleFonts.cairo()),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
          ),
        );

        _titleController.clear();
        _bodyController.clear();
        setState(() {
          _isUrgent = false;
          _selectedTarget = 'ALL_STUDENTS';
          _selectedGroupId = null;
        });

        _loadHistory();
        _tabController.animateTo(1);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل إرسال الإشعار: $e', style: GoogleFonts.cairo()),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(brandingProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'مركز بث التنبيهات والإشعارات',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16.5),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: branding.primaryColor,
          labelColor: branding.primaryColor,
          unselectedLabelColor: isDark ? Colors.grey[400] : const Color(0xFF64748B),
          labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelStyle: GoogleFonts.cairo(fontSize: 13),
          tabs: const [
            Tab(icon: Icon(LucideIcons.send, size: 16), text: 'إرسال إشعار جديد'),
            Tab(icon: Icon(LucideIcons.history, size: 16), text: 'سجل الإشعارات المرسلة'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildComposeTab(branding, isDark),
          _buildHistoryTab(branding, isDark),
        ],
      ),
    );
  }

  Widget _buildComposeTab(dynamic branding, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Header Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: branding.primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: branding.primaryColor.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.bellRing, color: branding.primaryColor, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'أرسل تنبيهات فورية تظهر لطلاب السنتر على هواتفهم مباشرة وفِي مركز الإشعارات الخاص بهم.',
                      style: GoogleFonts.cairo(fontSize: 12, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 1. Notification Title
            Text(
              'عنوان الإشعار *',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'مثال: موعد الحصة القادمة / امتحان شامل جديد',
                hintStyle: GoogleFonts.cairo(fontSize: 12, color: Colors.grey),
                prefixIcon: const Icon(LucideIcons.type, size: 18),
                filled: true,
                fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
                  ),
                ),
              ),
              validator: (val) =>
                  (val == null || val.trim().isEmpty) ? 'برجاء إدخال عنوان الإشعار' : null,
            ),
            const SizedBox(height: 14),

            // 2. Notification Body
            Text(
              'نص التنبيه أو الرسالة *',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _bodyController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'اكتب تفاصيل التنبيه أو التعليمات الموجهة للطلاب هنا...',
                hintStyle: GoogleFonts.cairo(fontSize: 12, color: Colors.grey),
                filled: true,
                fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
                  ),
                ),
              ),
              validator: (val) =>
                  (val == null || val.trim().isEmpty) ? 'برجاء كتابة نص التنبيه' : null,
            ),
            const SizedBox(height: 16),

            // 3. Notification Type Selector
            Text(
              'تصنيف الإشعار',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildTypeChip('عام 📢', 'GENERAL', branding),
                _buildTypeChip('عاجل 🚨', 'URGENT', branding),
                _buildTypeChip('امتحان 📝', 'EXAM', branding),
                _buildTypeChip('درس أو حصة 📚', 'LESSON', branding),
                _buildTypeChip('جدول ومواعيد ⏰', 'SCHEDULE', branding),
                _buildTypeChip('إعلان سنتر 🌟', 'ANNOUNCEMENT', branding),
              ],
            ),
            const SizedBox(height: 18),

            // 4. Target Audience Selector
            Text(
              'الجمهور المستهدف',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: Text('جميع طلاب السنتر', style: GoogleFonts.cairo(fontSize: 12.5)),
                    value: 'ALL_STUDENTS',
                    groupValue: _selectedTarget,
                    activeColor: branding.primaryColor,
                    onChanged: (val) => setState(() => _selectedTarget = val!),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: Text('مجموعة محددة', style: GoogleFonts.cairo(fontSize: 12.5)),
                    value: 'GROUP',
                    groupValue: _selectedTarget,
                    activeColor: branding.primaryColor,
                    onChanged: (val) => setState(() => _selectedTarget = val!),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),

            // Group Dropdown if GROUP target chosen
            if (_selectedTarget == 'GROUP') ...[
              const SizedBox(height: 8),
              if (_isLoadingGroups)
                const Center(child: CircularProgressIndicator())
              else if (_groups.isEmpty)
                Text('لا توجد مجموعات متاحة', style: GoogleFonts.cairo(color: Colors.grey, fontSize: 12))
              else
                DropdownButtonFormField<String>(
                  value: _selectedGroupId,
                  decoration: InputDecoration(
                    labelText: 'اختر المجموعة المستهدفة',
                    labelStyle: GoogleFonts.cairo(fontSize: 12),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
                      ),
                    ),
                  ),
                  items: _groups.map((g) {
                    final gid = g['id']?.toString() ?? '';
                    final name = g['name']?.toString() ?? 'مجموعة';
                    return DropdownMenuItem<String>(
                      value: gid,
                      child: Text(name, style: GoogleFonts.cairo(fontSize: 12.5)),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedGroupId = val),
                ),
            ],
            const SizedBox(height: 14),

            // 5. Urgent Priority Toggle
            SwitchListTile(
              title: Text('تنبيه فائق الأهمية (High Priority)', style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold)),
              subtitle: Text('تمييز الإشعار بلون أحمر لسرعة انتباه الطلاب', style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey)),
              value: _isUrgent,
              activeColor: Colors.redAccent,
              contentPadding: EdgeInsets.zero,
              onChanged: (val) => setState(() => _isUrgent = val),
            ),
            const SizedBox(height: 20),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: branding.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _isSubmitting ? null : _handleSendBroadcast,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(LucideIcons.send, color: Colors.white, size: 18),
                label: Text(
                  _isSubmitting ? 'جاري البث والإرسال...' : 'بث التنبيه لجميع الطلاب الآن',
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip(String label, String value, dynamic branding) {
    final isSelected = _selectedType == value;
    return ChoiceChip(
      label: Text(
        label,
        style: GoogleFonts.cairo(
          fontSize: 11.5,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? branding.primaryColor : Colors.grey[700],
        ),
      ),
      selected: isSelected,
      onSelected: (sel) {
        if (sel) setState(() => _selectedType = value);
      },
      selectedColor: branding.primaryColor.withOpacity(0.15),
    );
  }

  Widget _buildHistoryTab(dynamic branding, bool isDark) {
    if (_isLoadingHistory) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.inbox, size: 54, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'لا توجد تنبيهات مرسلة حتى الآن',
              style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'أي إشعار يتم بثه لطلاب السنتر سيتم حفظه وتوثيقه هنا',
              style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        itemCount: _history.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final n = _history[index];
          final title = n['title']?.toString() ?? 'إشعار سنتر';
          final body = n['body']?.toString() ?? '';
          final target = n['target']?.toString() ?? 'ALL_STUDENTS';
          final isUrgent = n['isUrgent'] == true;
          final groupName = n['group']?['name']?.toString() ?? '';

          DateTime? date;
          if (n['createdAt'] != null) {
            date = DateTime.tryParse(n['createdAt'].toString());
          }
          final dateStr = date != null
              ? DateFormat('d MMM yyyy - hh:mm a', 'ar').format(date)
              : '';

          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isUrgent
                    ? Colors.redAccent.withOpacity(0.5)
                    : (isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isUrgent ? Colors.redAccent : (isDark ? Colors.white : const Color(0xFF0F172A)),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isUrgent)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'عاجل',
                          style: GoogleFonts.cairo(fontSize: 10, color: Colors.redAccent, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: GoogleFonts.cairo(fontSize: 12.5, color: isDark ? Colors.grey[300] : const Color(0xFF475569)),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      target == 'ALL_STUDENTS'
                          ? '🎯 موجه لـ: جميع الطلاب'
                          : '🎯 موجه لـ: ${groupName.isNotEmpty ? groupName : "مجموعة خاصة"}',
                      style: GoogleFonts.cairo(fontSize: 11, color: branding.primaryColor, fontWeight: FontWeight.w600),
                    ),
                    if (dateStr.isNotEmpty)
                      Text(
                        dateStr,
                        style: GoogleFonts.cairo(fontSize: 10.5, color: Colors.grey),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
