import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/sync_service.dart';
import '../../../data/models/attendance_event_model.dart';
import '../../../data/models/attendance_record_model.dart';
import '../../../data/models/employee_model.dart';
import '../../../data/repositories/attendance_repository.dart';
import '../../../data/repositories/employee_repository.dart';
import '../../dashboard/controllers/dashboard_controller.dart';

class AttendanceController extends GetxController {
  final AttendanceRepository _attendanceRepo = Get.find<AttendanceRepository>();
  final EmployeeRepository _employeeRepo = Get.find<EmployeeRepository>();
  final LocationService locationService = Get.find<LocationService>();
  final SyncService syncService = Get.find<SyncService>();

  final RxBool isLoading = true.obs;
  final RxBool isSubmitting = false.obs;
  final RxBool isCheckingLocation = false.obs;

  final Rx<AttendanceRecordModel?> todayRecord = Rx<AttendanceRecordModel?>(null);
  final Rx<EmployeeModel?> employee = Rx<EmployeeModel?>(null);
  final Rx<LocationResult?> locationResult = Rx<LocationResult?>(null);

  final RxString statusMessage = ''.obs;

  Worker? _locationSimulationWorker;
  Worker? _customLocationWorker;

  @override
  void onInit() {
    super.onInit();
    initData();

    // Re-verify location whenever reviewer changes simulation mode or custom company location
    _locationSimulationWorker = ever(locationService.simulationMode, (_) {
      verifyLocation();
    });
    _customLocationWorker = ever(locationService.currentOfficeLatitude, (_) {
      verifyLocation();
    });
  }

