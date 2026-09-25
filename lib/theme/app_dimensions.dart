import 'package:flutter/material.dart';

/// Spacing constants for the Image2Caption design system.
abstract final class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
  static const double huge = 48.0;

  /// Standard screen horizontal padding.
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: 20);
  static const EdgeInsets screenPaddingAll = EdgeInsets.fromLTRB(20, 16, 20, 32);
}

/// Border radius constants for the Image2Caption design system.
abstract final class AppRadius {
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 20.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double full = 999.0;

  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius chipRadius = BorderRadius.all(Radius.circular(full));
  static const BorderRadius buttonRadius = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius bottomSheetRadius = BorderRadius.vertical(top: Radius.circular(xxl));
}

/// Shadow definitions for the Image2Caption design system.
abstract final class AppShadows {
  static List<BoxShadow> card(bool isDark) => [
    BoxShadow(
      color: isDark
          ? const Color(0xFF000000).withValues(alpha: 0.4)
          : const Color(0xFF7C3AED).withValues(alpha: 0.08),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> button = [
    BoxShadow(
      color: const Color(0xFF7C3AED).withValues(alpha: 0.35),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> subtle(bool isDark) => [
    BoxShadow(
      color: isDark
          ? const Color(0xFF000000).withValues(alpha: 0.25)
          : const Color(0xFF000000).withValues(alpha: 0.06),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
}

/// Gradient helper methods.
abstract final class AppGradients {
  static const LinearGradient brand = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7C3AED), Color(0xFF9333EA), Color(0xFFEC4899)],
  );

  static const LinearGradient hero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6D28D9), Color(0xFF9333EA), Color(0xFFDB2777)],
  );

  static const LinearGradient accent1 = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7C3AED), Color(0xFF9333EA)],
  );

  static const LinearGradient accent2 = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
  );

  static const LinearGradient accent3 = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFDB2777), Color(0xFF9333EA)],
  );

  static const LinearGradient backgroundLight = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF3F0FA), Color(0xFFF8F7FC)],
  );

  static const LinearGradient backgroundDark = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF12121A), Color(0xFF0F0F14)],
  );
}
