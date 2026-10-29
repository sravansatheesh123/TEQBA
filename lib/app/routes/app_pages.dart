import 'package:get/get.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/storage_service.dart';
import '../../modules/attendance/bindings/attendance_binding.dart';
import '../../modules/attendance/views/attendance_view.dart';
import '../../modules/auth/bindings/login_binding.dart';
import '../../modules/auth/views/login_view.dart';
import '../../modules/dashboard/bindings/dashboard_binding.dart';
import '../../modules/dashboard/views/dashboard_view.dart';
import '../../modules/history/bindings/history_binding.dart';
import '../../modules/history/views/history_view.dart';
import '../../modules/leave/bindings/leave_binding.dart';
import '../../modules/leave/views/leave_view.dart';
import 'app_routes.dart';

class AppPages {
  static String get initial {
    try {
      if (Get.isRegistered<StorageService>()) {
        final storage = Get.find<StorageService>();
        final isLoggedIn = storage.getSetting(AppConstants.keyIsLoggedIn) == true;
        if (isLoggedIn) {
          return Routes.dashboard;
        }
      }
    } catch (_) {}
    return Routes.login;
  }

  static final routes = [
    GetPage(
      name: Routes.login,
      page: () => const LoginView(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: Routes.dashboard,
      page: () => const DashboardView(),
      binding: DashboardBinding(),
    ),
    GetPage(
      name: Routes.attendance,
      page: () => const AttendanceView(),
      binding: AttendanceBinding(),
    ),
    GetPage(
      name: Routes.history,
      page: () => const HistoryView(),
      binding: HistoryBinding(),
    ),
    GetPage(
      name: Routes.leave,
      page: () => const LeaveView(),
      binding: LeaveBinding(),
    ),
  ];
}
