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

  Future<Map<String, dynamic>?> getStudentProfile(String id) async {
    try {
      final res = await _dio.get('/students/$id/profile');
      return res.data as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('Error getStudentProfile: $e');
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

  Future<List<Map<String, dynamic>>> syncStages(List<String> stages) async {
    try {
      final res = await _dio.post('/academic/sync-stages', data: {'stages': stages});
      if (res.data is List) {
        return List<Map<String, dynamic>>.from(res.data);
      }
      return [];
    } catch (e) {
      debugPrint('Error syncStages: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> createAcademicYear(Map<String, dynamic> data) async {
    try {
      final res = await _dio.post('/academic/years', data: data);
      return res.data as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('Error createAcademicYear: $e');
      rethrow;
    }
  }

  Future<bool> deleteAcademicYear(String id) async {
    try {
      await _dio.delete('/academic/years/$id');
      return true;
    } catch (e) {
      debugPrint('Error deleteAcademicYear: $e');
      return false;
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

  Future<Map<String, dynamic>?> createSubject(Map<String, dynamic> data) async {
    try {
      final res = await _dio.post('/academic/subjects', data: data);
      return res.data as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('Error createSubject: $e');
      rethrow;
    }
  }

  Future<bool> deleteSubject(String id) async {
    try {
      await _dio.delete('/academic/subjects/$id');
      return true;
    } catch (e) {
      debugPrint('Error deleteSubject: $e');
      return false;
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

  Future<Map<String, dynamic>?> getTeacher(String id) async {
    try {
      final res = await _dio.get('/teachers/$id');
      return res.data as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('Error getTeacher: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> updateTeacher(String id, Map<String, dynamic> data) async {
    try {
      final res = await _dio.put('/teachers/$id', data: data);
      return res.data as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('Error updateTeacher: $e');
      rethrow;
    }
  }

  Future<void> deleteTeacher(String id) async {
    try {
      await _dio.delete('/teachers/$id');
    } catch (e) {
      debugPrint('Error deleteTeacher: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> resetTeacherPassword(String id, String password) async {
    try {
      final res = await _dio.post('/teachers/$id/reset-password', data: {'password': password});
      return res.data as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('Error resetTeacherPassword: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> createTeacherPayout(Map<String, dynamic> data) async {
    try {
      final res = await _dio.post('/teachers/payouts', data: data);
      return res.data as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('Error createTeacherPayout: $e');
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
      return res.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error scanAttendance: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getGroupAttendance(String groupId, {String? date, String? sessionId}) async {
    try {
      final params = <String, dynamic>{};
      if (date != null) params['date'] = date;
      if (sessionId != null && sessionId.isNotEmpty) params['sessionId'] = sessionId;
      final res = await _dio.get('/attendance/group/$groupId', queryParameters: params);
      if (res.data is List) {
        return List<Map<String, dynamic>>.from(res.data);
      }
      return [];
    } catch (e) {
      debugPrint('Error getGroupAttendance: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getGroupSessions(String groupId) async {
    try {
      final res = await _dio.get('/academic/groups/$groupId/sessions');
      if (res.data is List) {
        return List<Map<String, dynamic>>.from(res.data);
      }
      return [];
    } catch (e) {
      debugPrint('Error getGroupSessions: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> recordAssessment(Map<String, dynamic> data) async {
    try {
      final res = await _dio.post('/attendance/assessment', data: data);
      return Map<String, dynamic>.from(res.data);
    } catch (e) {
      debugPrint('Error recordAssessment: $e');
      rethrow;
    }
  }

  Future<bool> recordAbsence(String studentId, String groupId) async {
    try {
      await _dio.post('/attendance/record-absence', data: {
        'studentId': studentId,
        'groupId': groupId,
      });
      return true;
    } catch (e) {
      debugPrint('Error recordAbsence: $e');
      return false;
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

  Future<List<Map<String, dynamic>>> getLowStockBooks() async {
    try {
      final res = await _dio.get('/books/low-stock');
      if (res.data is List) {
        return List<Map<String, dynamic>>.from(res.data);
      }
      return [];
    } catch (e) {
      debugPrint('Error getLowStockBooks: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> createBook(Map<String, dynamic> data) async {
    try {
      final res = await _dio.post('/books', data: data);
      return Map<String, dynamic>.from(res.data);
    } catch (e) {
      debugPrint('Error createBook: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> updateBook(String id, Map<String, dynamic> data) async {
    try {
      final res = await _dio.put('/books/$id', data: data);
      return Map<String, dynamic>.from(res.data);
    } catch (e) {
      debugPrint('Error updateBook: $e');
      rethrow;
    }
  }

  Future<bool> deleteBook(String id) async {
    try {
      await _dio.delete('/books/$id');
      return true;
    } catch (e) {
      debugPrint('Error deleteBook: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> sellBook({
    required String bookId,
    required String studentCode,
    int quantity = 1,
    String paymentMethod = 'CASH',
  }) async {
    try {
      final res = await _dio.post('/books/sell', data: {
        'bookId': bookId,
        'studentCode': studentCode,
        'quantity': quantity,
        'paymentMethod': paymentMethod,
      });
      return Map<String, dynamic>.from(res.data);
    } catch (e) {
      debugPrint('Error sellBook: $e');
      rethrow;
    }
  }

  // ==========================================
  // 7. Finance, Cashier & Analytics APIs
  // ==========================================
  Future<Map<String, dynamic>> getFinanceOverview() async {
    try {
      final res = await _dio.get('/finance/overview');
      if (res.data is Map) {
        return Map<String, dynamic>.from(res.data);
      }
      return {};
    } catch (e) {
      debugPrint('Error getFinanceOverview: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> getTransactions({
    int page = 1,
    int limit = 50,
    String? method,
    String? type,
    String? teacherId,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (method != null && method != 'الكل') queryParams['method'] = method;
      if (type != null && type != 'الكل') queryParams['type'] = type;
      if (teacherId != null && teacherId != 'الكل') queryParams['teacherId'] = teacherId;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final res = await _dio.get('/finance/transactions', queryParameters: queryParams);
      if (res.data is Map) {
        return Map<String, dynamic>.from(res.data);
      }
      return {'items': [], 'totalCount': 0};
    } catch (e) {
      debugPrint('Error getTransactions: $e');
      return {'items': [], 'totalCount': 0};
    }
  }

  Future<Map<String, dynamic>?> createTransaction(Map<String, dynamic> data) async {
    try {
      final res = await _dio.post('/finance/transactions', data: data);
      return Map<String, dynamic>.from(res.data);
    } catch (e) {
      debugPrint('Error createTransaction: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> closeShift(Map<String, dynamic> data) async {
    try {
      final res = await _dio.post('/finance/shift-closing', data: data);
      return Map<String, dynamic>.from(res.data);
    } catch (e) {
      debugPrint('Error closeShift: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getDailyFinanceReport({String? date}) async {
    try {
      final q = date != null ? '?date=$date' : '';
      final res = await _dio.get('/finance/daily-report$q');
      if (res.data is Map) {
        return Map<String, dynamic>.from(res.data);
      }
      return {};
    } catch (e) {
      debugPrint('Error getDailyFinanceReport: $e');
      return {};
    }
  }

  // ==========================================
  // 8. Staff & Assistants Management APIs
  // ==========================================
  Future<List<Map<String, dynamic>>> getStaff() async {
    try {
      final res = await _dio.get('/tenants/staff');
      if (res.data is List) {
        return List<Map<String, dynamic>>.from(res.data);
      }
      return [];
    } catch (e) {
      debugPrint('Error getStaff: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> createStaff(Map<String, dynamic> data) async {
    try {
      final res = await _dio.post('/tenants/staff', data: data);
      return Map<String, dynamic>.from(res.data);
    } catch (e) {
      debugPrint('Error createStaff: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> updateStaff(String id, Map<String, dynamic> data) async {
    try {
      final res = await _dio.put('/tenants/staff/$id', data: data);
      return Map<String, dynamic>.from(res.data);
    } catch (e) {
      debugPrint('Error updateStaff: $e');
      rethrow;
    }
  }

  Future<bool> deleteStaff(String id) async {
    try {
      await _dio.delete('/tenants/staff/$id');
      return true;
    } catch (e) {
      debugPrint('Error deleteStaff: $e');
      return false;
    }
  }

  // ==========================================
  // 9. Teachers & Settlements APIs
  // ==========================================
  Future<Map<String, dynamic>?> calculateTeacherPayout(Map<String, dynamic> data) async {
    try {
      final res = await _dio.post('/teachers/payouts/calculate', data: data);
      return Map<String, dynamic>.from(res.data);
    } catch (e) {
      debugPrint('Error calculateTeacherPayout: $e');
      rethrow;
    }
  }

  // ==========================================
  // 10. Storefront & Online Platform Courses APIs
  // ==========================================
  Future<List<Map<String, dynamic>>> getCourses() async {
    try {
      final res = await _dio.get('/courses');
      if (res.data is List) {
        return List<Map<String, dynamic>>.from(res.data);
      }
      return [];
    } catch (e) {
      debugPrint('Error getCourses: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> createCourse(Map<String, dynamic> data) async {
    try {
      final res = await _dio.post('/courses', data: data);
      return Map<String, dynamic>.from(res.data);
    } catch (e) {
      debugPrint('Error createCourse: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getCourseDetails(String courseId) async {
    try {
      final res = await _dio.get('/courses/$courseId');
      return Map<String, dynamic>.from(res.data);
    } catch (e) {
      debugPrint('Error getCourseDetails: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> addChapter(String courseId, Map<String, dynamic> data) async {
    try {
      final res = await _dio.post('/courses/$courseId/chapters', data: data);
      return Map<String, dynamic>.from(res.data);
    } catch (e) {
      debugPrint('Error addChapter: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> updateChapter(String chapterId, Map<String, dynamic> data) async {
    try {
      final res = await _dio.put('/courses/chapters/$chapterId', data: data);
      return Map<String, dynamic>.from(res.data);
    } catch (e) {
      debugPrint('Error updateChapter: $e');
      rethrow;
    }
  }

  Future<bool> deleteChapter(String chapterId) async {
    try {
      final res = await _dio.delete('/courses/chapters/$chapterId');
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      debugPrint('Error deleteChapter: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> addLesson(String chapterId, Map<String, dynamic> data) async {
    try {
      final res = await _dio.post('/courses/chapters/$chapterId/lessons', data: data);
      return Map<String, dynamic>.from(res.data);
    } catch (e) {
      debugPrint('Error addLesson: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> updateLesson(String lessonId, Map<String, dynamic> data) async {
    try {
      final res = await _dio.put('/courses/lessons/$lessonId', data: data);
      return Map<String, dynamic>.from(res.data);
    } catch (e) {
      debugPrint('Error updateLesson: $e');
      rethrow;
    }
  }

  Future<bool> deleteLesson(String lessonId) async {
    try {
      final res = await _dio.delete('/courses/lessons/$lessonId');
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      debugPrint('Error deleteLesson: $e');
      rethrow;
    }
  }

  Future<bool> reorderLessons(String chapterId, List<String> lessonIds) async {
    try {
      final res = await _dio.post('/courses/chapters/$chapterId/reorder', data: {'lessonIds': lessonIds});
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      debugPrint('Error reorderLessons: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> createExam(Map<String, dynamic> data) async {
    try {
      final res = await _dio.post('/exams', data: data);
      return Map<String, dynamic>.from(res.data);
    } catch (e) {
      debugPrint('Error createExam: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getExam(String examId) async {
    try {
      final res = await _dio.get('/exams/$examId');
      return Map<String, dynamic>.from(res.data);
    } catch (e) {
      debugPrint('Error getExam: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> updateExam(String examId, Map<String, dynamic> data) async {
    try {
      final res = await _dio.put('/exams/$examId', data: data);
      return Map<String, dynamic>.from(res.data);
    } catch (e) {
      debugPrint('Error updateExam: $e');
      rethrow;
    }
  }

  Future<bool> deleteExam(String examId) async {
    try {
      final res = await _dio.delete('/exams/$examId');
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      debugPrint('Error deleteExam: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> grantCourseToGroup(String courseId, String groupId) async {
    try {
      final res = await _dio.post('/courses/$courseId/grant-group', data: {'groupId': groupId});
      return Map<String, dynamic>.from(res.data);
    } catch (e) {
      debugPrint('Error grantCourseToGroup: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> grantCourseToGroups(String courseId, List<String> groupIds) async {
    try {
      final res = await _dio.post('/courses/$courseId/grant-groups', data: {'groupIds': groupIds});
      return Map<String, dynamic>.from(res.data);
    } catch (e) {
      debugPrint('Error grantCourseToGroups: $e');
      rethrow;
    }
  }

  Future<List<String>> getGrantedCourseGroups(String courseId) async {
    try {
      final res = await _dio.get('/courses/$courseId/granted-groups');
      if (res.data is List) {
        return List<String>.from((res.data as List).map((e) => e.toString()));
      }
      return [];
    } catch (e) {
      debugPrint('Error getGrantedCourseGroups: $e');
      return [];
    }
  }


  Future<Map<String, dynamic>?> getPlatformAnalytics({String? teacherId}) async {
    try {
      final query = teacherId != null ? {'teacherId': teacherId} : null;
      final res = await _dio.get('/courses/platform/analytics', queryParameters: query);
      return Map<String, dynamic>.from(res.data);
    } catch (e) {
      debugPrint('Error getPlatformAnalytics: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getTeacherPortalStats({String? teacherId}) async {
    try {
      final endpoint = teacherId != null ? '/teachers/$teacherId/dashboard-stats' : '/teachers/portal/stats';
      final res = await _dio.get(endpoint);
      return Map<String, dynamic>.from(res.data);
    } catch (e) {
      debugPrint('Error getTeacherPortalStats: $e');
      return null;
    }
  }


  Future<Map<String, dynamic>?> getCurrentTenant() async {
    try {
      final res = await _dio.get('/tenants/current');
      return Map<String, dynamic>.from(res.data);
    } catch (e) {
      debugPrint('Error getCurrentTenant: $e');
      return null;
    }
  }
  Future<bool> updateStorefrontConfig(Map<String, dynamic> config) async {
    try {
      final res = await _dio.put('/storefront/config', data: config);
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      debugPrint('Error updateStorefrontConfig: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getPublicStorefront(String host) async {
    try {
      final res = await _dio.get('/storefront/public/$host');
      return Map<String, dynamic>.from(res.data);
    } catch (e) {
      debugPrint('Error getPublicStorefront: $e');
      return null;
    }
  }

  // ==========================================
  // 11. Cloudflare R2 Uploads API
  // ==========================================
  Future<String?> uploadImageFile(dynamic file, {String folder = 'general', String? customFileName}) async {
    try {
      FormData formData;
      if (file is File) {
        final fileName = customFileName ?? file.path.split('/').last;
        formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(file.path, filename: fileName),
        });
      } else if (file is List<int>) {
        final fileName = customFileName ?? 'upload_${DateTime.now().millisecondsSinceEpoch}.jpg';
        formData = FormData.fromMap({
          'file': MultipartFile.fromBytes(file, filename: fileName),
        });
      } else {
        throw Exception('صيغة الملف غير مدعومة');
      }

      final res = await _dio.post(
        '/uploads?folder=$folder',
        data: formData,
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = res.data;
        if (data['file'] != null && data['file']['url'] != null) {
          String url = data['file']['url'].toString();
          if (url.startsWith('/')) {
            url = '${AppConstants.productionApiBaseUrl}$url';
          }
          return url;
        }
      }
      throw Exception(res.data?['message'] ?? 'فشل خادم التخزين في حفظ الملف');
    } catch (e) {
      debugPrint('Error uploadImageFile: $e');
      rethrow;
    }
  }

  // ==========================================
  // 12. Branding & Tenant Settings
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

  // ==========================================
  // 13. Slug Availability & Staff Activities
  // ==========================================
  Future<Map<String, dynamic>> checkSubdomainAvailability(String slug) async {
    try {
      final res = await _dio.get('/tenants/check-subdomain/$slug');
      return Map<String, dynamic>.from(res.data);
    } catch (e) {
      debugPrint('Error checkSubdomainAvailability: $e');
      return {'available': false, 'slug': slug, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>?> getStaffActivityProfile(String staffId, {String timeRange = 'today'}) async {
    try {
      final res = await _dio.get('/tenants/staff/$staffId/activity', queryParameters: {'timeRange': timeRange});
      return Map<String, dynamic>.from(res.data);
    } catch (e) {
      debugPrint('Error getStaffActivityProfile: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getMyAssistantActivity({String timeRange = 'today'}) async {
    try {
      final res = await _dio.get('/tenants/staff/me/activity', queryParameters: {'timeRange': timeRange});
      return Map<String, dynamic>.from(res.data);
    } catch (e) {
      debugPrint('Error getMyAssistantActivity: $e');
      return null;
    }
  }
}

