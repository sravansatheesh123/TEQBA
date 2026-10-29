import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../../data/models/employee_model.dart';
import 'mock_scenario.dart';

class MockApiInterceptor extends Interceptor {
  // Scenario state
  MockScenario currentScenario = MockScenario.success;
  bool isForceOffline = false;

  // Idempotency tracking (store event IDs that server has committed)
  final Set<String> _processedEventIds = {};

  // Server state simulation
  late EmployeeModel _employee;
  late Map<String, dynamic> _leaveBalance;
  final List<Map<String, dynamic>> _leaveRequests = [];
  final Map<String, Map<String, dynamic>> _attendanceRecords = {}; // keyed by date YYYY-MM-DD

  MockApiInterceptor() {
    _initializeSeedData();
  }

  void _initializeSeedData() {
    _employee = EmployeeModel.defaultEmployee();

    _leaveBalance = {
      'casualLeave': 12,
      'sickLeave': 8,
      'usedCasual': 2,
      'usedSick': 1,
    };

    // Seed past 5 days attendance
    final now = DateTime.now();
    final dateFormat = DateFormat('yyyy-MM-dd');

    for (int i = 5; i >= 1; i--) {
      final pastDate = now.subtract(Duration(days: i));
      if (pastDate.weekday != DateTime.saturday && pastDate.weekday != DateTime.sunday) {
        final dateStr = dateFormat.format(pastDate);
        final inTime = DateTime(pastDate.year, pastDate.month, pastDate.day, 9, 15 + (i * 3));
        final outTime = DateTime(pastDate.year, pastDate.month, pastDate.day, 18, 30 + (i * 2));

        _attendanceRecords[dateStr] = {
          'id': 'att_$dateStr',
          'date': dateStr,
          'checkInTime': inTime.toIso8601String(),
          'checkOutTime': outTime.toIso8601String(),
          'status': 'checked_out',
          'syncStatus': 'synced',
          'checkInLatitude': 12.971598,
          'checkInLongitude': 77.594562,
          'checkOutLatitude': 12.971598,
          'checkOutLongitude': 77.594562,
        };
      }
    }

    // Seed past leave requests
    final pastLeaveStart = now.subtract(const Duration(days: 15));
    final pastLeaveEnd = now.subtract(const Duration(days: 14));
    _leaveRequests.add({
      'id': 'leave_seed_01',
      'employeeId': _employee.id,
      'leaveType': 'casual',
      'startDate': pastLeaveStart.toIso8601String(),
      'endDate': pastLeaveEnd.toIso8601String(),
      'daysCount': 2,
      'reason': 'Family function attendance',
      'status': 'approved',
      'createdAt': now.subtract(const Duration(days: 20)).toIso8601String(),
    });

    final pastSickStart = now.subtract(const Duration(days: 8));
    _leaveRequests.add({
      'id': 'leave_seed_02',
      'employeeId': _employee.id,
      'leaveType': 'sick',
      'startDate': pastSickStart.toIso8601String(),
      'endDate': pastSickStart.toIso8601String(),
      'daysCount': 1,
      'reason': 'Viral fever recovery',
      'status': 'approved',
      'createdAt': now.subtract(const Duration(days: 9)).toIso8601String(),
    });
  }

