import 'package:flutter/services.dart';

class SoundService {
  static void successFeedback() {
    HapticFeedback.lightImpact();
    SystemSound.play(SystemSoundType.click);
  }

  static void warningFeedback() {
    HapticFeedback.mediumImpact();
  }

  static void lightImpact() {
    HapticFeedback.lightImpact();
  }

  static void errorFeedback() {
    HapticFeedback.heavyImpact();
    HapticFeedback.vibrate();
  }
}
