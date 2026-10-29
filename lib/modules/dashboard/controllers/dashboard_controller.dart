import 'dart:async';
import 'package:get/get.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/sync_service.dart';
import '../../../data/models/attendance_record_model.dart';
import '../../../data/models/employee_model.dart';
import '../../../data/models/leave_balance_model.dart';
import '../../../data/repositories/attendance_repository.dart';
import '../../../data/repositories/employee_repository.dart';
import '../../../data/repositories/leave_repository.dart';

class DashboardController extends GetxController {
  final EmployeeRepository _employeeRepo = Get.find<EmployeeRepository>();
  final AttendanceRepository _attendanceRepo = Get.find<AttendanceRepository>();
  final LeaveRepository _leaveRepo = Get.find<LeaveRepository>();
  final ConnectivityService connectivityService = Get.find<ConnectivityService>();
  final SyncService syncService = Get.find<SyncService>();
  final LocationService locationService = Get.find<LocationService>();

  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;

  final Rx<EmployeeModel?> employee = Rx<EmployeeModel?>(null);
  final Rx<AttendanceRecordModel?> todayRecord = Rx<AttendanceRecordModel?>(null);
  final RxList<AttendanceRecordModel> recentRecords = <AttendanceRecordModel>[].obs;
  final Rx<LeaveBalanceModel?> leaveBalance = Rx<LeaveBalanceModel?>(null);

  final Rx<LocationResult?> currentLocation = Rx<LocationResult?>(null);
  final RxBool isFetchingLocation = false.obs;

  final Rx<Duration> elapsedDuration = Duration.zero.obs;
  Timer? _liveDurationTimer;

  Worker? _syncWorker;
  Worker? _locationSimulationWorker;
  Worker? _customLocationWorker;

  @override
  void onInit() {
    super.onInit();
    loadDashboardData();

    // Listen to sync updates to refresh records automatically
    _syncWorker = ever(syncService.syncVersion, (_) {
      loadDashboardData(isSilent: true);
    });

    // Re-fetch current location whenever reviewer toggles simulation mode or changes company location
    _locationSimulationWorker = ever(locationService.simulationMode, (_) {
      fetchCurrentLocation();
    });
    _customLocationWorker = ever(locationService.currentOfficeLatitude, (_) {
      fetchCurrentLocation();
    });
  }

  Future<void> loadDashboardData({bool forceRefresh = false, bool isSilent = false}) async {
    if (!isSilent) {
      isLoading.value = true;
      errorMessage.value = '';
    }

    try {
      // 1. Employee Profile
      employee.value = await _employeeRepo.getEmployeeProfile(forceRefresh: forceRefresh);

      // 2. Today's Attendance
      todayRecord.value = await _attendanceRepo.getTodayRecord();
      _startLiveTimerIfNeeded();

      // 3. Attendance History (Latest 5 records)
      final allHistory = await _attendanceRepo.getAttendanceHistory();
      // Exclude today from history list to avoid duplication if present
      final todayStr = _attendanceRepo.todayDateStr;
      final filtered = allHistory.where((r) => r.date != todayStr).take(5).toList();
      recentRecords.assignAll(filtered);

      // 4. Leave Balance
      leaveBalance.value = await _leaveRepo.getLeaveBalance();

      // 5. Current GPS Location
      await fetchCurrentLocation();

      errorMessage.value = '';
    } catch (e) {
      errorMessage.value = 'Failed to load dashboard: ${e.toString()}';
    } finally {
      if (!isSilent) {
        isLoading.value = false;
      }
    }
  }

  Future<void> fetchCurrentLocation() async {
    isFetchingLocation.value = true;
    try {
      final office = employee.value?.officeConfig;
      final targetLat = locationService.isCustomOfficeSaved.value
          ? locationService.currentOfficeLatitude.value
          : (office?.latitude ?? locationService.currentOfficeLatitude.value);
      final targetLng = locationService.isCustomOfficeSaved.value
          ? locationService.currentOfficeLongitude.value
          : (office?.longitude ?? locationService.currentOfficeLongitude.value);
      final maxRadius = office?.radiusMeters ?? AppConstants.maxAllowedDistanceMeters;

      final res = await locationService.getCurrentLocation(
        targetOfficeLat: targetLat,
        targetOfficeLng: targetLng,
        maxRadius: maxRadius,
      );
      currentLocation.value = res;
    } catch (_) {
    } finally {
      isFetchingLocation.value = false;
    }
  }

  void _startLiveTimerIfNeeded() {
    _liveDurationTimer?.cancel();
    final today = todayRecord.value;
    if (today != null &&
        today.status == AttendanceStatus.checkedIn &&
        today.checkInTime != null) {
      elapsedDuration.value = DateTime.now().difference(today.checkInTime!);
      _liveDurationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (todayRecord.value?.checkInTime != null) {
          elapsedDuration.value =
              DateTime.now().difference(todayRecord.value!.checkInTime!);
        }
      });
    } else if (today?.checkInTime != null && today?.checkOutTime != null) {
      elapsedDuration.value = today!.checkOutTime!.difference(today.checkInTime!);
    } else {
      elapsedDuration.value = Duration.zero;
    }
  }

  Future<void> triggerSync() async {
    final result = await syncService.syncPendingQueue();
    await loadDashboardData(isSilent: true);
    Get.snackbar(
      'Sync Completed',
      result.message,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  String formatDuration(Duration dur) {
    final hours = dur.inHours.toString().padLeft(2, '0');
    final minutes = dur.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = dur.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  void onClose() {
    _liveDurationTimer?.cancel();
    _syncWorker?.dispose();
    _locationSimulationWorker?.dispose();
    _customLocationWorker?.dispose();
    super.onClose();
  }
}
