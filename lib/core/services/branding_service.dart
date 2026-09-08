import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class BrandingModel {
  final String centerName;
  final String subdomain;
  final Color primaryColor;
  final Color secondaryColor;
  final String? logoUrl;
  final String? heroBannerUrl;
  final String? selectedIconAlias;
  final bool isDarkMode;

  const BrandingModel({
    required this.centerName,
    this.subdomain = 'center-alnoor',
    required this.primaryColor,
    required this.secondaryColor,
    this.logoUrl,
    this.heroBannerUrl,
    this.selectedIconAlias,
    this.isDarkMode = false,
  });

  factory BrandingModel.defaultBranding() {
    return const BrandingModel(
      centerName: AppConstants.defaultCenterName,
      subdomain: 'center-alnoor',
      primaryColor: AppConstants.defaultPrimaryColor,
      secondaryColor: AppConstants.defaultSecondaryColor,
      isDarkMode: false,
    );
  }

  BrandingModel copyWith({
    String? centerName,
    String? subdomain,
    Color? primaryColor,
    Color? secondaryColor,
    String? logoUrl,
    String? heroBannerUrl,
    String? selectedIconAlias,
    bool? isDarkMode,
  }) {
    return BrandingModel(
      centerName: centerName ?? this.centerName,
      subdomain: subdomain ?? this.subdomain,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      logoUrl: logoUrl ?? this.logoUrl,
      heroBannerUrl: heroBannerUrl ?? this.heroBannerUrl,
      selectedIconAlias: selectedIconAlias ?? this.selectedIconAlias,
      isDarkMode: isDarkMode ?? this.isDarkMode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'centerName': centerName,
      'subdomain': subdomain,
      'primaryColor': primaryColor.value,
      'secondaryColor': secondaryColor.value,
      'logoUrl': logoUrl,
      'heroBannerUrl': heroBannerUrl,
      'selectedIconAlias': selectedIconAlias,
      'isDarkMode': isDarkMode,
    };
  }

  static Color parseHexColor(String? hexString, Color defaultColor) {
    if (hexString == null || hexString.isEmpty) return defaultColor;
    String hex = hexString.replaceAll('#', '').trim();
    if (hex.length == 6) hex = 'FF$hex';
    final val = int.tryParse(hex, radix: 16);
    return val != null ? Color(val) : defaultColor;
  }

  factory BrandingModel.fromTenant(Map<String, dynamic> tenant, {BrandingModel? current}) {
    final cur = current ?? BrandingModel.defaultBranding();
    final name = tenant['name']?.toString();
    final subdomain = tenant['subdomain']?.toString();
    final brandingConfig = tenant['brandingConfig'] as Map<String, dynamic>? ?? {};
    final logoUrl = brandingConfig['logoUrl']?.toString() ?? tenant['logoUrl']?.toString();
    final primaryColor = parseHexColor(brandingConfig['primaryColor']?.toString(), cur.primaryColor);
    final secondaryColor = parseHexColor(brandingConfig['secondaryColor']?.toString(), cur.secondaryColor);

    return cur.copyWith(
      centerName: (name != null && name.isNotEmpty) ? name : cur.centerName,
      subdomain: (subdomain != null && subdomain.isNotEmpty) ? subdomain : cur.subdomain,
      primaryColor: primaryColor,
      secondaryColor: secondaryColor,
      logoUrl: (logoUrl != null && logoUrl.isNotEmpty) ? logoUrl : cur.logoUrl,
    );
  }

  factory BrandingModel.fromJson(Map<String, dynamic> json) {
    return BrandingModel(
      centerName: json['centerName'] as String? ?? AppConstants.defaultCenterName,
      subdomain: json['subdomain'] as String? ?? 'center-alnoor',
      primaryColor: json['primaryColor'] != null
          ? Color(json['primaryColor'] as int)
          : AppConstants.defaultPrimaryColor,
      secondaryColor: json['secondaryColor'] != null
          ? Color(json['secondaryColor'] as int)
          : AppConstants.defaultSecondaryColor,
      logoUrl: json['logoUrl'] as String?,
      heroBannerUrl: json['heroBannerUrl'] as String?,
      selectedIconAlias: json['selectedIconAlias'] as String?,
      isDarkMode: json['isDarkMode'] as bool? ?? false,
    );
  }
}

class BrandingService {
  static Future<BrandingModel> loadBranding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      BrandingModel model = BrandingModel.defaultBranding();

      final raw = prefs.getString(AppConstants.keyBranding);
      if (raw != null) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        model = BrandingModel.fromJson(map);
      }

      // Check if user session has tenant branding that should be synced
      final rawUser = prefs.getString(AppConstants.keyUserData);
      if (rawUser != null) {
        final userMap = jsonDecode(rawUser) as Map<String, dynamic>;
        final tenant = userMap['tenant'] as Map<String, dynamic>?;
        if (tenant != null) {
          model = BrandingModel.fromTenant(tenant, current: model);
        }
      }

      return model;
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
