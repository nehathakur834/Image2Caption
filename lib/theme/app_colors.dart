import 'package:flutter/material.dart';

/// Centralized color palette for the Image2Caption design system.
abstract final class AppColors {
  // ── Brand Gradient ──────────────────────────────────────────────────
  static const Color brandPurple = Color(0xFF7C3AED);
  static const Color brandViolet = Color(0xFF9333EA);
  static const Color brandPink = Color(0xFFEC4899);
  static const Color brandBlue = Color(0xFF3B82F6);

  // ── Light Surface ───────────────────────────────────────────────────
  static const Color lightBackground = Color(0xFFF8F7FC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF3F0FA);
  static const Color lightBorder = Color(0xFFE9E4F5);

  // ── Dark Surface ────────────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF0F0F14);
  static const Color darkSurface = Color(0xFF1A1A24);
  static const Color darkSurfaceVariant = Color(0xFF22222E);
  static const Color darkBorder = Color(0xFF2E2E3E);

  // ── Text ────────────────────────────────────────────────────────────
  static const Color textDark = Color(0xFF1A1A2E);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color textLight = Color(0xFFFFFFFF);

  // ── Status ──────────────────────────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);

  // ── Gradient definitions ────────────────────────────────────────────
  static const List<Color> brandGradientColors = [
    brandPurple,
    brandViolet,
    brandPink,
  ];

  static const List<Color> heroGradientColors = [
    Color(0xFF6D28D9),
    Color(0xFF9333EA),
    Color(0xFFDB2777),
  ];

  static const List<Color> cardAccent1 = [
    Color(0xFF7C3AED),
    Color(0xFF9333EA),
  ];

  static const List<Color> cardAccent2 = [
    Color(0xFF2563EB),
    Color(0xFF7C3AED),
  ];

  static const List<Color> cardAccent3 = [
    Color(0xFFDB2777),
    Color(0xFF9333EA),
  ];
}
