import 'package:get/get.dart';
import '../../core/network/api_client.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/services/location_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/sync_service.dart';
import '../theme/theme_helper.dart';
import '../../data/datasources/local/app_local_datasource.dart';
import '../../data/datasources/remote/app_remote_datasource.dart';
import '../../data/repositories/attendance_repository.dart';
import '../../data/repositories/employee_repository.dart';
import '../../data/repositories/leave_repository.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    final apiClient = Get.put<ApiClient>(ApiClient(), permanent: true);
    final storageService = Get.find<StorageService>(); // Initialized in main()
    final connectivityService = Get.put<ConnectivityService>(ConnectivityService(), permanent: true);
    Get.put<LocationService>(LocationService(), permanent: true);
    Get.put<ThemeService>(ThemeService(), permanent: true);
    final localDataSource = Get.put<AppLocalDataSource>(
      AppLocalDataSource(storageService),
      permanent: true,
    );
    final remoteDataSource = Get.put<AppRemoteDataSource>(
      AppRemoteDataSource(apiClient),
      permanent: true,
    );
    final syncService = Get.put<SyncService>(
      SyncService(localDataSource, remoteDataSource, connectivityService),
      permanent: true,
    );
    Get.put<EmployeeRepository>(
      EmployeeRepository(localDataSource, remoteDataSource),
      permanent: true,
    );
    Get.put<AttendanceRepository>(
      AttendanceRepository(localDataSource, remoteDataSource, connectivityService, syncService),
      permanent: true,
    );
    Get.put<LeaveRepository>(
      LeaveRepository(localDataSource, remoteDataSource, connectivityService),
      permanent: true,
    );
  }
}
