import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../core/network/api_client.dart';

class UserModel {
  final String id;
  final String name;
  final String role;
  final String email;
  final String phone;
  final String? teacherId;
  final String? tenantId;

  const UserModel({
    required this.id,
    required this.name,
    required this.role,
    required this.email,
    required this.phone,
    this.teacherId,
    this.tenantId,
  });

  bool get isAdmin => role == AppConstants.roleOwner || role == AppConstants.roleAdmin;
  bool get isAssistant => role == AppConstants.roleAssistant;
  bool get isTeacher => role == AppConstants.roleTeacher;

  String get roleArabicTitle {
    switch (role) {
      case AppConstants.roleOwner:
        return 'مالك السنتر';
      case AppConstants.roleAdmin:
        return 'مدير النظام';
      case AppConstants.roleAssistant:
        return 'مساعد واستقبال';
      case AppConstants.roleTeacher:
        return 'معلم / مدرس';
      default:
        return role;
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
      };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? 'مستخدم زُرار',
        role: json['role'] as String? ?? AppConstants.roleAdmin,
        email: json['email'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        teacherId: json['teacherId'] as String?,
        tenantId: json['tenantId'] as String?,
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
  AuthNotifier() : super(const AuthState()) {
    _loadStoredSession();
  }

  Future<void> _loadStoredSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.keyAuthToken);
      final rawUser = prefs.getString(AppConstants.keyUserData);

      if (token != null && rawUser != null) {
        final userMap = jsonDecode(rawUser) as Map<String, dynamic>;
        state = state.copyWith(
          isAuthenticated: true,
          user: UserModel.fromJson(userMap),
        );
        return;
      }
    } catch (e) {
      debugPrint('Error loading stored session: $e');
    }

    // Default to a pre-authenticated Admin demo state if no session exists
    final defaultDemoUser = const UserModel(
      id: 'demo-admin-1',
      name: 'أ/ عمر (إدارة السنتر)',
      role: AppConstants.roleOwner,
      email: 'admin@zorar.app',
      phone: '01000000001',
    );
    state = state.copyWith(
      isAuthenticated: true,
      user: defaultDemoUser,
    );
  }

  Future<bool> login(String usernameOrPhone, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await ApiClient().dio.post('/auth/login', data: {
        'username': usernameOrPhone.trim(),
        'password': password.trim(),
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        final token = data['access_token'] ?? data['token'];
        final userMap = data['user'] ?? {};

        final user = UserModel.fromJson(userMap);
        final prefs = await SharedPreferences.getInstance();
        if (token != null) {
          await prefs.setString(AppConstants.keyAuthToken, token.toString());
        }
        await prefs.setString(AppConstants.keyUserData, jsonEncode(user.toJson()));

        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          user: user,
        );
        return true;
      }
    } catch (e) {
      debugPrint('Live API login error: $e');
    }

    // Smart Fallback & Automatic Role Detection for immediate demo/offline:
    final cleanInput = usernameOrPhone.toLowerCase().trim();
    UserModel detectedUser;

    if (cleanInput.contains('teach') ||
        cleanInput.contains('مدرس') ||
        cleanInput.contains('معلم') ||
        cleanInput == '01222222223') {
      detectedUser = const UserModel(
        id: 'demo-teacher-1',
        name: 'أ/ أحمد كمال (معلم لغة عربية)',
        role: AppConstants.roleTeacher,
        email: 'teacher@zorar.app',
        phone: '01222222223',
        teacherId: 'teacher-101',
      );
    } else if (cleanInput.contains('assist') ||
        cleanInput.contains('مساعد') ||
        cleanInput.contains('استقبال') ||
        cleanInput.contains('كاشير') ||
        cleanInput == '01111111112') {
      detectedUser = const UserModel(
        id: 'demo-assistant-1',
        name: 'سارة أحمد (استقبال ومساعد سنتر)',
        role: AppConstants.roleAssistant,
        email: 'assistant@zorar.app',
        phone: '01111111112',
      );
    } else {
      // Default: Center Admin / Owner
      final displayName = cleanInput.contains('@')
          ? cleanInput.split('@')[0]
          : cleanInput.isNotEmpty
              ? 'إدارة السنتر ($cleanInput)'
              : 'أ/ عمر (إدارة السنتر)';
      detectedUser = UserModel(
        id: 'owner-auto-${DateTime.now().millisecondsSinceEpoch}',
        name: displayName,
        role: AppConstants.roleOwner,
        email: cleanInput.contains('@') ? cleanInput : 'admin@zorar.app',
        phone: cleanInput.isNotEmpty ? cleanInput : '01000000001',
      );
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyUserData, jsonEncode(detectedUser.toJson()));
    await prefs.setString(AppConstants.keyAuthToken, 'demo-token-${DateTime.now().millisecondsSinceEpoch}');

    state = state.copyWith(
      isLoading: false,
      isAuthenticated: true,
      user: detectedUser,
    );
    return true;
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
      final response = await ApiClient().dio.post('/tenants', data: {
        'name': centerName,
        'type': orgType.contains('مدرس') ? 'TEACHER' : 'CENTER',
        'subdomain': subdomain,
        'ownerName': ownerName,
        'phone': phone,
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return await login(email.isNotEmpty ? email : phone, password);
      }
    } catch (e) {
      debugPrint('Tenant registration API error: $e');
    }

    // Local Fallback: Create account immediately
    final newUser = UserModel(
      id: 'tenant-owner-${DateTime.now().millisecondsSinceEpoch}',
      name: '$ownerName ($centerName)',
      role: orgType.contains('مدرس') ? AppConstants.roleTeacher : AppConstants.roleOwner,
      email: email,
      phone: phone,
      tenantId: subdomain,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyUserData, jsonEncode(newUser.toJson()));
    await prefs.setString(AppConstants.keyAuthToken, 'demo-token-${DateTime.now().millisecondsSinceEpoch}');

    state = state.copyWith(
      isLoading: false,
      isAuthenticated: true,
      user: newUser,
    );
    return true;
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
  return AuthNotifier();
});
