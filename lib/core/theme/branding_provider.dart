import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/branding_service.dart';
import '../services/dynamic_icon_service.dart';

class BrandingNotifier extends StateNotifier<BrandingModel> {
  BrandingNotifier() : super(BrandingModel.defaultBranding()) {
    _init();
  }

  Future<void> _init() async {
    final loaded = await BrandingService.loadBranding();
    state = loaded;
  }

  Future<void> updateCenterName(String name) async {
    state = state.copyWith(centerName: name);
    await BrandingService.saveBranding(state);
  }

  Future<void> updateSubdomain(String subdomain) async {
    state = state.copyWith(subdomain: subdomain);
    await BrandingService.saveBranding(state);
  }

  Future<void> updateLogoUrl(String url) async {
    state = state.copyWith(logoUrl: url);
    await BrandingService.saveBranding(state);
  }

  Future<void> updateHeroBannerUrl(String url) async {
    state = state.copyWith(heroBannerUrl: url);
    await BrandingService.saveBranding(state);
  }

  Future<void> updatePrimaryColor(Color color) async {
    state = state.copyWith(primaryColor: color);
    await BrandingService.saveBranding(state);
  }

  Future<void> toggleDarkMode() async {
    state = state.copyWith(isDarkMode: !state.isDarkMode);
    await BrandingService.saveBranding(state);
  }

  Future<bool> updateAppIcon(String? iconAlias) async {
    final success = await DynamicIconService.setAppIcon(iconAlias);
    if (success) {
      state = state.copyWith(selectedIconAlias: iconAlias);
      await BrandingService.saveBranding(state);
    }
    return success;
  }
}

final brandingProvider = StateNotifierProvider<BrandingNotifier, BrandingModel>((ref) {
  return BrandingNotifier();
});
