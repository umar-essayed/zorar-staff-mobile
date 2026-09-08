import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/services/sound_service.dart';
import '../../core/theme/branding_provider.dart';

class StudentAdmissionPublicScreen extends ConsumerStatefulWidget {
  const StudentAdmissionPublicScreen({super.key});

  @override
  ConsumerState<StudentAdmissionPublicScreen> createState() =>
      _StudentAdmissionPublicScreenState();
}

class _StudentAdmissionPublicScreenState
    extends ConsumerState<StudentAdmissionPublicScreen> {
  final _formKey = GlobalKey<FormState>();

  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final parentPhoneCtrl = TextEditingController();
  final schoolCtrl = TextEditingController();
  final notesCtrl = TextEditingController();

  String selectedGrade = 'الصف الثالث الثانوي';
  String selectedGroup = '3ث لغة عربية (أ) - أ/ أحمد كمال';

  bool isSubmitted = false;
  String generatedAppId = 'ADM-2026-904';

  @override
  void dispose() {
    nameCtrl.dispose();
    phoneCtrl.dispose();
    parentPhoneCtrl.dispose();
    schoolCtrl.dispose();
    notesCtrl.dispose();
    super.dispose();
  }

  void _submitApplication() {
    if (_formKey.currentState?.validate() ?? false) {
      SoundService.successFeedback();
      setState(() => isSubmitted = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(brandingProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'استمارة الحجز والتقديم الإلكتروني',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: isSubmitted
            ? _buildSuccessReceipt(context, branding)
            : _buildAdmissionForm(context, branding),
      ),
    );
  }

  Widget _buildAdmissionForm(BuildContext context, dynamic branding) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Banner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: branding.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: branding.primaryColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: branding.primaryColor.withOpacity(0.15),
                  child: Icon(LucideIcons.clipboardCheck, color: branding.primaryColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'التقديم لـ ${branding.centerName}',
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        'سجل بياناتك وسيتم حجز مقعدك والتواصل لتأكيد الحضور',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Text(
            '1. البيانات الشخصية للطالب',
            style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          TextFormField(
            controller: nameCtrl,
            decoration: const InputDecoration(
              labelText: 'اسم الطالب رباعي باللغة العربية *',
              prefixIcon: Icon(LucideIcons.user, size: 20),
            ),
            validator: (v) => v == null || v.isEmpty ? 'يرجى إدخال اسم الطالب' : null,
          ),
          const SizedBox(height: 12),

          TextFormField(
            controller: phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'رقم هاتف الطالب *',
              prefixIcon: Icon(LucideIcons.phone, size: 20),
            ),
            validator: (v) => v == null || v.length < 10 ? 'يرجى إدخال رقم هاتف صالح' : null,
          ),
          const SizedBox(height: 12),

          TextFormField(
            controller: parentPhoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'رقم هاتف ولي الأمر (المفعل عليه واتساب) *',
              prefixIcon: Icon(LucideIcons.messageSquare, size: 20),
            ),
            validator: (v) => v == null || v.length < 10 ? 'يرجى إدخال هاتف ولي الأمر' : null,
          ),
          const SizedBox(height: 12),

          TextFormField(
            controller: schoolCtrl,
            decoration: const InputDecoration(
              labelText: 'المدرسة المقيد بها الطالب',
              prefixIcon: Icon(LucideIcons.school, size: 20),
            ),
          ),

          const SizedBox(height: 24),

          Text(
            '2. المرحلة الدراسية والمجموعة',
            style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          DropdownButtonFormField<String>(
            value: selectedGrade,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'المرحلة التعليمية',
              prefixIcon: Icon(LucideIcons.graduationCap, size: 20),
            ),
            items: const [
              DropdownMenuItem(value: 'الصف الأول الثانوي', child: Text('الصف الأول الثانوي')),
              DropdownMenuItem(value: 'الصف الثاني الثانوي', child: Text('الصف الثاني الثانوي')),
              DropdownMenuItem(value: 'الصف الثالث الثانوي', child: Text('الصف الثالث الثانوي')),
            ],
            onChanged: (val) {
              if (val != null) setState(() => selectedGrade = val);
            },
          ),
          const SizedBox(height: 12),

          DropdownButtonFormField<String>(
            value: selectedGroup,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'المجموعة والمدرس المطلوب',
              prefixIcon: Icon(LucideIcons.layers, size: 20),
            ),
            items: const [
              DropdownMenuItem(
                value: '3ث لغة عربية (أ) - أ/ أحمد كمال',
                child: Text('3ث لغة عربية (أ) - أ/ أحمد كمال'),
              ),
              DropdownMenuItem(
                value: '2ث كيمياء (ب) - أ/ حسام فؤاد',
                child: Text('2ث كيمياء (ب) - أ/ حسام فؤاد'),
              ),
              DropdownMenuItem(
                value: '1ث فيزياء (ج) - أ/ محمد إبراهيم',
                child: Text('1ث فيزياء (ج) - أ/ محمد إبراهيم'),
              ),
            ],
            onChanged: (val) {
              if (val != null) setState(() => selectedGroup = val);
            },
          ),
          const SizedBox(height: 12),

          TextFormField(
            controller: notesCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'ملاحظات أو أسئلة إضافية (اختياري)',
              prefixIcon: Icon(LucideIcons.messageCircle, size: 20),
            ),
          ),

          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              icon: const Icon(LucideIcons.send, size: 18),
              label: Text(
                'إرسال طلب الحجز',
                style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              onPressed: _submitApplication,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessReceipt(BuildContext context, dynamic branding) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(LucideIcons.checkCircle2, color: Color(0xFF10B981), size: 54),
        ),
        const SizedBox(height: 16),
        Text(
          'تم استلام طلب التقديم بنجاح! 🎉',
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'سيقوم فريق الاستقبال في ${branding.centerName} بمراجعة الطلب والتواصل معكم عبر واتساب لتأكيد موعد الحصة واستلام الكارت.',
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey[700], height: 1.6),
        ),
        const SizedBox(height: 24),

        // Digital Booking Voucher Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: branding.primaryColor.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Text('رقم استمارة الحجز الرسمية', style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 4),
              Text(
                generatedAppId,
                style: GoogleFonts.cairo(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: branding.primaryColor,
                  letterSpacing: 1.2,
                ),
              ),
              const Divider(height: 24),
              _buildReceiptRow('اسم الطالب:', nameCtrl.text),
              _buildReceiptRow('هاتف ولي الأمر:', parentPhoneCtrl.text),
              _buildReceiptRow('المرحلة:', selectedGrade),
              _buildReceiptRow('المجموعة المختارة:', selectedGroup),
              const Divider(height: 24),
              const Icon(LucideIcons.qrCode, size: 70),
              const SizedBox(height: 6),
              Text(
                'قدم هذا الكود للاستقبال بالسنتر لتسريع استلام كارت الحضور',
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            icon: const Icon(LucideIcons.refreshCw, size: 16),
            label: const Text('تقديم طلب لطالب آخر'),
            onPressed: () {
              setState(() {
                nameCtrl.clear();
                phoneCtrl.clear();
                parentPhoneCtrl.clear();
                schoolCtrl.clear();
                notesCtrl.clear();
                isSubmitted = false;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey)),
          Text(value, style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
