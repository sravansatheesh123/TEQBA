enum AttendanceEventType { checkIn, checkOut }

enum SyncStatus { pending, synced, rejected }

class AttendanceEventModel {
  final String eventId;
  final String employeeId;
  final AttendanceEventType type;
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final double distanceFromOffice;
  final SyncStatus syncStatus;
  final String? rejectionReason;
  final int retryCount;
  final DateTime createdAt;
  final DateTime? syncedAt;

  AttendanceEventModel({
    required this.eventId,
    required this.employeeId,
    required this.type,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.distanceFromOffice,
    this.syncStatus = SyncStatus.pending,
    this.rejectionReason,
    this.retryCount = 0,
    required this.createdAt,
    this.syncedAt,
  });

  factory AttendanceEventModel.fromJson(Map<String, dynamic> json) {
    return AttendanceEventModel(
      eventId: json['eventId'] as String,
      employeeId: json['employeeId'] as String,
      type: (json['type'] as String) == 'check_out'
          ? AttendanceEventType.checkOut
          : AttendanceEventType.checkIn,
      timestamp: DateTime.parse(json['timestamp'] as String),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      distanceFromOffice: (json['distanceFromOffice'] as num?)?.toDouble() ?? 0.0,
      syncStatus: _parseSyncStatus(json['syncStatus'] as String?),
      rejectionReason: json['rejectionReason'] as String?,
      retryCount: json['retryCount'] as int? ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      syncedAt: json['syncedAt'] != null
          ? DateTime.parse(json['syncedAt'] as String)
          : null,
    );
  }

  static SyncStatus _parseSyncStatus(String? status) {
    switch (status) {
      case 'synced':
        return SyncStatus.synced;
      case 'rejected':
        return SyncStatus.rejected;
      case 'pending':
      default:
        return SyncStatus.pending;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'employeeId': employeeId,
      'type': type == AttendanceEventType.checkOut ? 'check_out' : 'check_in',
      'timestamp': timestamp.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'distanceFromOffice': distanceFromOffice,
      'syncStatus': syncStatus.name,
      'rejectionReason': rejectionReason,
      'retryCount': retryCount,
      'createdAt': createdAt.toIso8601String(),
      'syncedAt': syncedAt?.toIso8601String(),
    };
  }

  AttendanceEventModel copyWith({
    String? eventId,
    String? employeeId,
    AttendanceEventType? type,
    DateTime? timestamp,
    double? latitude,
    double? longitude,
    double? distanceFromOffice,
    SyncStatus? syncStatus,
    String? rejectionReason,
    int? retryCount,
    DateTime? createdAt,
    DateTime? syncedAt,
  }) {
    return AttendanceEventModel(
      eventId: eventId ?? this.eventId,
      employeeId: employeeId ?? this.employeeId,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      distanceFromOffice: distanceFromOffice ?? this.distanceFromOffice,
      syncStatus: syncStatus ?? this.syncStatus,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      retryCount: retryCount ?? this.retryCount,
      createdAt: createdAt ?? this.createdAt,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }
}
