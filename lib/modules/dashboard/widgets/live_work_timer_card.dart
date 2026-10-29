import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/models/attendance_event_model.dart';
import '../../../data/models/attendance_record_model.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/theme/theme_helper.dart';
import '../controllers/dashboard_controller.dart';

class LiveWorkTimerCard extends StatelessWidget {
  const LiveWorkTimerCard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();

    return Obx(() {
      final today = controller.todayRecord.value;
      final status = today?.status ?? AttendanceStatus.notCheckedIn;
      final isPendingSync = today?.syncStatus == SyncStatus.pending;
      final isRejected = today?.syncStatus == SyncStatus.rejected;

      String statusTitle;
      Color statusColor;
      Color statusBg;
      Color statusBorder;
      IconData statusIcon;

      switch (status) {
        case AttendanceStatus.checkedIn:
          statusTitle = 'Checked In • Working';
          statusColor = const Color(0xFF059669);
          statusBg = const Color(0xFFECFDF5);
          statusBorder = const Color(0xFFA7F3D0);
          statusIcon = Icons.verified_rounded;
          break;
        case AttendanceStatus.checkedOut:
          statusTitle = 'Shift Completed';
          statusColor = const Color(0xFF2563EB);
          statusBg = const Color(0xFFEFF6FF);
          statusBorder = const Color(0xFFBFDBFE);
          statusIcon = Icons.task_alt_rounded;
          break;
        case AttendanceStatus.notCheckedIn:
          statusTitle = 'Not Checked In';
          statusColor = const Color(0xFF64748B);
          statusBg = const Color(0xFFF1F5F9);
          statusBorder = const Color(0xFFE2E8F0);
          statusIcon = Icons.schedule_rounded;
          break;
      }

      final timeFormat = DateFormat('hh:mm a');
      final inTimeStr = today?.checkInTime != null ? timeFormat.format(today!.checkInTime!) : '--:--';
      final outTimeStr = today?.checkOutTime != null ? timeFormat.format(today!.checkOutTime!) : '--:--';

      // 8-hour shift progress calculation
      const standardShiftSeconds = 8 * 3600;
      final elapsedSeconds = controller.elapsedDuration.value.inSeconds;
      final shiftProgress = (elapsedSeconds / standardShiftSeconds).clamp(0.0, 1.0);
      final percentCompleted = (shiftProgress * 100).toInt();

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: ThemeHelper.isLight
                ? [Colors.white, const Color(0xFFF8FAFC)]
                : (ThemeHelper.isDark
                    ? [const Color(0xFF1E293B), const Color(0xFF172033)]
                    : [const Color(0xFF26221D), const Color(0xFF1D1914)]),
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: ThemeHelper.isLight ? 0.05 : 0.22),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: statusColor.withValues(alpha: 0.08),
              blurRadius: 28,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: ThemeHelper.cardBorder, width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Top Header Row: Status Badge & Sync / Date Pill
            Row(
              children: [
                // Status Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (status == AttendanceStatus.checkedIn)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Icon(statusIcon, color: statusColor, size: 14),
                        ),
                      Text(
                        statusTitle,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Sync or Date Badge
                if (isPendingSync)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.hourglass_top_rounded, color: Color(0xFFD97706), size: 12),
                        SizedBox(width: 4),
                        Text(
                          'Pending Sync',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFD97706),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (isRejected)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 12),
                        SizedBox(width: 4),
                        Text(
                          'Sync Rejected',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: ThemeHelper.surfaceVariant,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: ThemeHelper.cardBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 11, color: ThemeHelper.textSecondary),
                        const SizedBox(width: 5),
                        Text(
                          DateFormat('d MMM, yyyy').format(DateTime.now()),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: ThemeHelper.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),

            // 2. Active Working Hours Hero Display
            Row(
              children: [
                Icon(Icons.access_time_filled_rounded, size: 13, color: ThemeHelper.textSecondary),
                const SizedBox(width: 6),
                Text(
                  'WORKING HOURS TODAY',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: ThemeHelper.textSecondary,
                    letterSpacing: 0.8,
                  ),
                ),
                const Spacer(),
                if (status == AttendanceStatus.checkedIn)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.play_circle_fill_rounded, color: Color(0xFF059669), size: 12),
                        SizedBox(width: 4),
                        Text(
                          'LIVE TIMER',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF059669),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),

