import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ============================================================================
// FitPro Theme System
// Light: "Kinetic High-Contrast Editorial" — Volt-accented, high-energy white
// Dark:  "High-Performance Editorial"      — Deep sanctuary, neon-glow dark
//
// Both themes use Plus Jakarta Sans exclusively for typographic consistency.
// ============================================================================

class AppTheme {
  AppTheme._();

  // ─────────────────────────────────────────────────────────────────────────
  // LIGHT THEME COLORS — "The Neon Pulse"
  // ─────────────────────────────────────────────────────────────────────────
  static const _lightPrimary = Color(0xFF546200);
  static const _lightOnPrimary = Color(0xFFFFFFFF);
  static const _lightPrimaryContainer = Color(0xFFDAF900); // "Volt" engine
  static const _lightOnPrimaryContainer = Color(0xFF505D00);
  static const _lightPrimaryFixed = Color(0xFFD2E74D);
  static const _lightPrimaryFixedDim = Color(0xFFA8BF00);

  static const _lightSecondary = Color(0xFF5C6146);
  static const _lightOnSecondary = Color(0xFFFFFFFF);
  static const _lightSecondaryContainer = Color(0xFFE1E6C4);
  static const _lightOnSecondaryContainer = Color(0xFF494E34);

  static const _lightTertiary = Color(0xFF3A665D);
  static const _lightOnTertiary = Color(0xFFFFFFFF);
  static const _lightTertiaryContainer = Color(0xFFBCECE1);
  static const _lightOnTertiaryContainer = Color(0xFF205048);

  static const _lightError = Color(0xFFBA1A1A);
  static const _lightOnError = Color(0xFFFFFFFF);
  static const _lightErrorContainer = Color(0xFFFFDAD6);
  static const _lightOnErrorContainer = Color(0xFF93000A);

  static const _lightSurface = Color(0xFFF5F6F7);
  static const _lightOnSurface = Color(0xFF2C2F30);
  static const _lightOnSurfaceVariant = Color(0xFF595C5D);
  static const _lightSurfaceContainerLowest = Color(0xFFFFFFFF);
  static const _lightSurfaceContainerLow = Color(0xFFEFF1F2);
  static const _lightSurfaceContainer = Color(0xFFE9EBEC);
  static const _lightSurfaceContainerHigh = Color(0xFFE3E5E6);
  static const _lightSurfaceContainerHighest = Color(0xFFDDDFE0);
  static const _lightSurfaceBright = Color(0xFFF9FAFA);
  static const _lightSurfaceTint = Color(0xFF546200);

  static const _lightOutline = Color(0xFF787C7D);
  static const _lightOutlineVariant = Color(0xFFC7CBCC);
  static const _lightInverseSurface = Color(0xFF2F3132);
  static const _lightOnInverseSurface = Color(0xFFF0F1F2);
  static const _lightInversePrimary = Color(0xFFB8D400);
  static const _lightScrim = Color(0xFF000000);
  static const _lightShadow = Color(0xFF000000);

  // ─────────────────────────────────────────────────────────────────────────
  // DARK THEME COLORS — "The Kinetic Sanctuary"
  // ─────────────────────────────────────────────────────────────────────────
  static const _darkPrimary = Color(0xFF4CD6FB); // Electric Momentum
  static const _darkOnPrimary = Color(0xFF003642);
  static const _darkPrimaryContainer = Color(0xFF00B4D8);
  static const _darkOnPrimaryContainer = Color(0xFFD0EFFF);
  static const _darkPrimaryFixed = Color(0xFF4CD6FB);
  static const _darkPrimaryFixedDim = Color(0xFF29C6F0);

  static const _darkSecondary = Color(0xFF72DD80); // Vitality
  static const _darkOnSecondary = Color(0xFF003A0E);
  static const _darkSecondaryContainer = Color(0xFF008131);
  static const _darkOnSecondaryContainer = Color(0xFFBAFFCB);

  static const _darkTertiary = Color(0xFFFFB59D); // The Spark
  static const _darkOnTertiary = Color(0xFF4E1C00);
  static const _darkTertiaryContainer = Color(0xFFFF8155);
  static const _darkOnTertiaryContainer = Color(0xFFFFE0D4);

  static const _darkError = Color(0xFFFFB4AB);
  static const _darkOnError = Color(0xFF690005);
  static const _darkErrorContainer = Color(0xFF93000A);
  static const _darkOnErrorContainer = Color(0xFFFFDAD6);

