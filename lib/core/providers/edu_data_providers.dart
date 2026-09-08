import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/edu_api_service.dart';

// 1. Students Provider with search & group filtering
final studentsSearchQueryProvider = StateProvider<String>((ref) => '');
final studentsSelectedGroupFilterProvider = StateProvider<String?>((ref) => null);

final liveStudentsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final search = ref.watch(studentsSearchQueryProvider);
  final groupId = ref.watch(studentsSelectedGroupFilterProvider);
  return await EduApiService().getStudents(search: search, groupId: groupId);
});

// 2. Academic Groups Provider
final liveGroupsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return await EduApiService().getGroups();
});

// 3. Academic Years Provider
final liveAcademicYearsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return await EduApiService().getAcademicYears();
});

// 4. Academic Subjects Provider
final liveSubjectsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return await EduApiService().getSubjects();
});

// 5. Teachers Provider
final liveTeachersProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return await EduApiService().getTeachers();
});

// 6. Admissions Submissions Provider
final liveAdmissionsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return await EduApiService().getAdmissionSubmissions();
});

// 7. Books & Inventory Provider
final liveBooksProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return await EduApiService().getBooks();
});

// 8. Group & Session Attendance Live Provider
final liveGroupAttendanceProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, groupId) async {
  if (groupId.isEmpty) return [];
  return await EduApiService().getGroupAttendance(groupId);
});

final liveSessionAttendanceProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, ({String groupId, String? sessionId})>((ref, arg) async {
  if (arg.groupId.isEmpty) return [];
  return await EduApiService().getGroupAttendance(arg.groupId, sessionId: arg.sessionId);
});

// 9. Finance Overview & Analytics Provider
final liveFinanceOverviewProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return await EduApiService().getFinanceOverview();
});

// 10. Financial Transactions Provider
final transactionsMethodFilterProvider = StateProvider<String>((ref) => 'الكل');
final transactionsTypeFilterProvider = StateProvider<String>((ref) => 'الكل');
final transactionsTeacherFilterProvider = StateProvider<String>((ref) => 'الكل');
final transactionsSearchQueryProvider = StateProvider<String>((ref) => '');

final liveTransactionsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final method = ref.watch(transactionsMethodFilterProvider);
  final type = ref.watch(transactionsTypeFilterProvider);
  final teacher = ref.watch(transactionsTeacherFilterProvider);
  final search = ref.watch(transactionsSearchQueryProvider);

  return await EduApiService().getTransactions(
    method: method,
    type: type,
    teacherId: teacher,
    search: search,
  );
});

// 11. Staff & Assistants Provider
final liveStaffProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return await EduApiService().getStaff();
});

// 12. Low Stock Books Provider
final liveLowStockBooksProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return await EduApiService().getLowStockBooks();
});

// 13. Daily Report Provider
final liveDailyReportProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String?>((ref, date) async {
  return await EduApiService().getDailyFinanceReport(date: date);
});

// 14. Student Profile Live Provider
final liveStudentProfileProvider = FutureProvider.autoDispose.family<Map<String, dynamic>?, String>((ref, studentId) async {
  if (studentId.isEmpty) return null;
  return await EduApiService().getStudentProfile(studentId);
});

// 15. Online Courses Live Provider
final liveCoursesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return await EduApiService().getCourses();
});

// 16. Current Tenant Details & Quota Provider
final liveTenantDetailsProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  return await EduApiService().getCurrentTenant();
});

