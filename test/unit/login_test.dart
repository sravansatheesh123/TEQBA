import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:machine_task/core/constants/app_constants.dart';
import 'package:machine_task/core/services/storage_service.dart';
import 'package:machine_task/modules/auth/controllers/login_controller.dart';

void main() {
  late Directory tempDir;
  late StorageService storageService;
  late LoginController loginController;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    Get.reset();

    tempDir = Directory.systemTemp.createTempSync('login_test_');
    storageService = StorageService();
    await storageService.init(customPath: tempDir.path);
    Get.put<StorageService>(storageService);

    loginController = LoginController();
    Get.put<LoginController>(loginController);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
    Get.reset();
  });

  group('Login & Authentication Flow Tests', () {
    test('Default assigned test credentials match intest@123 and 123456', () {
      expect(AppConstants.defaultTestUsername, 'intest@123');
      expect(AppConstants.defaultTestPassword, '123456');

      expect(loginController.usernameController.text, 'intest@123');
      expect(loginController.passwordController.text, '123456');
      expect(loginController.rememberMe.value, true);
      expect(loginController.isPasswordVisible.value, false);
    });

    test('Empty username shows validation error', () async {
      loginController.usernameController.text = '';
      loginController.passwordController.text = '123456';

      await loginController.login();

      expect(loginController.errorMessage.value, 'Please enter your Employee ID or Email');
      expect(storageService.getSetting(AppConstants.keyIsLoggedIn), isNot(true));
    });

    test('Empty password shows validation error', () async {
      loginController.usernameController.text = 'intest@123';
      loginController.passwordController.text = '';

      await loginController.login();

      expect(loginController.errorMessage.value, 'Please enter your password');
      expect(storageService.getSetting(AppConstants.keyIsLoggedIn), isNot(true));
    });

    test('Invalid credentials reject login with error message', () async {
      loginController.usernameController.text = 'wrong_user@corp.com';
      loginController.passwordController.text = 'wrong_pass';

      await loginController.login();

      expect(loginController.errorMessage.value.contains('Invalid credentials'), true);
      expect(storageService.getSetting(AppConstants.keyIsLoggedIn), isNot(true));
    });

    test('Correct credentials (intest@123 & 123456) succeed and persist session', () async {
      loginController.usernameController.text = 'intest@123';
      loginController.passwordController.text = '123456';

      await loginController.login();

      expect(loginController.errorMessage.value, '');
      expect(storageService.getSetting(AppConstants.keyIsLoggedIn), true);
      expect(storageService.getSetting(AppConstants.keyLoggedInUsername), 'intest@123');
    });

    test('fillDemoCredentials resets username to intest@123 and password to 123456', () {
      loginController.usernameController.text = 'other';
      loginController.passwordController.text = '000000';
      loginController.errorMessage.value = 'Some error';

      loginController.fillDemoCredentials();

      expect(loginController.usernameController.text, 'intest@123');
      expect(loginController.passwordController.text, '123456');
      expect(loginController.errorMessage.value, '');
    });

    test('Logout clears the persistent login session', () async {
      // First log in
      await storageService.saveSetting(AppConstants.keyIsLoggedIn, true);
      expect(storageService.getSetting(AppConstants.keyIsLoggedIn), true);

      // Trigger logout
      await LoginController.logout();

      expect(storageService.getSetting(AppConstants.keyIsLoggedIn), false);
    });
  });
}
