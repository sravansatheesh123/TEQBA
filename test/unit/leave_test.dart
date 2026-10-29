import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:machine_task/core/network/api_client.dart';
import 'package:machine_task/core/network/mock_api_interceptor.dart';
import 'package:machine_task/core/services/connectivity_service.dart';
import 'package:machine_task/core/services/storage_service.dart';
import 'package:machine_task/data/datasources/local/app_local_datasource.dart';
import 'package:machine_task/data/datasources/remote/app_remote_datasource.dart';
import 'package:machine_task/data/models/leave_request_model.dart';
import 'package:machine_task/data/repositories/leave_repository.dart';

void main() {
  late Directory tempDir;
  late StorageService storageService;
  late AppLocalDataSource localDataSource;
  late MockApiInterceptor mockInterceptor;
  late ApiClient apiClient;
  late AppRemoteDataSource remoteDataSource;
  late ConnectivityService connectivityService;
  late LeaveRepository leaveRepo;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = Directory.systemTemp.createTempSync('hrms_leave_test_');

    storageService = StorageService();
    await storageService.init(customPath: tempDir.path);

    localDataSource = AppLocalDataSource(storageService);
    mockInterceptor = MockApiInterceptor();
    apiClient = ApiClient(interceptor: mockInterceptor);
    remoteDataSource = AppRemoteDataSource(apiClient);
    connectivityService = ConnectivityService();
    connectivityService.isOnline.value = true;

    leaveRepo = LeaveRepository(localDataSource, remoteDataSource, connectivityService);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('REBS HRMS Leave Validation Tests', () {
    test('4. Overlapping leave dates are rejected', () async {
      final now = DateTime.now();
      final existingStart = now.add(const Duration(days: 2));
      final existingEnd = now.add(const Duration(days: 4));

      // 1. Submit first valid leave application
      final firstResult = await leaveRepo.applyLeave(
        employeeId: 'EMP-4092',
        leaveType: LeaveType.casual,
        startDate: existingStart,
        endDate: existingEnd,
        reason: 'Annual doctor checkup and recovery',
      );
      expect(firstResult.isSuccess, true);

      // 2. When employee attempts to apply for a second leave that overlaps with the first
      final overlapStart = now.add(const Duration(days: 3));
      final overlapEnd = now.add(const Duration(days: 5));

      final secondResult = await leaveRepo.applyLeave(
        employeeId: 'EMP-4092',
        leaveType: LeaveType.casual,
        startDate: overlapStart,
        endDate: overlapEnd,
        reason: 'Personal family emergency travel',
      );

      // 3. Then the overlapping request MUST be rejected
      expect(secondResult.isSuccess, false);
      expect(secondResult.message.toLowerCase(), contains('overlap'));
    });

    test('Leave reason with less than 10 non-whitespace characters is rejected', () async {
      final now = DateTime.now();
      final result = await leaveRepo.applyLeave(
        employeeId: 'EMP-4092',
        leaveType: LeaveType.casual,
        startDate: now.add(const Duration(days: 10)),
        endDate: now.add(const Duration(days: 10)),
        reason: 'trip   ', // only 4 non-whitespace chars
      );

      expect(result.isSuccess, false);
      expect(result.message, contains('10 non-whitespace characters'));
    });

    test('Half-day leave (First Half & Second Half) records 0.5 days and allows non-overlapping same-day slots', () async {
      final now = DateTime.now();
      final targetDate = now.add(const Duration(days: 12));

      // 1. Submit First Half leave (Morning slot - 0.5 days)
      final firstHalfResult = await leaveRepo.applyLeave(
        employeeId: 'EMP-4092',
        leaveType: LeaveType.casual,
        startDate: targetDate,
        endDate: targetDate,
        dayType: LeaveDayType.firstHalf,
        reason: 'Morning medical consultation checkup',
      );
      expect(firstHalfResult.isSuccess, true);

      final requests = await leaveRepo.getLeaveRequests();
      final createdFirstHalf = requests.firstWhere((r) => r.dayType == LeaveDayType.firstHalf);
      expect(createdFirstHalf.daysCount, 0.5);
      expect(createdFirstHalf.dayType, LeaveDayType.firstHalf);

      // 2. Submit Second Half leave on the SAME day (Afternoon slot - 0.5 days)
      final secondHalfResult = await leaveRepo.applyLeave(
        employeeId: 'EMP-4092',
        leaveType: LeaveType.sick,
        startDate: targetDate,
        endDate: targetDate,
        dayType: LeaveDayType.secondHalf,
        reason: 'Afternoon recovery and therapy session',
      );
      // Since firstHalf and secondHalf are complementary non-overlapping slots, both succeed
      expect(secondHalfResult.isSuccess, true);

      // 3. Attempting a Full Day on that same date should now overlap and be rejected
      final fullDayResult = await leaveRepo.applyLeave(
        employeeId: 'EMP-4092',
        leaveType: LeaveType.casual,
        startDate: targetDate,
        endDate: targetDate,
        dayType: LeaveDayType.fullDay,
        reason: 'Full day family event out of town',
      );
      expect(fullDayResult.isSuccess, false);
      expect(fullDayResult.message.toLowerCase(), contains('overlap'));
    });
  });
}
