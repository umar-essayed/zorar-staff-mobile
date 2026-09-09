import 'package:flutter/material.dart';

class AppConstants {
  static const String productionApiBaseUrl = 'https://zoraredu-backend.vercel.app';
  static const String defaultApiBaseUrl = 'https://zoraredu-backend.vercel.app/api/v1';
  static const String localApiBaseUrl = 'https://zoraredu-backend.vercel.app/api/v1';

  // Storage Keys
  static const String keyAuthToken = 'zorar_auth_token';
  static const String keyUserData = 'zorar_user_data';
  static const String keyBranding = 'zorar_branding_data';
  static const String keyApiUrl = 'zorar_api_url';

  // Roles
  static const String roleOwner = 'OWNER';
  static const String roleAdmin = 'ADMIN';
  static const String roleAssistant = 'ASSISTANT';
  static const String roleTeacher = 'TEACHER';

  // Official Zorar Code Brand Identity
  static const String defaultCenterName = 'EduZorar';
  static const String appDisplayName = 'EduZorar';
  static const Color defaultPrimaryColor = Color(0xFF0143A3); // Royal Blue #0143A3
  static const Color defaultSecondaryColor = Color(0xFFFF8A00); // Vibrant Orange #FF8A00
  static const String defaultLogoAsset = 'assets/images/zorar_icon.png';
  static const String defaultCurrency = 'ج.م';
}
