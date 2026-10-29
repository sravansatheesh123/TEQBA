import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/theme/theme_helper.dart';

class ThemeHelperSheet extends StatefulWidget {
  const ThemeHelperSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ThemeHelperSheet(),
    );
  }

  @override
  State<ThemeHelperSheet> createState() => _ThemeHelperSheetState();
}

class _ThemeHelperSheetState extends State<ThemeHelperSheet> {
  late AppThemeMode _selectedMode;

  @override
  void initState() {
    super.initState();
    _selectedMode = ThemeHelper.mode;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark = ThemeHelper.isDark;
      final isComfort = ThemeHelper.isEyeComfort;
      final sheetBg = ThemeHelper.cardColor;
      final textPrim = ThemeHelper.textPrimary;
      final textSec = ThemeHelper.textSecondary;
      final borderColor = ThemeHelper.cardBorder;

      return Container(
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: borderColor, width: 1.2)),
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
                    color: isDark || isComfort ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: ThemeHelper.primaryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.palette_rounded,
                      color: ThemeHelper.primaryColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Theme & Display Helper',
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: textPrim,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Select your preferred workspace visual mode',
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
              Divider(height: 24, color: borderColor),

              // Section Header
              Text(
                'WORKSPACE APPEARANCE MODES',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: ThemeHelper.primaryColor,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 12),

              // Option 1: Light Mode
              _buildThemeOption(
                mode: AppThemeMode.light,
                title: 'Light Mode',
                subtitle: 'Crisp, high-contrast daytime workspace with clean white cards and royal blue accents.',
                icon: Icons.wb_sunny_rounded,
                iconColor: const Color(0xFFF59E0B),
                previewColors: const [Color(0xFFF8FAFC), Colors.white, Color(0xFF2563EB)],
              ),

              const SizedBox(height: 10),

              // Option 2: Dark Mode
              _buildThemeOption(
                mode: AppThemeMode.dark,
                title: 'Dark Mode',
                subtitle: 'Deep midnight slate theme. Reduces screen glare & power consumption in dim lighting.',
                icon: Icons.nightlight_round,
                iconColor: const Color(0xFF60A5FA),
                previewColors: const [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF3B82F6)],
              ),

              const SizedBox(height: 10),

              // Option 3: Dark Eye Comfort Mode
              _buildThemeOption(
                mode: AppThemeMode.eyeComfort,
                title: 'Dark Eye Comfort Mode',
                subtitle: 'Warm espresso & amber shield. Eliminates harsh blue-light strain during evening shifts.',
                badge: 'EYE CARE SHIELD',
                badgeBg: const Color(0xFFFEF3C7),
                badgeFg: const Color(0xFF92400E),
                icon: Icons.visibility_rounded,
                iconColor: const Color(0xFFF59E0B),
                previewColors: const [Color(0xFF181512), Color(0xFF26221D), Color(0xFFF59E0B)],
              ),

              const SizedBox(height: 24),

              // Submit & Apply Theme Button
              Container(
                width: double.infinity,
                height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _selectedMode == AppThemeMode.eyeComfort
                        ? [const Color(0xFFD97706), const Color(0xFFF59E0B)]
                        : (_selectedMode == AppThemeMode.dark
                            ? [const Color(0xFF2563EB), const Color(0xFF3B82F6)]
                            : [const Color(0xFF0F172A), const Color(0xFF1E293B)]),
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: (_selectedMode == AppThemeMode.eyeComfort
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFF3B82F6))
                          .withValues(alpha: 0.35),
                      blurRadius: 16,
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
                    'Apply Selected Theme',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                  onPressed: () {
                    ThemeHelper.setTheme(_selectedMode);
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                    Get.snackbar(
                      'Theme Applied',
                      _selectedMode == AppThemeMode.eyeComfort
                          ? 'Switched to Dark Eye Comfort Mode (Eye Care Shield Active)'
                          : (_selectedMode == AppThemeMode.dark
                              ? 'Switched to Dark Mode (Midnight Slate Active)'
                              : 'Switched to Light Mode (Daytime Workspace Active)'),
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: const Color(0xFF0F172A),
                      colorText: Colors.white,
                      icon: Icon(
                        _selectedMode == AppThemeMode.eyeComfort
                            ? Icons.visibility_rounded
                            : (_selectedMode == AppThemeMode.dark
                                ? Icons.nightlight_round
                                : Icons.wb_sunny_rounded),
                        color: const Color(0xFF22C55E),
                      ),
                      margin: const EdgeInsets.all(16),
                      borderRadius: 12,
                      duration: const Duration(seconds: 3),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildThemeOption({
    required AppThemeMode mode,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required List<Color> previewColors,
    String? badge,
    Color? badgeBg,
    Color? badgeFg,
  }) {
    final isSelected = _selectedMode == mode;
    final primary = ThemeHelper.primaryColor;
    final textPrim = ThemeHelper.textPrimary;
    final textSec = ThemeHelper.textSecondary;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        setState(() {
          _selectedMode = mode;
        });
        // Instant live update
        ThemeHelper.setTheme(mode);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? primary.withValues(alpha: 0.08) : ThemeHelper.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primary : ThemeHelper.cardBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
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
                      if (badge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeBg ?? const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              color: badgeFg ?? const Color(0xFF92400E),
                              letterSpacing: 0.4,
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
                  const SizedBox(height: 8),
                  // Color swatch preview row
                  Row(
                    children: [
                      const Text(
                        'Palette: ',
                        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: Colors.grey),
                      ),
                      const SizedBox(width: 4),
                      for (final color in previewColors) ...[
                        Container(
                          width: 14,
                          height: 14,
                          margin: const EdgeInsets.only(right: 4),
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.withValues(alpha: 0.4), width: 0.8),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? primary : Colors.grey.shade400,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
