import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/models/attendance_event_model.dart';
import '../../../data/models/attendance_record_model.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/theme_helper.dart';
import '../controllers/dashboard_controller.dart';

class RecentAttendanceList extends StatelessWidget {
  const RecentAttendanceList({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();

    return Obx(() {
      final records = controller.recentRecords;

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: ThemeHelper.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: ThemeHelper.isLight ? 0.04 : 0.18),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: ThemeHelper.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.history_rounded, color: ThemeHelper.primaryColor, size: 20),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Recent Attendance',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: ThemeHelper.textPrimary,
                            letterSpacing: -0.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () {
                    Get.toNamed(Routes.history);
                  },
                  child: Text(
                    'View All',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: ThemeHelper.primaryColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (records.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.event_note_outlined, size: 36, color: ThemeHelper.textSecondary.withValues(alpha: 0.4)),
                      const SizedBox(height: 6),
                      Text(
                        'No previous records found',
                        style: TextStyle(fontSize: 12, color: ThemeHelper.textSecondary),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: records.length,
                separatorBuilder: (_, __) => Divider(height: 14, color: ThemeHelper.cardBorder),
                itemBuilder: (context, index) {
                  final item = records[index];
                  return _buildRecordTile(item);
                },
              ),
          ],
        ),
      );
    });
  }

  Widget _buildRecordTile(AttendanceRecordModel item) {
    DateTime? parsedDate;
    try {
      parsedDate = DateTime.parse(item.date);
    } catch (_) {}

    final dateLabel = parsedDate != null
        ? DateFormat('EEE, MMM dd').format(parsedDate)
        : item.date;

    final timeFormat = DateFormat('hh:mm a');
    final inStr = item.checkInTime != null ? timeFormat.format(item.checkInTime!) : '--:--';
    final outStr = item.checkOutTime != null ? timeFormat.format(item.checkOutTime!) : '--:--';

    Color badgeBg;
    Color badgeText;
    String badgeLabel;

    switch (item.syncStatus) {
      case SyncStatus.pending:
        badgeBg = AppColors.statusPendingBg;
        badgeText = AppColors.statusPendingText;
        badgeLabel = 'Pending Sync';
        break;
      case SyncStatus.rejected:
        badgeBg = AppColors.statusRejectedBg;
        badgeText = AppColors.statusRejectedText;
        badgeLabel = 'Rejected';
        break;
      case SyncStatus.synced:
        badgeBg = AppColors.statusSyncedBg;
        badgeText = AppColors.statusSyncedText;
        badgeLabel = 'Synced';
        break;
    }

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: ThemeHelper.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                parsedDate != null ? DateFormat('dd').format(parsedDate) : '--',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: ThemeHelper.textPrimary),
              ),
              Text(
                parsedDate != null ? DateFormat('MMM').format(parsedDate).toUpperCase() : '',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: ThemeHelper.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dateLabel,
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: ThemeHelper.textPrimary),
              ),
              const SizedBox(height: 2),
              Text(
                'In: $inStr  •  Out: $outStr',
                style: TextStyle(fontSize: 11, color: ThemeHelper.textSecondary),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badgeLabel,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: badgeText,
                ),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              item.formattedWorkingHours,
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: ThemeHelper.textPrimary),
            ),
          ],
        ),
      ],
    );
  }
}
