enum LeaveType { casual, sick }

enum LeaveStatus { pending, approved, rejected }

enum LeaveDayType { fullDay, firstHalf, secondHalf }

extension LeaveDayTypeExtension on LeaveDayType {
  String get title {
    switch (this) {
      case LeaveDayType.fullDay:
        return 'Full Day';
      case LeaveDayType.firstHalf:
        return 'First Half';
      case LeaveDayType.secondHalf:
        return 'Second Half';
    }
  }

  String get shortLabel {
    switch (this) {
      case LeaveDayType.fullDay:
        return 'Full Day (1.0d)';
      case LeaveDayType.firstHalf:
        return 'First Half (0.5d)';
      case LeaveDayType.secondHalf:
        return 'Second Half (0.5d)';
    }
  }

  String get timeSlot {
    switch (this) {
      case LeaveDayType.fullDay:
        return '09:00 AM - 06:00 PM (Full Shift)';
      case LeaveDayType.firstHalf:
        return '09:00 AM - 01:30 PM (Morning Slot)';
      case LeaveDayType.secondHalf:
        return '01:30 PM - 06:00 PM (Afternoon Slot)';
    }
  }
}

class LeaveRequestModel {
  final String id;
  final String employeeId;
  final LeaveType leaveType;
  final DateTime startDate;
  final DateTime endDate;
  final double daysCount;
  final LeaveDayType dayType;
  final String reason;
  final LeaveStatus status;
  final DateTime createdAt;
  final String? rejectionReason;

  LeaveRequestModel({
    required this.id,
    required this.employeeId,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.daysCount,
    this.dayType = LeaveDayType.fullDay,
    required this.reason,
    this.status = LeaveStatus.pending,
    required this.createdAt,
    this.rejectionReason,
  });

  bool overlapsWith(DateTime otherStart, DateTime otherEnd, {LeaveDayType otherDayType = LeaveDayType.fullDay}) {
    // Normalizing dates to midnight
    final s1 = DateTime(startDate.year, startDate.month, startDate.day);
    final e1 = DateTime(endDate.year, endDate.month, endDate.day);
    final s2 = DateTime(otherStart.year, otherStart.month, otherStart.day);
    final e2 = DateTime(otherEnd.year, otherEnd.month, otherEnd.day);

    final dateOverlap = !(e1.isBefore(s2) || s1.isAfter(e2));
    if (!dateOverlap) return false;

    // If both requests are for the exact same single day and are different half days, they do not collide
    if (s1.isAtSameMomentAs(e1) && s2.isAtSameMomentAs(e2) && s1.isAtSameMomentAs(s2)) {
      if ((dayType == LeaveDayType.firstHalf && otherDayType == LeaveDayType.secondHalf) ||
          (dayType == LeaveDayType.secondHalf && otherDayType == LeaveDayType.firstHalf)) {
        return false;
      }
    }

    return true;
  }

  factory LeaveRequestModel.fromJson(Map<String, dynamic> json) {
    return LeaveRequestModel(
      id: json['id'] as String,
      employeeId: json['employeeId'] as String? ?? 'EMP-4092',
      leaveType: (json['leaveType'] as String) == 'sick'
          ? LeaveType.sick
          : LeaveType.casual,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      daysCount: (json['daysCount'] as num?)?.toDouble() ?? 1.0,
      dayType: _parseDayType(json['dayType'] as String?),
      reason: json['reason'] as String? ?? '',
      status: _parseStatus(json['status'] as String?),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      rejectionReason: json['rejectionReason'] as String?,
    );
  }

  static LeaveDayType _parseDayType(String? val) {
    switch (val) {
      case 'firstHalf':
        return LeaveDayType.firstHalf;
      case 'secondHalf':
        return LeaveDayType.secondHalf;
      case 'fullDay':
      default:
        return LeaveDayType.fullDay;
    }
  }

  static LeaveStatus _parseStatus(String? status) {
    switch (status) {
      case 'approved':
        return LeaveStatus.approved;
      case 'rejected':
        return LeaveStatus.rejected;
      case 'pending':
      default:
        return LeaveStatus.pending;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'leaveType': leaveType == LeaveType.sick ? 'sick' : 'casual',
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'daysCount': daysCount,
      'dayType': dayType.name,
      'reason': reason,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'rejectionReason': rejectionReason,
    };
  }

  LeaveRequestModel copyWith({
    String? id,
    String? employeeId,
    LeaveType? leaveType,
    DateTime? startDate,
    DateTime? endDate,
    double? daysCount,
    LeaveDayType? dayType,
    String? reason,
    LeaveStatus? status,
    DateTime? createdAt,
    String? rejectionReason,
  }) {
    return LeaveRequestModel(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      leaveType: leaveType ?? this.leaveType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      daysCount: daysCount ?? this.daysCount,
      dayType: dayType ?? this.dayType,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}
