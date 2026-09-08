import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'sound_service.dart';

class WhatsAppService {
  static void sendParentReceipt({
    required BuildContext context,
    required String parentPhone,
    required String studentName,
    required String itemTitle,
    required double amount,
    required String receiptNumber,
    required String centerName,
  }) {
    final message = '''
السلام عليكم ورحمة الله وبركاته،
إشعار سداد من سنتر *$centerName*:

تم استلام مبلغ *${amount.toStringAsFixed(0)} ج.م*
👤 الطالب: *$studentName*
📦 البند: $itemTitle
🧾 رقم الإيصال: $receiptNumber
📅 التاريخ: ${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}

شكراً لتعاونكم معنا! ✨
''';

    _copyAndNotify(context, message, 'تم نسخ نص إيصال الدفع وجاهز للمشاركة عبر واتساب');
  }

  static void sendAbsenceAlert({
    required BuildContext context,
    required String parentPhone,
    required String studentName,
    required String subjectName,
    required String groupName,
    required String centerName,
  }) {
    final message = '''
تنبيه غياب من سنتر *$centerName*:

نود إحاطتكم علماً بغياب الطالب:
👤 *$studentName*
عن حضور حصة مادة: *$subjectName* ($groupName)
📅 اليوم: ${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}

يرجى التواصل مع إدارة السنتر للمتابعة.
''';

  static void sendCustomMessage(
    BuildContext context, {
    required String phone,
    required String message,
  }) {
    _copyAndNotify(context, message, 'تم نسخ الرسالة وجاهزة للإرسال إلى $phone عبر واتساب');
  }

  static void _copyAndNotify(BuildContext context, String text, String feedbackText) {
    Clipboard.setData(ClipboardData(text: text));
    SoundService.successFeedback();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(feedbackText)),
          ],
        ),
      ),
    );
  }
}
