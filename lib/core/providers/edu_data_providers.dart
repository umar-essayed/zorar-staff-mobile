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

// 8. Group Attendance Live Provider
final liveGroupAttendanceProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, groupId) async {
  if (groupId.isEmpty) return [];
  return await EduApiService().getGroupAttendance(groupId);
});
