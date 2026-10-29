import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/storage_service.dart';
import 'app_theme.dart';

enum AppThemeMode {
  light,
  dark,
  eyeComfort,
}

class ThemeService extends GetxService {
  final Rx<AppThemeMode> currentThemeMode = AppThemeMode.light.obs;

  ThemeService() {
    _loadSavedTheme();
  }

  @override
  void onInit() {
    super.onInit();
    _loadSavedTheme();
  }

  void _loadSavedTheme() {
    try {
      if (Get.isRegistered<StorageService>()) {
        final storage = Get.find<StorageService>();
        final saved = storage.getSetting(AppConstants.keyAppThemeMode);
        if (saved != null) {
          if (saved == 'dark') {
            currentThemeMode.value = AppThemeMode.dark;
          } else if (saved == 'eyeComfort') {
            currentThemeMode.value = AppThemeMode.eyeComfort;
          } else {
            currentThemeMode.value = AppThemeMode.light;
          }
        }
      }
    } catch (_) {}
  }

  void setTheme(AppThemeMode mode) {
    currentThemeMode.value = mode;

    try {
      if (Get.isRegistered<StorageService>()) {
        final storage = Get.find<StorageService>();
        storage.saveSetting(AppConstants.keyAppThemeMode, mode.name);
      }
    } catch (_) {}

    // Update global Flutter Theme when app UI context is active
    if (Get.context != null) {
      try {
        Get.changeTheme(AppTheme.getTheme(mode));
      } catch (_) {}
    }

    // Update System Status Bar Icon Brightness
    try {
      if (mode == AppThemeMode.light) {
        SystemChrome.setSystemUIOverlayStyle(
          const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
          ),
        );
      } else {
        SystemChrome.setSystemUIOverlayStyle(
          const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
          ),
        );
      }
    } catch (_) {}
  }

  bool get isLight => currentThemeMode.value == AppThemeMode.light;
  bool get isDark => currentThemeMode.value == AppThemeMode.dark;
  bool get isEyeComfort => currentThemeMode.value == AppThemeMode.eyeComfort;

  String get currentName {
    switch (currentThemeMode.value) {
      case AppThemeMode.light:
        return 'Light Mode';
      case AppThemeMode.dark:
        return 'Dark Mode';
      case AppThemeMode.eyeComfort:
        return 'Eye Comfort';
    }
  }

  IconData get currentIcon {
    switch (currentThemeMode.value) {
      case AppThemeMode.light:
        return Icons.wb_sunny_rounded;
      case AppThemeMode.dark:
        return Icons.nightlight_round;
      case AppThemeMode.eyeComfort:
        return Icons.visibility_rounded;
    }
  }

  Color get background {
    switch (currentThemeMode.value) {
      case AppThemeMode.light:
        return const Color(0xFFF8FAFC);
      case AppThemeMode.dark:
        return const Color(0xFF0F172A);
      case AppThemeMode.eyeComfort:
        return const Color(0xFF181512);
    }
  }

  Color get cardColor {
    switch (currentThemeMode.value) {
      case AppThemeMode.light:
        return Colors.white;
      case AppThemeMode.dark:
        return const Color(0xFF1E293B);
      case AppThemeMode.eyeComfort:
        return const Color(0xFF26221D);
    }
  }

  Color get cardBorder {
    switch (currentThemeMode.value) {
      case AppThemeMode.light:
        return const Color(0xFFE2E8F0);
      case AppThemeMode.dark:
        return const Color(0xFF334155);
      case AppThemeMode.eyeComfort:
        return const Color(0xFF3D352E);
    }
  }

  Color get surfaceVariant {
    switch (currentThemeMode.value) {
      case AppThemeMode.light:
        return const Color(0xFFF1F5F9);
      case AppThemeMode.dark:
        return const Color(0xFF172033);
      case AppThemeMode.eyeComfort:
        return const Color(0xFF2D2720);
    }
  }

  Color get textPrimary {
    switch (currentThemeMode.value) {
      case AppThemeMode.light:
        return const Color(0xFF0F172A);
      case AppThemeMode.dark:
        return const Color(0xFFF8FAFC);
      case AppThemeMode.eyeComfort:
        return const Color(0xFFFDF6E2);
    }
  }

  Color get textSecondary {
    switch (currentThemeMode.value) {
      case AppThemeMode.light:
        return const Color(0xFF64748B);
      case AppThemeMode.dark:
        return const Color(0xFF94A3B8);
      case AppThemeMode.eyeComfort:
        return const Color(0xFFD4B996);
    }
  }

  Color get primaryColor {
    switch (currentThemeMode.value) {
      case AppThemeMode.light:
        return const Color(0xFF2563EB);
      case AppThemeMode.dark:
        return const Color(0xFF3B82F6);
      case AppThemeMode.eyeComfort:
        return const Color(0xFFF59E0B);
    }
  }

  Color get navBarBg {
    switch (currentThemeMode.value) {
      case AppThemeMode.light:
        return Colors.white;
      case AppThemeMode.dark:
        return const Color(0xFF1E293B);
      case AppThemeMode.eyeComfort:
        return const Color(0xFF26221D);
    }
  }

  LinearGradient get headerGradient {
    switch (currentThemeMode.value) {
      case AppThemeMode.light:
        return const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case AppThemeMode.dark:
        return const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case AppThemeMode.eyeComfort:
        return const LinearGradient(
          colors: [Color(0xFF2C2416), Color(0xFF1C170E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }
}

class ThemeHelper {
  static ThemeService get service {
    if (!Get.isRegistered<ThemeService>()) {
      Get.put<ThemeService>(ThemeService(), permanent: true);
    }
    return Get.find<ThemeService>();
  }

  static AppThemeMode get mode => service.currentThemeMode.value;
  static bool get isLight => service.isLight;
  static bool get isDark => service.isDark;
  static bool get isDarkMode => service.isDark;
  static bool get isEyeComfort => service.isEyeComfort;

  static String get currentName => service.currentName;
  static IconData get currentIcon => service.currentIcon;

  static Color get background => service.background;
  static Color get cardColor => service.cardColor;
  static Color get cardBorder => service.cardBorder;
  static Color get surfaceVariant => service.surfaceVariant;
  static Color get textPrimary => service.textPrimary;
  static Color get textSecondary => service.textSecondary;
  static Color get primaryColor => service.primaryColor;
  static Color get navBarBg => service.navBarBg;
  static LinearGradient get headerGradient => service.headerGradient;

  static void setTheme(AppThemeMode mode) => service.setTheme(mode);
}
