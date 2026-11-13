import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────────────────────────
//  HR System — Material Design 3 Design System
//  Single source of truth for all UI tokens & theme components
// ─────────────────────────────────────────────────────────────────

// ── Color Tokens ──────────────────────────────────────────────────
class AppColors {
  AppColors._();

  // Brand — Blue 600 seed
  static const Color primary      = Color(0xFF1D6AE5);
  static const Color primaryDark  = Color(0xFF1354BF);
  static const Color primaryLight = Color(0xFFEBF2FF);
  static const Color onPrimary    = Colors.white;

  // Secondary — Violet accent
  static const Color secondary    = Color(0xFF7C3AED);
  static const Color secondaryBg  = Color(0xFFF3E8FF);

  // Semantic
  static const Color success      = Color(0xFF16A34A);
  static const Color successLight = Color(0xFFF0FDF4);
  static const Color error        = Color(0xFFDC2626);
  static const Color errorLight   = Color(0xFFFEF2F2);
  static const Color warning      = Color(0xFFD97706);
  static const Color warningLight = Color(0xFFFFFBEB);
  static const Color info         = Color(0xFF0284C7);
  static const Color infoLight    = Color(0xFFE0F2FE);

  // Neutrals — Slate scale
  static const Color textPrimary   = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textHint      = Color(0xFF94A3B8);
  static const Color border        = Color(0xFFE2E8F0);
  static const Color divider       = Color(0xFFF1F5F9);
  static const Color surface       = Color(0xFFFFFFFF);
  static const Color surfaceVar    = Color(0xFFF8FAFC);
  static const Color background    = Color(0xFFF1F5F9);
  static const Color cardShadow    = Color(0x0D000000);

  // Nav drawer active tint
  static const Color drawerActive  = Color(0xFFEBF2FF);
}

// ── Typography Tokens ─────────────────────────────────────────────
class AppTextStyles {
  AppTextStyles._();

  static const TextStyle displayLarge = TextStyle(
    fontSize: 30, fontWeight: FontWeight.w800,
    color: AppColors.textPrimary, letterSpacing: -0.5, height: 1.2,
  );
  static const TextStyle displayMedium = TextStyle(
    fontSize: 24, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, letterSpacing: -0.3, height: 1.25,
  );
  static const TextStyle displaySmall = TextStyle(
    fontSize: 20, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, letterSpacing: -0.2, height: 1.3,
  );
  static const TextStyle titleLarge = TextStyle(
    fontSize: 18, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, height: 1.4,
  );
  static const TextStyle titleMedium = TextStyle(
    fontSize: 15, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary, height: 1.4,
  );
  static const TextStyle titleSmall = TextStyle(
    fontSize: 13, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary, height: 1.4,
  );
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 15, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary, height: 1.5,
  );
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 13, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary, height: 1.5,
  );
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w400,
    color: AppColors.textHint, height: 1.4,
  );
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w600,
    color: AppColors.textSecondary, letterSpacing: 0.1,
  );
  static const TextStyle labelMedium = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w600,
    color: AppColors.textSecondary, letterSpacing: 0.5,
  );
  static const TextStyle labelBold = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w700,
    color: AppColors.textSecondary, letterSpacing: 0.8,
  );
  static const TextStyle buttonText = TextStyle(
    fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.2,
  );
  static const TextStyle captionText = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w500,
    color: AppColors.textHint, letterSpacing: 0.2,
  );
}

// ── Theme Builder ─────────────────────────────────────────────────
class AppTheme {
  AppTheme._();

  // ── Convenience color getters (used by feature screens) ───────
  static Color get primaryColor => AppColors.primary;
  static Color get bgColor      => AppColors.background;

