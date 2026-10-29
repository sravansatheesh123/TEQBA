import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:machine_task/app/theme/theme_helper.dart';
import 'package:machine_task/core/constants/app_constants.dart';
import 'package:machine_task/core/services/storage_service.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  late Directory tempDir;
  late StorageService storageService;
  late ThemeService themeService;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    Get.reset();

    tempDir = Directory.systemTemp.createTempSync('theme_test_');
    storageService = StorageService();
    await storageService.init(customPath: tempDir.path);
    Get.put<StorageService>(storageService);

    themeService = ThemeService();
    Get.put<ThemeService>(themeService);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
    Get.reset();
  });

  group('Theme Helper & Display Mode Tests', () {
    test('Default mode is Light Mode with crisp workspace colors', () {
      expect(themeService.currentThemeMode.value, AppThemeMode.light);
      expect(themeService.isLight, true);
      expect(themeService.isDark, false);
      expect(themeService.isEyeComfort, false);
      expect(themeService.currentName, 'Light Mode');
      expect(themeService.cardColor, Colors.white);
      expect(themeService.background, const Color(0xFFF8FAFC));
    });

    test('Switching to Dark Mode activates Midnight Slate theme', () {
      themeService.setTheme(AppThemeMode.dark);

      expect(themeService.currentThemeMode.value, AppThemeMode.dark);
      expect(themeService.isDark, true);
      expect(themeService.isLight, false);
      expect(themeService.isEyeComfort, false);
      expect(themeService.currentName, 'Dark Mode');
      expect(themeService.background, const Color(0xFF0F172A));
      expect(themeService.cardColor, const Color(0xFF1E293B));
      expect(themeService.textPrimary, const Color(0xFFF8FAFC));

      // Verifies persistence in Hive storage
      final saved = storageService.getSetting(AppConstants.keyAppThemeMode);
      expect(saved, 'dark');
    });

    test('Switching to Dark Eye Comfort Mode activates Warm Amber shield', () {
      themeService.setTheme(AppThemeMode.eyeComfort);

      expect(themeService.currentThemeMode.value, AppThemeMode.eyeComfort);
      expect(themeService.isEyeComfort, true);
      expect(themeService.isDark, false);
      expect(themeService.isLight, false);
      expect(themeService.currentName, 'Eye Comfort');
      expect(themeService.background, const Color(0xFF181512));
      expect(themeService.cardColor, const Color(0xFF26221D));
      expect(themeService.textPrimary, const Color(0xFFFDF6E2));
      expect(themeService.primaryColor, const Color(0xFFF59E0B));

      // Verifies persistence in Hive storage
      final saved = storageService.getSetting(AppConstants.keyAppThemeMode);
      expect(saved, 'eyeComfort');
    });

    test('New ThemeService instance automatically restores persisted theme mode', () async {
      // Save eye comfort mode in storage
      await storageService.saveSetting(AppConstants.keyAppThemeMode, 'eyeComfort');

      // Create new service instance to simulate app restart
      final newService = ThemeService();
      expect(newService.currentThemeMode.value, AppThemeMode.eyeComfort);
      expect(newService.isEyeComfort, true);
    });

    test('ThemeHelper static facade delegates correctly to active ThemeService', () {
      ThemeHelper.setTheme(AppThemeMode.eyeComfort);
      expect(ThemeHelper.mode, AppThemeMode.eyeComfort);
      expect(ThemeHelper.isEyeComfort, true);
      expect(ThemeHelper.currentName, 'Eye Comfort');
      expect(ThemeHelper.primaryColor, const Color(0xFFF59E0B));
      expect(ThemeHelper.background, const Color(0xFF181512));
      expect(ThemeHelper.cardColor, const Color(0xFF26221D));

      ThemeHelper.setTheme(AppThemeMode.dark);
      expect(ThemeHelper.mode, AppThemeMode.dark);
      expect(ThemeHelper.isDark, true);
      expect(ThemeHelper.currentName, 'Dark Mode');
      expect(ThemeHelper.background, const Color(0xFF0F172A));
      expect(ThemeHelper.cardColor, const Color(0xFF1E293B));

      ThemeHelper.setTheme(AppThemeMode.light);
      expect(ThemeHelper.mode, AppThemeMode.light);
      expect(ThemeHelper.isLight, true);
      expect(ThemeHelper.currentName, 'Light Mode');
      expect(ThemeHelper.cardColor, Colors.white);
    });
  });
}
