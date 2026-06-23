import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Premium color palette ──
  static const Color _primaryDark = Color(0xFF0D3B7A);
  static const Color _primary = Color(0xFF1565C0);
  // static const Color _primaryLight = Color(0xFF42A5F5); // RIMOSSO: inutilizzato
  static const Color _accent = Color(0xFF00897B); // teal accent
  static const Color _surface = Color(0xFFF8FAFD);
  static const Color _surfaceCard = Colors.white;
  static const Color _onSurface = Color(0xFF1A2138);
  static const Color _onSurfaceMuted = Color(0xFF5F6785);

  static ThemeData of({bool seniorMode = false, bool darkMode = false}) {
    return darkMode
        ? _buildDarkTheme(seniorMode: seniorMode)
        : _buildLightTheme(seniorMode: seniorMode);
  }

  static ThemeData _buildLightTheme({bool seniorMode = false}) {
    final base = ThemeData.light(useMaterial3: true);
    var textTheme = GoogleFonts.interTextTheme(base.textTheme).copyWith(
      displayLarge: GoogleFonts.inter(
          fontSize: 57,
          fontWeight: FontWeight.w800,
          color: _onSurface,
          letterSpacing: -1.5),
      displayMedium: GoogleFonts.inter(
          fontSize: 45,
          fontWeight: FontWeight.w700,
          color: _onSurface,
          letterSpacing: -0.5),
      displaySmall: GoogleFonts.inter(
          fontSize: 36, fontWeight: FontWeight.w700, color: _onSurface),
      headlineLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: _onSurface,
          letterSpacing: -0.3),
      headlineMedium: GoogleFonts.inter(
          fontSize: 28, fontWeight: FontWeight.w600, color: _onSurface),
      headlineSmall: GoogleFonts.inter(
          fontSize: 24, fontWeight: FontWeight.w600, color: _onSurface),
      titleLarge: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: _onSurface,
          letterSpacing: 0.15),
      titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: _onSurface,
          letterSpacing: 0.1),
      titleSmall: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w600, color: _onSurface),
      bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: _onSurface,
          height: 1.5),
      bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: _onSurface,
          height: 1.5),
      bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: _onSurfaceMuted,
          height: 1.4),
      labelLarge: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.5),
      labelMedium: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.4),
      labelSmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: _onSurfaceMuted,
          letterSpacing: 0.5),
    );
    if (seniorMode) {
      textTheme = _scaledTextTheme(textTheme, 1.25);
    }
    final colorScheme = ColorScheme.light(
      primary: _primary,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFD6E7FF),
      onPrimaryContainer: _primaryDark,
      secondary: _accent,
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFB2DFDB),
      onSecondaryContainer: const Color(0xFF004D40),
      tertiary: const Color(0xFF6D5CB4),
      surface: _surface,
      onSurface: _onSurface,
      onSurfaceVariant: _onSurfaceMuted,
      outline: const Color(0xFFD0D5E0),
      outlineVariant: const Color(0xFFE8ECF2),
      error: const Color(0xFFD32F2F),
      shadow: const Color(0x1A1A2138),
    );
    return base.copyWith(
      colorScheme: colorScheme,
      primaryColor: _primary,
      scaffoldBackgroundColor: _surface,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 2,
        centerTitle: false,
        backgroundColor: _primaryDark,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black26,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: GoogleFonts.inter(
          fontSize: seniorMode ? 22 : 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.3,
        ),
        iconTheme: const IconThemeData(color: Colors.white, size: 22),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: _surfaceCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.6)),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: seniorMode ? const Size(200, 56) : const Size(88, 50),
          elevation: 0,
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle:
              GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: seniorMode ? const Size(200, 56) : const Size(88, 50),
          foregroundColor: _primary,
          side: BorderSide(color: _primary.withOpacity(0.4)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle:
              GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _primary,
          textStyle:
              GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: _onSurfaceMuted,
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: _onSurfaceMuted.withOpacity(0.6),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.primaryContainer.withOpacity(0.3),
        labelStyle:
            GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
      ),
      dialogTheme: DialogThemeData(
        elevation: 6,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        backgroundColor: _onSurface,
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withOpacity(0.5),
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? _primary
                : Colors.grey[400]),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? _primary.withOpacity(0.3)
                : Colors.grey[300]),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: _primary,
        unselectedLabelColor: _onSurfaceMuted,
        indicatorColor: _primary,
        labelStyle:
            GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle:
            GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }

  static ThemeData _buildDarkTheme({bool seniorMode = false}) {
    final base = ThemeData.dark(useMaterial3: true);
    // Palette dark migliorata per contrasto
    const _darkBackground = Color(0xFF181C22); // più chiaro
    const _darkSurface = Color(0xFF23272F); // più chiaro
    const _darkSurfaceCard = Color(0xFF262B35); // card più chiara
    const _darkSurfaceElevated = Color(0xFF2D3340);
    const _darkOnSurface = Color(0xFFF5F7FA); // testo quasi bianco
    const _darkOnSurfaceMuted = Color(0xFFBFC7D5); // testo secondario
    const _darkPrimary = Color(0xFF5B9BF0);
    const _darkPrimaryContainer = Color(0xFF1A3A6E);
    const _darkAccent = Color(0xFF26C0A8);
    const _darkOutline = Color(0xFF3A4252);
    const _darkOutlineVariant = Color(0xFF2D3340);
    var textTheme = GoogleFonts.interTextTheme(base.textTheme).copyWith(
      displayLarge: GoogleFonts.inter(
          fontSize: 57,
          fontWeight: FontWeight.w800,
          color: _darkOnSurface,
          letterSpacing: -1.5),
      displayMedium: GoogleFonts.inter(
          fontSize: 45,
          fontWeight: FontWeight.w700,
          color: _darkOnSurface,
          letterSpacing: -0.5),
      displaySmall: GoogleFonts.inter(
          fontSize: 36, fontWeight: FontWeight.w700, color: _darkOnSurface),
      headlineLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: _darkOnSurface,
          letterSpacing: -0.3),
      headlineMedium: GoogleFonts.inter(
          fontSize: 28, fontWeight: FontWeight.w600, color: _darkOnSurface),
      headlineSmall: GoogleFonts.inter(
          fontSize: 24, fontWeight: FontWeight.w600, color: _darkOnSurface),
      titleLarge: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: _darkOnSurface,
          letterSpacing: 0.15),
      titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: _darkOnSurface,
          letterSpacing: 0.1),
      titleSmall: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w600, color: _darkOnSurface),
      bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: _darkOnSurface,
          height: 1.5),
      bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: _darkOnSurface,
          height: 1.5),
      bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: _darkOnSurfaceMuted,
          height: 1.4),
      labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: _darkOnSurface,
          letterSpacing: 0.5),
      labelMedium: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: _darkOnSurface,
          letterSpacing: 0.4),
      labelSmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: _darkOnSurfaceMuted,
          letterSpacing: 0.5),
    );
    if (seniorMode) textTheme = _scaledTextTheme(textTheme, 1.25);
    final colorScheme = ColorScheme.dark(
      primary: _darkPrimary,
      onPrimary: Color(0xFF0D2550),
      primaryContainer: _darkPrimaryContainer,
      onPrimaryContainer: Color(0xFFB8D4FF),
      secondary: _darkAccent,
      onSecondary: Color(0xFF003730),
      secondaryContainer: Color(0xFF004D40),
      onSecondaryContainer: Color(0xFF9EE0D4),
      tertiary: Color(0xFFBBAEF0),
      surface: _darkSurface,
      onSurface: _darkOnSurface,
      onSurfaceVariant: _darkOnSurfaceMuted,
      outline: _darkOutline,
      outlineVariant: _darkOutlineVariant,
      error: Color(0xFFEF5350),
      shadow: Color(0x33000000),
      surfaceContainerHighest: _darkSurfaceElevated,
    );
    return base.copyWith(
      colorScheme: colorScheme,
      primaryColor: _darkPrimary,
      scaffoldBackgroundColor: _darkBackground,
      cardColor: _darkSurfaceCard,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 2,
        centerTitle: false,
        backgroundColor: _darkPrimaryContainer,
        foregroundColor: _darkOnSurface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black26,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: GoogleFonts.inter(
          fontSize: seniorMode ? 22 : 18,
          fontWeight: FontWeight.w700,
          color: _darkOnSurface,
          letterSpacing: 0.3,
        ),
        iconTheme: const IconThemeData(color: Colors.white, size: 22),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: _darkSurfaceCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: _darkOutlineVariant.withOpacity(0.6)),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: seniorMode ? const Size(200, 56) : const Size(88, 50),
          elevation: 0,
          backgroundColor: _darkPrimary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle:
              GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: seniorMode ? const Size(200, 56) : const Size(88, 50),
          foregroundColor: _darkPrimary,
          side: BorderSide(color: _darkPrimary.withOpacity(0.4)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle:
              GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _darkPrimary,
          textStyle:
              GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkSurfaceCard,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _darkOutline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _darkOutlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _darkPrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: _darkOnSurfaceMuted,
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: _darkOnSurfaceMuted.withOpacity(0.7),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: _darkPrimary.withOpacity(0.15),
        labelStyle: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w500, color: _darkOnSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: _darkSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
      ),
      dialogTheme: DialogThemeData(
        elevation: 6,
        backgroundColor: _darkSurfaceCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: GoogleFonts.inter(
            fontSize: 18, fontWeight: FontWeight.w700, color: _darkOnSurface),
        contentTextStyle:
            GoogleFonts.inter(fontSize: 15, color: _darkOnSurface),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        backgroundColor: _darkOnSurface,
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: _darkSurface,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        surfaceTintColor: Colors.transparent,
        backgroundColor: _darkSurfaceCard,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: _darkOutlineVariant.withOpacity(0.5),
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        tileColor: _darkSurface,
        textColor: _darkOnSurface,
        iconColor: _darkOnSurfaceMuted,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? _darkPrimary
                : Colors.grey[600]),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? _darkPrimary.withOpacity(0.3)
                : Colors.grey[800]),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: _darkPrimary,
        unselectedLabelColor: _darkOnSurfaceMuted,
        indicatorColor: _darkPrimary,
        labelStyle:
            GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle:
            GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }

  /// Scale all text sizes by a factor (used for senior mode).
  static TextTheme _scaledTextTheme(TextTheme t, double factor) {
    return t.copyWith(
      displayLarge: t.displayLarge
          ?.copyWith(fontSize: (t.displayLarge?.fontSize ?? 57) * factor),
      displayMedium: t.displayMedium
          ?.copyWith(fontSize: (t.displayMedium?.fontSize ?? 45) * factor),
      displaySmall: t.displaySmall
          ?.copyWith(fontSize: (t.displaySmall?.fontSize ?? 36) * factor),
      headlineLarge: t.headlineLarge
          ?.copyWith(fontSize: (t.headlineLarge?.fontSize ?? 32) * factor),
      headlineMedium: t.headlineMedium
          ?.copyWith(fontSize: (t.headlineMedium?.fontSize ?? 28) * factor),
      headlineSmall: t.headlineSmall
          ?.copyWith(fontSize: (t.headlineSmall?.fontSize ?? 24) * factor),
      titleLarge: t.titleLarge
          ?.copyWith(fontSize: (t.titleLarge?.fontSize ?? 20) * factor),
      titleMedium: t.titleMedium
          ?.copyWith(fontSize: (t.titleMedium?.fontSize ?? 16) * factor),
      titleSmall: t.titleSmall
          ?.copyWith(fontSize: (t.titleSmall?.fontSize ?? 14) * factor),
      bodyLarge: t.bodyLarge
          ?.copyWith(fontSize: (t.bodyLarge?.fontSize ?? 16) * factor),
      bodyMedium: t.bodyMedium
          ?.copyWith(fontSize: (t.bodyMedium?.fontSize ?? 14) * factor),
      bodySmall: t.bodySmall
          ?.copyWith(fontSize: (t.bodySmall?.fontSize ?? 12) * factor),
      labelLarge: t.labelLarge
          ?.copyWith(fontSize: (t.labelLarge?.fontSize ?? 14) * factor),
      labelMedium: t.labelMedium
          ?.copyWith(fontSize: (t.labelMedium?.fontSize ?? 12) * factor),
      labelSmall: t.labelSmall
          ?.copyWith(fontSize: (t.labelSmall?.fontSize ?? 11) * factor),
    );
  }
}
