import 'package:flutter/material.dart';

class AppConstants {
  static const String defaultApiBaseUrl = 'http://10.0.2.2:4000/api';
  static const String localApiBaseUrl = 'http://localhost:4000/api';

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
  static const String defaultCenterName = 'زرار كود • EduZorar Pro';
  static const String appDisplayName = 'زرار كود (Zorar Code)';
  static const Color defaultPrimaryColor = Color(0xFF0143A3); // Royal Blue #0143A3
  static const Color defaultSecondaryColor = Color(0xFFFF8A00); // Vibrant Orange #FF8A00
  static const String defaultLogoAsset = 'assets/images/zorar_icon.png';
  static const String defaultCurrency = 'ج.م';
}