  // ── Material 3 ThemeData ──────────────────────────────────────
  static ThemeData get themeData {
    final cs = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primaryLight,
      onPrimaryContainer: AppColors.primaryDark,
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.secondaryBg,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.surfaceVar,
      error: AppColors.error,
      onError: Colors.white,
      outline: AppColors.border,
      outlineVariant: AppColors.divider,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: AppColors.background,

      // ── Typography ───────────────────────────────────────────
      textTheme: const TextTheme(
        displayLarge:  TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.5),
        displayMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.3),
        displaySmall:  TextStyle(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.2),
        headlineLarge:  TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        headlineMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        headlineSmall:  TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        titleLarge:  TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        titleSmall:  TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        bodyLarge:   TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
        bodyMedium:  TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
        bodySmall:   TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textHint),
        labelLarge:  TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5),
        labelSmall:  TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8),
      ),

      // ── AppBar ───────────────────────────────────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 2,
        shadowColor: AppColors.cardShadow,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: AppTextStyles.titleLarge,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.textSecondary, size: 22),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),

      // ── Bottom NavigationBar ─────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: AppColors.cardShadow,
        elevation: 8,
        height: 68,
        indicatorColor: AppColors.primaryLight,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.primary : AppColors.textHint,
            letterSpacing: 0.2,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 22,
            color: selected ? AppColors.primary : AppColors.textHint,
          );
        }),
      ),

      // ── Navigation Drawer ─────────────────────────────────────
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 16,
        shadowColor: AppColors.cardShadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
        ),
      ),

      // ── Card ─────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),

      // ── Elevated Button ───────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: AppTextStyles.buttonText,
        ),
      ),

      // ── Outlined Button ───────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: AppTextStyles.buttonText,
        ),
      ),

      // ── Text Button ───────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTextStyles.labelLarge,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      // ── FAB ───────────────────────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        extendedTextStyle: AppTextStyles.buttonText,
      ),

      // ── Input ─────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        labelStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
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
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
      ),

      // ── Chip ─────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVar,
        selectedColor: AppColors.primaryLight,
        labelStyle: AppTextStyles.labelMedium,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        checkmarkColor: AppColors.primary,
      ),

      // ── List Tile ─────────────────────────────────────────────
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        minLeadingWidth: 0,
        iconColor: AppColors.textHint,
        titleTextStyle: AppTextStyles.titleMedium,
        subtitleTextStyle: AppTextStyles.bodySmall,
      ),

      // ── Divider ───────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 0,
      ),

      // ── Dialog ────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 24,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: AppTextStyles.titleLarge,
        contentTextStyle: AppTextStyles.bodyMedium,
      ),

      // ── SnackBar ──────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),

      // ── Bottom Sheet ──────────────────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        showDragHandle: true,
        dragHandleColor: AppColors.border,
      ),

      // ── Progress Indicator ────────────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),
    );
  }

  // ── Input Decoration Helper ───────────────────────────────────
  static InputDecoration inputDecoration(
    String label, {
    IconData? icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
      prefixIcon: icon != null
          ? Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Icon(icon, size: 20, color: AppColors.textHint),
            )
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
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
    );
  }

  // ── Button Styles ─────────────────────────────────────────────
  static ButtonStyle primaryButtonStyle({double radius = 12}) {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      shadowColor: Colors.transparent,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
      textStyle: AppTextStyles.buttonText,
    );
  }

  static ButtonStyle dangerButtonStyle({double radius = 10}) {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.error,
      foregroundColor: Colors.white,
      elevation: 0,
      shadowColor: Colors.transparent,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
      textStyle: AppTextStyles.buttonText,
    );
  }

  // ── Card Decoration ───────────────────────────────────────────
  static BoxDecoration cardDecoration({double radius = 16}) {
    return BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppColors.border),
      boxShadow: const [
        BoxShadow(
          color: AppColors.cardShadow,
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
    );
  }

  // ── Stat Card Decoration ──────────────────────────────────────
  static BoxDecoration statCardDecoration(Color color) {
    return BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withValues(alpha: 0.15)),
      boxShadow: [
        BoxShadow(
          color: color.withValues(alpha: 0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  // ── Role Badge ────────────────────────────────────────────────
  static Widget roleBadge(String role) {
    Color bg, fg;
    IconData icon;
    switch (role.toUpperCase()) {
      case 'ADMIN':
        bg = const Color(0xFFF3E8FF); fg = const Color(0xFF7C3AED);
        icon = Icons.shield_rounded;
      case 'MANAGER':
        bg = const Color(0xFFFFF7ED); fg = const Color(0xFFEA580C);
        icon = Icons.manage_accounts_rounded;
      default:
        bg = AppColors.primaryLight; fg = AppColors.primary;
        icon = Icons.person_rounded;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
            style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: fg,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  // ── Status Badge ──────────────────────────────────────────────
  static Widget statusBadge(String status, {Color? color, Color? bg}) {
    final resolvedColor = color ?? _statusColor(status);
    final resolvedBg = bg ?? resolvedColor.withValues(alpha: 0.1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: resolvedBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w700,
          color: resolvedColor, letterSpacing: 0.3,
        ),
      ),
    );
  }

  static Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED': case 'PAID': case 'PRESENT': return AppColors.success;
      case 'REJECTED': case 'CANCELLED': case 'ABSENT': return AppColors.error;
      case 'PENDING': case 'LATE': return AppColors.warning;
      default: return AppColors.textHint;
    }
  }

  // ── Section Header ────────────────────────────────────────────
  static Widget sectionHeader(String title, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: AppTextStyles.labelBold.copyWith(
                color: AppColors.textHint, letterSpacing: 1,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }

  // ── Loading Indicator ─────────────────────────────────────────
  static Widget loadingIndicator({Color color = Colors.white}) {
    return SizedBox(
      height: 20, width: 20,
      child: CircularProgressIndicator(color: color, strokeWidth: 2.5),
    );
  }

  // ── SnackBar Helper ───────────────────────────────────────────
  static void showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
    bool isWarning = false,
  }) {
    Color bg = isError
        ? AppColors.error
        : isWarning
            ? AppColors.warning
            : AppColors.success;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(
          isError
              ? Icons.error_outline
              : isWarning
                  ? Icons.warning_amber_rounded
                  : Icons.check_circle_outline,
          color: Colors.white,
          size: 18,
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(message)),
      ]),
      backgroundColor: bg,
    ));
  }

  // ── Empty State ───────────────────────────────────────────────
  static Widget emptyState({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.primaryLight, shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(title, style: AppTextStyles.titleMedium, textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle, style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
            ],
            if (action != null) ...[
              const SizedBox(height: 20),
              action,
            ],
          ],
        ),
      ),
    );
  }

  // ── Error State ───────────────────────────────────────────────
  static Widget errorState({
    required String message,
    required VoidCallback onRetry,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.errorLight, shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wifi_off_rounded,
                  size: 40, color: AppColors.error),
            ),
            const SizedBox(height: 16),
            Text(message,
                style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: primaryButtonStyle(radius: 10),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
