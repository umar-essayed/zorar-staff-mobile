import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/edu_api_service.dart';

class OfflineAttendanceItem {
  final String id;
  final String identifier;
  final String groupId;
  final String? sessionId;
  final String? studentName;
  final DateTime scannedAt;

  OfflineAttendanceItem({
    required this.id,
    required this.identifier,
    required this.groupId,
    this.sessionId,
    this.studentName,
    required this.scannedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'identifier': identifier,
    'groupId': groupId,
    if (sessionId != null) 'sessionId': sessionId,
    if (studentName != null) 'studentName': studentName,
    'scannedAt': scannedAt.toIso8601String(),
  };

  factory OfflineAttendanceItem.fromJson(Map<String, dynamic> json) => OfflineAttendanceItem(
    id: json['id'] ?? UniqueKey().toString(),
    identifier: json['identifier'] ?? '',
    groupId: json['groupId'] ?? '',
    sessionId: json['sessionId'],
    studentName: json['studentName'],
    scannedAt: json['scannedAt'] != null ? DateTime.parse(json['scannedAt']) : DateTime.now(),
  );
}

class SyncReport {
  final int total;
  final int synced;
  final int failed;
  final int alreadyRecorded;

  SyncReport({
    required this.total,
    required this.synced,
    required this.failed,
    required this.alreadyRecorded,
  });
}

class OfflineAttendanceService {
  static const String _storageKey = 'offline_attendance_queue_v1';
  static final OfflineAttendanceService _instance = OfflineAttendanceService._internal();

  factory OfflineAttendanceService() => _instance;
  OfflineAttendanceService._internal();

  Future<List<OfflineAttendanceItem>> getQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.isEmpty) return [];
      final list = jsonDecode(raw) as List;
      return list.map((e) => OfflineAttendanceItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error getting offline queue: $e');
      return [];
    }
  }

  Future<int> getCount() async {
    final queue = await getQueue();
    return queue.length;
  }

  Future<bool> enqueue({
    required String identifier,
    required String groupId,
    String? sessionId,
    String? studentName,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentQueue = await getQueue();

      // Avoid exact duplicates in the queue
      final exists = currentQueue.any(
        (item) => item.identifier == identifier && item.groupId == groupId && item.sessionId == sessionId,
      );
      if (exists) {
        return false;
      }

      final newItem = OfflineAttendanceItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        identifier: identifier,
        groupId: groupId,
        sessionId: sessionId,
        studentName: studentName,
        scannedAt: DateTime.now(),
      );

      currentQueue.add(newItem);
      await prefs.setString(_storageKey, jsonEncode(currentQueue.map((e) => e.toJson()).toList()));
      return true;
    } catch (e) {
      debugPrint('Error enqueueing offline attendance: $e');
      return false;
    }
  }

  Future<void> remove(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentQueue = await getQueue();
      currentQueue.removeWhere((item) => item.id == id);
      await prefs.setString(_storageKey, jsonEncode(currentQueue.map((e) => e.toJson()).toList()));
    } catch (e) {
      debugPrint('Error removing offline attendance: $e');
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  Future<SyncReport> syncQueue() async {
    final queue = await getQueue();
    if (queue.isEmpty) {
      return SyncReport(total: 0, synced: 0, failed: 0, alreadyRecorded: 0);
    }

    int syncedCount = 0;
    int alreadyCount = 0;
    int failedCount = 0;
    final remaining = <OfflineAttendanceItem>[];

    for (final item in queue) {
      try {
        await EduApiService().scanAttendance(
          identifier: item.identifier,
          groupId: item.groupId,
          sessionId: item.sessionId,
          forceGrace: true,
        );
        syncedCount++;
      } catch (e) {
        if (e is DioException) {
          final code = e.response?.statusCode;
          final data = e.response?.data;
          final msg = data is Map ? (data['message']?.toString() ?? '') : '';

          // If attendance is already marked or student not in group/forbidden logic that is permanent
          if (code == 400 || code == 409 || msg.contains('مسبق') || msg.contains('بالفعل')) {
            alreadyCount++;
            continue; // Dropped from queue because it's resolved or permanently failed
          }

          // Connection failure - stop sync attempt and keep remaining queue intact
          if (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.connectionError ||
              e.type == DioExceptionType.sendTimeout ||
              e.type == DioExceptionType.receiveTimeout) {
            remaining.add(item);
            failedCount++;
            // Don't hammer failing connection
            break;
          }
        }

        // Generic error: retain for future retry
        remaining.add(item);
        failedCount++;
      }
    }

    // Save updated queue back to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(remaining.map((e) => e.toJson()).toList()));

    return SyncReport(
      total: queue.length,
      synced: syncedCount,
      failed: failedCount,
      alreadyRecorded: alreadyCount,
    );
  }
}
