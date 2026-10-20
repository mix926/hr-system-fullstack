import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  HR System — Shared Design System
//  Single source of truth for all UI tokens
// ─────────────────────────────────────────────

class AppColors {
  AppColors._();

  // Brand
  static const Color primary      = Color(0xFF2563EB); // Indigo-600
  static const Color primaryDark  = Color(0xFF1D4ED8); // Indigo-700
  static const Color primaryLight = Color(0xFFEFF6FF); // Indigo-50
  static const Color accent       = Color(0xFF7C3AED); // Violet-600

  // Semantics
  static const Color success      = Color(0xFF16A34A);
  static const Color successLight = Color(0xFFF0FDF4);
  static const Color error        = Color(0xFFDC2626);
  static const Color errorLight   = Color(0xFFFEF2F2);
  static const Color warning      = Color(0xFFD97706);
  static const Color warningLight = Color(0xFFFFFBEB);

  // Neutrals (Slate scale)
  static const Color textPrimary   = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textHint      = Color(0xFF94A3B8);
  static const Color border        = Color(0xFFE2E8F0);
  static const Color divider       = Color(0xFFF1F5F9);
  static const Color surface       = Color(0xFFFFFFFF);
  static const Color background    = Color(0xFFF8FAFC);
  static const Color cardShadow    = Color(0x0A000000);
}

class AppTextStyles {
  AppTextStyles._();

  static const TextStyle displayLarge = TextStyle(
    fontSize: 28, fontWeight: FontWeight.w800,
    color: AppColors.textPrimary, letterSpacing: -0.5,
  );
  static const TextStyle displayMedium = TextStyle(
    fontSize: 22, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, letterSpacing: -0.3,
  );
  static const TextStyle titleLarge = TextStyle(
    fontSize: 18, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );
  static const TextStyle titleMedium = TextStyle(
    fontSize: 15, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 15, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 13, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w400,
    color: AppColors.textHint,
  );
  static const TextStyle labelBold = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w700,
    color: AppColors.textSecondary, letterSpacing: 0.5,
  );
  static const TextStyle buttonText = TextStyle(
    fontSize: 15, fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );
}

class AppTheme {
  AppTheme._();

  // ── Input Decoration ─────────────────────────────
  static InputDecoration inputDecoration(String label, {IconData? icon, Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      labelStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
      prefixIcon: icon != null
          ? Icon(icon, size: 20, color: AppColors.textHint)
          : null,
      suffixIcon: suffix,
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 1.8),
      ),
    );
  }

  // ── Primary Button ────────────────────────────────
  static ButtonStyle primaryButtonStyle({double radius = 12}) {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
      textStyle: AppTextStyles.buttonText,
    );
  }

  // ── Danger Button ─────────────────────────────────
  static ButtonStyle dangerButtonStyle({double radius = 10}) {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.error,
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
      textStyle: AppTextStyles.buttonText,
    );
  }

  // ── Card Decoration ───────────────────────────────
  static BoxDecoration cardDecoration({double radius = 16}) {
    return BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppColors.border),
      boxShadow: const [
        BoxShadow(
          color: AppColors.cardShadow,
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    );
  }

  // ── Role Badge ────────────────────────────────────
  static Widget roleBadge(String role) {
    Color bg, fg;
    IconData icon;
    switch (role.toUpperCase()) {
      case 'ADMIN':
        bg = const Color(0xFFF3E8FF); fg = const Color(0xFF7C3AED);
        icon = Icons.shield_rounded;
        break;
      case 'MANAGER':
        bg = const Color(0xFFFFF7ED); fg = const Color(0xFFEA580C);
        icon = Icons.manage_accounts_rounded;
        break;
      default:
        bg = AppColors.primaryLight; fg = AppColors.primary;
        icon = Icons.person_rounded;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            role.toUpperCase(),
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
          ),
        ],
      ),
    );
  }

  // ── Loading Button Child ──────────────────────────
  static Widget loadingIndicator() {
    return const SizedBox(
      height: 20, width: 20,
      child: CircularProgressIndicator(
        color: Colors.white, strokeWidth: 2.5,
      ),
    );
  }

  // ── SnackBar Helper ───────────────────────────────
  static void showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(isError ? Icons.error_outline : Icons.check_circle_outline,
            color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(message)),
      ]),
      backgroundColor: isError ? AppColors.error : AppColors.success,
    ));
  }

  // ── MaterialApp ThemeData ─────────────────────────
  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        surface: AppColors.surface,
      ),
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: AppColors.border,
        titleTextStyle: AppTextStyles.titleLarge,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.textSecondary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primaryLight,
        labelTextStyle: WidgetStateProperty.all(AppTextStyles.bodySmall),
        elevation: 0,
        shadowColor: AppColors.border,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