            // Large Digital Clock
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    controller.formatDuration(controller.elapsedDuration.value),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.6,
                      color: ThemeHelper.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'hrs:min:sec',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: ThemeHelper.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Shift Progress Bar (Target 8h standard workday)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: shiftProgress,
                minHeight: 6,
                backgroundColor: const Color(0xFFE2E8F0),
                valueColor: AlwaysStoppedAnimation<Color>(
                  status == AttendanceStatus.checkedIn ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  status == AttendanceStatus.notCheckedIn
                      ? 'Ready to check-in'
                      : '$percentCompleted% of 8h shift elapsed',
                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                ),
                const Text(
                  'Goal: 08:00:00',
                  style: TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 3. Check-In & Check-Out Punch Time Cards
            Row(
              children: [
                // Check-in Punch Card
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                    decoration: BoxDecoration(
                      color: inTimeStr != '--:--'
                          ? (ThemeHelper.isLight ? const Color(0xFFF0FDF4) : const Color(0xFF064E3B).withValues(alpha: 0.35))
                          : ThemeHelper.surfaceVariant,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: inTimeStr != '--:--' ? const Color(0xFFBBF7D0).withValues(alpha: 0.6) : ThemeHelper.cardBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: inTimeStr != '--:--'
                                ? (ThemeHelper.isLight ? const Color(0xFFDCFCE7) : const Color(0xFF065F46))
                                : (ThemeHelper.isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155)),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Icon(
                            Icons.login_rounded,
                            color: inTimeStr != '--:--' ? const Color(0xFF059669) : ThemeHelper.textSecondary,
                            size: 15,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Check-In',
                                style: TextStyle(fontSize: 10, color: ThemeHelper.textSecondary, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                inTimeStr,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: ThemeHelper.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Check-out Punch Card
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                    decoration: BoxDecoration(
                      color: outTimeStr != '--:--'
                          ? (ThemeHelper.isLight ? const Color(0xFFEFF6FF) : const Color(0xFF1E3A8A).withValues(alpha: 0.35))
                          : ThemeHelper.surfaceVariant,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: outTimeStr != '--:--' ? const Color(0xFFBFDBFE).withValues(alpha: 0.6) : ThemeHelper.cardBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: outTimeStr != '--:--'
                                ? (ThemeHelper.isLight ? const Color(0xFFDBEAFE) : const Color(0xFF1D4ED8))
                                : (ThemeHelper.isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155)),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Icon(
                            Icons.logout_rounded,
                            color: outTimeStr != '--:--' ? const Color(0xFF2563EB) : ThemeHelper.textSecondary,
                            size: 15,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Check-Out',
                                style: TextStyle(fontSize: 10, color: ThemeHelper.textSecondary, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                outTimeStr,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: ThemeHelper.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 4. Live Current GPS Geofence Radar Card (Overflow-safe & attractive)
            Obx(() {
              final loc = controller.currentLocation.value;
              final isFetching = controller.isFetchingLocation.value;
              final isInside = loc != null && loc.isWithinGeofence;
              final hasCoords = loc?.latitude != null && loc?.longitude != null;
              final officeName = controller.locationService.currentOfficeName.value;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isInside
                      ? (ThemeHelper.isLight ? const Color(0xFFF0FDF4) : const Color(0xFF064E3B).withValues(alpha: 0.28))
                      : (loc == null
                          ? ThemeHelper.surfaceVariant
                          : (ThemeHelper.isLight ? const Color(0xFFFEF2F2) : const Color(0xFF7F1D1D).withValues(alpha: 0.28))),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isInside
                        ? const Color(0xFF86EFAC).withValues(alpha: 0.6)
                        : (loc == null ? ThemeHelper.cardBorder : const Color(0xFFFCA5A5).withValues(alpha: 0.6)),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row: Radar Icon + Title + Status Pill + Refresh button
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: isInside
                                ? const Color(0xFF059669)
                                : (loc == null ? const Color(0xFF64748B) : const Color(0xFFDC2626)),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Icon(
                            isInside
                                ? Icons.my_location_rounded
                                : (loc == null ? Icons.location_searching_rounded : Icons.location_off_rounded),
                            color: Colors.white,
                            size: 15,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  'GPS GEOFENCE RADAR',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                    color: isInside
                                        ? const Color(0xFF059669)
                                        : (loc == null ? ThemeHelper.textSecondary : const Color(0xFFDC2626)),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isFetching) ...[
                                const SizedBox(width: 6),
                                SizedBox(
                                  width: 10,
                                  height: 10,
                                  child: CircularProgressIndicator(strokeWidth: 1.5, color: ThemeHelper.primaryColor),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (loc != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isInside
                                  ? const Color(0xFFD1FAE5)
                                  : const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isInside ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                  size: 10,
                                  color: isInside ? const Color(0xFF059669) : const Color(0xFFDC2626),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  isInside ? 'Within Area' : 'Outside',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: isInside ? const Color(0xFF059669) : const Color(0xFFDC2626),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(width: 4),
                        IconButton(
                          icon: isFetching
                              ? SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: ThemeHelper.primaryColor),
                                )
                              : Icon(Icons.refresh_rounded, size: 18, color: ThemeHelper.primaryColor),
                          tooltip: 'Refresh Location',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: isFetching ? null : () => controller.fetchCurrentLocation(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Coordinates & Distance Detail Container
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: ThemeHelper.isLight ? Colors.white.withValues(alpha: 0.8) : Colors.black.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isFetching)
                            Text(
                              'Acquiring device GPS coordinates...',
                              style: TextStyle(fontSize: 10.5, color: ThemeHelper.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          else if (hasCoords)
                            Row(
                              children: [
                                Icon(Icons.explore_outlined, size: 12, color: ThemeHelper.textSecondary),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '${loc!.latitude!.toStringAsFixed(5)}, ${loc.longitude!.toStringAsFixed(5)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: ThemeHelper.textPrimary,
                                      letterSpacing: 0.1,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            )
                          else
                            Text(
                              'Location not acquired yet',
                              style: TextStyle(fontSize: 10.5, color: ThemeHelper.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          if (loc?.distanceMeters != null) ...[
                            const SizedBox(height: 3),
                            Text(
                              '${loc!.distanceMeters!.round()}m from $officeName (Max radius: 200m)',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: isInside ? const Color(0xFF059669) : ThemeHelper.textSecondary,
                                fontWeight: isInside ? FontWeight.w600 : FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),

            // 5. Attractive High-Impact Gradient Action Button
            Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: status == AttendanceStatus.notCheckedIn
                      ? [const Color(0xFF059669), const Color(0xFF10B981)]
                      : (status == AttendanceStatus.checkedIn
                          ? [const Color(0xFFD97706), const Color(0xFFF59E0B)]
                          : [const Color(0xFF1E293B), const Color(0xFF334155)]),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: (status == AttendanceStatus.notCheckedIn
                            ? const Color(0xFF10B981)
                            : (status == AttendanceStatus.checkedIn
                                ? const Color(0xFFF59E0B)
                                : const Color(0xFF1E293B)))
                        .withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () async {
                  await Get.toNamed(Routes.attendance);
                  if (Get.isRegistered<DashboardController>()) {
                    Get.find<DashboardController>().loadDashboardData(isSilent: true);
                  }
                },
                icon: Icon(
                  status == AttendanceStatus.checkedIn
                      ? Icons.logout_rounded
                      : (status == AttendanceStatus.checkedOut
                          ? Icons.task_alt_rounded
                          : Icons.fingerprint_rounded),
                  size: 20,
                  color: Colors.white,
                ),
                label: Text(
                  status == AttendanceStatus.notCheckedIn
                      ? 'Mark Check-In Now'
                      : (status == AttendanceStatus.checkedIn
                          ? 'Proceed to Check-Out'
                          : 'View Today Attendance Details'),
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
