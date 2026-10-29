import 'package:hive_flutter/hive_flutter.dart';
import '../constants/app_constants.dart';

class StorageService {
  late Box _employeeBox;
  late Box _attendanceBox;
  late Box _syncQueueBox;
  late Box _leaveRequestsBox;
  late Box _leaveBalanceBox;
  late Box _settingsBox;

  Future<void> init({String? customPath}) async {
    if (customPath != null) {
      Hive.init(customPath);
    } else {
      await Hive.initFlutter();
    }
    _employeeBox = await Hive.openBox(AppConstants.employeeBox);
    _attendanceBox = await Hive.openBox(AppConstants.attendanceBox);
    _syncQueueBox = await Hive.openBox(AppConstants.syncQueueBox);
    _leaveRequestsBox = await Hive.openBox(AppConstants.leaveRequestsBox);
    _leaveBalanceBox = await Hive.openBox(AppConstants.leaveBalanceBox);
    _settingsBox = await Hive.openBox(AppConstants.settingsBox);
  }

  // Employee Profile
  Future<void> saveEmployee(Map<String, dynamic> data) async {
    await _employeeBox.put('profile', data);
  }

  Map<String, dynamic>? getEmployee() {
    final data = _employeeBox.get('profile');
    if (data == null) return null;
    return Map<String, dynamic>.from(data);
  }

  // Attendance Records (cached for offline viewing)
  Future<void> saveAttendanceRecords(List<Map<String, dynamic>> records) async {
    await _attendanceBox.clear();
    for (var r in records) {
      await _attendanceBox.put(r['date'], r);
    }
  }

  Future<void> putAttendanceRecord(Map<String, dynamic> record) async {
    await _attendanceBox.put(record['date'], record);
  }

  Map<String, dynamic>? getAttendanceRecord(String date) {
    final data = _attendanceBox.get(date);
    if (data == null) return null;
    return Map<String, dynamic>.from(data);
  }

  List<Map<String, dynamic>> getAllAttendanceRecords() {
    final list = <Map<String, dynamic>>[];
    for (var key in _attendanceBox.keys) {
      final val = _attendanceBox.get(key);
      if (val != null) {
        list.add(Map<String, dynamic>.from(val));
      }
    }
    // Sort descending by date
    list.sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));
    return list;
  }

  // Sync Queue (Pending Offline Attendance Events)
  Future<void> addToSyncQueue(Map<String, dynamic> eventJson) async {
    final eventId = eventJson['eventId'] as String;
    await _syncQueueBox.put(eventId, eventJson);
  }

  Future<void> updateSyncQueueItem(String eventId, Map<String, dynamic> eventJson) async {
    await _syncQueueBox.put(eventId, eventJson);
  }

  Future<void> removeFromSyncQueue(String eventId) async {
    await _syncQueueBox.delete(eventId);
  }

  List<Map<String, dynamic>> getSyncQueue() {
    final list = <Map<String, dynamic>>[];
    for (var key in _syncQueueBox.keys) {
      final val = _syncQueueBox.get(key);
      if (val != null) {
        list.add(Map<String, dynamic>.from(val));
      }
    }
    // Sort ascending by timestamp to preserve FIFO ordering (check-in before check-out)
    list.sort((a, b) {
      final t1 = DateTime.parse(a['timestamp'] as String);
      final t2 = DateTime.parse(b['timestamp'] as String);
      return t1.compareTo(t2);
    });
    return list;
  }

  int get pendingQueueCount => _syncQueueBox.length;

  // Leave Balance
  Future<void> saveLeaveBalance(Map<String, dynamic> data) async {
    await _leaveBalanceBox.put('balance', data);
  }

  Map<String, dynamic>? getLeaveBalance() {
    final data = _leaveBalanceBox.get('balance');
    if (data == null) return null;
    return Map<String, dynamic>.from(data);
  }

  // Leave Requests
  Future<void> saveLeaveRequests(List<Map<String, dynamic>> requests) async {
    await _leaveRequestsBox.clear();
    for (var req in requests) {
      await _leaveRequestsBox.put(req['id'], req);
    }
  }

  Future<void> putLeaveRequest(Map<String, dynamic> req) async {
    await _leaveRequestsBox.put(req['id'], req);
  }

  List<Map<String, dynamic>> getLeaveRequests() {
    final list = <Map<String, dynamic>>[];
    for (var key in _leaveRequestsBox.keys) {
      final val = _leaveRequestsBox.get(key);
      if (val != null) {
        list.add(Map<String, dynamic>.from(val));
      }
    }
    list.sort((a, b) {
      final d1 = DateTime.parse(a['createdAt'] as String);
      final d2 = DateTime.parse(b['createdAt'] as String);
      return d2.compareTo(d1); // newest first
    });
    return list;
  }

  // Settings & Simulation
  Future<void> saveSetting(String key, dynamic value) async {
    await _settingsBox.put(key, value);
  }

  dynamic getSetting(String key, {dynamic defaultValue}) {
    return _settingsBox.get(key, defaultValue: defaultValue);
  }

  Future<void> clearAll() async {
    await _employeeBox.clear();
    await _attendanceBox.clear();
    await _syncQueueBox.clear();
    await _leaveRequestsBox.clear();
    await _leaveBalanceBox.clear();
  }
}
