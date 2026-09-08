import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'sound_service.dart';

class ExportService {
  static void exportFinancialSummary({
    required BuildContext context,
    required String centerName,
    required double totalIncome,
    required double totalExpenses,
    required double netProfit,
    required int totalTransactions,
  }) {
    final report = '''
==============================
تقرير الإيرادات والمصروفات - $centerName
تاريخ التقرير: ${DateTime.now().toString().substring(0, 16)}
==============================
• إجمالي الإيرادات المحصلة: ${totalIncome.toStringAsFixed(0)} ج.م
• إجمالي المصروفات: ${totalExpenses.toStringAsFixed(0)} ج.م
• صافي الخزينة: ${netProfit.toStringAsFixed(0)} ج.م
• عدد العمليات المالية: $totalTransactions عملية
==============================
تم الاستخراج عبر تطبيق زرار كود المحمول
''';

    _copyAndNotify(context, report, 'تم نسخ ملخص الخزينة والماليات بنجاح');
  }

  static void exportAttendanceRoster({
    required BuildContext context,
    required String groupTitle,
    required int presentCount,
    required int absentCount,
    required List<String> presentStudents,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('كشف حضور وغياب المجموعة: $groupTitle');
    buffer.writeln('التاريخ: ${DateTime.now().toString().substring(0, 10)}');
    buffer.writeln('الحضور: $presentCount | الغياب: $absentCount');
    buffer.writeln('--------------------------------');
    for (int i = 0; i < presentStudents.length; i++) {
      buffer.writeln('${i + 1}. ${presentStudents[i]} - [حاضر]');
    }
    buffer.writeln('--------------------------------');
    buffer.writeln('زرار كود • إدارة المراكز التعليمية');

    _copyAndNotify(context, buffer.toString(), 'تم نسخ كشف الحضور بنجاح');
  }

  static void _copyAndNotify(BuildContext context, String text, String feedbackText) {
    Clipboard.setData(ClipboardData(text: text));
    SoundService.successFeedback();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF0143A3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Row(
          children: [
            const Icon(Icons.copy_all, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(feedbackText)),
          ],
        ),
      ),
    );
  }
}
