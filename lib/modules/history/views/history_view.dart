import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/models/attendance_event_model.dart';
import '../../../data/models/attendance_record_model.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/theme_helper.dart';
import '../controllers/history_controller.dart';

class HistoryView extends GetView<HistoryController> {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Scaffold(
        backgroundColor: ThemeHelper.background,
        appBar: AppBar(
          backgroundColor: ThemeHelper.background,
          elevation: 0,
          iconTheme: IconThemeData(color: ThemeHelper.textPrimary),
          title: Text(
            'Attendance History',
            style: TextStyle(
              color: ThemeHelper.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 15.5,
              letterSpacing: -0.2,
            ),
          ),
        ),
        body: Column(
          children: [
            // Filter Chips Row
            _buildFilterBar(),

            // Records List
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }

                final records = controller.filteredRecords;

                if (records.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  onRefresh: () => controller.loadHistory(),
                  color: AppColors.primary,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: records.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final record = records[index];
                      return _buildHistoryCard(record);
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildFilterBar() {
    final filters = ['All', 'Synced', 'Pending', 'Rejected'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: ThemeHelper.cardColor,
        border: Border(bottom: BorderSide(color: ThemeHelper.cardBorder)),
      ),
      child: Obx(() {
        final active = controller.selectedFilter.value;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: filters.map((f) {
              final isSelected = active == f;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(
                    f,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : ThemeHelper.textPrimary,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  backgroundColor: ThemeHelper.surfaceVariant,
                  showCheckmark: false,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : ThemeHelper.cardBorder,
                    ),
                  ),
                  onSelected: (_) => controller.setFilter(f),
                ),
              );
            }).toList(),
          ),
        );
      }),
    );
  }

  Widget _buildHistoryCard(AttendanceRecordModel record) {
    DateTime? parsedDate;
    try {
      parsedDate = DateTime.parse(record.date);
    } catch (_) {}

    final dateStr = parsedDate != null
        ? DateFormat('EEEE, MMM dd, yyyy').format(parsedDate)
        : record.date;

    final timeFormat = DateFormat('hh:mm a');
    final inTime = record.checkInTime != null ? timeFormat.format(record.checkInTime!) : '--:--';
    final outTime = record.checkOutTime != null ? timeFormat.format(record.checkOutTime!) : '--:--';

    Color badgeBg;
    Color badgeText;
    String badgeTitle;
    IconData badgeIcon;

    switch (record.syncStatus) {
      case SyncStatus.pending:
        badgeBg = AppColors.statusPendingBg;
        badgeText = AppColors.statusPendingText;
        badgeTitle = 'Pending Sync';
        badgeIcon = Icons.hourglass_top_rounded;
        break;
      case SyncStatus.rejected:
        badgeBg = AppColors.statusRejectedBg;
        badgeText = AppColors.statusRejectedText;
        badgeTitle = 'Rejected';
        badgeIcon = Icons.error_outline_rounded;
        break;
      case SyncStatus.synced:
        badgeBg = AppColors.statusSyncedBg;
        badgeText = AppColors.statusSyncedText;
        badgeTitle = 'Synced';
        badgeIcon = Icons.check_circle_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeHelper.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ThemeHelper.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Date & Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.1,
                    color: ThemeHelper.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(badgeIcon, color: badgeText, size: 11),
                    const SizedBox(width: 4),
                    Text(
                      badgeTitle,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: badgeText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // In / Out & Duration Grid
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ThemeHelper.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Check-in', style: TextStyle(fontSize: 10, color: ThemeHelper.textSecondary)),
                      const SizedBox(height: 2),
                      Text(
                        inTime,
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: ThemeHelper.textPrimary),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 26, color: ThemeHelper.cardBorder),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Check-out', style: TextStyle(fontSize: 10, color: ThemeHelper.textSecondary)),
                      const SizedBox(height: 2),
                      Text(
                        outTime,
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: ThemeHelper.textPrimary),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 26, color: ThemeHelper.cardBorder),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Duration', style: TextStyle(fontSize: 10, color: ThemeHelper.textSecondary)),
                      const SizedBox(height: 2),
                      Text(
                        record.formattedWorkingHours,
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (record.rejectionReason != null && record.rejectionReason!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.statusRejectedBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.errorRed),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Rejection reason: ${record.rejectionReason}',
                      style: const TextStyle(fontSize: 10.5, color: AppColors.statusRejectedText),
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_toggle_off_rounded, size: 48, color: ThemeHelper.textSecondary.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text(
              'No Attendance Records',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: ThemeHelper.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'No records match the current filter (${controller.selectedFilter.value}).',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11.5, color: ThemeHelper.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
