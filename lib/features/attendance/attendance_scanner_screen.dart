import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/services/sound_service.dart';
import '../../core/theme/branding_provider.dart';
import 'emergency_session_dialog.dart';

class AttendanceScannerScreen extends ConsumerStatefulWidget {
  const AttendanceScannerScreen({super.key});

  @override
  ConsumerState<AttendanceScannerScreen> createState() => _AttendanceScannerScreenState();
}

class _AttendanceScannerScreenState extends ConsumerState<AttendanceScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;
  bool _torchOn = false;
  String currentGroup = '3ث لغة عربية (أ) - الحصة 5';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final rawValue = barcodes.first.rawValue;
    if (rawValue != null && rawValue.isNotEmpty) {
      _processStudentScan(rawValue);
    }
  }

  void _processStudentScan(String code) {
    setState(() => _isProcessing = true);

    // Mock scan evaluation
    if (code.contains('1004') || code.contains('STU-1') || code.contains('010')) {
      SoundService.successFeedback();
      _showScanResultModal(
        status: 'SUCCESS',
        studentName: 'محمود عبد الرازق حسن',
        studentCode: code.toUpperCase(),
        seatNumber: 'مقعد 14 (قاعة 1)',
        message: 'تم تسجيل الحضور بنجاح • الاشتراك مسدد بالكامل ✅',
      );
    } else if (code.contains('99') || code.contains('WARN')) {
      SoundService.warningFeedback();
      _showScanResultModal(
        status: 'WARNING',
        studentName: 'سلمى إبراهيم خليل',
        studentCode: code.toUpperCase(),
        seatNumber: 'مقعد 22 (قاعة 1)',
        message: 'تم تسجيل الحضور • تنبيه: في فترة السماح ويجب تجديد الاشتراك ⚠️',
      );
    } else {
      SoundService.errorFeedback();
      _showScanResultModal(
        status: 'ERROR',
        studentName: 'طالب غير مسجل أو كود غير صالح',
        studentCode: code.toUpperCase(),
        seatNumber: 'غير مخصص',
        message: 'تنبيه: الطالب غير مقيد في هذه المجموعة أو تم مسح كود خاطئ ❌',
      );
    }
  }

  void _showScanResultModal({
    required String status,
    required String studentName,
    required String studentCode,
    required String seatNumber,
    required String message,
  }) {
    Color color;
    IconData icon;
    switch (status) {
      case 'SUCCESS':
        color = const Color(0xFF10B981);
        icon = LucideIcons.checkCircle2;
        break;
      case 'WARNING':
        color = const Color(0xFFF59E0B);
        icon = LucideIcons.alertTriangle;
        break;
      default:
        color = const Color(0xFFEF4444);
        icon = LucideIcons.xCircle;
    }

    showModalBottomSheet(
      context: context,
      isDismissible: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Icon(icon, color: color, size: 48),
              const SizedBox(height: 12),
              Text(
                studentName,
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$studentCode • $seatNumber',
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: color),
                  onPressed: () {
                    Navigator.pop(ctx);
                    setState(() => _isProcessing = false);
                  },
                  child: const Text('متابعة مسح الطالب التالي'),
                ),
              ),
            ],
          ),
        );
      },
    ).then((_) {
      if (mounted) setState(() => _isProcessing = false);
    });
  }

  void _showManualSearchDialog() {
    final searchCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تسجيل حضور يدوي بكود الطالب', style: GoogleFonts.cairo(fontSize: 15)),
        content: TextField(
          controller: searchCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'أدخل كود الطالب (مثال: STU-1004)',
            prefixIcon: Icon(LucideIcons.hash),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final code = searchCtrl.text.trim();
              Navigator.pop(ctx);
              if (code.isNotEmpty) {
                _processStudentScan(code);
              }
            },
            child: const Text('تسجيل الحضور'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(brandingProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ماسح الحضور فائق السرعة',
              style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              currentGroup,
              style: GoogleFonts.cairo(fontSize: 11.5, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _torchOn ? LucideIcons.flashlight : LucideIcons.flashlightOff,
              color: _torchOn ? Colors.yellow : Colors.white,
            ),
            tooltip: 'تشغيل الفلاش',
            onPressed: () async {
              await _controller.toggleTorch();
              setState(() => _torchOn = !_torchOn);
            },
          ),
          IconButton(
            icon: const Icon(LucideIcons.calendarPlus, color: Color(0xFFF59E0B)),
            tooltip: 'فتح حصة استثنائية',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => const EmergencySessionDialog(),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera View
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // Targeting Scanner Overlay Frame
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: branding.primaryColor, width: 3),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'QR / Barcode',
                        style: GoogleFonts.cairo(color: Colors.white, fontSize: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Control Panel
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                    icon: const Icon(LucideIcons.keyboard, size: 18),
                    label: const Text('إدخال كود يدوي'),
                    onPressed: _showManualSearchDialog,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: branding.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(LucideIcons.camera, size: 18),
                    label: const Text('تبديل الكاميرا'),
                    onPressed: () => _controller.switchCamera(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
