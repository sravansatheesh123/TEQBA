import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../dev_tools/views/theme_helper_sheet.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/theme_helper.dart';
import '../../../app/widgets/app_drawer.dart';
import '../controllers/dashboard_controller.dart';
import '../widgets/leave_summary_card.dart';
import '../widgets/live_work_timer_card.dart';
import '../widgets/sync_banner_widget.dart';

class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Scaffold(
        backgroundColor: ThemeHelper.background,
        drawer: const AppDrawer(),
        appBar: _buildAppBar(context),
        body: Obx(() {
          if (controller.isLoading.value) {
            return Center(
              child: CircularProgressIndicator(color: ThemeHelper.primaryColor),
            );
          }

          if (controller.errorMessage.isNotEmpty && controller.employee.value == null) {
            return _buildErrorState();
          }

          return RefreshIndicator(
            onRefresh: () => controller.loadDashboardData(forceRefresh: true),
            color: ThemeHelper.primaryColor,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Employee Header Card - Tapping opens Theme Helper directly
                  _buildEmployeeHeader(context),

                  // 2. Offline / Pending Sync Banner
                  const SyncBannerWidget(),

                  // 3. Live Work Timer & Attendance Card
                  const LiveWorkTimerCard(),

                  // 4. Leave Balance Summary Card
                  const LeaveSummaryCard(),
                ],
              ),
            ),
          );
        }),
        bottomNavigationBar: _buildBottomNav(),
      );
    });
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: ThemeHelper.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: ThemeHelper.textPrimary),
      leading: Builder(
        builder: (ctx) => IconButton(
          tooltip: 'Open Workspace Drawer',
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: ThemeHelper.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ThemeHelper.cardBorder),
            ),
            child: Icon(Icons.menu_rounded, color: ThemeHelper.textPrimary, size: 19),
          ),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: ThemeHelper.primaryColor,
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Icon(Icons.hub_rounded, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'REBS HRMS',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: ThemeHelper.textPrimary,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Employee Workspace',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: ThemeHelper.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeHeader(BuildContext context) {
    return Obx(() {
      final emp = controller.employee.value;
      if (emp == null) return const SizedBox.shrink();

      return Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        decoration: BoxDecoration(
          gradient: ThemeHelper.headerGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => ThemeHelperSheet.show(context),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  // Profile Avatar with theme badge
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: Colors.white24,
                        backgroundImage: NetworkImage(emp.avatarUrl),
                        onBackgroundImageError: (_, __) {},
                        child: emp.avatarUrl.isEmpty
                            ? const Icon(Icons.person, color: Colors.white)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: ThemeHelper.primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: Icon(
                            ThemeHelper.currentIcon,
                            size: 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                    Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                emp.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                emp.id,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${emp.role}  •  ${emp.department}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            const Icon(Icons.business_rounded, color: Colors.white60, size: 11),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                emp.officeConfig.name,
                                style: const TextStyle(color: Colors.white60, fontSize: 10.5),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Direct Theme Helper pill indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(ThemeHelper.currentIcon, color: Colors.amberAccent, size: 12),
                        const SizedBox(width: 3),
                        Text(
                          ThemeHelper.mode == AppThemeMode.eyeComfort
                              ? 'Comfort'
                              : (ThemeHelper.mode == AppThemeMode.dark ? 'Dark' : 'Light'),
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 50, color: AppColors.errorRed),
            const SizedBox(height: 12),
            Text(
              controller.errorMessage.value,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: ThemeHelper.textPrimary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => controller.loadDashboardData(forceRefresh: true),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return NavigationBar(
      selectedIndex: 0,
      height: 60,
      backgroundColor: ThemeHelper.navBarBg,
      indicatorColor: ThemeHelper.primaryColor.withValues(alpha: 0.15),
      elevation: 8,
      onDestinationSelected: (index) async {
        if (index == 1) {
          await Get.toNamed(Routes.attendance);
          controller.loadDashboardData(isSilent: true);
        } else if (index == 2) {
          await Get.toNamed(Routes.history);
        } else if (index == 3) {
          await Get.toNamed(Routes.leave);
        }
      },
      destinations: [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined, color: ThemeHelper.textSecondary),
          selectedIcon: Icon(Icons.dashboard_rounded, color: ThemeHelper.primaryColor),
          label: 'Dashboard',
        ),
        NavigationDestination(
          icon: Icon(Icons.fingerprint_rounded, color: ThemeHelper.textSecondary),
          selectedIcon: Icon(Icons.fingerprint_rounded, color: ThemeHelper.primaryColor),
          label: 'Attendance',
        ),
        NavigationDestination(
          icon: Icon(Icons.history_rounded, color: ThemeHelper.textSecondary),
          selectedIcon: Icon(Icons.history_rounded, color: ThemeHelper.primaryColor),
          label: 'History',
        ),
        NavigationDestination(
          icon: Icon(Icons.calendar_month_outlined, color: ThemeHelper.textSecondary),
          selectedIcon: Icon(Icons.calendar_month_rounded, color: ThemeHelper.primaryColor),
          label: 'Leave',
        ),
      ],
    );
  }
}
