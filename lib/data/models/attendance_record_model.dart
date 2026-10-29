import 'attendance_event_model.dart';

enum AttendanceStatus { notCheckedIn, checkedIn, checkedOut }

class AttendanceRecordModel {
  final String id;
  final String date; // YYYY-MM-DD
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final double? checkInLatitude;
  final double? checkInLongitude;
  final double? checkOutLatitude;
  final double? checkOutLongitude;
  final AttendanceStatus status;
  final SyncStatus syncStatus;
  final String? checkInEventId;
  final String? checkOutEventId;
  final String? rejectionReason;

  AttendanceRecordModel({
    required this.id,
    required this.date,
    this.checkInTime,
    this.checkOutTime,
    this.checkInLatitude,
    this.checkInLongitude,
    this.checkOutLatitude,
    this.checkOutLongitude,
    this.status = AttendanceStatus.notCheckedIn,
    this.syncStatus = SyncStatus.synced,
    this.checkInEventId,
    this.checkOutEventId,
    this.rejectionReason,
  });

  Duration get workingDuration {
    if (checkInTime == null) return Duration.zero;
    final end = checkOutTime ?? DateTime.now();
    return end.difference(checkInTime!);
  }

  String get formattedWorkingHours {
    if (checkInTime == null) return '0h 0m';
    final dur = workingDuration;
    final hours = dur.inHours;
    final minutes = dur.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  factory AttendanceRecordModel.fromJson(Map<String, dynamic> json) {
    return AttendanceRecordModel(
      id: json['id'] as String,
      date: json['date'] as String,
      checkInTime: json['checkInTime'] != null
          ? DateTime.parse(json['checkInTime'] as String)
          : null,
      checkOutTime: json['checkOutTime'] != null
          ? DateTime.parse(json['checkOutTime'] as String)
          : null,
      checkInLatitude: (json['checkInLatitude'] as num?)?.toDouble(),
      checkInLongitude: (json['checkInLongitude'] as num?)?.toDouble(),
      checkOutLatitude: (json['checkOutLatitude'] as num?)?.toDouble(),
      checkOutLongitude: (json['checkOutLongitude'] as num?)?.toDouble(),
      status: _parseAttendanceStatus(json['status'] as String?),
      syncStatus: _parseSyncStatus(json['syncStatus'] as String?),
      checkInEventId: json['checkInEventId'] as String?,
      checkOutEventId: json['checkOutEventId'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
    );
  }

  static AttendanceStatus _parseAttendanceStatus(String? status) {
    switch (status) {
      case 'checked_in':
        return AttendanceStatus.checkedIn;
      case 'checked_out':
        return AttendanceStatus.checkedOut;
      case 'not_checked_in':
      default:
        return AttendanceStatus.notCheckedIn;
    }
  }

  static SyncStatus _parseSyncStatus(String? status) {
    switch (status) {
      case 'pending':
        return SyncStatus.pending;
      case 'rejected':
        return SyncStatus.rejected;
      case 'synced':
      default:
        return SyncStatus.synced;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'checkInTime': checkInTime?.toIso8601String(),
      'checkOutTime': checkOutTime?.toIso8601String(),
      'checkInLatitude': checkInLatitude,
      'checkInLongitude': checkInLongitude,
      'checkOutLatitude': checkOutLatitude,
      'checkOutLongitude': checkOutLongitude,
      'status': status == AttendanceStatus.checkedOut
          ? 'checked_out'
          : status == AttendanceStatus.checkedIn
              ? 'checked_in'
              : 'not_checked_in',
      'syncStatus': syncStatus.name,
      'checkInEventId': checkInEventId,
      'checkOutEventId': checkOutEventId,
      'rejectionReason': rejectionReason,
    };
  }

  AttendanceRecordModel copyWith({
    String? id,
    String? date,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    double? checkInLatitude,
    double? checkInLongitude,
    double? checkOutLatitude,
    double? checkOutLongitude,
    AttendanceStatus? status,
    SyncStatus? syncStatus,
    String? checkInEventId,
    String? checkOutEventId,
    String? rejectionReason,
  }) {
    return AttendanceRecordModel(
      id: id ?? this.id,
      date: date ?? this.date,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      checkInLatitude: checkInLatitude ?? this.checkInLatitude,
      checkInLongitude: checkInLongitude ?? this.checkInLongitude,
      checkOutLatitude: checkOutLatitude ?? this.checkOutLatitude,
      checkOutLongitude: checkOutLongitude ?? this.checkOutLongitude,
      status: status ?? this.status,
      syncStatus: syncStatus ?? this.syncStatus,
      checkInEventId: checkInEventId ?? this.checkInEventId,
      checkOutEventId: checkOutEventId ?? this.checkOutEventId,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}
