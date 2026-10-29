import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../data/models/employee_model.dart';
import '../../../data/models/leave_balance_model.dart';
import '../../../data/models/leave_request_model.dart';
import '../../../data/repositories/employee_repository.dart';
import '../../../data/repositories/leave_repository.dart';

class LeaveController extends GetxController with GetSingleTickerProviderStateMixin {
  final LeaveRepository _leaveRepo = Get.find<LeaveRepository>();
  final EmployeeRepository _employeeRepo = Get.find<EmployeeRepository>();
  final ConnectivityService connectivityService = Get.find<ConnectivityService>();

  late TabController tabController;

  final RxBool isLoading = true.obs;
  final RxBool isSubmitting = false.obs;

  final Rx<EmployeeModel?> employee = Rx<EmployeeModel?>(null);
  final Rx<LeaveBalanceModel?> leaveBalance = Rx<LeaveBalanceModel?>(null);
  final RxList<LeaveRequestModel> leaveRequests = <LeaveRequestModel>[].obs;

  // Form Fields State
  final Rx<LeaveType> selectedLeaveType = LeaveType.casual.obs;
  final Rx<LeaveDayType> selectedDayType = LeaveDayType.fullDay.obs;
  final Rx<DateTime> startDate = DateTime.now().obs;
  final Rx<DateTime> endDate = DateTime.now().obs;
  final TextEditingController reasonController = TextEditingController();
  final RxInt reasonLength = 0.obs;

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 2, vsync: this);
    reasonController.addListener(() {
      final nonWs = reasonController.text.replaceAll(RegExp(r'\s+'), '');
      reasonLength.value = nonWs.length;
    });
    loadData();
  }

  Future<void> loadData({bool isSilent = false}) async {
    if (!isSilent) isLoading.value = true;
    try {
      employee.value = await _employeeRepo.getEmployeeProfile();
      leaveBalance.value = await _leaveRepo.getLeaveBalance();
      final list = await _leaveRepo.getLeaveRequests();
      leaveRequests.assignAll(list);
    } finally {
      if (!isSilent) isLoading.value = false;
    }
  }

  double get calculatedDaysCount {
    if (selectedDayType.value != LeaveDayType.fullDay) {
      return 0.5;
    }
    final s = DateTime(startDate.value.year, startDate.value.month, startDate.value.day);
    final e = DateTime(endDate.value.year, endDate.value.month, endDate.value.day);
    if (e.isBefore(s)) return 0.0;
    return (e.difference(s).inDays + 1).toDouble();
  }

  void setDayType(LeaveDayType type) {
    selectedDayType.value = type;
    if (type != LeaveDayType.fullDay) {
      endDate.value = startDate.value;
    }
  }

  void setStartDate(DateTime date) {
    startDate.value = date;
    if (selectedDayType.value != LeaveDayType.fullDay || endDate.value.isBefore(date)) {
      endDate.value = date;
    }
  }

  void setEndDate(DateTime date) {
    endDate.value = date;
  }

  Future<void> submitLeaveApplication() async {
    // 1. Connection check
    if (!connectivityService.isOnline.value) {
      Get.snackbar(
        'Offline',
        'Leave submission requires an active internet connection.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade800,
        colorText: Colors.white,
      );
      return;
    }

    final reason = reasonController.text.trim();
    final empId = employee.value?.id ?? 'EMP-4092';

    isSubmitting.value = true;
    try {
      final result = await _leaveRepo.applyLeave(
        employeeId: empId,
        leaveType: selectedLeaveType.value,
        startDate: startDate.value,
        endDate: selectedDayType.value == LeaveDayType.fullDay ? endDate.value : startDate.value,
        reason: reason,
        dayType: selectedDayType.value,
      );

      if (result.isSuccess) {
        reasonController.clear();
        await loadData(isSilent: true);
        tabController.animateTo(1); // Switch to Leave History tab

        Get.snackbar(
          'Application Submitted',
          'Your leave request has been submitted for approval.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade700,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Submission Failed',
          result.message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade800,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      }
    } finally {
      isSubmitting.value = false;
    }
  }

  @override
  void onClose() {
    tabController.dispose();
    reasonController.dispose();
    super.onClose();
  }
}
