class OfficeConfigModel {
  final String name;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final String timezone;

  OfficeConfigModel({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.timezone,
  });

  factory OfficeConfigModel.fromJson(Map<String, dynamic> json) {
    return OfficeConfigModel(
      name: json['name'] as String? ?? 'REBS HQ',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 12.9715987,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 77.5945627,
      radiusMeters: (json['radiusMeters'] as num?)?.toDouble() ?? 200.0,
      timezone: json['timezone'] as String? ?? 'Asia/Kolkata',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'radiusMeters': radiusMeters,
      'timezone': timezone,
    };
  }

  OfficeConfigModel copyWith({
    String? name,
    double? latitude,
    double? longitude,
    double? radiusMeters,
    String? timezone,
  }) {
    return OfficeConfigModel(
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      timezone: timezone ?? this.timezone,
    );
  }
}
