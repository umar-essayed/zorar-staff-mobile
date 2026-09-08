import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/branding_provider.dart';

class UserModel {
  final String id;
  final String name;
  final String role;
  final String email;
  final String phone;
  final String? teacherId;
  final String? tenantId;
  final Map<String, dynamic>? tenant;

  const UserModel({
    required this.id,
    required this.name,
    required this.role,
    required this.email,
    required this.phone,
    this.teacherId,
    this.tenantId,
    this.tenant,
  });

  bool get isAdmin =>
      role == 'OWNER' ||
      role == 'ADMIN' ||
      role == 'TENANT_ADMIN' ||
      role == 'SUPER_ADMIN' ||
      role == AppConstants.roleOwner ||
      role == AppConstants.roleAdmin;

  bool get isAssistant =>
      role == 'ASSISTANT' || role == 'STAFF' || role == AppConstants.roleAssistant;

  bool get isTeacher =>
      role == 'TEACHER' || role == AppConstants.roleTeacher;

  String get roleArabicTitle {
    switch (role.toUpperCase()) {
      case 'OWNER':
        return 'مالك السنتر';
      case 'TENANT_ADMIN':
        return 'المدير العام';
      case 'ADMIN':
        return 'مدير النظام';
      case 'SUPER_ADMIN':
        return 'المدير الأعلى';
      case 'ASSISTANT':
      case 'STAFF':
        return 'مساعد إداري واستقبال';
      case 'TEACHER':
        return 'المحاضر / المعلم';
      default:
        return 'عضو الفريق';
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'role': role,
        'email': email,
        'phone': phone,
        'teacherId': teacherId,
        'tenantId': tenantId,
        'tenant': tenant,
      };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? 'مستخدم زُرار',
        role: json['role'] as String? ?? 'TENANT_ADMIN',
        email: json['email'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        teacherId: json['teacherId'] as String?,
        tenantId: json['tenantId'] as String?,
        tenant: json['tenant'] as Map<String, dynamic>?,
      );
}

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final UserModel? user;
  final String? errorMessage;

  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    UserModel? user,
    String? errorMessage,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref? ref;

  AuthNotifier([this.ref]) : super(const AuthState()) {
    _loadStoredSession();
  }

