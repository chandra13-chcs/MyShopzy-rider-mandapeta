import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const brand = Color(0xFF247653);
  static const darkGreen = Color(0xFF183B32);
  static const accentGreen = Color(0xFF9BBB82);
  static const brandYellow = Color(0xFFE8B65A);
  static const accentCoral = Color(0xFFC98A4A);
  static const accentBlue = Color(0xFF5F8D75);
  static const appBackground = Color(0xFFF4F7F4);
  static const background = appBackground;
  static const surface = Color(0xFFFFFFFF);
  static const fieldSurface = Color(0xFFFAFCFA);
  static const lightGreenSurface = Color(0xFFE8F1E9);
  static const lightBlueSurface = Color(0xFFEEF3F0);
  static const onlineBox = Color(0xFFEAF3EB);
  static const summaryCard = Color(0xFFE8F1E9);
  static const currentDeliveryCard = Color(0xFFFFFFFF);
  static const performanceTile = Color(0xFFEEF3F0);
  static const primaryText = Color(0xFF263A32);
  static const secondaryText = Color(0xFF68766F);
  static const success = brand;
  static const warning = Color(0xFF9A6A17);
  static const error = Color(0xFFB42318);
  static const errorSoft = Color(0xFFFFE8E6);
  static const divider = Color(0xFFDCE5E7);
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
      tertiary: accentCoral,
      onTertiary: surface,
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
        backgroundColor: darkGreen,
        foregroundColor: surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Color(0x33123D35),
        shape: Border(bottom: BorderSide(color: accentCoral, width: 2)),
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: surface,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
        ),
        iconTheme: IconThemeData(color: surface),
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 62,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 5,
        shadowColor: const Color(0x24123D35),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: Color(0xFFDCE9E4)),
        ),
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 14,
        shadowColor: const Color(0x33123D35),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
          side: const BorderSide(color: Color(0xFFDCE9E4)),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: brandYellow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: divider,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: lightBlueSurface,
        selectedColor: lightGreenSurface,
        secondarySelectedColor: brandYellow.withValues(alpha: 0.3),
        disabledColor: appBackground,
        surfaceTintColor: Colors.transparent,
        side: const BorderSide(color: divider),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        labelStyle: const TextStyle(
          color: primaryText,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: const TextStyle(
          color: darkGreen,
          fontWeight: FontWeight.w700,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: brand,
        linearTrackColor: lightGreenSurface,
        circularTrackColor: lightGreenSurface,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentCoral,
        foregroundColor: surface,
        elevation: 5,
        focusElevation: 7,
        hoverElevation: 8,
        highlightElevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fieldSurface,
        hintStyle: const TextStyle(color: secondaryText),
        labelStyle: const TextStyle(color: secondaryText),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: brand, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style:
            FilledButton.styleFrom(
              backgroundColor: brand,
              foregroundColor: surface,
              disabledBackgroundColor: lightGreenSurface,
              disabledForegroundColor: darkGreen,
              textStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              minimumSize: const Size(48, 48),
            ).copyWith(
              animationDuration: const Duration(milliseconds: 180),
              elevation: _buttonElevation,
              shadowColor: const WidgetStatePropertyAll(Color(0x33123D35)),
              overlayColor: _buttonOverlay,
              backgroundBuilder: _buttonDepthEffect,
            ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style:
            OutlinedButton.styleFrom(
              foregroundColor: brand,
              disabledForegroundColor: darkGreen,
              side: const BorderSide(color: brand),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              minimumSize: const Size(48, 48),
            ).copyWith(
              animationDuration: const Duration(milliseconds: 180),
              elevation: _buttonElevation,
              shadowColor: const WidgetStatePropertyAll(Color(0x33123D35)),
              overlayColor: _buttonOverlay,
              backgroundBuilder: _buttonDepthEffect,
            ),
      ),
      textButtonTheme: TextButtonThemeData(
        style:
            TextButton.styleFrom(
              foregroundColor: brand,
              disabledForegroundColor: darkGreen,
              textStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ).copyWith(
              animationDuration: const Duration(milliseconds: 180),
              elevation: _buttonElevation,
              shadowColor: const WidgetStatePropertyAll(Color(0x33123D35)),
              overlayColor: _buttonOverlay,
              backgroundBuilder: _buttonDepthEffect,
            ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          animationDuration: const Duration(milliseconds: 180),
          elevation: _buttonElevation,
          shadowColor: const WidgetStatePropertyAll(Color(0x33123D35)),
          overlayColor: _buttonOverlay,
          backgroundBuilder: _buttonDepthEffect,
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return brand;
          return divider;
        }),
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return brandYellow;
          return surface;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return brand;
          return secondaryText.withValues(alpha: 0.35);
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
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: darkGreen,
        contentTextStyle: TextStyle(
          color: surface,
          fontWeight: FontWeight.w600,
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _RiderPageTransitionsBuilder(),
          TargetPlatform.iOS: _RiderPageTransitionsBuilder(),
          TargetPlatform.linux: _RiderPageTransitionsBuilder(),
          TargetPlatform.macOS: _RiderPageTransitionsBuilder(),
          TargetPlatform.windows: _RiderPageTransitionsBuilder(),
        },
      ),
    );
  }

  static WidgetStateProperty<double> get _buttonElevation =>
      WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return 0;
        if (states.contains(WidgetState.pressed)) return 1;
        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused)) {
          return 6;
        }
        return 3;
      });

  static WidgetStateProperty<Color?> get _buttonOverlay =>
      WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return brandYellow.withValues(alpha: 0.3);
        }
        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused)) {
          return brandYellow.withValues(alpha: 0.18);
        }
        return null;
      });

  static ButtonLayerBuilder get _buttonDepthEffect => (context, states, child) {
    final pressed = states.contains(WidgetState.pressed);
    final hovered = states.contains(WidgetState.hovered);
    final focused = states.contains(WidgetState.focused);
    final disabled = states.contains(WidgetState.disabled);
    final motionDisabled = MediaQuery.disableAnimationsOf(context);
    if (motionDisabled) return child ?? const SizedBox.shrink();
    final lift = pressed
        ? 2.0
        : hovered || focused
        ? -2.0
        : 0.0;
    final scale = pressed
        ? 0.965
        : hovered || focused
        ? 1.025
        : 1.0;
    final tiltX = pressed
        ? 0.035
        : hovered || focused
        ? -0.018
        : 0.0;
    final tiltY = pressed
        ? -0.025
        : hovered || focused
        ? 0.018
        : 0.0;
    final transform = Matrix4.identity()
      ..setEntry(3, 2, 0.001)
      ..rotateX(tiltX)
      ..rotateY(tiltY)
      ..translateByDouble(0, lift, 0, 1)
      ..scaleByDouble(scale, scale, scale, 1);

    return AnimatedContainer(
      duration: motionDisabled
          ? Duration.zero
          : const Duration(milliseconds: 170),
      curve: Curves.easeOutCubic,
      transformAlignment: Alignment.center,
      transform: transform,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: disabled
            ? const []
            : [
                BoxShadow(
                  color: (hovered || focused ? accentBlue : brand).withValues(
                    alpha: pressed
                        ? 0.14
                        : hovered || focused
                        ? 0.24
                        : 0.16,
                  ),
                  blurRadius: pressed
                      ? 3
                      : hovered || focused
                      ? 19
                      : 10,
                  offset: Offset(
                    0,
                    pressed
                        ? 1
                        : hovered || focused
                        ? 7
                        : 4,
                  ),
                ),
              ],
      ),
      child: child,
    );
  };
}

class _RiderPageTransitionsBuilder extends PageTransitionsBuilder {
  const _RiderPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) return child;

    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curvedAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.12, 0),
          end: Offset.zero,
        ).animate(curvedAnimation),
        child: AnimatedBuilder(
          animation: curvedAnimation,
          child: child,
          builder: (context, child) {
            final progress = curvedAnimation.value;
            final scale = 0.97 + (0.03 * progress);
            final transform = Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(0.035 * (1 - progress))
              ..scaleByDouble(scale, scale, scale, 1);
            return Transform(
              alignment: Alignment.center,
              transform: transform,
              child: child,
            );
          },
        ),
      ),
    );
  }
}
