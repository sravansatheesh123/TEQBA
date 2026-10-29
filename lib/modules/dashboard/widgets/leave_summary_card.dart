import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/leave_balance_model.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/theme/theme_helper.dart';
import '../controllers/dashboard_controller.dart';

class LeaveSummaryCard extends StatelessWidget {
  const LeaveSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();

    return Obx(() {
      final balance = controller.leaveBalance.value;
      final casual = balance?.availableCasual ?? 0.0;
      final sick = balance?.availableSick ?? 0.0;
      final total = balance?.totalAvailable ?? 0.0;
      final casualStr = LeaveBalanceModel.format(casual);
      final sickStr = LeaveBalanceModel.format(sick);
      final totalStr = LeaveBalanceModel.format(total);

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
                      Icon(Icons.calendar_month_rounded, color: ThemeHelper.primaryColor, size: 20),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Leave Balance',
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
                TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () {
                    Get.toNamed(Routes.leave);
                  },
                  icon: Icon(Icons.add_rounded, size: 14, color: ThemeHelper.primaryColor),
                  label: Text(
                    'Apply Leave',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: ThemeHelper.primaryColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                // Casual Leave Card
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ThemeHelper.isLight
                          ? const Color(0xFFEFF6FF)
                          : const Color(0xFF1E3A8A).withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: ThemeHelper.isLight
                            ? const Color(0xFFBFDBFE)
                            : const Color(0xFF3B82F6).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Casual Leave',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: ThemeHelper.isLight ? Colors.blue.shade900 : const Color(0xFF93C5FD),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              casualStr,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: ThemeHelper.isLight ? Colors.blue.shade900 : const Color(0xFF93C5FD),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'days left',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: ThemeHelper.isLight ? Colors.blue.shade700 : const Color(0xFFBFDBFE),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Sick Leave Card
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ThemeHelper.isLight
                          ? const Color(0xFFECFDF5)
                          : const Color(0xFF064E3B).withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: ThemeHelper.isLight
                            ? const Color(0xFFA7F3D0)
                            : const Color(0xFF10B981).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sick Leave',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: ThemeHelper.isLight ? const Color(0xFF065F46) : const Color(0xFF6EE7B7),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              sickStr,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: ThemeHelper.isLight ? const Color(0xFF065F46) : const Color(0xFF6EE7B7),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'days left',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: ThemeHelper.isLight ? Colors.teal.shade700 : const Color(0xFFA7F3D0),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: ThemeHelper.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: ThemeHelper.cardBorder.withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Total Available Allowance',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: ThemeHelper.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '$totalStr Days',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: ThemeHelper.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}
