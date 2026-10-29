import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'app/bindings/initial_binding.dart';
import 'app/routes/app_pages.dart';
import 'app/theme/app_theme.dart';
import 'app/theme/theme_helper.dart';
import 'core/services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations & status bar
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize persistent Hive storage
  final storageService = StorageService();
  await storageService.init();
  Get.put<StorageService>(storageService, permanent: true);

  final themeService = Get.put<ThemeService>(ThemeService(), permanent: true);

  runApp(RebsHrmsApp(initialTheme: AppTheme.getTheme(themeService.currentThemeMode.value)));
}

class RebsHrmsApp extends StatelessWidget {
  final ThemeData initialTheme;
  const RebsHrmsApp({super.key, required this.initialTheme});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'REBS HRMS - Employee Workspace',
      debugShowCheckedModeBanner: false,
      theme: initialTheme,
      initialRoute: AppPages.initial,
      initialBinding: InitialBinding(),
      getPages: AppPages.routes,
      defaultTransition: Transition.cupertino,
    );
  }
}
