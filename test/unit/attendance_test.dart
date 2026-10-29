import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:machine_task/core/network/api_client.dart';
import 'package:machine_task/core/network/mock_api_interceptor.dart';
import 'package:machine_task/core/services/connectivity_service.dart';
import 'package:machine_task/core/services/storage_service.dart';
import 'package:machine_task/core/services/sync_service.dart';
import 'package:machine_task/data/datasources/local/app_local_datasource.dart';
import 'package:machine_task/data/datasources/remote/app_remote_datasource.dart';
import 'package:machine_task/data/models/attendance_event_model.dart';
import 'package:machine_task/data/models/attendance_record_model.dart';
import 'package:machine_task/data/repositories/attendance_repository.dart';

void main() {
  late Directory tempDir;
  late StorageService storageService;
  late AppLocalDataSource localDataSource;
  late MockApiInterceptor mockInterceptor;
  late ApiClient apiClient;
  late AppRemoteDataSource remoteDataSource;
  late ConnectivityService connectivityService;
  late SyncService syncService;
  late AttendanceRepository attendanceRepo;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = Directory.systemTemp.createTempSync('hrms_test_');

    storageService = StorageService();
    await storageService.init(customPath: tempDir.path);

    localDataSource = AppLocalDataSource(storageService);
    mockInterceptor = MockApiInterceptor();
    apiClient = ApiClient(interceptor: mockInterceptor);
    remoteDataSource = AppRemoteDataSource(apiClient);
    connectivityService = ConnectivityService();
    connectivityService.isOnline.value = true;

    syncService = SyncService(localDataSource, remoteDataSource, connectivityService);
    attendanceRepo = AttendanceRepository(
      localDataSource,
      remoteDataSource,
      connectivityService,
      syncService,
    );
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('REBS HRMS Attendance Requirements Tests', () {
    test('1. Check-out without check-in is rejected', () async {
      // Given: Employee has not checked in for today
      final todayRecord = await attendanceRepo.getTodayRecord();
      expect(todayRecord.status, AttendanceStatus.notCheckedIn);

      // When: Employee attempts check-out directly
      final result = await attendanceRepo.recordAttendance(
        employeeId: 'EMP-4092',
        type: AttendanceEventType.checkOut,
        latitude: 12.971598,
        longitude: 77.594562,
        distanceFromOffice: 0.0,
      );

      // Then: The check-out request MUST be rejected
      expect(result.isSuccess, false);
      expect(result.message, contains('Check-out is permitted only after check-in'));
    });

    test('2. Repeated submission or retry does not create duplicate attendance (Idempotency)', () async {
      const eventId = 'test-idempotent-event-uuid-001';
      final now = DateTime.now();

      final event = AttendanceEventModel(
        eventId: eventId,
        employeeId: 'EMP-4092',
        type: AttendanceEventType.checkIn,
        timestamp: now,
        latitude: 12.971598,
        longitude: 77.594562,
        distanceFromOffice: 0.0,
        createdAt: now,
      );

      // First submission to Mock HTTP API
      final firstResponse = await apiClient.post(
        '/attendance/events',
        data: event.toJson(),
      );
      expect(firstResponse.statusCode, 201);
      expect(firstResponse.data['status'], 'synced');

      // Retry/Repeated submission with identical eventId
      final secondResponse = await apiClient.post(
        '/attendance/events',
        data: event.toJson(),
      );

      // Must be idempotent: returns 200 without creating a duplicate record
      expect(secondResponse.statusCode, 200);
      expect(secondResponse.data['status'], 'idempotent_duplicate');
      expect(secondResponse.data['eventId'], eventId);
    });

    test('3. Pending attendance survives persistence and can be synchronized in order', () async {
      // Step A: Go offline
      connectivityService.isOnline.value = false;

      final t1 = DateTime.now().subtract(const Duration(hours: 4));
      final t2 = DateTime.now().subtract(const Duration(hours: 1));

      // Check-in queued while offline
      final checkInEvent = AttendanceEventModel(
        eventId: 'event_offline_in_01',
        employeeId: 'EMP-4092',
        type: AttendanceEventType.checkIn,
        timestamp: t1,
        latitude: 12.971598,
        longitude: 77.594562,
        distanceFromOffice: 0.0,
        syncStatus: SyncStatus.pending,
        createdAt: t1,
      );

      // Check-out queued while offline
      final checkOutEvent = AttendanceEventModel(
        eventId: 'event_offline_out_02',
        employeeId: 'EMP-4092',
        type: AttendanceEventType.checkOut,
        timestamp: t2,
        latitude: 12.971598,
        longitude: 77.594562,
        distanceFromOffice: 0.0,
        syncStatus: SyncStatus.pending,
        createdAt: t2,
      );

      // Add to local offline storage queue
      await localDataSource.queueAttendanceEvent(checkInEvent);
      await localDataSource.queueAttendanceEvent(checkOutEvent);

      // Verify persistence: Both events exist in Hive queue
      final queued = localDataSource.getQueuedEvents();
      expect(queued.length, 2);
      // Preserves FIFO order (check-in first, check-out second)
      expect(queued.first.type, AttendanceEventType.checkIn);
      expect(queued.last.type, AttendanceEventType.checkOut);

      // Step B: Reconnect network and trigger synchronization
      connectivityService.isOnline.value = true;
      final syncResult = await syncService.syncPendingQueue();

      // Verify both events synchronized successfully
      expect(syncResult.syncedCount, 2);
      expect(syncResult.failedCount, 0);
      expect(localDataSource.pendingEventsCount, 0);
    });

    test('4. Full Check-In and Check-Out lifecycle works properly', () async {
      // Step 1: Initial state is not checked in
      var today = await attendanceRepo.getTodayRecord();
      expect(today.status, AttendanceStatus.notCheckedIn);
      expect(today.checkInTime, isNull);
      expect(today.checkOutTime, isNull);

      // Step 2: Perform Check-In
      final checkInResult = await attendanceRepo.recordAttendance(
        employeeId: 'EMP-4092',
        type: AttendanceEventType.checkIn,
        latitude: 12.971598,
        longitude: 77.594562,
        distanceFromOffice: 0.0,
      );
      expect(checkInResult.isSuccess, true);
      expect(checkInResult.record?.status, AttendanceStatus.checkedIn);
      expect(checkInResult.record?.checkInTime, isNotNull);

      // Step 3: Duplicate check-in is rejected
      final duplicateCheckIn = await attendanceRepo.recordAttendance(
        employeeId: 'EMP-4092',
        type: AttendanceEventType.checkIn,
        latitude: 12.971598,
        longitude: 77.594562,
        distanceFromOffice: 0.0,
      );
      expect(duplicateCheckIn.isSuccess, false);
      expect(duplicateCheckIn.message, contains('already checked in'));

      // Step 4: Perform Check-Out
      final checkOutResult = await attendanceRepo.recordAttendance(
        employeeId: 'EMP-4092',
        type: AttendanceEventType.checkOut,
        latitude: 12.971598,
        longitude: 77.594562,
        distanceFromOffice: 0.0,
      );
      expect(checkOutResult.isSuccess, true);
      expect(checkOutResult.record?.status, AttendanceStatus.checkedOut);
      expect(checkOutResult.record?.checkOutTime, isNotNull);

      // Step 5: Duplicate check-out is rejected
      final duplicateCheckOut = await attendanceRepo.recordAttendance(
        employeeId: 'EMP-4092',
        type: AttendanceEventType.checkOut,
        latitude: 12.971598,
        longitude: 77.594562,
        distanceFromOffice: 0.0,
      );
      expect(duplicateCheckOut.isSuccess, false);
      expect(duplicateCheckOut.message, contains('already checked out'));

      // Step 6: Reset today's record for testing restores Not Checked In state
      final resetRecord = await attendanceRepo.resetTodayRecordForTesting();
      expect(resetRecord.status, AttendanceStatus.notCheckedIn);

      // Step 7: Employee can check in again after reset
      final reCheckIn = await attendanceRepo.recordAttendance(
        employeeId: 'EMP-4092',
        type: AttendanceEventType.checkIn,
        latitude: 12.971598,
        longitude: 77.594562,
        distanceFromOffice: 0.0,
      );
      expect(reCheckIn.isSuccess, true);
      expect(reCheckIn.record?.status, AttendanceStatus.checkedIn);
    });
  });
}
