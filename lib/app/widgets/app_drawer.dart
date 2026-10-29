import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/services/location_service.dart';
import '../../modules/attendance/controllers/attendance_controller.dart';
import '../../modules/auth/controllers/login_controller.dart';
import '../../modules/dashboard/controllers/dashboard_controller.dart';
import '../../modules/dev_tools/views/theme_helper_sheet.dart';
import '../routes/app_routes.dart';
import '../theme/app_colors.dart';
import '../theme/theme_helper.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final bg = ThemeHelper.cardColor;
      final textPrim = ThemeHelper.textPrimary;
      final textSec = ThemeHelper.textSecondary;
      final primary = ThemeHelper.primaryColor;
      final border = ThemeHelper.cardBorder;
      final surfVar = ThemeHelper.surfaceVariant;

      final locService = Get.isRegistered<LocationService>() ? Get.find<LocationService>() : null;
      final simMode = locService?.simulationMode.value ?? LocationSimulationMode.realGps;
      final currentRoute = Get.currentRoute;

      return Drawer(
        backgroundColor: bg,
        elevation: 16,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 1. Employee Profile Header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                decoration: BoxDecoration(
                  color: surfVar,
                  border: Border(bottom: BorderSide(color: border)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [primary, primary.withValues(alpha: 0.8)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: primary.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'TE',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Test Employee',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: textPrim,
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 1),
                              Text(
                                'intest@123 • REBS-2024-042',
                                style: TextStyle(fontSize: 11, color: textSec),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Software Engineer • Engineering',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: primary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Office location pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.business_rounded, size: 12, color: primary),
                          const SizedBox(width: 5),
                          Text(
                            'Bengaluru HQ (Fixed 200m Geofence)',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: textPrim,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Scrollable Body with Controls & Navigation
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  children: [
                    // --- SECTION 1: WORKSPACE DISPLAY MODES ---
                    _buildSectionHeader('WORKSPACE APPEARANCE'),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: surfVar,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: border),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              _buildThemeButton(
                                label: 'Light',
                                icon: Icons.wb_sunny_rounded,
                                isSelected: ThemeHelper.isLight,
                                color: const Color(0xFF2563EB),
                                onTap: () => ThemeHelper.setTheme(AppThemeMode.light),
                              ),
                              const SizedBox(width: 6),
                              _buildThemeButton(
                                label: 'Dark',
                                icon: Icons.nightlight_round,
                                isSelected: ThemeHelper.isDark,
                                color: const Color(0xFF60A5FA),
                                onTap: () => ThemeHelper.setTheme(AppThemeMode.dark),
                              ),
                              const SizedBox(width: 6),
                              _buildThemeButton(
                                label: 'Eye Care',
                                icon: Icons.visibility_rounded,
                                isSelected: ThemeHelper.isEyeComfort,
                                color: const Color(0xFFF59E0B),
                                onTap: () => ThemeHelper.setTheme(AppThemeMode.eyeComfort),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () {
                              Navigator.pop(context);
                              ThemeHelperSheet.show(context);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.palette_rounded, size: 13, color: primary),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Display Mode Settings',
                                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: primary),
                                  ),
                                  const SizedBox(width: 2),
                                  Icon(Icons.chevron_right_rounded, size: 14, color: primary),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // --- SECTION 2: REVIEWER & DEV TOOLS ---
                    _buildSectionHeader('REVIEWER TESTING SIMULATOR'),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: surfVar,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: border),
                      ),
                      child: Column(
                        children: [
                          _buildDrawerTile(
                            icon: Icons.desk_rounded,
                            iconColor: simMode == LocationSimulationMode.atOffice ? AppColors.checkInGreen : textSec,
                            title: 'Office Desk (0m away)',
                            subtitle: 'Simulate inside Bangalore office geofence',
                            trailing: simMode == LocationSimulationMode.atOffice
                                ? _buildActiveTag('ACTIVE', AppColors.checkInGreen)
                                : null,
                            onTap: () {
                              locService?.setSimulationMode(LocationSimulationMode.atOffice);
                              _triggerLocationRefresh();
                            },
                          ),
                          Divider(height: 1, indent: 44, color: border),
                          _buildDrawerTile(
                            icon: Icons.my_location_rounded,
                            iconColor: simMode == LocationSimulationMode.realGps ? primary : textSec,
                            title: 'Real Device GPS',
                            subtitle: 'Acquire real-time coordinates from device',
                            trailing: simMode == LocationSimulationMode.realGps
                                ? _buildActiveTag('ACTIVE', primary)
                                : null,
                            onTap: () {
                              locService?.setSimulationMode(LocationSimulationMode.realGps);
                              _triggerLocationRefresh();
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // --- SECTION 3: APP NAVIGATION ---
                    _buildSectionHeader('WORKSPACE NAVIGATION'),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: surfVar,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: border),
                      ),
                      child: Column(
                        children: [
                          _buildNavItem(
                            icon: Icons.dashboard_rounded,
                            label: 'Dashboard',
                            isSelected: currentRoute == Routes.dashboard || currentRoute == '/',
                            onTap: () {
                              Navigator.pop(context);
                              if (currentRoute != Routes.dashboard && currentRoute != '/') {
                                Get.offAllNamed(Routes.dashboard);
                              }
                            },
                          ),
                          Divider(height: 1, indent: 44, color: border),
                          _buildNavItem(
                            icon: Icons.fingerprint_rounded,
                            label: 'Attendance Check-In / Out',
                            isSelected: currentRoute == Routes.attendance,
                            onTap: () async {
                              Navigator.pop(context);
                              if (currentRoute != Routes.attendance) {
                                await Get.toNamed(Routes.attendance);
                                if (Get.isRegistered<DashboardController>()) {
                                  Get.find<DashboardController>().loadDashboardData(isSilent: true);
                                }
                              }
                            },
                          ),
                          Divider(height: 1, indent: 44, color: border),
                          _buildNavItem(
                            icon: Icons.history_rounded,
                            label: 'Attendance History',
                            isSelected: currentRoute == Routes.history,
                            onTap: () {
                              Navigator.pop(context);
                              if (currentRoute != Routes.history) {
                                Get.toNamed(Routes.history);
                              }
                            },
                          ),
                          Divider(height: 1, indent: 44, color: border),
                          _buildNavItem(
                            icon: Icons.calendar_month_rounded,
                            label: 'Leave Management',
                            isSelected: currentRoute == Routes.leave,
                            onTap: () {
                              Navigator.pop(context);
                              if (currentRoute != Routes.leave) {
                                Get.toNamed(Routes.leave);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Drawer Bottom Sign Out Tile
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: surfVar,
                  border: Border(top: BorderSide(color: border)),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.pop(context);
                    Get.dialog(
                      AlertDialog(
                        backgroundColor: bg,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: Row(
                          children: [
                            const Icon(Icons.logout_rounded, color: Color(0xFFDC2626)),
                            const SizedBox(width: 8),
                            Text(
                              'Sign Out',
                              style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                                color: textPrim,
                              ),
                            ),
                          ],
                        ),
                        content: Text(
                          'Are you sure you want to sign out of REBS HRMS?',
                          style: TextStyle(fontSize: 12.5, color: textSec),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Get.back(),
                            child: Text('Cancel', style: TextStyle(color: textSec, fontSize: 12.5)),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFDC2626),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () {
                              Get.back();
                              LoginController.logout();
                            },
                            child: const Text('Sign Out', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 16),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Sign Out Session',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, size: 16, color: textSec),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 2),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          color: ThemeHelper.textSecondary,
          letterSpacing: 0.7,
        ),
      ),
    );
  }

  Widget _buildThemeButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.16) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : Colors.transparent,
              width: 1.2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: isSelected ? color : ThemeHelper.textSecondary),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  color: isSelected ? color : ThemeHelper.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 15, color: iconColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: ThemeHelper.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 10, color: ThemeHelper.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 6),
              trailing,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final primary = ThemeHelper.primaryColor;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 17,
              color: isSelected ? primary : ThemeHelper.textSecondary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? primary : ThemeHelper.textPrimary,
                ),
              ),
            ),
            if (isSelected)
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  void _triggerLocationRefresh() {
    if (Get.isRegistered<AttendanceController>()) {
      Get.find<AttendanceController>().verifyLocation();
    }
    if (Get.isRegistered<DashboardController>()) {
      Get.find<DashboardController>().fetchCurrentLocation();
    }
  }
}
