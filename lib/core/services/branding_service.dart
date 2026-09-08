import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class BrandingModel {
  final String centerName;
  final Color primaryColor;
  final Color secondaryColor;
  final String? logoUrl;
  final String? selectedIconAlias;
  final bool isDarkMode;

  const BrandingModel({
    required this.centerName,
    required this.primaryColor,
    required this.secondaryColor,
    this.logoUrl,
    this.selectedIconAlias,
    this.isDarkMode = false,
  });

  factory BrandingModel.defaultBranding() {
    return const BrandingModel(
      centerName: AppConstants.defaultCenterName,
      primaryColor: AppConstants.defaultPrimaryColor,
      secondaryColor: AppConstants.defaultSecondaryColor,
      isDarkMode: false,
    );
  }

  BrandingModel copyWith({
    String? centerName,
    Color? primaryColor,
    Color? secondaryColor,
    String? logoUrl,
    String? selectedIconAlias,
    bool? isDarkMode,
  }) {
    return BrandingModel(
      centerName: centerName ?? this.centerName,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      logoUrl: logoUrl ?? this.logoUrl,
      selectedIconAlias: selectedIconAlias ?? this.selectedIconAlias,
      isDarkMode: isDarkMode ?? this.isDarkMode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'centerName': centerName,
      'primaryColor': primaryColor.value,
      'secondaryColor': secondaryColor.value,
      'logoUrl': logoUrl,
      'selectedIconAlias': selectedIconAlias,
      'isDarkMode': isDarkMode,
    };
  }

  factory BrandingModel.fromJson(Map<String, dynamic> json) {
    return BrandingModel(
      centerName: json['centerName'] as String? ?? AppConstants.defaultCenterName,
      primaryColor: json['primaryColor'] != null
          ? Color(json['primaryColor'] as int)
          : AppConstants.defaultPrimaryColor,
      secondaryColor: json['secondaryColor'] != null
          ? Color(json['secondaryColor'] as int)
          : AppConstants.defaultSecondaryColor,
      logoUrl: json['logoUrl'] as String?,
      selectedIconAlias: json['selectedIconAlias'] as String?,
      isDarkMode: json['isDarkMode'] as bool? ?? false,
    );
  }
}

class BrandingService {
  static Future<BrandingModel> loadBranding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(AppConstants.keyBranding);
      if (raw != null) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        return BrandingModel.fromJson(map);
      }
    } catch (e) {
      debugPrint('Error reading branding: $e');
    }
    return BrandingModel.defaultBranding();
  }

  static Future<void> saveBranding(BrandingModel branding) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.keyBranding, jsonEncode(branding.toJson()));
    } catch (e) {
      debugPrint('Error saving branding: $e');
    }
  }
}
