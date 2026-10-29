import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/services/sync_service.dart';
import '../datasources/local/app_local_datasource.dart';
import '../datasources/remote/app_remote_datasource.dart';
import '../models/attendance_event_model.dart';
import '../models/attendance_record_model.dart';

class AttendanceResult {
  final bool isSuccess;
  final AttendanceRecordModel? record;
  final String message;
  final bool isOfflineQueued;

  AttendanceResult({
    required this.isSuccess,
    this.record,
    required this.message,
    this.isOfflineQueued = false,
  });
}

class AttendanceRepository {
  final AppLocalDataSource _localDataSource;
  final AppRemoteDataSource _remoteDataSource;
  final ConnectivityService _connectivityService;
  final SyncService _syncService;
  final Uuid _uuid = const Uuid();

  AttendanceRepository(
    this._localDataSource,
    this._remoteDataSource,
    this._connectivityService,
    this._syncService,
  );

  String get todayDateStr => DateFormat('yyyy-MM-dd').format(DateTime.now());

  Future<AttendanceRecordModel> getTodayRecord() async {
    final dateStr = todayDateStr;
    final cached = _localDataSource.getAttendanceRecordForDate(dateStr);
    if (cached != null) {
      return cached;
    }

    // Default empty record for today
    final initial = AttendanceRecordModel(
      id: 'att_$dateStr',
      date: dateStr,
      status: AttendanceStatus.notCheckedIn,
      syncStatus: SyncStatus.synced,
    );
    await _localDataSource.saveOrUpdateAttendanceRecord(initial);
    return initial;
  }

  Future<AttendanceRecordModel> resetTodayRecordForTesting() async {
    final dateStr = todayDateStr;
    final initial = AttendanceRecordModel(
      id: 'att_$dateStr',
      date: dateStr,
      status: AttendanceStatus.notCheckedIn,
      syncStatus: SyncStatus.synced,
    );
    await _localDataSource.saveOrUpdateAttendanceRecord(initial);
    return initial;
  }

  Future<List<AttendanceRecordModel>> getAttendanceHistory() async {
    // 1. Try fetching remote if online
    if (_connectivityService.isOnline.value) {
      try {
        final remoteRecords = await _remoteDataSource.getAttendanceHistory();
        await _localDataSource.cacheAttendanceRecords(remoteRecords);
      } catch (_) {
        // Fallback to cache on error
      }
    }

    // 2. Fetch all cached records from Hive
    final cached = _localDataSource.getCachedAttendanceRecords();
    return cached;
  }

  Future<AttendanceResult> recordAttendance({
    required String employeeId,
    required AttendanceEventType type,
    required double latitude,
    required double longitude,
    required double distanceFromOffice,
  }) async {
    final now = DateTime.now();
    final dateStr = todayDateStr;
    final currentRecord = await getTodayRecord();

    // 1. Device-side validation
    if (type == AttendanceEventType.checkIn) {
      if (currentRecord.status != AttendanceStatus.notCheckedIn) {
        return AttendanceResult(
          isSuccess: false,
          record: currentRecord,
          message: 'You have already checked in for today ($dateStr).',
        );
      }
    } else {
      if (currentRecord.status == AttendanceStatus.notCheckedIn ||
          currentRecord.checkInTime == null) {
        return AttendanceResult(
          isSuccess: false,
          record: currentRecord,
          message: 'Check-out is permitted only after check-in.',
        );
      }
      if (currentRecord.status == AttendanceStatus.checkedOut) {
        return AttendanceResult(
          isSuccess: false,
          record: currentRecord,
          message: 'You have already checked out for today.',
        );
      }
    }

    // 2. Prepare Unique Event Model (Idempotency key)
    final eventId = _uuid.v4();
    final event = AttendanceEventModel(
      eventId: eventId,
      employeeId: employeeId,
      type: type,
      timestamp: now,
      latitude: latitude,
      longitude: longitude,
      distanceFromOffice: distanceFromOffice,
      syncStatus: SyncStatus.pending,
      createdAt: now,
    );

    // Build optimistic record
    final optimisticRecord = currentRecord.copyWith(
      checkInTime: type == AttendanceEventType.checkIn ? now : currentRecord.checkInTime,
      checkOutTime: type == AttendanceEventType.checkOut ? now : currentRecord.checkOutTime,
      checkInLatitude: type == AttendanceEventType.checkIn ? latitude : currentRecord.checkInLatitude,
      checkInLongitude: type == AttendanceEventType.checkIn ? longitude : currentRecord.checkInLongitude,
      checkOutLatitude: type == AttendanceEventType.checkOut ? latitude : currentRecord.checkOutLatitude,
      checkOutLongitude: type == AttendanceEventType.checkOut ? longitude : currentRecord.checkOutLongitude,
      status: type == AttendanceEventType.checkIn
          ? AttendanceStatus.checkedIn
          : AttendanceStatus.checkedOut,
      syncStatus: SyncStatus.pending,
      checkInEventId: type == AttendanceEventType.checkIn ? eventId : currentRecord.checkInEventId,
      checkOutEventId: type == AttendanceEventType.checkOut ? eventId : currentRecord.checkOutEventId,
    );

    // Save optimistic record to local storage first (so it survives app closing immediately!)
    await _localDataSource.saveOrUpdateAttendanceRecord(optimisticRecord);

    // 3. If online, attempt direct sync
    if (_connectivityService.isOnline.value) {
      try {
        await _remoteDataSource.postAttendanceEvent(event);

        // Synced successfully!
        final syncedRecord = optimisticRecord.copyWith(
          syncStatus: SyncStatus.synced,
        );
        await _localDataSource.saveOrUpdateAttendanceRecord(syncedRecord);

        return AttendanceResult(
          isSuccess: true,
          record: syncedRecord,
          message: '${type == AttendanceEventType.checkIn ? "Check-in" : "Check-out"} recorded & synced successfully.',
          isOfflineQueued: false,
        );
      } on DioException catch (dioErr) {
        // If 409 conflict: event or day already registered on server
        if (dioErr.response?.statusCode == 409) {
          final syncedRecord = optimisticRecord.copyWith(
            syncStatus: SyncStatus.synced,
          );
          await _localDataSource.saveOrUpdateAttendanceRecord(syncedRecord);
          return AttendanceResult(
            isSuccess: true,
            record: syncedRecord,
            message: 'Attendance confirmed on server.',
          );
        }

        // Network error, timeout or 500 error -> enqueue locally for sync!
        await _localDataSource.queueAttendanceEvent(event);
        _syncService.syncVersion.value++;

        return AttendanceResult(
          isSuccess: true,
          record: optimisticRecord,
          message: 'Saved locally (Offline). Will automatically sync when connection improves.',
          isOfflineQueued: true,
        );
      } catch (_) {
        // General error -> enqueue
        await _localDataSource.queueAttendanceEvent(event);
        _syncService.syncVersion.value++;

        return AttendanceResult(
          isSuccess: true,
          record: optimisticRecord,
          message: 'Saved locally (Offline). Will sync automatically.',
          isOfflineQueued: true,
        );
      }
    } else {
      // 4. Offline mode: enqueue locally
      await _localDataSource.queueAttendanceEvent(event);
      _syncService.syncVersion.value++;

      return AttendanceResult(
        isSuccess: true,
        record: optimisticRecord,
        message: 'Saved locally (Offline). Pending synchronization.',
        isOfflineQueued: true,
      );
    }
  }
}
