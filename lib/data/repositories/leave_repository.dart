import 'package:dio/dio.dart';
import '../../core/services/connectivity_service.dart';
import '../datasources/local/app_local_datasource.dart';
import '../datasources/remote/app_remote_datasource.dart';
import '../models/leave_balance_model.dart';
import '../models/leave_request_model.dart';

class LeaveSubmissionResult {
  final bool isSuccess;
  final LeaveRequestModel? request;
  final String message;

  LeaveSubmissionResult({
    required this.isSuccess,
    this.request,
    required this.message,
  });
}

class LeaveRepository {
  final AppLocalDataSource _localDataSource;
  final AppRemoteDataSource _remoteDataSource;
  final ConnectivityService _connectivityService;

  LeaveRepository(
    this._localDataSource,
    this._remoteDataSource,
    this._connectivityService,
  );

  Future<LeaveBalanceModel> getLeaveBalance() async {
    // 1. If online, fetch from remote
    if (_connectivityService.isOnline.value) {
      try {
        final remoteBalance = await _remoteDataSource.getLeaveBalance();
        await _localDataSource.cacheLeaveBalance(remoteBalance);
        return remoteBalance;
      } catch (_) {}
    }

    // 2. Fallback to cached balance
    final cached = _localDataSource.getCachedLeaveBalance();
    if (cached != null) return cached;

    // Default initial balance
    final fallback = LeaveBalanceModel.initial();
    await _localDataSource.cacheLeaveBalance(fallback);
    return fallback;
  }

  Future<List<LeaveRequestModel>> getLeaveRequests() async {
    // 1. If online, fetch from remote
    if (_connectivityService.isOnline.value) {
      try {
        final remoteRequests = await _remoteDataSource.getLeaveRequests();
        await _localDataSource.cacheLeaveRequests(remoteRequests);
        return remoteRequests;
      } catch (_) {}
    }

    // 2. Return cached requests for offline viewing
    return _localDataSource.getCachedLeaveRequests();
  }

  Future<LeaveSubmissionResult> applyLeave({
    required String employeeId,
    required LeaveType leaveType,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
    LeaveDayType dayType = LeaveDayType.fullDay,
  }) async {
    // 1. Connectivity check: "Leave submission requires connectivity"
    if (!_connectivityService.isOnline.value) {
      return LeaveSubmissionResult(
        isSuccess: false,
        message: 'Leave submission requires an active internet connection. Please connect and try again.',
      );
    }

    // 2. Validate dates: Start date cannot be before current company date (today)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDay = DateTime(startDate.year, startDate.month, startDate.day);
    final effectiveEndDay = dayType == LeaveDayType.fullDay
        ? DateTime(endDate.year, endDate.month, endDate.day)
        : startDay;

    if (startDay.isBefore(today)) {
      return LeaveSubmissionResult(
        isSuccess: false,
        message: 'Start date cannot be in the past.',
      );
    }

    if (effectiveEndDay.isBefore(startDay)) {
      return LeaveSubmissionResult(
        isSuccess: false,
        message: 'End date cannot be before start date.',
      );
    }

    // 3. Reason validation: at least 10 non-whitespace characters
    final nonWhitespaceReason = reason.replaceAll(RegExp(r'\s+'), '');
    if (nonWhitespaceReason.length < 10) {
      return LeaveSubmissionResult(
        isSuccess: false,
        message: 'Reason must contain at least 10 non-whitespace characters.',
      );
    }

    // Calculate requested days (0.5 for half day, calendar days for full day)
    final double daysCount = dayType == LeaveDayType.fullDay
        ? (effectiveEndDay.difference(startDay).inDays + 1).toDouble()
        : 0.5;

    // 4. Balance check
    final balance = await getLeaveBalance();
    final available = leaveType == LeaveType.casual
        ? balance.availableCasual
        : balance.availableSick;

    if (daysCount > available) {
      final formattedDays = LeaveBalanceModel.format(daysCount);
      final formattedAvail = LeaveBalanceModel.format(available);
      return LeaveSubmissionResult(
        isSuccess: false,
        message: 'Requested days ($formattedDays) exceed available $leaveType leave balance ($formattedAvail).',
      );
    }

    // 5. Overlap check against existing Pending and Approved requests
    final existingRequests = await getLeaveRequests();
    for (final req in existingRequests) {
      if (req.status == LeaveStatus.pending || req.status == LeaveStatus.approved) {
        if (req.overlapsWith(startDay, effectiveEndDay, otherDayType: dayType)) {
          return LeaveSubmissionResult(
            isSuccess: false,
            message: 'Selected dates overlap with an existing ${req.status.name.toUpperCase()} request (${req.startDate.toString().split(' ')[0]} to ${req.endDate.toString().split(' ')[0]}).',
          );
        }
      }
    }

    // 6. Send to remote server (Mock API)
    try {
      final newRequest = LeaveRequestModel(
        id: 'leave_${DateTime.now().millisecondsSinceEpoch}',
        employeeId: employeeId,
        leaveType: leaveType,
        startDate: startDay,
        endDate: effectiveEndDay,
        daysCount: daysCount,
        dayType: dayType,
        reason: reason.trim(),
        status: LeaveStatus.pending,
        createdAt: DateTime.now(),
      );

      final created = await _remoteDataSource.postLeaveRequest(newRequest);

      // Save to local cache
      await _localDataSource.addLeaveRequest(created);

      // Refresh balance
      await getLeaveBalance();

      return LeaveSubmissionResult(
        isSuccess: true,
        request: created,
        message: 'Leave application submitted successfully.',
      );
    } on DioException catch (dioErr) {
      final serverMsg = dioErr.response?.data?['message'] ?? 'Server rejected the leave request.';
      return LeaveSubmissionResult(
        isSuccess: false,
        message: serverMsg.toString(),
      );
    } catch (e) {
      return LeaveSubmissionResult(
        isSuccess: false,
        message: 'Failed to submit leave: ${e.toString()}',
      );
    }
  }
}
