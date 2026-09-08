import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:staff_mobile/core/services/security_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SecurityService Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Default PIN is 1234', () async {
      final isDefaultOk = await SecurityService.verifyPin('1234');
      expect(isDefaultOk, isTrue);

      final isWrongFail = await SecurityService.verifyPin('0000');
      expect(isWrongFail, isFalse);
    });

    test('Setting new PIN works', () async {
      await SecurityService.setPin('9876');
      final isNewOk = await SecurityService.verifyPin('9876');
      expect(isNewOk, isTrue);

      final isOldFail = await SecurityService.verifyPin('1234');
      expect(isOldFail, isFalse);
    });

    test('Biometric toggle works', () async {
      final defaultBio = await SecurityService.isBiometricsEnabled();
      expect(defaultBio, isTrue);

      await SecurityService.setBiometrics(false);
      final updatedBio = await SecurityService.isBiometricsEnabled();
      expect(updatedBio, isFalse);
    });
  });
}
