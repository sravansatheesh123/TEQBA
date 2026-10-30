import '../../../core/services/storage_service.dart';
import '../../models/attendance_event_model.dart';
import '../../models/attendance_record_model.dart';
import '../../models/employee_model.dart';
import '../../models/leave_balance_model.dart';
import '../../models/leave_request_model.dart';

class AppLocalDataSource {
  final StorageService _storageService;

  AppLocalDataSource(this._storageService);
  Future<void> cacheEmployee(EmployeeModel employee) async {
    await _storageService.saveEmployee(employee.toJson());
  }

  EmployeeModel? getCachedEmployee() {
    final json = _storageService.getEmployee();
    if (json == null) return null;
    return EmployeeModel.fromJson(json);
  }
  Future<void> cacheAttendanceRecords(List<AttendanceRecordModel> records) async {
    final list = records.map((e) => e.toJson()).toList();
    await _storageService.saveAttendanceRecords(list);
  }

  Future<void> saveOrUpdateAttendanceRecord(AttendanceRecordModel record) async {
    await _storageService.putAttendanceRecord(record.toJson());
  }

  List<AttendanceRecordModel> getCachedAttendanceRecords() {
    final list = _storageService.getAllAttendanceRecords();
    return list.map((e) => AttendanceRecordModel.fromJson(e)).toList();
  }

  AttendanceRecordModel? getAttendanceRecordForDate(String date) {
    final json = _storageService.getAttendanceRecord(date);
    if (json == null) return null;
    return AttendanceRecordModel.fromJson(json);
  }

  // Offline Sync Queue (FIFO)
  Future<void> queueAttendanceEvent(AttendanceEventModel event) async {
    await _storageService.addToSyncQueue(event.toJson());
  }

  Future<void> updateQueuedEvent(AttendanceEventModel event) async {
    await _storageService.updateSyncQueueItem(event.eventId, event.toJson());
  }

  Future<void> removeQueuedEvent(String eventId) async {
    await _storageService.removeFromSyncQueue(eventId);
  }

  List<AttendanceEventModel> getQueuedEvents() {
    final list = _storageService.getSyncQueue();
    return list.map((e) => AttendanceEventModel.fromJson(e)).toList();
  }

  int get pendingEventsCount => _storageService.pendingQueueCount;

  // Leave Balance
  Future<void> cacheLeaveBalance(LeaveBalanceModel balance) async {
    await _storageService.saveLeaveBalance(balance.toJson());
  }

  LeaveBalanceModel? getCachedLeaveBalance() {
    final json = _storageService.getLeaveBalance();
    if (json == null) return null;
    return LeaveBalanceModel.fromJson(json);
  }

  // Leave Requests
  Future<void> cacheLeaveRequests(List<LeaveRequestModel> requests) async {
    final list = requests.map((e) => e.toJson()).toList();
    await _storageService.saveLeaveRequests(list);
  }

  Future<void> addLeaveRequest(LeaveRequestModel request) async {
    await _storageService.putLeaveRequest(request.toJson());
  }

  List<LeaveRequestModel> getCachedLeaveRequests() {
    final list = _storageService.getLeaveRequests();
    return list.map((e) => LeaveRequestModel.fromJson(e)).toList();
  }
}