  Future<void> initData() async {
    isLoading.value = true;
    try {
      employee.value = await _employeeRepo.getEmployeeProfile();
      todayRecord.value = await _attendanceRepo.getTodayRecord();
      await verifyLocation();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> verifyLocation() async {
    isCheckingLocation.value = true;
    try {
      final office = employee.value?.officeConfig;
      final targetLat = locationService.isCustomOfficeSaved.value
          ? locationService.currentOfficeLatitude.value
          : (office?.latitude ?? locationService.currentOfficeLatitude.value);
      final targetLng = locationService.isCustomOfficeSaved.value
          ? locationService.currentOfficeLongitude.value
          : (office?.longitude ?? locationService.currentOfficeLongitude.value);
      final maxRadius = office?.radiusMeters ?? AppConstants.maxAllowedDistanceMeters;

      final result = await locationService.getCurrentLocation(
        targetOfficeLat: targetLat,
        targetOfficeLng: targetLng,
        maxRadius: maxRadius,
      );

      locationResult.value = result;
    } finally {
      isCheckingLocation.value = false;
    }
  }

  Future<void> checkIn() async {
    // 1. Debounce guard against repeated taps
    if (isSubmitting.value) return;

    final current = todayRecord.value;
    if (current != null && current.status != AttendanceStatus.notCheckedIn) {
      if (Get.context != null) {
        Get.snackbar(
          'Action Denied',
          'You have already marked check-in for today.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade700,
          colorText: Colors.white,
        );
      }
      return;
    }

    // 2. Geofence verification
    if (locationResult.value == null || !locationResult.value!.isSuccess) {
      await verifyLocation();
    }

    final loc = locationResult.value;
    if (loc == null || !loc.isSuccess) {
      if (Get.context != null) {
        Get.snackbar(
          'Location Required',
          loc?.errorMessage ?? 'Unable to obtain GPS location. Please check permissions.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.amber.shade900,
          colorText: Colors.white,
        );
      }
      return;
    }

    if (!loc.isWithinGeofence) {
      final dist = loc.distanceMeters?.round() ?? 0;
      if (Get.context != null) {
        Get.snackbar(
          'Outside Permitted Area',
          'You are ${dist}m away from the Bangalore office. Check-in is permitted only within 200m.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade800,
          colorText: Colors.white,
          icon: const Icon(Icons.location_off_rounded, color: Colors.white),
          margin: const EdgeInsets.all(12),
          duration: const Duration(seconds: 4),
        );
      }
      return;
    }

    isSubmitting.value = true;
    try {
      final empId = employee.value?.id ?? 'EMP-4092';
      final result = await _attendanceRepo.recordAttendance(
        employeeId: empId,
        type: AttendanceEventType.checkIn,
        latitude: loc.latitude!,
        longitude: loc.longitude!,
        distanceFromOffice: loc.distanceMeters ?? 0.0,
      );

      if (result.isSuccess && result.record != null) {
        todayRecord.value = result.record;

        // Synchronize Dashboard immediately
        if (Get.isRegistered<DashboardController>()) {
          Get.find<DashboardController>().loadDashboardData(isSilent: true);
        }

        if (Get.context != null) {
          Get.snackbar(
            result.isOfflineQueued ? 'Check-In Saved (Offline)' : 'Check-In Successful',
            result.message,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: result.isOfflineQueued ? Colors.amber.shade800 : Colors.green.shade700,
            colorText: Colors.white,
          );
        }
      } else {
        if (Get.context != null) {
          Get.snackbar(
            'Check-In Failed',
            result.message,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.shade800,
            colorText: Colors.white,
          );
        }
      }
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> checkOut() async {
    // 1. Debounce guard against repeated taps
    if (isSubmitting.value) return;

    final current = todayRecord.value;
    if (current == null || current.status == AttendanceStatus.notCheckedIn) {
      if (Get.context != null) {
        Get.snackbar(
          'Action Denied',
          'Check-out is permitted only after check-in.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade700,
          colorText: Colors.white,
        );
      }
      return;
    }

    if (current.status == AttendanceStatus.checkedOut) {
      if (Get.context != null) {
        Get.snackbar(
          'Action Denied',
          'You have already checked out for today.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade700,
          colorText: Colors.white,
        );
      }
      return;
    }

    // 2. Geofence verification
    if (locationResult.value == null || !locationResult.value!.isSuccess) {
      await verifyLocation();
    }

    final loc = locationResult.value;
    if (loc == null || !loc.isSuccess) {
      if (Get.context != null) {
        Get.snackbar(
          'Location Required',
          loc?.errorMessage ?? 'Unable to obtain GPS location.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.amber.shade900,
          colorText: Colors.white,
        );
      }
      return;
    }

    if (!loc.isWithinGeofence) {
      final dist = loc.distanceMeters?.round() ?? 0;
      if (Get.context != null) {
        Get.snackbar(
          'Outside Permitted Area',
          'You are ${dist}m away from the Bangalore office. Check-out is permitted only within 200m.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade800,
          colorText: Colors.white,
          icon: const Icon(Icons.location_off_rounded, color: Colors.white),
          margin: const EdgeInsets.all(12),
          duration: const Duration(seconds: 4),
        );
      }
      return;
    }

    isSubmitting.value = true;
    try {
      final empId = employee.value?.id ?? 'EMP-4092';
      final result = await _attendanceRepo.recordAttendance(
        employeeId: empId,
        type: AttendanceEventType.checkOut,
        latitude: loc.latitude!,
        longitude: loc.longitude!,
        distanceFromOffice: loc.distanceMeters ?? 0.0,
      );

      if (result.isSuccess && result.record != null) {
        todayRecord.value = result.record;

        // Synchronize Dashboard immediately
        if (Get.isRegistered<DashboardController>()) {
          Get.find<DashboardController>().loadDashboardData(isSilent: true);
        }

        if (Get.context != null) {
          Get.snackbar(
            result.isOfflineQueued ? 'Check-Out Saved (Offline)' : 'Check-Out Successful',
            result.message,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: result.isOfflineQueued ? Colors.amber.shade800 : Colors.blue.shade700,
            colorText: Colors.white,
          );
        }
      } else {
        if (Get.context != null) {
          Get.snackbar(
            'Check-Out Failed',
            result.message,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.shade800,
            colorText: Colors.white,
          );
        }
      }
    } finally {
      isSubmitting.value = false;
    }
  }


  Future<void> resetTodayAttendance() async {
    final reset = await _attendanceRepo.resetTodayRecordForTesting();
    todayRecord.value = reset;

    if (Get.isRegistered<DashboardController>()) {
      Get.find<DashboardController>().loadDashboardData(isSilent: true);
    }

    if (Get.context != null) {
      Get.snackbar(
        'Attendance Reset',
        'Today\'s record has been reset to Not Checked In. You can test Check-In again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF0F172A),
        colorText: Colors.white,
        icon: const Icon(Icons.refresh_rounded, color: Colors.amber),
      );
    }
  }

  Future<void> saveCurrentLocationAsOffice() async {
    isCheckingLocation.value = true;
    try {
      final res = await locationService.saveCurrentGpsAsCompanyLocation();
      await verifyLocation();
      if (Get.context != null) {
        if (res.isSuccess) {
          Get.snackbar(
            'Office Location Saved',
            'Your current device GPS coordinates are now set as the company office location.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.shade700,
            colorText: Colors.white,
          );
        } else {
          Get.snackbar(
            'Failed to Save Location',
            res.errorMessage ?? 'Could not obtain device GPS.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.shade700,
            colorText: Colors.white,
          );
        }
      }
    } finally {
      isCheckingLocation.value = false;
    }
  }

  Future<void> resetCompanyLocation() async {
    isCheckingLocation.value = true;
    try {
      await locationService.resetCompanyLocationToDefault();
      await verifyLocation();
      if (Get.context != null) {
        Get.snackbar(
          'Location Reset',
          'Company office location restored to Bengaluru HQ default.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF0F172A),
          colorText: Colors.white,
        );
      }
    } finally {
      isCheckingLocation.value = false;
    }
  }

  @override
  void onClose() {
    _locationSimulationWorker?.dispose();
    _customLocationWorker?.dispose();
    super.onClose();
  }
}
