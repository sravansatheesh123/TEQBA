import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/storage_service.dart';

class LoginController extends GetxController {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final RxBool isLoading = false.obs;
  final RxBool isPasswordVisible = false.obs;
  final RxBool rememberMe = true.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // Pre-populate with user requested credentials for reviewer ease of testing
    usernameController.text = AppConstants.defaultTestUsername;
    passwordController.text = AppConstants.defaultTestPassword;
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void fillDemoCredentials() {
    usernameController.text = AppConstants.defaultTestUsername;
    passwordController.text = AppConstants.defaultTestPassword;
    errorMessage.value = '';
  }

  Future<void> login() async {
    final user = usernameController.text.trim();
    final pass = passwordController.text.trim();

    errorMessage.value = '';

    if (user.isEmpty) {
      errorMessage.value = 'Please enter your Employee ID or Email';
      return;
    }

    if (pass.isEmpty) {
      errorMessage.value = 'Please enter your password';
      return;
    }

    // Validate credentials matching user request: intest@123 / 123456
    final isValidUsername = user.toLowerCase() == AppConstants.defaultTestUsername.toLowerCase();
    final isValidPassword = pass == AppConstants.defaultTestPassword;

    if (isValidUsername && isValidPassword) {
      isLoading.value = true;
      await Future.delayed(const Duration(milliseconds: 500));
      isLoading.value = false;

      try {
        if (Get.isRegistered<StorageService>()) {
          final storage = Get.find<StorageService>();
          await storage.saveSetting(AppConstants.keyIsLoggedIn, true);
          await storage.saveSetting(AppConstants.keyLoggedInUsername, user);
        }
      } catch (_) {}

      if (Get.context != null) {
        Get.offAllNamed(Routes.dashboard);

        Get.snackbar(
          'Authentication Successful',
          'Welcome to REBS HRMS ($user)',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF0F172A),
          colorText: Colors.white,
          icon: const Icon(Icons.verified_user_rounded, color: Color(0xFF10B981)),
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
          duration: const Duration(seconds: 3),
        );
      }
    } else {
      errorMessage.value = 'Invalid credentials. Use "${AppConstants.defaultTestUsername}" & "${AppConstants.defaultTestPassword}"';
      if (Get.context != null) {
        Get.snackbar(
          'Authentication Failed',
          'Invalid Employee ID or Password. Demo: ${AppConstants.defaultTestUsername} / ${AppConstants.defaultTestPassword}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF991B1B),
          colorText: Colors.white,
          icon: const Icon(Icons.error_outline_rounded, color: Colors.white),
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
          duration: const Duration(seconds: 3),
        );
      }
    }
  }

  static Future<void> logout() async {
    try {
      if (Get.isRegistered<StorageService>()) {
        final storage = Get.find<StorageService>();
        await storage.saveSetting(AppConstants.keyIsLoggedIn, false);
      }
    } catch (_) {}

    if (Get.context != null) {
      Get.offAllNamed(Routes.login);

      Get.snackbar(
        'Logged Out',
        'You have been logged out of your session',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF0F172A),
        colorText: Colors.white,
        icon: const Icon(Icons.logout_rounded, color: Colors.amber),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 2),
      );
    }
  }

  @override
  void onClose() {
    usernameController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
