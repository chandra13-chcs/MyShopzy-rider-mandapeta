import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const brand = Color(0xFFE85D2A);
  static const background = Color(0xFFF6F7F9);
  static const surface = Color(0xFFFFFFFF);
  static const primaryText = Color(0xFF202124);
  static const secondaryText = Color(0xFF74777C);
  static const success = Color(0xFF168A56);
  static const warning = Color(0xFFB7791F);
  static const error = Color(0xFFB42318);
  static const divider = Color(0xFFE6E8EB);
  static const brandSoft = Color(0xFFFFE8DE);
  static const successSoft = Color(0xFFE9F5EF);
  static const mapSurface = Color(0xFFE8F0E9);
  static const onDarkSurface = Color(0xB3FFFFFF);
  static const darkDivider = Color(0x33FFFFFF);
  static const bonus = Color(0xFF8BE0B3);

  static const screenTitle = TextStyle(
    color: primaryText,
    fontSize: 20,
    fontWeight: FontWeight.w700,
  );
  static const greetingTitle = TextStyle(
    color: primaryText,
    fontSize: 19,
    fontWeight: FontWeight.w700,
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
      secondary: success,
      onSecondary: surface,
      error: error,
      onError: surface,
      surface: surface,
      onSurface: primaryText,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
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
        backgroundColor: background,
        foregroundColor: primaryText,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: screenTitle,
        iconTheme: IconThemeData(color: primaryText),
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
        backgroundColor: surface,
        elevation: 0,
        height: 72,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorColor: brand.withValues(alpha: 0.12),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected)
                ? brand
                : secondaryText,
            size: 22,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return TextStyle(
            color: states.contains(WidgetState.selected)
                ? brand
                : secondaryText,
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
