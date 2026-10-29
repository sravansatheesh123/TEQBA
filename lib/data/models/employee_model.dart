import 'office_config_model.dart';

class EmployeeModel {
  final String id;
  final String name;
  final String department;
  final String role;
  final String email;
  final String avatarUrl;
  final OfficeConfigModel officeConfig;

  EmployeeModel({
    required this.id,
    required this.name,
    required this.department,
    required this.role,
    required this.email,
    required this.avatarUrl,
    required this.officeConfig,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      id: json['id'] as String? ?? 'EMP-4092',
      name: json['name'] as String? ?? 'Alex Johnson',
      department: json['department'] as String? ?? 'Mobile Engineering',
      role: json['role'] as String? ?? 'Senior Flutter Developer',
      email: json['email'] as String? ?? 'alex.johnson@rebs.io',
      avatarUrl: json['avatarUrl'] as String? ?? 'https://i.pravatar.cc/300?img=12',
      officeConfig: json['officeConfig'] != null
          ? OfficeConfigModel.fromJson(Map<String, dynamic>.from(json['officeConfig']))
          : OfficeConfigModel(
              name: 'REBS Bengaluru Tech Park',
              latitude: 12.9715987,
              longitude: 77.5945627,
              radiusMeters: 200.0,
              timezone: 'Asia/Kolkata',
            ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'department': department,
      'role': role,
      'email': email,
      'avatarUrl': avatarUrl,
      'officeConfig': officeConfig.toJson(),
    };
  }

  static EmployeeModel defaultEmployee() {
    return EmployeeModel(
      id: 'EMP-4092',
      name: 'Alex Johnson',
      department: 'Mobile Engineering',
      role: 'Senior Flutter Developer',
      email: 'alex.johnson@rebs.io',
      avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
      officeConfig: OfficeConfigModel(
        name: 'REBS Bengaluru Tech Park',
        latitude: 12.9715987,
        longitude: 77.5945627,
        radiusMeters: 200.0,
        timezone: 'Asia/Kolkata',
      ),
    );
  }
}
