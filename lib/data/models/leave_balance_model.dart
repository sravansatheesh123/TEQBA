class LeaveBalanceModel {
  final double casualLeave;
  final double sickLeave;
  final double usedCasual;
  final double usedSick;

  LeaveBalanceModel({
    required this.casualLeave,
    required this.sickLeave,
    this.usedCasual = 0.0,
    this.usedSick = 0.0,
  });

  double get availableCasual => (casualLeave - usedCasual).clamp(0.0, 99.0);
  double get availableSick => (sickLeave - usedSick).clamp(0.0, 99.0);
  double get totalAvailable => availableCasual + availableSick;

  static String format(double val) {
    return val % 1 == 0 ? val.toInt().toString() : val.toStringAsFixed(1);
  }

  factory LeaveBalanceModel.fromJson(Map<String, dynamic> json) {
    return LeaveBalanceModel(
      casualLeave: (json['casualLeave'] as num?)?.toDouble() ?? 12.0,
      sickLeave: (json['sickLeave'] as num?)?.toDouble() ?? 8.0,
      usedCasual: (json['usedCasual'] as num?)?.toDouble() ?? 2.0,
      usedSick: (json['usedSick'] as num?)?.toDouble() ?? 1.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'casualLeave': casualLeave,
      'sickLeave': sickLeave,
      'usedCasual': usedCasual,
      'usedSick': usedSick,
      'availableCasual': availableCasual,
      'availableSick': availableSick,
      'totalAvailable': totalAvailable,
    };
  }

  LeaveBalanceModel copyWith({
    double? casualLeave,
    double? sickLeave,
    double? usedCasual,
    double? usedSick,
  }) {
    return LeaveBalanceModel(
      casualLeave: casualLeave ?? this.casualLeave,
      sickLeave: sickLeave ?? this.sickLeave,
      usedCasual: usedCasual ?? this.usedCasual,
      usedSick: usedSick ?? this.usedSick,
    );
  }

  static LeaveBalanceModel initial() {
    return LeaveBalanceModel(
      casualLeave: 12.0,
      sickLeave: 8.0,
      usedCasual: 2.0,
      usedSick: 1.0,
    );
  }
}
