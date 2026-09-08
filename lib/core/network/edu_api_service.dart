import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';
import 'api_client.dart';

class EduApiService {
  static final EduApiService _instance = EduApiService._internal();
  factory EduApiService() => _instance;
  EduApiService._internal();

  Dio get _dio => ApiClient().dio;

  // ==========================================
  // 1. Students APIs
  // ==========================================
  Future<List<Map<String, dynamic>>> getStudents({String? search, String? groupId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (groupId != null && groupId.isNotEmpty) queryParams['groupId'] = groupId;

      final res = await _dio.get('/students', queryParameters: queryParams);
      if (res.data is List) {
        return List<Map<String, dynamic>>.from(res.data);
      }
      return [];
    } catch (e) {
      debugPrint('Error getStudents: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getStudentById(String id) async {
    try {
      final res = await _dio.get('/students/$id');
      return res.data as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('Error getStudentById: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> createStudent(Map<String, dynamic> data) async {
    try {
      final res = await _dio.post('/students', data: data);
      return res.data as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('Error createStudent: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> updateStudent(String id, Map<String, dynamic> data) async {
    try {
      final res = await _dio.put('/students/$id', data: data);
      return res.data as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('Error updateStudent: $e');
      rethrow;
    }
  }

  Future<bool> deleteStudent(String id) async {
    try {
      await _dio.delete('/students/$id');
      return true;
    } catch (e) {
      debugPrint('Error deleteStudent: $e');
      return false;
    }
  }

  // ==========================================
  // 2. Academic & Groups APIs
  // ==========================================
  Future<List<Map<String, dynamic>>> getAcademicYears() async {
    try {
      final res = await _dio.get('/academic/years');
      if (res.data is List) {
        return List<Map<String, dynamic>>.from(res.data);
      }
      return [];
    } catch (e) {
      debugPrint('Error getAcademicYears: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getSubjects() async {
    try {
      final res = await _dio.get('/academic/subjects');
      if (res.data is List) {
        return List<Map<String, dynamic>>.from(res.data);
      }
      return [];
    } catch (e) {
      debugPrint('Error getSubjects: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getGroups() async {
    try {
      final res = await _dio.get('/academic/groups');
      if (res.data is List) {
        return List<Map<String, dynamic>>.from(res.data);
      }
      return [];
    } catch (e) {
      debugPrint('Error getGroups: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getGroupById(String id) async {
    try {
      final res = await _dio.get('/academic/groups/$id');
      return res.data as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('Error getGroupById: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> createGroup(Map<String, dynamic> data) async {
    try {
      final res = await _dio.post('/academic/groups', data: data);
      return res.data as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('Error createGroup: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> updateGroup(String id, Map<String, dynamic> data) async {
    try {
      final res = await _dio.put('/academic/groups/$id', data: data);
      return res.data as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('Error updateGroup: $e');
      rethrow;
    }
  }

  Future<bool> deleteGroup(String id) async {
    try {
      await _dio.delete('/academic/groups/$id');
      return true;
    } catch (e) {
      debugPrint('Error deleteGroup: $e');
      return false;
    }
  }

  // ==========================================
  // 3. Teachers APIs
  // ==========================================
  Future<List<Map<String, dynamic>>> getTeachers() async {
    try {
      final res = await _dio.get('/teachers');
      if (res.data is List) {
        return List<Map<String, dynamic>>.from(res.data);
      }
      return [];
    } catch (e) {
      debugPrint('Error getTeachers: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> createTeacher(Map<String, dynamic> data) async {
    try {
      final res = await _dio.post('/teachers', data: data);
      return res.data as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('Error createTeacher: $e');
      rethrow;
    }
  }

  // ==========================================
  // 4. Attendance & Scanning APIs
  // ==========================================
  Future<Map<String, dynamic>> scanAttendance({
    required String identifier,
    required String groupId,
    String? sessionId,
    bool forceGrace = false,
  }) async {
    try {
      final res = await _dio.post('/attendance/scan', data: {
        'identifier': identifier.trim(),
        'groupId': groupId,
        if (sessionId != null) 'sessionId': sessionId,
        'forceGrace': forceGrace,
      });
      return Map<String, dynamic>.from(res.data);
    } catch (e) {
      debugPrint('Error scanAttendance: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getGroupAttendance(String groupId, {String? date}) async {
    try {
      final q = date != null ? '?date=$date' : '';
      final res = await _dio.get('/attendance/group/$groupId$q');
      if (res.data is List) {
        return List<Map<String, dynamic>>.from(res.data);
      }
      return [];
    } catch (e) {
      debugPrint('Error getGroupAttendance: $e');
      return [];
    }
  }

  // ==========================================
  // 5. Admissions & Submissions APIs
  // ==========================================
  Future<List<Map<String, dynamic>>> getAdmissionSubmissions({String? formId}) async {
    try {
      final q = formId != null ? '?formId=$formId' : '';
      final res = await _dio.get('/admission/submissions$q');
      if (res.data is List) {
        return List<Map<String, dynamic>>.from(res.data);
      }
      return [];
    } catch (e) {
      debugPrint('Error getAdmissionSubmissions: $e');
      return [];
    }
  }

  Future<bool> approveAdmissionSubmission(String id, String academicYearId, {List<String>? groupIds}) async {
    try {
      await _dio.post('/admission/submissions/$id/approve', data: {
        'academicYearId': academicYearId,
        'groupIds': groupIds ?? [],
      });
      return true;
    } catch (e) {
      debugPrint('Error approveAdmissionSubmission: $e');
      return false;
    }
  }

  Future<bool> rejectAdmissionSubmission(String id, {String? reason}) async {
    try {
      await _dio.post('/admission/submissions/$id/reject', data: {
        'reason': reason ?? 'عدم استيفاء الشروط أو اكتمال الأعداد',
      });
      return true;
    } catch (e) {
      debugPrint('Error rejectAdmissionSubmission: $e');
      return false;
    }
  }

  // ==========================================
  // 6. Books & Inventory APIs
  // ==========================================
  Future<List<Map<String, dynamic>>> getBooks() async {
    try {
      final res = await _dio.get('/books');
      if (res.data is List) {
        return List<Map<String, dynamic>>.from(res.data);
      }
      return [];
    } catch (e) {
      debugPrint('Error getBooks: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> sellBook({
    required String bookId,
    required String studentCode,
    int quantity = 1,
  }) async {
    try {
      final res = await _dio.post('/books/sell', data: {
        'bookId': bookId,
        'studentCode': studentCode,
        'quantity': quantity,
      });
      return Map<String, dynamic>.from(res.data);
    } catch (e) {
      debugPrint('Error sellBook: $e');
      rethrow;
    }
  }

  // ==========================================
  // 7. Cloudflare R2 Uploads API
  // ==========================================
  Future<String?> uploadImageFile(dynamic file, {String folder = 'general'}) async {
    try {
      FormData formData;
      if (file is File) {
        final fileName = file.path.split('/').last;
        formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(file.path, filename: fileName),
        });
      } else if (file is List<int>) {
        formData = FormData.fromMap({
          'file': MultipartFile.fromBytes(file, filename: 'upload_${DateTime.now().millisecondsSinceEpoch}.jpg'),
        });
      } else {
        return null;
      }

      final res = await _dio.post(
        '/uploads?folder=$folder',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = res.data;
        if (data['file'] != null && data['file']['url'] != null) {
          return data['file']['url'].toString();
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error uploadImageFile: $e');
      return null;
    }
  }

  // ==========================================
  // 8. Branding & Tenant Settings
  // ==========================================
  Future<bool> updateBranding(Map<String, dynamic> brandingData) async {
    try {
      final res = await _dio.put('/tenants/branding', data: brandingData);
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      debugPrint('Error updateBranding: $e');
      return false;
    }
  }
}
