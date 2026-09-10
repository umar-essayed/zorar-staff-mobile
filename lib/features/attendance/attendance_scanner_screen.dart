import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:dio/dio.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/network/edu_api_service.dart';
import '../../core/providers/edu_data_providers.dart';
import '../../core/services/offline_attendance_service.dart';
import '../../core/services/sound_service.dart';
import '../../core/services/whatsapp_service.dart';
import '../../core/theme/branding_provider.dart';
import '../auth/auth_provider.dart';
import 'emergency_session_dialog.dart';

class AttendanceScannerScreen extends ConsumerStatefulWidget {
  final String? initialGroupId;
  const AttendanceScannerScreen({super.key, this.initialGroupId});

  @override
  ConsumerState<AttendanceScannerScreen> createState() => _AttendanceScannerScreenState();
}

class _AttendanceScannerScreenState extends ConsumerState<AttendanceScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    formats: const [
      BarcodeFormat.code128,
      BarcodeFormat.code39,
      BarcodeFormat.code93,
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
      BarcodeFormat.qrCode,
    ],
  );

  String? _selectedYearId;
  String? _selectedSubjectId;
  String? _selectedGroupId;
  String? _selectedSessionId;
  List<Map<String, dynamic>> _groupSessions = [];
  bool _isLoadingSessions = false;

  final _manualCodeCtrl = TextEditingController();
  bool _isProcessing = false;
  bool _torchOn = false;
  String? _lastScanFeedback;
  Color? _feedbackColor;
  String? _lastScannedCode;
  DateTime? _lastScannedTime;

  int _offlineCount = 0;
  bool _isSyncingOffline = false;

  @override
  void initState() {
    super.initState();
    _selectedGroupId = widget.initialGroupId;
    if (_selectedGroupId != null) {
      _fetchSessionsForGroup(_selectedGroupId!);
    }
    _loadOfflineCount();
  }

  Future<void> _loadOfflineCount() async {
    final count = await OfflineAttendanceService().getCount();
    if (mounted) {
      setState(() => _offlineCount = count);
      if (count > 0 && !_isSyncingOffline) {
        _syncOfflineQueue(silent: true);
      }
    }
  }

  Future<void> _syncOfflineQueue({bool silent = false}) async {
    if (_isSyncingOffline) return;
    setState(() => _isSyncingOffline = true);

    try {
      final report = await OfflineAttendanceService().syncQueue();
      await _loadOfflineCount();

      if (mounted) {
        if (!silent && report.total > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'تمت المزامنة بنجاح: تم رفع ${report.synced} طالب ✅ (المتبقي: $_offlineCount)',
                style: GoogleFonts.cairo(),
              ),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        }
        if (_selectedGroupId != null) {
          ref.invalidate(liveSessionAttendanceProvider((groupId: _selectedGroupId!, sessionId: _selectedSessionId)));
          ref.invalidate(liveGroupAttendanceProvider(_selectedGroupId!));
        }
      }
    } catch (e) {
      debugPrint('Sync queue error: $e');
    } finally {
      if (mounted) {
        setState(() => _isSyncingOffline = false);
      }
    }
  }

  Future<void> _fetchSessionsForGroup(String groupId) async {
    setState(() {
      _isLoadingSessions = true;
      _selectedSessionId = null;
      _groupSessions = [];
    });
    try {
      final sessions = await EduApiService().getGroupSessions(groupId);
      if (mounted) {
        setState(() {
          _groupSessions = sessions;
          _isLoadingSessions = false;
          // Find currently open/in-progress session or fallback to first
          if (sessions.isNotEmpty) {
            final active = sessions.firstWhere(
              (s) => s['status'] == 'IN_PROGRESS' || s['status'] == 'OPEN',
              orElse: () => sessions.first,
            );
            _selectedSessionId = active['id']?.toString();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingSessions = false);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _manualCodeCtrl.dispose();
    super.dispose();
  }

  void _onBarcodeDetect(BarcodeCapture capture) {
    if (_isProcessing || _selectedGroupId == null) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final rawValue = barcodes.first.rawValue?.trim();
    if (rawValue == null || rawValue.isEmpty) return;

    // Fast client-side debounce: ignore repeated scans of identical code within 3 seconds
    final now = DateTime.now();
    if (_lastScannedCode == rawValue &&
        _lastScannedTime != null &&
        now.difference(_lastScannedTime!).inSeconds < 3) {
      return;
    }

    _lastScannedCode = rawValue;
    _lastScannedTime = now;
    _processAttendance(rawValue);
  }

  Future<void> _processAttendance(String code) async {
    if (_selectedGroupId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('يرجى تحديد المجموعة أولاً قبل المسح', style: GoogleFonts.cairo()),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);
    SoundService.lightImpact();

    try {
      final res = await EduApiService().scanAttendance(
        identifier: code,
        groupId: _selectedGroupId!,
        sessionId: _selectedSessionId,
      );

      SoundService.successFeedback();
      final student = res['student'] ?? {};
      final studentName = student['name'] ?? 'طالب مسجل';
      final status = res['status'] ?? 'PRESENT';
      final isLate = status == 'LATE';
      final msg = res['message'] ?? (isLate ? 'تم الحضور متأخراً ⚠️' : 'تم تسجيل الحضور بنجاح ✅');

      setState(() {
        _lastScanFeedback = '$studentName • $msg';
        _feedbackColor = isLate ? const Color(0xFFF59E0B) : const Color(0xFF10B981);
      });

      // Refresh group and session attendance list
      ref.invalidate(liveSessionAttendanceProvider((groupId: _selectedGroupId!, sessionId: _selectedSessionId)));
      ref.invalidate(liveGroupAttendanceProvider(_selectedGroupId!));

      // If we have offline items queued, silently trigger a sync in the background
      if (_offlineCount > 0) {
        _syncOfflineQueue(silent: true);
      }
    } catch (e) {
      bool isNetworkError = false;
      if (e is DioException) {
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.connectionError) {
          isNetworkError = true;
        }
      } else if (e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup') ||
          e.toString().contains('Network is unreachable')) {
        isNetworkError = true;
      }

      if (isNetworkError) {
        await OfflineAttendanceService().enqueue(
          identifier: code,
          groupId: _selectedGroupId!,
          sessionId: _selectedSessionId,
        );
        await _loadOfflineCount();
        SoundService.warningFeedback();
        setState(() {
          _lastScanFeedback = 'انقطع الإنترنت! تم الحفظ في طابور الأوفلاين 📡 (المعلق: $_offlineCount)';
          _feedbackColor = const Color(0xFFF59E0B);
        });
        return;
      }

      String errMsg = 'فشل التسجيل: تعذر الاتصال بالخادم';
      bool isWarning = false;

      if (e is DioException) {
        final resData = e.response?.data;
        if (resData != null) {
          final m = resData['message'];
          if (m != null) {
            errMsg = m is List ? m.join(', ') : m.toString();
          }
        }
        final statusCode = e.response?.statusCode;
        if (statusCode == 400 || statusCode == 409 || errMsg.contains('مسبق') || errMsg.contains('بالفعل')) {
          isWarning = true;
        }
      } else {
        errMsg = e.toString().replaceFirst('Exception: ', '');
      }

      if (isWarning) {
        SoundService.warningFeedback();
        setState(() {
          _lastScanFeedback = '$errMsg ⚠️';
          _feedbackColor = const Color(0xFFF59E0B);
        });
      } else {
        SoundService.errorFeedback();
        setState(() {
          _lastScanFeedback = '$errMsg ❌';
          _feedbackColor = const Color(0xFFEF4444);
        });
      }
    } finally {
      _manualCodeCtrl.clear();
      await Future.delayed(const Duration(milliseconds: 1400));
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(brandingProvider);
    final yearsAsync = ref.watch(liveAcademicYearsProvider);
    final subjectsAsync = ref.watch(liveSubjectsProvider);
    final groupsAsync = ref.watch(liveGroupsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'محطة تسجيل الحضور والباركود',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: _isSyncingOffline
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(LucideIcons.cloudUpload, color: Color(0xFF38BDF8)),
                tooltip: 'مزامنة الحضور الأوفلاين',
                onPressed: _isSyncingOffline ? null : () => _syncOfflineQueue(silent: false),
              ),
              if (_offlineCount > 0)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$_offlineCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: Icon(
              _torchOn ? LucideIcons.flashlight : LucideIcons.flashlightOff,
              color: _torchOn ? Colors.yellow : null,
            ),
            tooltip: 'تشغيل الفلاش',
            onPressed: () async {
              await _controller.toggleTorch();
              setState(() => _torchOn = !_torchOn);
            },
          ),
          IconButton(
            icon: const Icon(LucideIcons.calendarPlus, color: Color(0xFFF59E0B)),
            tooltip: 'فتح جلسة استثنائية',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => const EmergencySessionDialog(),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Offline Queue Banner (Shown whenever scans are waiting for sync)
            if (_offlineCount > 0)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.cloudOff, color: Color(0xFFF59E0B), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'يوجد $_offlineCount طالب مسجلين أوفلاين بانتظار المزامنة',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFF59E0B),
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _isSyncingOffline ? null : () => _syncOfflineQueue(silent: false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: _isSyncingOffline
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text('مزامنة الآن',
                              style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

            // STEP 1: Academic Year, Subject, and Group Selection (Like Web)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.15))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'تحديد المجموعة المستهدفة للحضور:',
                    style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: branding.primaryColor),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // Year Dropdown
                      Expanded(
                        child: yearsAsync.when(
                          data: (years) => DropdownButtonFormField<String>(
                            value: _selectedYearId,
                            isExpanded: true,
                            hint: Text('السنة الدراسية', style: GoogleFonts.cairo(fontSize: 11.5)),
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            items: years.map((y) {
                              return DropdownMenuItem<String>(
                                value: y['id'].toString(),
                                child: Text(y['name'] ?? '', style: GoogleFonts.cairo(fontSize: 11.5)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedYearId = val;
                                _selectedGroupId = null;
                              });
                            },
                          ),
                          loading: () => const LinearProgressIndicator(),
                          error: (_, __) => const Text('خطأ'),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Subject Dropdown
                      Expanded(
                        child: subjectsAsync.when(
                          data: (subjects) => DropdownButtonFormField<String>(
                            value: _selectedSubjectId,
                            isExpanded: true,
                            hint: Text('المادة', style: GoogleFonts.cairo(fontSize: 11.5)),
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            items: subjects.map((s) {
                              return DropdownMenuItem<String>(
                                value: s['id'].toString(),
                                child: Text(s['name'] ?? '', style: GoogleFonts.cairo(fontSize: 11.5)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedSubjectId = val;
                                _selectedGroupId = null;
                              });
                            },
                          ),
                          loading: () => const LinearProgressIndicator(),
                          error: (_, __) => const Text('خطأ'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Group Dropdown
                  groupsAsync.when(
                    data: (groups) {
                      final user = ref.watch(authProvider).user;
                      final availableGroups = groups.where((g) {
                        if (user?.isTeacher == true && user?.teacherId != null) {
                          final gTeacherId = g['teacherId']?.toString() ?? g['teacher']?['id']?.toString();
                          if (gTeacherId != user!.teacherId) return false;
                        }
                        if (_selectedYearId != null && g['academicYearId'] != _selectedYearId) return false;
                        if (_selectedSubjectId != null && g['subjectId'] != _selectedSubjectId) return false;
                        return true;
                      }).toList();

                      return DropdownButtonFormField<String>(
                        value: _selectedGroupId,
                        isExpanded: true,
                        hint: Text(
                          availableGroups.isEmpty ? 'لا توجد مجموعات مطابقة' : 'اختر المجموعة الحالية بالسنتر...',
                          style: GoogleFonts.cairo(fontSize: 12.5),
                        ),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(LucideIcons.layers, size: 18),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: branding.primaryColor),
                          ),
                        ),
                        items: availableGroups.map((g) {
                          final name = g['name'] ?? '';
                          final teacher = g['teacher']?['name'] ?? '';
                          return DropdownMenuItem<String>(
                            value: g['id'].toString(),
                            child: Text(
                              '$name ${teacher.isNotEmpty ? "($teacher)" : ""}',
                              style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.bold),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedGroupId = val;
                            _lastScanFeedback = null;
                          });
                          if (val != null) {
                            _fetchSessionsForGroup(val);
                          }
                        },
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (_, __) => const Text('خطأ في تحميل المجموعات'),
                  ),
                  if (_selectedGroupId != null) ...[
                    const SizedBox(height: 10),
                    if (_isLoadingSessions)
                      const Row(
                        children: [
                          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                          SizedBox(width: 8),
                          Text('جاري تحميل حصص وجلسات المجموعة...', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      )
                    else if (_groupSessions.isNotEmpty)
                      DropdownButtonFormField<String>(
                        value: _selectedSessionId,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'تحديد الحصة / الجلسة المستهدفة',
                          prefixIcon: const Icon(LucideIcons.calendarCheck, size: 18),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        items: _groupSessions.map((s) {
                          final num = s['sessionNumber'] ?? 1;
                          final topic = s['topic'] ?? 'حصة بدون عنوان';
                          final status = s['status'] ?? 'OPEN';
                          final isOngoing = status == 'IN_PROGRESS' || status == 'OPEN';

                          String dateLabel = '';
                          final rawDate = s['scheduledDate'] ?? s['actualDate'] ?? s['createdAt'];
                          if (rawDate != null) {
                            try {
                              final dt = DateTime.parse(rawDate.toString());
                              const days = ['الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];
                              const months = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
                              final dayName = days[dt.weekday % 7];
                              final monthName = months[dt.month - 1];
                              dateLabel = '$dayName ${dt.day} $monthName';
                            } catch (_) {}
                          }

                          return DropdownMenuItem<String>(
                            value: s['id'].toString(),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isOngoing ? Colors.green.withOpacity(0.15) : Colors.grey.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    dateLabel.isNotEmpty ? 'حصة $num • $dateLabel' : 'حصة $num',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                      color: isOngoing ? Colors.green.shade800 : Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    topic,
                                    style: GoogleFonts.cairo(fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() => _selectedSessionId = val);
                          if (_selectedGroupId != null) {
                            ref.invalidate(liveSessionAttendanceProvider((groupId: _selectedGroupId!, sessionId: val)));
                          }
                        },
                      ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 12),

            // STEP 2: Compact Barcode Scanner Box (Not 100% fullscreen, targeted 1D horizontal barcode box)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: _selectedGroupId != null ? branding.primaryColor : Colors.grey.withOpacity(0.4),
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_selectedGroupId != null ? branding.primaryColor : Colors.transparent).withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          if (_selectedGroupId != null)
                            MobileScanner(
                              controller: _controller,
                              onDetect: _onBarcodeDetect,
                            )
                          else
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(LucideIcons.scanLine, color: Colors.white54, size: 40),
                                  const SizedBox(height: 8),
                                  Text(
                                    'اختر المجموعة أولاً لتفعيل الماسح الضوئي',
                                    style: GoogleFonts.cairo(color: Colors.white70, fontSize: 12.5),
                                  ),
                                ],
                              ),
                            ),

                          // Horizontal 1D Barcode Targeting Reticle
                          if (_selectedGroupId != null)
                            Center(
                              child: Container(
                                width: 280,
                                height: 90,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Container(
                                    height: 2,
                                    width: 260,
                                    color: Colors.redAccent,
                                  ),
                                ),
                              ),
                            ),

                          // Processing Overlay
                          if (_isProcessing)
                            Container(
                              color: Colors.black54,
                              child: const Center(
                                child: CircularProgressIndicator(color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Feedback Banner
                  if (_lastScanFeedback != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: (_feedbackColor ?? branding.primaryColor).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _feedbackColor ?? branding.primaryColor),
                      ),
                      child: Text(
                        _lastScanFeedback!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: _feedbackColor ?? branding.primaryColor,
                        ),
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Manual Barcode Input Row
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _manualCodeCtrl,
                          keyboardType: TextInputType.text,
                          decoration: InputDecoration(
                            hintText: 'إدخال كود الطالب أو الباركود يدوياً...',
                            prefixIcon: const Icon(LucideIcons.barcode, size: 20),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onSubmitted: (val) {
                            if (val.trim().isNotEmpty) {
                              _processAttendance(val.trim());
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: branding.primaryColor,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(LucideIcons.check, size: 18),
                        label: const Text('تسجيل'),
                        onPressed: () {
                          if (_manualCodeCtrl.text.trim().isNotEmpty) {
                            _processAttendance(_manualCodeCtrl.text.trim());
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // STEP 3: Live Group & Session Attendance List Below Scanner
            if (_selectedGroupId != null)
              Consumer(
                builder: (context, ref, _) {
                  final attAsync = ref.watch(
                    liveSessionAttendanceProvider(
                      (groupId: _selectedGroupId!, sessionId: _selectedSessionId),
                    ),
                  );

                  String headerTitle = 'كشف حضور المجموعة';
                  if (_selectedSessionId != null && _groupSessions.isNotEmpty) {
                    final matchedSession = _groupSessions.firstWhere(
                      (s) => s['id']?.toString() == _selectedSessionId,
                      orElse: () => {},
                    );
                    if (matchedSession.isNotEmpty) {
                      final num = matchedSession['sessionNumber'] ?? 1;
                      headerTitle = 'كشف حضور حصة $num';
                    }
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  headerTitle,
                                  style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  _selectedSessionId != null
                                      ? 'مخصص للحضور الفعلي لهذه الجلسة فقط'
                                      : 'عرض حضور اليوم للمجموعة',
                                  style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(LucideIcons.refreshCw, size: 16),
                              tooltip: 'تحديث الكشف',
                              onPressed: () {
                                ref.invalidate(
                                  liveSessionAttendanceProvider(
                                    (groupId: _selectedGroupId!, sessionId: _selectedSessionId),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        attAsync.when(
                          data: (records) {
                            if (records.isEmpty) {
                              return Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    'لم يتم تسجيل أي حضور حتى الآن في هذه الحصة',
                                    style: GoogleFonts.cairo(fontSize: 12.5, color: Colors.grey),
                                  ),
                                ),
                              );
                            }

                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: records.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (ctx, idx) {
                                final item = records[idx];
                                final student = item['student'] ?? {};
                                final name = student['name'] ?? 'طالب';
                                final code = student['studentCode'] ?? '';
                                final phone = student['guardianPhone'] ?? student['phone'] ?? '';
                                final status = item['status'] ?? 'PRESENT';
                                final timeStr = item['scannedAt'] != null
                                    ? item['scannedAt'].toString().split('T').last.substring(0, 5)
                                    : 'الآن';

                                return Card(
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(color: Colors.grey.withOpacity(0.18)),
                                  ),
                                  child: ListTile(
                                    dense: true,
                                    leading: CircleAvatar(
                                      radius: 16,
                                      backgroundColor: status == 'LATE'
                                          ? const Color(0xFFF59E0B).withOpacity(0.15)
                                          : const Color(0xFF10B981).withOpacity(0.15),
                                      child: Icon(
                                        status == 'LATE' ? LucideIcons.clock : LucideIcons.check,
                                        size: 16,
                                        color: status == 'LATE' ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                                      ),
                                    ),
                                    title: Text(name, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13)),
                                    subtitle: Text('$code • تم التسجيل $timeStr', style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey)),
                                    trailing: IconButton(
                                      icon: const Icon(LucideIcons.messageSquare, color: Color(0xFF10B981), size: 18),
                                      tooltip: 'إشعار واتساب لولي الأمر',
                                      onPressed: () {
                                        WhatsAppService.sendCustomMessage(
                                          context,
                                          phone: phone,
                                          message: 'إشعار حضور: تم تسجيل حضور الطالب $name بنجاح الساعة $timeStr.',
                                        );
                                      },
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (_, __) => const Text('تعذر تحميل كشف الحضور'),
                        ),
                      ],
                    ),
                  );
                },
              ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
