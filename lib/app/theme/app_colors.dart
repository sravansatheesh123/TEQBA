import 'package:flutter/material.dart';

class AppColors {
  // Primary & Secondary Brand Colors
  static const Color primary = Color(0xFF2563EB); // Royal Blue
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primaryLight = Color(0xFF60A5FA);
  static const Color secondary = Color(0xFF0F172A); // Slate Navy
  
  // Accent & Action Colors
  static const Color accent = Color(0xFF6366F1); // Indigo
  static const Color checkInGreen = Color(0xFF10B981); // Emerald
  static const Color checkOutAmber = Color(0xFFF59E0B); // Amber
  static const Color errorRed = Color(0xFFEF4444); // Rose
  
  // Neutral & Surface Colors
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFEDF2F7);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color textLight = Color(0xFFFFFFFF);

  // Status & Badges
  static const Color statusPendingBg = Color(0xFFFEF3C7);
  static const Color statusPendingText = Color(0xFFB45309);
  
  static const Color statusSyncedBg = Color(0xFFD1FAE5);
  static const Color statusSyncedText = Color(0xFF065F46);
  
  static const Color statusRejectedBg = Color(0xFFFEE2E2);
  static const Color statusRejectedText = Color(0xFF991B1B);

  static const Color statusApprovedBg = Color(0xFFDCFCE7);
  static const Color statusApprovedText = Color(0xFF166534);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient checkInGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient checkOutGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
