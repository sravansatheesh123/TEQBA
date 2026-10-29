import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/models/leave_balance_model.dart';
import '../../../data/models/leave_request_model.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/theme_helper.dart';
import '../controllers/leave_controller.dart';

class LeaveView extends GetView<LeaveController> {
  const LeaveView({super.key});

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
            'Leave Management',
            style: TextStyle(
              color: ThemeHelper.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 15.5,
              letterSpacing: -0.2,
            ),
          ),
          bottom: TabBar(
            controller: controller.tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: ThemeHelper.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
            tabs: const [
              Tab(text: 'Apply Leave'),
              Tab(text: 'Leave History'),
            ],
          ),
        ),
        body: TabBarView(
          controller: controller.tabController,
          children: [
            _buildApplyLeaveTab(context),
            _buildLeaveHistoryTab(),
          ],
        ),
      );
    });
  }

  // TAB 1: APPLY LEAVE
  Widget _buildApplyLeaveTab(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator(color: AppColors.primary));
      }

      final balance = controller.leaveBalance.value;
      final selectedType = controller.selectedLeaveType.value;
      final selectedDayType = controller.selectedDayType.value;
      final requestedDays = controller.calculatedDaysCount;
      final nonWsCount = controller.reasonLength.value;
      final isSubmitting = controller.isSubmitting.value;
      final isOnline = controller.connectivityService.isOnline.value;

      final availCasual = balance?.availableCasual ?? 0.0;
      final availSick = balance?.availableSick ?? 0.0;
      final availSelected = selectedType == LeaveType.casual ? availCasual : availSick;
      final isExceedingBalance = requestedDays > availSelected;

      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Offline Warning Note if disconnected
            if (!isOnline)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.statusRejectedBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.wifi_off_rounded, color: AppColors.errorRed, size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Device is offline. Leave submission requires an active network connection.',
                        style: TextStyle(fontSize: 11, color: AppColors.statusRejectedText, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),

            // Available Balance Strip
            _buildBalanceStrip(availCasual, availSick),

            const SizedBox(height: 18),

            // 1. Leave Type Selector
            Text(
              'LEAVE CATEGORY',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: ThemeHelper.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildTypeOption(
                    title: 'Casual Leave',
                    subtitle: '${LeaveBalanceModel.format(availCasual)} days left',
                    type: LeaveType.casual,
                    isSelected: selectedType == LeaveType.casual,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTypeOption(
                    title: 'Sick Leave',
                    subtitle: '${LeaveBalanceModel.format(availSick)} days left',
                    type: LeaveType.sick,
                    isSelected: selectedType == LeaveType.sick,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // 2. Duration Mode: Full Day vs Half Day (Morning / Afternoon)
            Text(
              'LEAVE DURATION & TIME SLOT',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: ThemeHelper.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildDurationOption(
                    title: 'Full Day',
                    subtitle: 'Full 8h Shift',
                    badge: '1.0d',
                    icon: Icons.wb_sunny_rounded,
                    isSelected: selectedDayType == LeaveDayType.fullDay,
                    onTap: () => controller.setDayType(LeaveDayType.fullDay),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildDurationOption(
                    title: 'First Half',
                    subtitle: 'Morning Slot',
                    badge: '0.5d',
                    icon: Icons.wb_twilight_rounded,
                    isSelected: selectedDayType == LeaveDayType.firstHalf,
                    onTap: () => controller.setDayType(LeaveDayType.firstHalf),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildDurationOption(
                    title: 'Second Half',
                    subtitle: 'Afternoon Slot',
                    badge: '0.5d',
                    icon: Icons.nightlight_round,
                    isSelected: selectedDayType == LeaveDayType.secondHalf,
                    onTap: () => controller.setDayType(LeaveDayType.secondHalf),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // 3. Date Selection (Full Range vs Single Half-Day)
            if (selectedDayType == LeaveDayType.fullDay) ...[
              Text(
                'DATE RANGE',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: ThemeHelper.textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildDatePickerField(
                      context: context,
                      label: 'Start Date',
                      date: controller.startDate.value,
                      onDatePicked: (picked) => controller.setStartDate(picked),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDatePickerField(
                      context: context,
                      label: 'End Date',
                      date: controller.endDate.value,
                      minDate: controller.startDate.value,
                      onDatePicked: (picked) => controller.setEndDate(picked),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Text(
                'LEAVE DATE',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: ThemeHelper.textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              _buildDatePickerField(
                context: context,
                label: 'Selected Half-Day Date',
                date: controller.startDate.value,
                onDatePicked: (picked) => controller.setStartDate(picked),
              ),
            ],
            const SizedBox(height: 10),

            // Calculated Duration Chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isExceedingBalance ? AppColors.statusRejectedBg : ThemeHelper.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isExceedingBalance ? AppColors.errorRed.withValues(alpha: 0.4) : ThemeHelper.cardBorder,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    selectedDayType == LeaveDayType.fullDay ? Icons.date_range_rounded : Icons.hourglass_bottom_rounded,
                    size: 13,
                    color: isExceedingBalance ? AppColors.errorRed : AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    selectedDayType == LeaveDayType.fullDay
                        ? 'Total: ${LeaveBalanceModel.format(requestedDays)} calendar day(s) (Full Day)'
                        : 'Total: 0.5 Day (${selectedDayType.title} • ${selectedDayType.timeSlot})',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isExceedingBalance ? AppColors.errorRed : ThemeHelper.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            if (isExceedingBalance) ...[
              const SizedBox(height: 4),
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Text(
                  'Requested duration exceeds available balance!',
                  style: TextStyle(fontSize: 10.5, color: AppColors.errorRed, fontWeight: FontWeight.w600),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // 4. Reason Field
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'REASON FOR LEAVE',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: ThemeHelper.textSecondary,
                    letterSpacing: 0.8,
                  ),
                ),
                Text(
                  '$nonWsCount / 10 chars min',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: nonWsCount >= 10 ? AppColors.checkInGreen : ThemeHelper.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller.reasonController,
              maxLines: 4,
              style: TextStyle(color: ThemeHelper.textPrimary, fontSize: 12.5),
              decoration: InputDecoration(
                filled: true,
                fillColor: ThemeHelper.surfaceVariant,
                hintText: 'Enter reason (minimum 10 non-whitespace characters)...',
                hintStyle: TextStyle(color: ThemeHelper.textSecondary.withValues(alpha: 0.6), fontSize: 12),
                helperText: 'e.g. Attending family function, medical appointment',
                helperStyle: TextStyle(color: ThemeHelper.textSecondary, fontSize: 10.5),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: ThemeHelper.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: nonWsCount >= 10 ? AppColors.checkInGreen : AppColors.primary,
                    width: 1.8,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: isSubmitting ? null : () => controller.submitLeaveApplication(),
                child: isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Submit Leave Application',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildBalanceStrip(double casual, double sick) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ThemeHelper.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ThemeHelper.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text('Casual Leave', style: TextStyle(fontSize: 10.5, color: ThemeHelper.textSecondary)),
              const SizedBox(height: 2),
              Text(
                '${LeaveBalanceModel.format(casual)} Days',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.primary),
              ),
            ],
          ),
          Container(width: 1, height: 26, color: ThemeHelper.cardBorder),
          Column(
            children: [
              Text('Sick Leave', style: TextStyle(fontSize: 10.5, color: ThemeHelper.textSecondary)),
              const SizedBox(height: 2),
              Text(
                '${LeaveBalanceModel.format(sick)} Days',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.checkInGreen),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDurationOption({
    required String title,
    required String subtitle,
    required String badge,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.12) : ThemeHelper.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : ThemeHelper.cardBorder,
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, size: 15, color: isSelected ? AppColors.primary : ThemeHelper.textSecondary),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : ThemeHelper.surfaceVariant,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.white : ThemeHelper.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? AppColors.primary : ThemeHelper.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 1),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                subtitle,
                style: TextStyle(fontSize: 9.5, color: ThemeHelper.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeOption({
    required String title,
    required String subtitle,
    required LeaveType type,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => controller.selectedLeaveType.value = type,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.12) : ThemeHelper.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : ThemeHelper.cardBorder,
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: isSelected ? AppColors.primary : ThemeHelper.textSecondary.withValues(alpha: 0.5),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: ThemeHelper.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Text(
                subtitle,
                style: TextStyle(fontSize: 10, color: ThemeHelper.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePickerField({
    required BuildContext context,
    required String label,
    required DateTime date,
    DateTime? minDate,
    required Function(DateTime) onDatePicked,
  }) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return InkWell(
      onTap: () async {
        final initial = date.isBefore(minDate ?? today) ? (minDate ?? today) : date;
        final picked = await showDatePicker(
          context: context,
          initialDate: initial,
          firstDate: minDate ?? today,
          lastDate: today.add(const Duration(days: 365)),
        );
        if (picked != null) {
          onDatePicked(picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: ThemeHelper.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ThemeHelper.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 10, color: ThemeHelper.textSecondary)),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateFormat.format(date),
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: ThemeHelper.textPrimary),
                ),
                const Icon(Icons.calendar_today_rounded, size: 15, color: AppColors.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // TAB 2: LEAVE HISTORY
  Widget _buildLeaveHistoryTab() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator(color: AppColors.primary));
      }

      final requests = controller.leaveRequests;

      if (requests.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy_rounded, size: 48, color: ThemeHelper.textSecondary.withValues(alpha: 0.4)),
                const SizedBox(height: 12),
                Text('No Leave Requests', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: ThemeHelper.textPrimary)),
                const SizedBox(height: 6),
                Text(
                  'You haven\'t applied for any leaves yet.',
                  style: TextStyle(fontSize: 11.5, color: ThemeHelper.textSecondary),
                ),
              ],
            ),
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () => controller.loadData(),
        color: AppColors.primary,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final req = requests[index];
            return _buildLeaveRequestCard(req);
          },
        ),
      );
    });
  }

  Widget _buildLeaveRequestCard(LeaveRequestModel req) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final startStr = dateFormat.format(req.startDate);
    final endStr = dateFormat.format(req.endDate);
    final appliedTimeStr = DateFormat('MMM dd, yyyy • hh:mm a').format(req.createdAt);

    Color badgeBg;
    Color badgeText;
    String badgeLabel;

    switch (req.status) {
      case LeaveStatus.approved:
        badgeBg = AppColors.statusApprovedBg;
        badgeText = AppColors.statusApprovedText;
        badgeLabel = 'Approved';
        break;
      case LeaveStatus.rejected:
        badgeBg = AppColors.statusRejectedBg;
        badgeText = AppColors.statusRejectedText;
        badgeLabel = 'Rejected';
        break;
      case LeaveStatus.pending:
        badgeBg = AppColors.statusPendingBg;
        badgeText = AppColors.statusPendingText;
        badgeLabel = 'Pending';
        break;
    }

    final isHalfDay = req.dayType != LeaveDayType.fullDay;
    final durationLabel = isHalfDay ? req.dayType.title : 'Full Day';
    final durationBadgeColor = isHalfDay ? const Color(0xFFF59E0B) : AppColors.primary;

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
          // Row 1: Leave Category, Duration Mode Badge, and Approval Status
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        req.leaveType == LeaveType.casual ? 'Casual Leave' : 'Sick Leave',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.1,
                          color: ThemeHelper.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: durationBadgeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: durationBadgeColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        '$durationLabel (${LeaveBalanceModel.format(req.daysCount)}d)',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: durationBadgeColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  badgeLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: badgeText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Row 2: Leave Dates & Specific Working Shift Slot
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: ThemeHelper.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.date_range_rounded, size: 13, color: AppColors.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    isHalfDay
                        ? '$startStr (${req.dayType.timeSlot})'
                        : '$startStr  to  $endStr (Full Day Shift)',
                    style: TextStyle(
                      fontSize: 11,
                      color: ThemeHelper.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Row 3: FULL TIMESTAMP (Applied Date & Time)
          Row(
            children: [
              Icon(Icons.schedule_rounded, size: 12, color: ThemeHelper.textSecondary),
              const SizedBox(width: 5),
              Text(
                'Applied on: $appliedTimeStr',
                style: TextStyle(
                  fontSize: 10.5,
                  color: ThemeHelper.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Row 4: Reason Note
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: ThemeHelper.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '"${req.reason}"',
              style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: ThemeHelper.textPrimary),
            ),
          ),
          if (req.rejectionReason != null && req.rejectionReason!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.statusRejectedBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Rejection note: ${req.rejectionReason}',
                style: const TextStyle(fontSize: 10.5, color: AppColors.statusRejectedText),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
