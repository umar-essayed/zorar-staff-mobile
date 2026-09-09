import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dynamic_icon_plus/flutter_dynamic_icon_plus.dart';

class DynamicIconService {
  static Future<bool> supportsDynamicIcons() async {
    try {
      return await FlutterDynamicIconPlus.supportsAlternateIcons
          .timeout(const Duration(seconds: 3), onTimeout: () => false);
    } catch (e) {
      debugPrint('Error checking alternate icons support: $e');
      return false;
    }
  }

  static Future<String?> getCurrentIcon() async {
    try {
      return await FlutterDynamicIconPlus.alternateIconName
          .timeout(const Duration(seconds: 3), onTimeout: () => null);
    } catch (e) {
      debugPrint('Error getting current icon: $e');
      return null;
    }
  }

  static Future<bool> setAppIcon(String? iconName) async {
    try {
      final supported = await supportsDynamicIcons();
      if (!supported) {
        debugPrint('Dynamic app icon is not supported on this platform/device');
        return false;
      }
      await FlutterDynamicIconPlus.setAlternateIconName(
        iconName: iconName,
      ).timeout(const Duration(seconds: 4));
      return true;
    } on PlatformException catch (e) {
      debugPrint('PlatformException setting app icon: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Error setting app icon: $e');
      return false;
    }
  }
}