  static const _darkSurface = Color(0xFF0E1225); // The Void
  static const _darkOnSurface = Color(0xFFDEE1FC);
  static const _darkOnSurfaceVariant = Color(0xFFBCC9CE);
  static const _darkSurfaceContainerLowest = Color(0xFF090D20);
  static const _darkSurfaceContainerLow = Color(0xFF141830);
  static const _darkSurfaceContainer = Color(0xFF1B1E32);
  static const _darkSurfaceContainerHigh = Color(0xFF252840);
  static const _darkSurfaceContainerHighest = Color(0xFF303448);
  static const _darkSurfaceBright = Color(0xFF34384D);
  static const _darkSurfaceTint = Color(0xFF4CD6FB);

  static const _darkOutline = Color(0xFF546268);
  static const _darkOutlineVariant = Color(0xFF3D494D);
  static const _darkInverseSurface = Color(0xFFDEE1FC);
  static const _darkOnInverseSurface = Color(0xFF1B1E32);
  static const _darkInversePrimary = Color(0xFF006C84);
  static const _darkScrim = Color(0xFF000000);
  static const _darkShadow = Color(0xFF000000);

  // ─────────────────────────────────────────────────────────────────────────
  // TYPOGRAPHY — Plus Jakarta Sans (shared by both themes)
  //
  // Display: "Big Number" moments — Extra Bold, tight tracking
  // Headline/Title: Screen titles — tight line-height
  // Body: Workhorse text
  // Label: Tags — UPPERCASE feel, wide tracking
  // ─────────────────────────────────────────────────────────────────────────
  static TextTheme _buildTextTheme(Color onSurface, Color onSurfaceVariant) {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme();

    return baseTextTheme.copyWith(
      // Display — punchy editorial headers, big numbers
      displayLarge: GoogleFonts.plusJakartaSans(
        fontSize: 56,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.02 * 56,
        height: 1.1,
        color: onSurface,
      ),
      displayMedium: GoogleFonts.plusJakartaSans(
        fontSize: 44,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.02 * 44,
        height: 1.1,
        color: onSurface,
      ),
      displaySmall: GoogleFonts.plusJakartaSans(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.02 * 36,
        height: 1.1,
        color: onSurface,
      ),

      // Headline — screen titles, editorial anchors
      headlineLarge: GoogleFonts.plusJakartaSans(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.01 * 32,
        height: 1.1,
        color: onSurface,
      ),
      headlineMedium: GoogleFonts.plusJakartaSans(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.01 * 28,
        height: 1.1,
        color: onSurface,
      ),
      headlineSmall: GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        height: 1.15,
        color: onSurface,
      ),

      // Title — card headers, section labels
      titleLarge: GoogleFonts.plusJakartaSans(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.2,
        color: onSurface,
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        height: 1.25,
        color: onSurface,
      ),
      titleSmall: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.3,
        color: onSurface,
      ),

