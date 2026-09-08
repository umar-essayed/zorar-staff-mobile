import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'sound_service.dart';

class WhatsAppService {
  WhatsAppService._();

  /// تنظيف وتجهيز رقم الهاتف بصيغة دولية صحيحة (مثال: مصر 20)
  static String formatPhoneNumber(String rawPhone) {
    var cleaned = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.startsWith('00')) {
      cleaned = cleaned.substring(2);
    }
    if (cleaned.startsWith('0') && cleaned.length == 11) {
      cleaned = '2$cleaned';
    } else if (!cleaned.startsWith('2') && cleaned.length == 10) {
      cleaned = '20$cleaned';
    }
    return cleaned;
  }

  /// فتح محادثة واتساب مباشرة مع الطالب أو ولي الأمر مع رسالة جاهزة
  static Future<bool> launchWhatsApp({
    required BuildContext context,
    required String phone,
    required String message,
    String? feedbackTitle,
  }) async {
    final cleanPhone = formatPhoneNumber(phone);
    if (cleanPhone.isEmpty) {
      _showFeedback(context, 'رقم الهاتف غير صالح', isError: true);
      return false;
    }

    // نسخ الرسالة للحافظة كإجراء احتياطي فوري
    Clipboard.setData(ClipboardData(text: message));
    SoundService.lightImpact();

    final encodedText = Uri.encodeComponent(message);
    final nativeUri = Uri.parse('whatsapp://send?phone=$cleanPhone&text=$encodedText');
    final webUri = Uri.parse('https://wa.me/$cleanPhone?text=$encodedText');

    try {
      if (await canLaunchUrl(nativeUri)) {
        await launchUrl(nativeUri, mode: LaunchMode.externalApplication);
        SoundService.successFeedback();
        _showFeedback(context, feedbackTitle ?? 'جاري فتح تطبيق واتساب مباشرة...');
        return true;
      } else if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
        SoundService.successFeedback();
        _showFeedback(context, feedbackTitle ?? 'جاري فتح واتساب...');
        return true;
      } else {
        SoundService.successFeedback();
        _showFeedback(context, 'تم نسخ الرسالة للحافظة بنجاح، يمكنك لصقها في واتساب');
        return true;
      }
    } catch (e) {
      debugPrint('Error launching WhatsApp: $e');
      _showFeedback(context, 'تم نسخ الرسالة للحافظة لمشاركتها يدوياً');
      return false;
    }
  }

  /// 1. رسالة ترحيب بالطالب الجديد باللهجة المصرية الودودة
  static Future<bool> sendWelcomeMessage({
    required BuildContext context,
    required String phone,
    required String studentName,
    required String centerName,
  }) {
    final message = '''
منورنا يا بطل في سنتر *$centerName* 🌟
سعداء جداً بوجودك معانا، وإن شاء الله سنة دراسية كلها نجاح وتفوق وتقفيل درجات يا رب! 🎓
👤 الطالب: *$studentName*
لو محتاج أي استفسار أو مساعدة إحنا معاك خطوة بخطوة ودايماً في ضهرك! 💪✨
''';

    return launchWhatsApp(
      context: context,
      phone: phone,
      message: message.trim(),
      feedbackTitle: 'جاري فتح واتساب لإرسال رسالة الترحيب للطالب ($studentName)',
    );
  }

  /// 2. إخطار غياب ولي الأمر بلباقة ولهجة مصرية محترمة
  static Future<bool> sendAbsenceAlert({
    required BuildContext context,
    required String parentPhone,
    required String studentName,
    required String subjectName,
    required String groupName,
    required String centerName,
    String? dateStr,
  }) {
    final today = dateStr ?? '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';
    final message = '''
مساء الخير يا فندم ❤️
بنحب نطمنكم ونبلغ حضراتكم من سنتر *$centerName* إن ابننا الغالي *$studentName* غاب النهاردة عن حصة:
📚 *$subjectName* ($groupName)
📅 التاريخ: $today

بنأكد على ضرورة تعويض الحصة ومتابعة الشرح عشان ميفوتوش أي حاجة مهمة.
وربنا يوفقه دايماً يا رب ويشرفنا بأعلى الدرجات! 🌟🤲
''';

    return launchWhatsApp(
      context: context,
      phone: parentPhone,
      message: message.trim(),
      feedbackTitle: 'جاري إرسال تنبيه الغياب لولي أمر الطالب ($studentName)',
    );
  }

  /// 3. إيصال دفع وسداد رسمي وودود
  static Future<bool> sendParentReceipt({
    required BuildContext context,
    required String parentPhone,
    required String studentName,
    required String itemTitle,
    required double amount,
    required String receiptNumber,
    required String centerName,
  }) {
    final today = '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';
    final message = '''
إشعار سداد من سنتر *$centerName* 🧾✨
تم استلام مبلغ *${amount.toStringAsFixed(0)} ج.م* بنجاح.
👤 الطالب: *$studentName*
📦 البند: $itemTitle
🔢 رقم الإيصال: #$receiptNumber
📅 التاريخ: $today

شكراً لثقتكم الغالية ومنورنا دايماً في سنتر $centerName! ❤️
''';

    return launchWhatsApp(
      context: context,
      phone: parentPhone,
      message: message.trim(),
      feedbackTitle: 'جاري إرسال إيصال السداد لولي أمر الطالب ($studentName)',
    );
  }

  /// 4. رسالة تحفيز وتنبيه واجب وكويزات باللهجة المصرية
  static Future<bool> sendEncouragementAlert({
    required BuildContext context,
    required String phone,
    required String studentName,
    required String centerName,
    String? subjectName,
    String? customNote,
  }) {
    final notePart = customNote != null && customNote.isNotEmpty ? '\n💡 ملاحظة المدرس: $customNote' : '';
    final message = '''
يا بطل شادين حيلنا معاك! 🎯🔥
بنفكرك يا *$studentName* بحل الواجب ومذاكرة الحصة اللي فاتت كويس جداً عشان الكويز والتسميع الجاي في سنتر *$centerName*.${subjectName != null ? ' (مادة $subjectName)' : ''}$notePart

كلنا ثقة فيك وإنك هتشرفنا بدرجة ممتازة، متقلقش من أي حاجة وإحنا معاك خطوة بخطوة! 💪🌟
''';

    return launchWhatsApp(
      context: context,
      phone: phone,
      message: message.trim(),
      feedbackTitle: 'جاري إرسال رسالة التحفيز للطالب ($studentName)',
    );
  }

  /// 5. تقرير تقييم الحصة والواجب لولي الأمر باللهجة المصرية الودودة
  static Future<bool> sendSessionAssessmentReport({
    required BuildContext context,
    required String parentPhone,
    required String studentName,
    required String groupName,
    required int score,
    required int maxScore,
    required String homeworkStatus,
    required String centerName,
    String? behaviorNotes,
  }) {
    final hwText = homeworkStatus == 'DONE'
        ? 'تم الحل بالكامل وممتاز ⭐'
        : (homeworkStatus == 'INCOMPLETE' ? 'تم الحل جزئياً (ناقص) ⚠️' : 'لم يتم حل الواجب ❌');

    final notePart = (behaviorNotes != null && behaviorNotes.trim().isNotEmpty)
        ? '\n📝 ملاحظة المعلم: $behaviorNotes'
        : '';

    final message = '''
تقرير حصة اليوم من سنتر *$centerName* 📊✨
تحياتنا لحضراتكم، دي درجات ابننا الغالي *$studentName* في حصة ($groupName):
🎯 درجة التسميع / الكويز: *$score من $maxScore*
📚 حالة الواجب المنزلي: *$hwText*$notePart

مع تحيات سنتر $centerName وفريق العمل 🌟❤️
''';

    return launchWhatsApp(
      context: context,
      phone: parentPhone,
      message: message.trim(),
      feedbackTitle: 'جاري إرسال تقرير الحصة لولي أمر الطالب ($studentName)',
    );
  }

  /// 5. رسالة مخصصة
  static Future<bool> sendCustomMessage(
    BuildContext context, {
    required String phone,
    required String message,
  }) {
    return launchWhatsApp(
      context: context,
      phone: phone,
      message: message,
    );
  }

  static void _showFeedback(BuildContext context, String text, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? Colors.red : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Row(
          children: [
            Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13))),
          ],
        ),
      ),
    );
  }
}