  Future<void> _loadStoredSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.keyAuthToken);
      final rawUser = prefs.getString(AppConstants.keyUserData);

      if (token != null && rawUser != null && !token.startsWith('demo-')) {
        final userMap = jsonDecode(rawUser) as Map<String, dynamic>;
        final user = UserModel.fromJson(userMap);
        if (user.tenant != null && ref != null) {
          ref!.read(brandingProvider.notifier).updateFromTenant(user.tenant!);
        }
        state = state.copyWith(
          isAuthenticated: true,
          user: user,
        );
        return;
      }
    } catch (e) {
      debugPrint('Error loading stored session: $e');
    }

    // Unauthenticated state by default (no fake bypass)
    state = const AuthState(isAuthenticated: false, user: null);
  }

  Future<bool> login(String phone, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final cleanPhone = phone.trim();
      final cleanPassword = password.trim();

      if (cleanPhone.isEmpty || cleanPassword.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'يرجى إدخال رقم الهاتف وكلمة المرور',
        );
        return false;
      }

      final response = await ApiClient().dio.post('/auth/login', data: {
        'phone': cleanPhone,
        'password': cleanPassword,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        final token = data['accessToken'] ?? data['access_token'] ?? data['token'];
        final userMap = data['user'] ?? {};

        final user = UserModel.fromJson(userMap);
        final prefs = await SharedPreferences.getInstance();
        if (token != null) {
          await prefs.setString(AppConstants.keyAuthToken, token.toString());
        }
        await prefs.setString(AppConstants.keyUserData, jsonEncode(user.toJson()));

        if (user.tenant != null && ref != null) {
          await ref!.read(brandingProvider.notifier).updateFromTenant(user.tenant!);
        }

        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          user: user,
          errorMessage: null,
        );
        return true;
      } else {
        final msg = response.data?['message'] ?? 'فشل تسجيل الدخول';
        state = state.copyWith(isLoading: false, errorMessage: msg is List ? msg.join(', ') : msg.toString());
        return false;
      }
    } catch (e) {
      debugPrint('Live API login error: $e');
      String errorMsg = 'بيانات الدخول غير صحيحة أو السيرفر غير متاح';
      if (e is DioException) {
        final resData = e.response?.data;
        if (resData != null && resData['message'] != null) {
          final m = resData['message'];
          errorMsg = m is List ? m.join(', ') : m.toString();
        } else if (e.response?.statusCode == 401) {
          errorMsg = 'رقم الهاتف أو كلمة المرور غير صحيحة';
        } else if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
          errorMsg = 'انتهت مهلة الاتصال بالسيرفر، يرجى المحاولة مجدداً';
        }
      }
      state = state.copyWith(isLoading: false, errorMessage: errorMsg);
      return false;
    }
  }

  Future<bool> registerTenant({
    required String orgType,
    required String centerName,
    required String ownerName,
    required String phone,
    required String email,
    required String password,
    required String subdomain,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final cleanSubdomain = subdomain.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9-]'), '');
      if (cleanSubdomain.isEmpty) {
        state = state.copyWith(isLoading: false, errorMessage: 'يرجى إدخال اسم نطاق فرعي صحيح (أحرف إنجليزية وأرقام)');
        return false;
      }

      // Step 1: Create Tenant on backend
      final tenantRes = await ApiClient().dio.post('/tenants', data: {
        'name': centerName.trim(),
        'type': orgType.contains('مدرس') ? 'TEACHER' : 'CENTER',
        'subdomain': cleanSubdomain,
      });

      final tenantData = tenantRes.data;
      final tenantId = tenantData['id'] ?? tenantData['tenantId'];

      // Step 2: Register User as TENANT_ADMIN
      await ApiClient().dio.post('/auth/register', data: {
        'name': ownerName.trim(),
        'phone': phone.trim(),
        'password': password.trim(),
        'role': 'TENANT_ADMIN',
        'tenantId': tenantId,
      });

      // Step 3: Login with newly created credentials
      return await login(phone.trim(), password.trim());
    } catch (e) {
      debugPrint('Tenant registration API error: $e');
      String errorMsg = 'تعذر إنشاء الحساب الجديد، يرجى مراجعة البيانات';
      if (e is DioException) {
        final resData = e.response?.data;
        if (resData != null && resData['message'] != null) {
          final m = resData['message'];
          errorMsg = m is List ? m.join(', ') : m.toString();
        } else if (e.response?.statusCode == 409) {
          errorMsg = 'النطاق الفرعي أو رقم الهاتف مسجل بالفعل';
        }
      }
      state = state.copyWith(isLoading: false, errorMessage: errorMsg);
      return false;
    }
  }

  // Fast demo account switcher for immediate live testing
  void switchDemoRole(String role) {
    UserModel selected;
    switch (role) {
      case AppConstants.roleAssistant:
        selected = const UserModel(
          id: 'demo-assistant-1',
          name: 'سارة أحمد (استقبال وكاشير)',
          role: AppConstants.roleAssistant,
          email: 'assistant@zorar.app',
          phone: '01111111112',
        );
        break;
      case AppConstants.roleTeacher:
        selected = const UserModel(
          id: 'demo-teacher-1',
          name: 'مستر أحمد كمال (لغة عربية)',
          role: AppConstants.roleTeacher,
          email: 'teacher@zorar.app',
          phone: '01222222223',
          teacherId: 'teacher-101',
        );
        break;
      default:
        selected = const UserModel(
          id: 'demo-admin-1',
          name: 'أ/ عمر (إدارة السنتر)',
          role: AppConstants.roleOwner,
          email: 'admin@zorar.app',
          phone: '01000000001',
        );
    }

    state = state.copyWith(
      isAuthenticated: true,
      user: selected,
    );
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyAuthToken);
    await prefs.remove(AppConstants.keyUserData);
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});
