import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../models/attendance_event_model.dart';
import '../../models/attendance_record_model.dart';
import '../../models/employee_model.dart';
import '../../models/leave_balance_model.dart';
import '../../models/leave_request_model.dart';

class AppRemoteDataSource {
  final ApiClient _apiClient;

  AppRemoteDataSource(this._apiClient);

  Future<EmployeeModel> getEmployee() async {
    final response = await _apiClient.get(ApiEndpoints.employeeMe);
    return EmployeeModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<AttendanceRecordModel>> getAttendanceHistory({String? month}) async {
    final response = await _apiClient.get(
      ApiEndpoints.attendanceHistory,
      queryParameters: month != null ? {'month': month} : null,
    );
    final data = response.data as List;
    return data.map((e) => AttendanceRecordModel.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<Map<String, dynamic>> postAttendanceEvent(AttendanceEventModel event) async {
    final response = await _apiClient.post(
      ApiEndpoints.attendanceEvents,
      data: event.toJson(),
    );
    return response.data as Map<String, dynamic>;
  }

  Future<LeaveBalanceModel> getLeaveBalance() async {
    final response = await _apiClient.get(ApiEndpoints.leaveBalance);
    return LeaveBalanceModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<LeaveRequestModel>> getLeaveRequests() async {
    final response = await _apiClient.get(ApiEndpoints.leaveRequests);
    final data = response.data as List;
    return data.map((e) => LeaveRequestModel.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<LeaveRequestModel> postLeaveRequest(LeaveRequestModel request) async {
    final response = await _apiClient.post(
      ApiEndpoints.leaveRequests,
      data: request.toJson(),
    );
    return LeaveRequestModel.fromJson(response.data as Map<String, dynamic>);
  }
}
