import 'package:get/get.dart';
import '../../../core/services/sync_service.dart';
import '../../../data/models/attendance_event_model.dart';
import '../../../data/models/attendance_record_model.dart';
import '../../../data/repositories/attendance_repository.dart';

class HistoryController extends GetxController {
  final AttendanceRepository _attendanceRepo = Get.find<AttendanceRepository>();
  final SyncService _syncService = Get.find<SyncService>();

  final RxBool isLoading = true.obs;
  final RxList<AttendanceRecordModel> allRecords = <AttendanceRecordModel>[].obs;
  final RxString selectedFilter = 'All'.obs; // All, Synced, Pending, Rejected

  Worker? _syncWorker;

  @override
  void onInit() {
    super.onInit();
    loadHistory();

    _syncWorker = ever(_syncService.syncVersion, (_) {
      loadHistory(isSilent: true);
    });
  }

  Future<void> loadHistory({bool isSilent = false}) async {
    if (!isSilent) isLoading.value = true;
    try {
      final records = await _attendanceRepo.getAttendanceHistory();
      allRecords.assignAll(records);
    } finally {
      if (!isSilent) isLoading.value = false;
    }
  }

  List<AttendanceRecordModel> get filteredRecords {
    if (selectedFilter.value == 'All') {
      return allRecords;
    } else if (selectedFilter.value == 'Synced') {
      return allRecords.where((r) => r.syncStatus == SyncStatus.synced).toList();
    } else if (selectedFilter.value == 'Pending') {
      return allRecords.where((r) => r.syncStatus == SyncStatus.pending).toList();
    } else if (selectedFilter.value == 'Rejected') {
      return allRecords.where((r) => r.syncStatus == SyncStatus.rejected).toList();
    }
    return allRecords;
  }

  void setFilter(String filter) {
    selectedFilter.value = filter;
  }

  @override
  void onClose() {
    _syncWorker?.dispose();
    super.onClose();
  }
}
