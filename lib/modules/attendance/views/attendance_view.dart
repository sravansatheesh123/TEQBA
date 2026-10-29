import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/services/location_service.dart';
import '../../../data/models/attendance_event_model.dart';
import '../../../data/models/attendance_record_model.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/theme_helper.dart';
import '../controllers/attendance_controller.dart';

class AttendanceView extends GetView<AttendanceController> {
  const AttendanceView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final bg = ThemeHelper.background;
      final textPrim = ThemeHelper.textPrimary;

      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: bg,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: IconThemeData(color: textPrim),
          titleSpacing: 0,
          title: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              'Attendance Check-In / Out',
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: textPrim,
              ),
            ),
          ),
        ),
        body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        final today = controller.todayRecord.value;
        final status = today?.status ?? AttendanceStatus.notCheckedIn;
        final isPendingSync = today?.syncStatus == SyncStatus.pending;
        final loc = controller.locationResult.value;
        final isSubmitting = controller.isSubmitting.value;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. GPS Location Geofence Card
              _buildLocationStatusCard(context, loc),

              const SizedBox(height: 16),

              // 2. Today's Attendance State Card
              _buildAttendanceStatusCard(today, status, isPendingSync),

              const SizedBox(height: 24),

              // 3. Action Buttons Section
              const Text(
                'ATTENDANCE ACTIONS',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 12),

              // Check-In Button
              _buildActionButton(
                label: status == AttendanceStatus.notCheckedIn
                    ? 'Check-In to Office'
                    : 'Check-In Completed',
                subtitle: status == AttendanceStatus.notCheckedIn
                    ? 'Permitted once per working day'
                    : (today?.checkInTime != null
                        ? 'Recorded at ${DateFormat('hh:mm a').format(today!.checkInTime!)}'
                        : ''),
                icon: Icons.login_rounded,
                gradient: AppColors.checkInGradient,
                isEnabled: status == AttendanceStatus.notCheckedIn && !isSubmitting,
                isLoading: isSubmitting && status == AttendanceStatus.notCheckedIn,
                onTap: () => controller.checkIn(),
              ),

              const SizedBox(height: 14),

              // Check-Out Button
              _buildActionButton(
                label: status == AttendanceStatus.checkedIn
                    ? 'Check-Out from Office'
                    : (status == AttendanceStatus.checkedOut
                        ? 'Check-Out Completed'
                        : 'Check-Out (Requires Check-In)'),
                subtitle: status == AttendanceStatus.checkedIn
                    ? 'Permitted only after check-in'
                    : (today?.checkOutTime != null
                        ? 'Recorded at ${DateFormat('hh:mm a').format(today!.checkOutTime!)}'
                        : 'Check-in must be completed first'),
                icon: Icons.logout_rounded,
                gradient: AppColors.checkOutGradient,
                isEnabled: status == AttendanceStatus.checkedIn && !isSubmitting,
                isLoading: isSubmitting && status == AttendanceStatus.checkedIn,
                onTap: () => controller.checkOut(),
              ),

              const SizedBox(height: 24),

              // 4. Quick Rule Guide Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: ThemeHelper.surfaceVariant,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: ThemeHelper.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline_rounded, size: 16, color: ThemeHelper.primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          'HR Attendance Rules',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: ThemeHelper.textPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildRuleItem('Employee can check in once per working day.'),
                    _buildRuleItem('Check-out is permitted only after check-in.'),
                    _buildRuleItem('GPS geofence radius is enforced within 200m.'),
                    _buildRuleItem('Works offline: Queued events auto-sync when online.'),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
      );
    });
  }

  Widget _buildLocationStatusCard(BuildContext context, LocationResult? loc) {
    final isChecking = controller.isCheckingLocation.value;
    final isSuccess = loc != null && loc.isSuccess;
    final isInside = loc != null && loc.isWithinGeofence;
    final simMode = controller.locationService.simulationMode.value;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeHelper.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: !isSuccess || !isInside ? AppColors.errorRed.withValues(alpha: 0.5) : ThemeHelper.cardBorder,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: ThemeHelper.isLight ? 0.03 : 0.18),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isInside
                      ? AppColors.checkInGreen.withValues(alpha: 0.1)
                      : AppColors.errorRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isInside ? Icons.location_on_rounded : Icons.location_off_rounded,
                  color: isInside ? AppColors.checkInGreen : AppColors.errorRed,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            isInside ? 'Within Permitted Area' : 'Outside Permitted Area',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                              color: isInside ? AppColors.checkInGreen : AppColors.errorRed,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isChecking) ...[
                          const SizedBox(width: 8),
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      isInside
                          ? '${loc.distanceMeters?.round() ?? 0}m from Bangalore HQ (Limit: 200m)'
                          : (loc?.errorMessage ?? 'Must be within 200m of office to mark attendance'),
                      style: TextStyle(fontSize: 11, color: ThemeHelper.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Coords Info Bar
          if (loc?.latitude != null && loc?.longitude != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              decoration: BoxDecoration(
                color: ThemeHelper.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.explore_outlined, size: 12, color: ThemeHelper.textSecondary),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      'GPS: ${loc!.latitude!.toStringAsFixed(6)}, ${loc.longitude!.toStringAsFixed(6)} (${loc.distanceMeters?.round() ?? 0}m away)',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: ThemeHelper.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          // 2-Option Location Testing Switch
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TESTING LOCATION SWITCH',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: ThemeHelper.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                simMode == LocationSimulationMode.atOffice ? 'Inside Area (0m)' : 'Real Device GPS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: simMode == LocationSimulationMode.atOffice ? AppColors.checkInGreen : ThemeHelper.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: ThemeHelper.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ThemeHelper.cardBorder),
            ),
            child: Row(
              children: [
                // Option 1: Office Desk (0m away)
                Expanded(
                  child: InkWell(
                    onTap: () {
                      controller.locationService.setSimulationMode(LocationSimulationMode.atOffice);
                      controller.verifyLocation();
                    },
                    borderRadius: BorderRadius.circular(9),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: simMode == LocationSimulationMode.atOffice ? AppColors.checkInGreen : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: simMode == LocationSimulationMode.atOffice
                            ? [
                                BoxShadow(
                                  color: AppColors.checkInGreen.withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.desk_rounded,
                            size: 14,
                            color: simMode == LocationSimulationMode.atOffice ? Colors.white : ThemeHelper.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Office Desk (0m)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: simMode == LocationSimulationMode.atOffice ? Colors.white : ThemeHelper.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),

                // Option 2: Real Device GPS (Current / Outside Location)
                Expanded(
                  child: InkWell(
                    onTap: () {
                      controller.locationService.setSimulationMode(LocationSimulationMode.realGps);
                      controller.verifyLocation();
                    },
                    borderRadius: BorderRadius.circular(9),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: simMode == LocationSimulationMode.realGps ? ThemeHelper.primaryColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: simMode == LocationSimulationMode.realGps
                            ? [
                                BoxShadow(
                                  color: ThemeHelper.primaryColor.withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.my_location_rounded,
                            size: 14,
                            color: simMode == LocationSimulationMode.realGps ? Colors.white : ThemeHelper.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Real Device GPS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: simMode == LocationSimulationMode.realGps ? Colors.white : ThemeHelper.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Message only if outside (No simulator setup popup / buttons)
          if (!isInside) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: ThemeHelper.isLight ? const Color(0xFFFEF2F2) : const Color(0xFF7F1D1D).withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.errorRed, size: 15),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Outside Bangalore office area (${loc?.distanceMeters?.round() ?? 0}m away). Check-in permitted only within 200m.',
                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.errorRed),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAttendanceStatusCard(
    AttendanceRecordModel? today,
    AttendanceStatus status,
    bool isPendingSync,
  ) {
    final dateFormat = DateFormat('EEEE, MMMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');

    String statusText;
    Color statusColor;

    switch (status) {
      case AttendanceStatus.checkedIn:
        statusText = 'Checked In';
        statusColor = AppColors.checkInGreen;
        break;
      case AttendanceStatus.checkedOut:
        statusText = 'Checked Out (Day Completed)';
        statusColor = ThemeHelper.primaryColor;
        break;
      case AttendanceStatus.notCheckedIn:
        statusText = 'Not Checked In';
        statusColor = ThemeHelper.textSecondary;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ThemeHelper.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ThemeHelper.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: ThemeHelper.isLight ? 0.03 : 0.18),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  dateFormat.format(DateTime.now()),
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: ThemeHelper.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isPendingSync) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: AppColors.statusPendingBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Pending Sync',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.statusPendingText,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    color: statusColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: ThemeHelper.cardBorder),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Check-in Time', style: TextStyle(fontSize: 10, color: ThemeHelper.textSecondary)),
                    const SizedBox(height: 2),
                    Text(
                      today?.checkInTime != null ? timeFormat.format(today!.checkInTime!) : '--:--',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: ThemeHelper.textPrimary),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Check-out Time', style: TextStyle(fontSize: 10, color: ThemeHelper.textSecondary)),
                    const SizedBox(height: 2),
                    Text(
                      today?.checkOutTime != null ? timeFormat.format(today!.checkOutTime!) : '--:--',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: ThemeHelper.textPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required String subtitle,
    required IconData icon,
    required LinearGradient gradient,
    required bool isEnabled,
    required bool isLoading,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: isEnabled ? gradient : null,
        color: isEnabled ? null : ThemeHelper.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: isEnabled ? null : Border.all(color: ThemeHelper.cardBorder),
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: gradient.colors.first.withValues(alpha: 0.3),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? onTap : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: isEnabled ? Colors.white.withValues(alpha: 0.2) : (ThemeHelper.isLight ? Colors.grey.shade300 : Colors.grey.shade700),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Icon(
                          icon,
                          color: isEnabled ? Colors.white : ThemeHelper.textSecondary,
                          size: 22,
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          color: isEnabled ? Colors.white : ThemeHelper.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle.isNotEmpty)
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 11,
                            color: isEnabled ? Colors.white70 : ThemeHelper.textSecondary.withValues(alpha: 0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: isEnabled ? Colors.white70 : ThemeHelper.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRuleItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(color: ThemeHelper.primaryColor, fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 11, color: ThemeHelper.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