      // Body — workhorse text
      bodyLarge: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.15,
        height: 1.5,
        color: onSurface,
      ),
      bodyMedium: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        height: 1.45,
        color: onSurfaceVariant,
      ),
      bodySmall: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        height: 1.4,
        color: onSurfaceVariant,
      ),

      // Label — tags, metadata; uppercase-ready, wide tracking
      labelLarge: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.05 * 14,
        height: 1.3,
        color: onSurface,
      ),
      labelMedium: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.05 * 12,
        height: 1.3,
        color: onSurfaceVariant,
      ),
      labelSmall: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.05 * 11,
        height: 1.25,
        color: onSurfaceVariant,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // LIGHT THEME
  // ─────────────────────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: _lightPrimary,
      onPrimary: _lightOnPrimary,
      primaryContainer: _lightPrimaryContainer,
      onPrimaryContainer: _lightOnPrimaryContainer,
      primaryFixed: _lightPrimaryFixed,
      primaryFixedDim: _lightPrimaryFixedDim,
      secondary: _lightSecondary,
      onSecondary: _lightOnSecondary,
      secondaryContainer: _lightSecondaryContainer,
      onSecondaryContainer: _lightOnSecondaryContainer,
      tertiary: _lightTertiary,
      onTertiary: _lightOnTertiary,
      tertiaryContainer: _lightTertiaryContainer,
      onTertiaryContainer: _lightOnTertiaryContainer,
      error: _lightError,
      onError: _lightOnError,
      errorContainer: _lightErrorContainer,
      onErrorContainer: _lightOnErrorContainer,
      surface: _lightSurface,
      onSurface: _lightOnSurface,
      onSurfaceVariant: _lightOnSurfaceVariant,
      surfaceContainerLowest: _lightSurfaceContainerLowest,
      surfaceContainerLow: _lightSurfaceContainerLow,
      surfaceContainer: _lightSurfaceContainer,
      surfaceContainerHigh: _lightSurfaceContainerHigh,
      surfaceContainerHighest: _lightSurfaceContainerHighest,
      surfaceBright: _lightSurfaceBright,
      surfaceTint: _lightSurfaceTint,
      outline: _lightOutline,
      outlineVariant: _lightOutlineVariant,
      inverseSurface: _lightInverseSurface,
      onInverseSurface: _lightOnInverseSurface,
      inversePrimary: _lightInversePrimary,
      scrim: _lightScrim,
      shadow: _lightShadow,
    );

    final textTheme = _buildTextTheme(_lightOnSurface, _lightOnSurfaceVariant);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: _lightSurface,

      // ── AppBar ────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: _lightSurface,
        foregroundColor: _lightOnSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: _lightOnSurface,
        ),
        iconTheme: const IconThemeData(color: _lightOnSurface),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),

      // ── Bottom Navigation ─────────────────────────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: _lightSurfaceContainerLowest,
        selectedItemColor: _lightPrimary,
        unselectedItemColor: _lightOnSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: _lightPrimary,
        ),
        unselectedLabelStyle: textTheme.labelSmall?.copyWith(
          color: _lightOnSurfaceVariant,
        ),
      ),

      // ── Navigation Bar (Material 3) ──────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _lightSurfaceContainerLowest,
        indicatorColor: _lightPrimaryContainer,
        labelTextStyle: WidgetStatePropertyAll(
          textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: _lightOnPrimaryContainer);
          }
          return const IconThemeData(color: _lightOnSurfaceVariant);
        }),
        elevation: 0,
        height: 72,
      ),

      // ── Cards — Radii: 20px (xl), no border ──────────────────────────
      cardTheme: CardThemeData(
        color: _lightSurfaceContainerLowest,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8),
      ),

      // ── Elevated Button (Primary) — Radii: 12px (md) ─────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _lightPrimaryContainer,
          foregroundColor: _lightOnPrimaryContainer,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // ── Filled Button ─────────────────────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _lightPrimaryContainer,
          foregroundColor: _lightOnPrimaryContainer,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // ── Outlined Button (Secondary) ───────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _lightOnSurface,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          side: BorderSide(color: _lightOutlineVariant.withValues(alpha: 0.15)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),

      // ── Text Button (Tertiary) ────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _lightPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // ── Floating Action Button ────────────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _lightPrimaryContainer,
        foregroundColor: _lightOnPrimaryContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // ── Input Fields ──────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _lightSurfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _lightPrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _lightError, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _lightError, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: _lightOnSurfaceVariant.withValues(alpha: 0.6),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: _lightOnSurfaceVariant,
        ),
      ),

      // ── Chips ─────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: _lightSurfaceContainerLow,
        selectedColor: _lightPrimaryContainer,
        labelStyle: textTheme.labelMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),

      // ── Divider — "No-Line Rule" fallback ─────────────────────────────
      dividerTheme: DividerThemeData(
        color: _lightOutlineVariant.withValues(alpha: 0.15),
        thickness: 1,
        space: 24,
      ),

      // ── Bottom Sheet ──────────────────────────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: _lightSurfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        showDragHandle: true,
        dragHandleColor: _lightOutlineVariant,
      ),

      // ── Dialog ────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: _lightSurfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        titleTextStyle: textTheme.headlineSmall,
        contentTextStyle: textTheme.bodyMedium,
      ),

      // ── Snack Bar ─────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _lightInverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: _lightOnInverseSurface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),

      // ── Tab Bar ───────────────────────────────────────────────────────
      tabBarTheme: TabBarThemeData(
        labelColor: _lightPrimary,
        unselectedLabelColor: _lightOnSurfaceVariant,
        labelStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle: textTheme.labelLarge,
        indicator: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: _lightPrimary, width: 2),
          ),
        ),
      ),

      // ── Switch / Checkbox / Radio ─────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _lightOnPrimaryContainer;
          }
          return _lightOutline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _lightPrimaryContainer;
          }
          return _lightSurfaceContainerHigh;
        }),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _lightPrimary;
          }
          return Colors.transparent;
        }),
        checkColor: const WidgetStatePropertyAll(_lightOnPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      // ── Progress Indicator (Neon Stroke) ──────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: _lightPrimaryContainer,
        linearTrackColor: _lightSurfaceContainerHigh,
        circularTrackColor: _lightSurfaceContainerHigh,
      ),

      // ── Icon ──────────────────────────────────────────────────────────
      iconTheme: const IconThemeData(
        color: _lightOnSurface,
        size: 24,
      ),

      // ── List Tile ─────────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        titleTextStyle: textTheme.titleSmall,
        subtitleTextStyle: textTheme.bodySmall,
        iconColor: _lightOnSurfaceVariant,
      ),

      // ── Popup Menu ────────────────────────────────────────────────────
      popupMenuTheme: PopupMenuThemeData(
        color: _lightSurfaceContainerLowest,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: textTheme.bodyMedium,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DARK THEME
  // ─────────────────────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: _darkPrimary,
      onPrimary: _darkOnPrimary,
      primaryContainer: _darkPrimaryContainer,
      onPrimaryContainer: _darkOnPrimaryContainer,
      primaryFixed: _darkPrimaryFixed,
      primaryFixedDim: _darkPrimaryFixedDim,
      secondary: _darkSecondary,
      onSecondary: _darkOnSecondary,
      secondaryContainer: _darkSecondaryContainer,
      onSecondaryContainer: _darkOnSecondaryContainer,
      tertiary: _darkTertiary,
      onTertiary: _darkOnTertiary,
      tertiaryContainer: _darkTertiaryContainer,
      onTertiaryContainer: _darkOnTertiaryContainer,
      error: _darkError,
      onError: _darkOnError,
      errorContainer: _darkErrorContainer,
      onErrorContainer: _darkOnErrorContainer,
      surface: _darkSurface,
      onSurface: _darkOnSurface,
      onSurfaceVariant: _darkOnSurfaceVariant,
      surfaceContainerLowest: _darkSurfaceContainerLowest,
      surfaceContainerLow: _darkSurfaceContainerLow,
      surfaceContainer: _darkSurfaceContainer,
      surfaceContainerHigh: _darkSurfaceContainerHigh,
      surfaceContainerHighest: _darkSurfaceContainerHighest,
      surfaceBright: _darkSurfaceBright,
      surfaceTint: _darkSurfaceTint,
      outline: _darkOutline,
      outlineVariant: _darkOutlineVariant,
      inverseSurface: _darkInverseSurface,
      onInverseSurface: _darkOnInverseSurface,
      inversePrimary: _darkInversePrimary,
      scrim: _darkScrim,
      shadow: _darkShadow,
    );

    final textTheme = _buildTextTheme(_darkOnSurface, _darkOnSurfaceVariant);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: _darkSurface,

      // ── AppBar ────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: _darkSurface,
        foregroundColor: _darkOnSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: _darkOnSurface,
        ),
        iconTheme: const IconThemeData(color: _darkOnSurface),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),

      // ── Bottom Navigation ─────────────────────────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: _darkSurfaceContainer,
        selectedItemColor: _darkPrimary,
        unselectedItemColor: _darkOnSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: _darkPrimary,
        ),
        unselectedLabelStyle: textTheme.labelSmall?.copyWith(
          color: _darkOnSurfaceVariant,
        ),
      ),

      // ── Navigation Bar (Material 3) ──────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _darkSurfaceContainer,
        indicatorColor: _darkPrimaryContainer.withValues(alpha: 0.3),
        labelTextStyle: WidgetStatePropertyAll(
          textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: _darkPrimary);
          }
          return const IconThemeData(color: _darkOnSurfaceVariant);
        }),
        elevation: 0,
        height: 72,
      ),

      // ── Cards — Radii: 20px (xl), no border ──────────────────────────
      cardTheme: CardThemeData(
        color: _darkSurfaceContainer,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8),
      ),

      // ── Elevated Button (Primary) — Gradient + 12px radii ────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _darkPrimaryContainer,
          foregroundColor: _darkOnPrimary,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // ── Filled Button ─────────────────────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _darkPrimaryContainer,
          foregroundColor: _darkOnPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // ── Outlined Button (Secondary — glassmorphic style) ──────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _darkOnSurface,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          side: BorderSide(color: _darkPrimary.withValues(alpha: 0.4)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),

      // ── Text Button (Tertiary) ────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _darkPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // ── Floating Action Button ────────────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _darkPrimaryContainer,
        foregroundColor: _darkOnPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // ── Input Fields ──────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkSurfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _darkPrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _darkError, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _darkError, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: _darkOnSurfaceVariant.withValues(alpha: 0.5),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: _darkOnSurfaceVariant,
        ),
      ),

      // ── Chips ─────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: _darkSurfaceContainerHigh,
        selectedColor: _darkPrimaryContainer.withValues(alpha: 0.3),
        labelStyle: textTheme.labelMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),

      // ── Divider ───────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: _darkOutlineVariant.withValues(alpha: 0.15),
        thickness: 1,
        space: 24,
      ),

      // ── Bottom Sheet (Performance Sheet) ──────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: _darkSurfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        showDragHandle: true,
        dragHandleColor: _darkOutlineVariant,
      ),

      // ── Dialog ────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: _darkSurfaceContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        titleTextStyle: textTheme.headlineSmall,
        contentTextStyle: textTheme.bodyMedium,
      ),

      // ── Snack Bar ─────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _darkInverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: _darkOnInverseSurface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),

      // ── Tab Bar ───────────────────────────────────────────────────────
      tabBarTheme: TabBarThemeData(
        labelColor: _darkPrimary,
        unselectedLabelColor: _darkOnSurfaceVariant,
        labelStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle: textTheme.labelLarge,
        indicator: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: _darkPrimary, width: 2),
          ),
        ),
      ),

      // ── Switch ────────────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _darkOnPrimary;
          }
          return _darkOutline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _darkPrimaryContainer;
          }
          return _darkSurfaceContainerHigh;
        }),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _darkPrimary;
          }
          return Colors.transparent;
        }),
        checkColor: const WidgetStatePropertyAll(_darkOnPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      // ── Progress Indicator ────────────────────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: _darkPrimary,
        linearTrackColor: _darkSurfaceContainerHighest,
        circularTrackColor: _darkSurfaceContainerHighest,
      ),

      // ── Icon ──────────────────────────────────────────────────────────
      iconTheme: const IconThemeData(
        color: _darkOnSurface,
        size: 24,
      ),

      // ── List Tile ─────────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        titleTextStyle: textTheme.titleSmall,
        subtitleTextStyle: textTheme.bodySmall,
        iconColor: _darkOnSurfaceVariant,
      ),

      // ── Popup Menu ────────────────────────────────────────────────────
      popupMenuTheme: PopupMenuThemeData(
        color: _darkSurfaceContainerHigh,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: textTheme.bodyMedium,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DECORATIONS & UTILITIES
  // ─────────────────────────────────────────────────────────────────────────

  /// Ambient shadow mimicking natural studio lighting (light mode).
  static List<BoxShadow> get ambientShadowLight => [
        BoxShadow(
          color: _lightOnSurface.withValues(alpha: 0.06),
          blurRadius: 40,
          spreadRadius: -10,
          offset: const Offset(0, 12),
        ),
      ];

  /// Ambient glow shadow for dark mode — tinted with primary.
  static List<BoxShadow> get ambientShadowDark => [
        BoxShadow(
          color: _darkSurfaceTint.withValues(alpha: 0.10),
          blurRadius: 24,
          spreadRadius: -4,
          offset: const Offset(0, 8),
        ),
      ];

  /// Returns the appropriate ambient shadow based on brightness.
  static List<BoxShadow> ambientShadow(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? ambientShadowDark
        : ambientShadowLight;
  }

  /// Ghost border for accessibility fallback (15% opacity outline-variant).
  static Border ghostBorder(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Border.all(
      color: scheme.outlineVariant.withValues(alpha: 0.15),
      width: 1,
    );
  }

  /// Glassmorphism decoration for floating nav / overlays.
  static BoxDecoration glassmorphism(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    return BoxDecoration(
      color: (isDark ? scheme.surfaceContainerLow : scheme.surfaceContainerLow)
          .withValues(alpha: 0.80),
      borderRadius: BorderRadius.circular(20),
      border: isDark
          ? Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1,
            )
          : null,
    );
    // NOTE: Apply BackdropFilter + ImageFilter.blur(sigmaX: 20, sigmaY: 20)
    // as a parent ClipRRect → BackdropFilter in the widget tree.
  }

  /// Signature gradient for primary action buttons.
  /// Light: primaryContainer → primaryFixedDim
  /// Dark:  primary (#00B4D8) → secondary (#92FE9D)
  static LinearGradient primaryGradient(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF00B4D8), Color(0xFF92FE9D)],
      );
    }
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [_lightPrimaryContainer, _lightPrimaryFixedDim],
    );
  }

  /// Dark-mode-only: soft radial glow behind charts/important data.
  static BoxDecoration primaryGlow({double radius = 200}) {
    return BoxDecoration(
      gradient: RadialGradient(
        colors: [
          _darkPrimaryFixedDim.withValues(alpha: 0.12),
          Colors.transparent,
        ],
        radius: radius / 100,
      ),
    );
  }
}
