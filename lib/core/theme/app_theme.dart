import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const brand = Color(0xFF2E7D32);
  static const darkGreen = Color(0xFF1B5E20);
  static const brandYellow = Color(0xFFFFC107);
  static const appBackground = Color(0xFFF7FAF7);
  static const background = appBackground;
  static const surface = Color(0xFFFFFFFF);
  static const fieldSurface = Color(0xFFF7FAF7);
  static const lightGreenSurface = Color(0xFFEFF8F4);
  static const onlineBox = Color(0xFFFFFFFF);
  static const summaryCard = Color(0xFFE8F5E9);
  static const currentDeliveryCard = Color(0xFFFFFFFF);
  static const performanceTile = Color(0xFFE8F5E9);
  static const primaryText = Color(0xFF202321);
  static const secondaryText = Color(0xFF777C79);
  static const success = brand;
  static const warning = Color(0xFF9A6700);
  static const error = Color(0xFFB42318);
  static const errorSoft = Color(0xFFFFE8E6);
  static const divider = Color(0xFFE2EAE5);
  static const brandSoft = lightGreenSurface;
  static const successSoft = lightGreenSurface;
  static const mapSurface = lightGreenSurface;
  static const onDarkSurface = Color(0xB3FFFFFF);
  static const darkDivider = Color(0x33FFFFFF);
  static const bonus = brandYellow;

  static const screenTitle = TextStyle(
    color: primaryText,
    fontSize: 20,
    fontWeight: FontWeight.w700,
  );
  static const greetingTitle = TextStyle(
    color: primaryText,
    fontSize: 24,
    fontWeight: FontWeight.w800,
  );
  static const sectionTitle = TextStyle(
    color: primaryText,
    fontSize: 18,
    fontWeight: FontWeight.w700,
  );
  static const cardTitle = TextStyle(
    color: primaryText,
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );
  static const bodyText = TextStyle(color: primaryText, fontSize: 14);
  static const secondaryTextStyle = TextStyle(
    color: secondaryText,
    fontSize: 13,
  );
  static const smallStatus = TextStyle(
    color: secondaryText,
    fontSize: 11,
    fontWeight: FontWeight.w600,
  );

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: brand,
      primary: brand,
      onPrimary: surface,
      secondary: brandYellow,
      onSecondary: darkGreen,
      error: error,
      onError: surface,
      surface: surface,
      onSurface: primaryText,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: appBackground,
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        headlineSmall: screenTitle,
        titleLarge: screenTitle,
        titleMedium: sectionTitle,
        titleSmall: cardTitle,
        bodyLarge: bodyText,
        bodyMedium: bodyText,
        bodySmall: secondaryTextStyle,
        labelLarge: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        labelMedium: smallStatus,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: brand,
        foregroundColor: surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: surface,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: surface),
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: divider),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: divider,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: const TextStyle(color: secondaryText),
        labelStyle: const TextStyle(color: secondaryText),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: brand, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: brand,
          foregroundColor: surface,
          disabledBackgroundColor: divider,
          disabledForegroundColor: secondaryText,
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          minimumSize: const Size(48, 44),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: brand,
          disabledForegroundColor: secondaryText,
          side: const BorderSide(color: brand),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          minimumSize: const Size(48, 44),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: brand,
          disabledForegroundColor: secondaryText,
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return success;
          return divider;
        }),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkGreen,
        elevation: 0,
        height: 72,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorColor: brandYellow.withValues(alpha: 0.18),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected)
                ? brandYellow
                : surface,
            size: 22,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return TextStyle(
            color: states.contains(WidgetState.selected)
                ? brandYellow
                : surface,
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          );
        }),
      ),
    );
  }
}
