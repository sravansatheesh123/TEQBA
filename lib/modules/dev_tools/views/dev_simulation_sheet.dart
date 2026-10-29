import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/location_service.dart';
import '../../../app/theme/theme_helper.dart';

class DevSimulationSheet extends StatefulWidget {
  const DevSimulationSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const DevSimulationSheet(),
    );
  }

  @override
  State<DevSimulationSheet> createState() => _DevSimulationSheetState();
}

class _DevSimulationSheetState extends State<DevSimulationSheet> {
  late LocationService _locationService;
  late LocationSimulationMode _selectedMode;

  @override
  void initState() {
    super.initState();
    _locationService = Get.find<LocationService>();
    final current = _locationService.simulationMode.value;
    if (current == LocationSimulationMode.atOffice) {
      _selectedMode = LocationSimulationMode.atOffice;
    } else {
      _selectedMode = LocationSimulationMode.realGps;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final cardBg = ThemeHelper.cardColor;
      final textPrim = ThemeHelper.textPrimary;
      final textSec = ThemeHelper.textSecondary;
      final primary = ThemeHelper.primaryColor;
      final border = ThemeHelper.cardBorder;

      return Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: border),
        ),
        padding: EdgeInsets.only(
          top: 16,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: ThemeHelper.isLight ? Colors.grey.shade300 : Colors.grey.shade700,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reviewer Simulation Panel',
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: textPrim,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Office Location: Bangalore HQ (Fixed)',
                          style: TextStyle(fontSize: 11, color: textSec),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, color: textSec),
                  ),
                ],
              ),
              Divider(height: 24, color: border),

              // Section Header
              Text(
                'SELECT LOCATION SCENARIO',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: primary,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 12),

              // Option 1: Current Location (Device GPS)
              _buildOptionCard(
                mode: LocationSimulationMode.realGps,
                title: 'Current Location (Device GPS)',
                subtitle: 'Fetches real-time GPS coordinates directly from your device.',
                badgeText: 'Device GPS',
                badgeBg: primary.withValues(alpha: 0.15),
                badgeFg: primary,
                icon: Icons.my_location_rounded,
              ),

              const SizedBox(height: 10),

              // Option 2: Office Desk (0m away)
              _buildOptionCard(
                mode: LocationSimulationMode.atOffice,
                title: 'Office Desk (0m away)',
                subtitle: 'Simulates sitting at Bangalore office desk. Exactly 0m from office.',
                badgeText: '< 200m (Valid)',
                badgeBg: const Color(0xFFD1FAE5),
                badgeFg: const Color(0xFF059669),
                icon: Icons.desk_rounded,
              ),

              const SizedBox(height: 20),

              // Attractive Submit Button
              Container(
                width: double.infinity,
                height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primary, primary.withValues(alpha: 0.85)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.35),
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
                  ),
                  icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                  label: const Text(
                    'Submit & Apply Simulation',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                  onPressed: () {
                    _locationService.setSimulationMode(_selectedMode);
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                    if (Get.context != null) {
                      Get.snackbar(
                        'Simulation Applied',
                        _selectedMode == LocationSimulationMode.realGps
                            ? 'Set to Current Location (Device GPS)'
                            : 'Set to Office Desk (0m away - Bangalore HQ)',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: const Color(0xFF0F172A),
                        colorText: Colors.white,
                        icon: const Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E)),
                        margin: const EdgeInsets.all(16),
                        borderRadius: 12,
                        duration: const Duration(seconds: 3),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildOptionCard({
    required LocationSimulationMode mode,
    required String title,
    required String subtitle,
    required String badgeText,
    required Color badgeBg,
    required Color badgeFg,
    required IconData icon,
  }) {
    final isSelected = _selectedMode == mode;
    final primary = ThemeHelper.primaryColor;
    final textPrim = ThemeHelper.textPrimary;
    final textSec = ThemeHelper.textSecondary;
    final surfVar = ThemeHelper.surfaceVariant;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        setState(() {
          _selectedMode = mode;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? primary.withValues(alpha: 0.1) : surfVar,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? primary : ThemeHelper.cardBorder,
            width: 1.8,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 2),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? primary : (ThemeHelper.isLight ? Colors.grey.shade300 : Colors.grey.shade700),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : (ThemeHelper.isLight ? Colors.grey.shade700 : Colors.grey.shade300),
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
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? primary : textPrim,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: badgeFg,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: textSec,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: isSelected ? primary : (ThemeHelper.isLight ? Colors.grey.shade400 : Colors.grey.shade600),
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
