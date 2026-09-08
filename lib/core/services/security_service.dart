import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sound_service.dart';

class SecurityService {
  static const _pinKey = 'zorar_security_pin';
  static const _biometricKey = 'zorar_biometrics_enabled';

  static Future<bool> isPinSet() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_pinKey);
  }

  static Future<bool> verifyPin(String enteredPin) async {
    final prefs = await SharedPreferences.getInstance();
    final savedPin = prefs.getString(_pinKey) ?? '1234';
    return enteredPin == savedPin;
  }

  static Future<void> setPin(String newPin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pinKey, newPin);
  }

  static Future<bool> isBiometricsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricKey) ?? true;
  }

  static Future<void> setBiometrics(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricKey, enabled);
  }

  static Future<bool> showSecurityPinDialog(BuildContext context, {String title = 'تأكيد الرمز الأمني'}) async {
    final pinController = TextEditingController();
    bool verified = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(LucideIcons.shieldCheck, color: Color(0xFF0143A3)),
            const SizedBox(width: 8),
            Text(title, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'أدخل الرمز السري المكون من 4 أرقام للمتابعة (الافتراضي 1234):',
              style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey[700]),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, letterSpacing: 10, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                counterText: '',
                hintText: '••••',
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text('إلغاء', style: GoogleFonts.cairo(color: Colors.grey)),
            onPressed: () {
              Navigator.pop(ctx);
            },
          ),
          ElevatedButton(
            child: Text('تأكيد', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
            onPressed: () async {
              final ok = await verifyPin(pinController.text.trim());
              if (ok) {
                verified = true;
                SoundService.successFeedback();
                Navigator.pop(ctx);
              } else {
                SoundService.errorFeedback();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('الرمز السري غير صحيح'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );

    return verified;
  }
}