  void resetState() {
    _processedEventIds.clear();
    _attendanceRecords.clear();
    _leaveRequests.clear();
    _initializeSeedData();
    currentScenario = MockScenario.success;
    isForceOffline = false;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // 1. Check Forced Offline simulation
    if (isForceOffline) {
      return handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          error: 'No internet connection (Simulated offline mode)',
        ),
      );
    }

    // 2. Check Mock Scenarios
    switch (currentScenario) {
      case MockScenario.slowResponse:
        await Future.delayed(const Duration(milliseconds: 3500));
        break;
      case MockScenario.timeout:
        await Future.delayed(const Duration(milliseconds: 800));
        return handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.connectionTimeout,
            error: 'Request timed out after 5000ms',
          ),
        );
      case MockScenario.serverError:
        return handler.reject(
          DioException(
            requestOptions: options,
            response: Response(
              requestOptions: options,
              statusCode: 500,
              data: {'message': 'Internal Server Error (Simulated 500)'},
            ),
            type: DioExceptionType.badResponse,
          ),
        );
      default:
        // Small realistic network delay
        await Future.delayed(const Duration(milliseconds: 300));
    }

    // 3. Dispatch to mock endpoint handlers
    final path = options.path;
    final method = options.method.toUpperCase();

    try {
      if (path.contains('/employee/me') && method == 'GET') {
        return handler.resolve(_handleGetEmployee(options));
      } else if (path.contains('/attendance/events') && method == 'POST') {
        return handler.resolve(_handlePostAttendanceEvent(options));
      } else if (path.contains('/attendance') && method == 'GET') {
        return handler.resolve(_handleGetAttendanceHistory(options));
      } else if (path.contains('/leave/balance') && method == 'GET') {
        return handler.resolve(_handleGetLeaveBalance(options));
      } else if (path.contains('/leave/requests') && method == 'GET') {
        return handler.resolve(_handleGetLeaveRequests(options));
      } else if (path.contains('/leave/requests') && method == 'POST') {
        return handler.resolve(_handlePostLeaveRequest(options));
      } else {
        return handler.reject(
          DioException(
            requestOptions: options,
            response: Response(
              requestOptions: options,
              statusCode: 404,
              data: {'message': 'Endpoint not found: $path'},
            ),
          ),
        );
      }
    } on DioException catch (e) {
      return handler.reject(e);
    } catch (e) {
      return handler.reject(
        DioException(
          requestOptions: options,
          error: e.toString(),
          type: DioExceptionType.unknown,
        ),
      );
    }
  }

  Response _handleGetEmployee(RequestOptions options) {
    return Response(
      requestOptions: options,
      statusCode: 200,
      data: _employee.toJson(),
    );
  }

  Response _handleGetAttendanceHistory(RequestOptions options) {
    final list = _attendanceRecords.values.toList();
    // Sort descending by date
    list.sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));
    return Response(
      requestOptions: options,
      statusCode: 200,
      data: list,
    );
  }

  Response _handlePostAttendanceEvent(RequestOptions options) {
    // If scenario is duplicateConflict
    if (currentScenario == MockScenario.duplicateConflict) {
      throw DioException(
        requestOptions: options,
        response: Response(
          requestOptions: options,
          statusCode: 409,
          data: {'message': 'Attendance conflict: Event already registered on server.'},
        ),
        type: DioExceptionType.badResponse,
      );
    }

    final data = options.data is Map ? options.data as Map<String, dynamic> : jsonDecode(options.data.toString()) as Map<String, dynamic>;
    final eventId = data['eventId'] as String;
    final type = data['type'] as String; // check_in or check_out
    final timestamp = DateTime.parse(data['timestamp'] as String);
    final dateStr = DateFormat('yyyy-MM-dd').format(timestamp);
    final lat = (data['latitude'] as num).toDouble();
    final lng = (data['longitude'] as num).toDouble();

    // 1. Idempotency Check:
    // If this eventId has already been recorded by the server, do not re-execute or duplicate.
    if (_processedEventIds.contains(eventId)) {
      final existingRecord = _attendanceRecords[dateStr];
      return Response(
        requestOptions: options,
        statusCode: 200,
        data: {
          'status': 'idempotent_duplicate',
          'message': 'Event was previously committed on server.',
          'eventId': eventId,
          'record': existingRecord,
        },
      );
    }

    // 2. Business rules validation:
    final currentRecord = _attendanceRecords[dateStr];

    if (type == 'check_in') {
      if (currentRecord != null && currentRecord['status'] != 'not_checked_in') {
        throw DioException(
          requestOptions: options,
          response: Response(
            requestOptions: options,
            statusCode: 409,
            data: {'message': 'Employee already checked in for today ($dateStr).'},
          ),
          type: DioExceptionType.badResponse,
        );
      }

      _attendanceRecords[dateStr] = {
        'id': 'att_$dateStr',
        'date': dateStr,
        'checkInTime': timestamp.toIso8601String(),
        'checkOutTime': null,
        'status': 'checked_in',
        'syncStatus': 'synced',
        'checkInLatitude': lat,
        'checkInLongitude': lng,
        'checkInEventId': eventId,
      };
    } else if (type == 'check_out') {
      if (currentRecord == null || currentRecord['checkInTime'] == null) {
        throw DioException(
          requestOptions: options,
          response: Response(
            requestOptions: options,
            statusCode: 400,
            data: {'message': 'Check-out is permitted only after check-in.'},
          ),
          type: DioExceptionType.badResponse,
        );
      }

      _attendanceRecords[dateStr] = {
        ...currentRecord,
        'checkOutTime': timestamp.toIso8601String(),
        'status': 'checked_out',
        'syncStatus': 'synced',
        'checkOutLatitude': lat,
        'checkOutLongitude': lng,
        'checkOutEventId': eventId,
      };
    }

    // Mark eventId as processed
    _processedEventIds.add(eventId);

    return Response(
      requestOptions: options,
      statusCode: 201,
      data: {
        'status': 'synced',
        'eventId': eventId,
        'message': 'Attendance event recorded successfully.',
        'record': _attendanceRecords[dateStr],
      },
    );
  }

  Response _handleGetLeaveBalance(RequestOptions options) {
    return Response(
      requestOptions: options,
      statusCode: 200,
      data: _leaveBalance,
    );
  }

  Response _handleGetLeaveRequests(RequestOptions options) {
    // Sort descending by created date
    final list = List<Map<String, dynamic>>.from(_leaveRequests);
    list.sort((a, b) => (b['createdAt'] as String).compareTo(a['createdAt'] as String));
    return Response(
      requestOptions: options,
      statusCode: 200,
      data: list,
    );
  }

  Response _handlePostLeaveRequest(RequestOptions options) {
    if (currentScenario == MockScenario.leaveRejected) {
      throw DioException(
        requestOptions: options,
        response: Response(
          requestOptions: options,
          statusCode: 422,
          data: {'message': 'Server policy rejected leave request: Department quota exceeded for selected dates.'},
        ),
        type: DioExceptionType.badResponse,
      );
    }

    final data = options.data is Map ? options.data as Map<String, dynamic> : jsonDecode(options.data.toString()) as Map<String, dynamic>;
    final leaveType = data['leaveType'] as String;
    final startDate = DateTime.parse(data['startDate'] as String);
    final endDate = DateTime.parse(data['endDate'] as String);
    final daysCount = (data['daysCount'] as num).toDouble();
    final dayType = data['dayType'] as String? ?? 'fullDay';
    final reason = (data['reason'] as String?)?.trim() ?? '';

    // Server-side validation
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDay = DateTime(startDate.year, startDate.month, startDate.day);

    if (startDay.isBefore(today)) {
      throw DioException(
        requestOptions: options,
        response: Response(
          requestOptions: options,
          statusCode: 422,
          data: {'message': 'Start date cannot be in the past.'},
        ),
        type: DioExceptionType.badResponse,
      );
    }

    if (endDate.isBefore(startDate)) {
      throw DioException(
        requestOptions: options,
        response: Response(
          requestOptions: options,
          statusCode: 422,
          data: {'message': 'End date cannot be before start date.'},
        ),
        type: DioExceptionType.badResponse,
      );
    }

    if (reason.replaceAll(RegExp(r'\s+'), '').length < 10) {
      throw DioException(
        requestOptions: options,
        response: Response(
          requestOptions: options,
          statusCode: 422,
          data: {'message': 'Reason must contain at least 10 non-whitespace characters.'},
        ),
        type: DioExceptionType.badResponse,
      );
    }

    // Balance check
    final isCasual = leaveType == 'casual';
    final avail = isCasual
        ? (_leaveBalance['casualLeave'] as num).toDouble() - (_leaveBalance['usedCasual'] as num).toDouble()
        : (_leaveBalance['sickLeave'] as num).toDouble() - (_leaveBalance['usedSick'] as num).toDouble();

    if (daysCount > avail) {
      throw DioException(
        requestOptions: options,
        response: Response(
          requestOptions: options,
          statusCode: 422,
          data: {'message': 'Requested days ($daysCount) exceed available balance ($avail).'},
        ),
        type: DioExceptionType.badResponse,
      );
    }

    // Overlap check
    for (final req in _leaveRequests) {
      if (req['status'] == 'pending' || req['status'] == 'approved') {
        final existingStart = DateTime.parse(req['startDate'] as String);
        final existingEnd = DateTime.parse(req['endDate'] as String);
        final existingDayType = req['dayType'] as String? ?? 'fullDay';
        final s1 = DateTime(existingStart.year, existingStart.month, existingStart.day);
        final e1 = DateTime(existingEnd.year, existingEnd.month, existingEnd.day);
        final s2 = DateTime(startDate.year, startDate.month, startDate.day);
        final e2 = DateTime(endDate.year, endDate.month, endDate.day);

        final isDateOverlap = !(e1.isBefore(s2) || s1.isAfter(e2));
        bool isActualOverlap = isDateOverlap;
        if (isDateOverlap && s1.isAtSameMomentAs(e1) && s2.isAtSameMomentAs(e2) && s1.isAtSameMomentAs(s2)) {
          if ((dayType == 'firstHalf' && existingDayType == 'secondHalf') ||
              (dayType == 'secondHalf' && existingDayType == 'firstHalf')) {
            isActualOverlap = false;
          }
        }

        if (isActualOverlap) {
          throw DioException(
            requestOptions: options,
            response: Response(
              requestOptions: options,
              statusCode: 422,
              data: {'message': 'Dates overlap with an existing ${req['status']} request.'},
            ),
            type: DioExceptionType.badResponse,
          );
        }
      }
    }

    // Deduct balance and insert
    if (isCasual) {
      _leaveBalance['usedCasual'] = (_leaveBalance['usedCasual'] as num).toDouble() + daysCount;
    } else {
      _leaveBalance['usedSick'] = (_leaveBalance['usedSick'] as num).toDouble() + daysCount;
    }

    final newLeave = {
      'id': 'leave_${DateTime.now().millisecondsSinceEpoch}',
      'employeeId': _employee.id,
      'leaveType': leaveType,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'daysCount': daysCount,
      'dayType': dayType,
      'reason': reason,
      'status': 'pending',
      'createdAt': DateTime.now().toIso8601String(),
    };

    _leaveRequests.add(newLeave);

    return Response(
      requestOptions: options,
      statusCode: 201,
      data: newLeave,
    );
  }
}
