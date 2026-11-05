import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hypixel_tracker/domain/entities/app_settings.dart';

// ---------------------------------------------------------------------------
// 1. Raw design tokens — the ONLY place literal values are allowed to live.
// ---------------------------------------------------------------------------

class AppColors {
  AppColors._();

  // Semantic
  static const success = Color(0xFF4CAF50); // e.g. bazaar sell price up
  static const danger = Color(0xFFE53935); // e.g. price drop, error state
  static const warning = Color(0xFFFFA726); // e.g. auction ending soon

  // The accent and the neutrals depend on the user's choice: see AppPalette.

  // SkyBlock rarities (Minecraft chat colours)
  static const rarityUncommon = Color(0xFF55FF55);
  static const rarityRare = Color(0xFF5555FF);
  static const rarityEpic = Color(0xFFAA00AA);
  static const rarityLegendary = Color(0xFFFFAA00);
  static const rarityMythic = Color(0xFFFF55FF);
  static const rarityDivine = Color(0xFF55FFFF);
  static const raritySpecial = Color(0xFFFF5555);
}

// The colours that change with the options tab: the accent (Hypixel gold,
// purple or green) and the light or dark neutrals. Read it in a widget with
// `context.palette`.
class AppPalette extends ThemeExtension<AppPalette> {
  final Brightness brightness;
  final Color accent;
  final Color accentDark;
  final Color onAccent; // text and icons on an accent background
  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color onBackground;
  final Color onSurfaceMuted;

  const AppPalette({
    required this.brightness,
    required this.accent,
    required this.accentDark,
    required this.onAccent,
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.onBackground,
    required this.onSurfaceMuted,
  });

  factory AppPalette.of(AppAccent accent, AppBrightness brightness) {
    final dark = brightness == AppBrightness.dark;

    // On a light background the bright accents are hard to read, so each
    // accent has a deeper shade for the light theme.
    final (Color main, Color deep) = switch ((accent, dark)) {
      (AppAccent.hypixel, true) => (
        const Color(0xFFF4C430), // Hypixel/SkyBlock gold
        const Color(0xFFB8860B),
      ),
      (AppAccent.hypixel, false) => (
        const Color(0xFFB8860B),
        const Color(0xFF8B6508),
      ),
      (AppAccent.purple, true) => (
        const Color(0xFFB388FF),
        const Color(0xFF7C4DFF),
      ),
      (AppAccent.purple, false) => (
        const Color(0xFF7E57C2),
        const Color(0xFF5E35B1),
      ),
      (AppAccent.green, true) => (
        const Color(0xFF4ADE80),
        const Color(0xFF16A34A),
      ),
      (AppAccent.green, false) => (
        const Color(0xFF2E7D32),
        const Color(0xFF1B5E20),
      ),
    };

    return dark
        ? AppPalette(
            brightness: Brightness.dark,
            accent: main,
            accentDark: deep,
            onAccent: const Color(0xFF121212),
            // Fits a Minecraft/SkyBlock aesthetic.
            background: const Color(0xFF121212),
            surface: const Color(0xFF1E1E1E),
            surfaceVariant: const Color(0xFF2A2A2A),
            onBackground: const Color(0xFFEDEDED),
            onSurfaceMuted: const Color(0xFFA0A0A0),
          )
        : AppPalette(
            brightness: Brightness.light,
            accent: main,
            accentDark: deep,
            onAccent: const Color(0xFFFFFFFF),
            // Cards (surfaceVariant) are white on a grey page.
            background: const Color(0xFFF2F2F5),
            surface: const Color(0xFFE4E4EA),
            surfaceVariant: const Color(0xFFFFFFFF),
            onBackground: const Color(0xFF1B1B1F),
            onSurfaceMuted: const Color(0xFF5E5E66),
          );
  }

  @override
  AppPalette copyWith() => this;

  // Switching theme swaps the palette at once, no animation needed.
  @override
  AppPalette lerp(AppPalette? other, double t) =>
      t < 0.5 ? this : (other ?? this);
}

extension AppPaletteContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}

class AppSpacing {
  AppSpacing._();

  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

class AppRadius {
  AppRadius._();

  static const sm = BorderRadius.all(Radius.circular(6));
  static const md = BorderRadius.all(Radius.circular(12));
  static const lg = BorderRadius.all(Radius.circular(20));
  static const xl = BorderRadius.all(Radius.circular(28));
}

// ---------------------------------------------------------------------------
// 2. Text styles — referenced via Theme.of(context).textTheme.*, never
//    built inline in a widget.
// ---------------------------------------------------------------------------

class AppTextStyles {
  AppTextStyles._();

  static const _fontFamily =
      'Inter'; // swap for a Minecraft-y display font if desired

  static TextTheme textTheme(AppPalette palette) => TextTheme(
    headlineLarge: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: palette.onBackground,
    ),
    headlineMedium: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: palette.onBackground,
    ),
    titleMedium: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 17,
      fontWeight: FontWeight.w600,
      color: palette.onBackground,
    ),
    bodyLarge: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 15,
      fontWeight: FontWeight.w400,
      color: palette.onBackground,
    ),
    bodyMedium: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 13,
      fontWeight: FontWeight.w400,
      color: palette.onSurfaceMuted,
    ),
    labelLarge: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: palette.onAccent,
    ),
  );
}

// ---------------------------------------------------------------------------
// 3. The actual ThemeData consumed by MaterialApp.
// ---------------------------------------------------------------------------

class AppTheme {
  AppTheme._();

  static ThemeData build(AppSettings settings) {
    final palette = AppPalette.of(settings.accent, settings.brightness);
    final textTheme = AppTextStyles.textTheme(palette);
    final dark = palette.brightness == Brightness.dark;

    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: palette.accent,
          brightness: palette.brightness,
        ).copyWith(
          primary: palette.accent,
          onPrimary: palette.onAccent,
          secondary: palette.accentDark,
          error: AppColors.danger,
          surface: palette.surface,
          onSurface: palette.onBackground,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: palette.background,
      textTheme: textTheme,
      extensions: [palette],

      appBarTheme: AppBarTheme(
        backgroundColor: palette.surface,
        foregroundColor: palette.onBackground,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.headlineMedium,
        // The app bars are see-through: the status bar icons must contrast
        // with the page, not with the bar.
        systemOverlayStyle: dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),

      iconTheme: IconThemeData(color: palette.onBackground),

      cardTheme: CardThemeData(
        color: palette.surfaceVariant,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lg),
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.accent,
          foregroundColor: palette.onAccent,
          textStyle: textTheme.labelLarge,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.lg),
        ),
      ),

      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          foregroundColor: palette.onSurfaceMuted,
          selectedForegroundColor: palette.accent,
          selectedBackgroundColor: palette.accent.withValues(alpha: 0.2),
          side: BorderSide(color: palette.surface),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surfaceVariant,
        contentPadding: const EdgeInsets.all(AppSpacing.md),
        border: OutlineInputBorder(
          borderRadius: AppRadius.xl,
          borderSide: BorderSide.none,
        ),
        hintStyle: textTheme.bodyMedium,
      ),

      dividerTheme: DividerThemeData(
        color: palette.surfaceVariant,
        thickness: 1,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: palette.surfaceVariant,
        labelStyle: textTheme.bodyMedium,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lg),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 4. Usage example — how a screen SHOULD reference all this.
// ---------------------------------------------------------------------------
//
// ❌ Wrong (hardcoded, fails the brief's rule):
//   Text('Bazaar', style: TextStyle(fontSize: 22, color: Color(0xFFF4C430)))
//   Padding(padding: EdgeInsets.all(16))
//
// ✅ Right:
//   Text('Bazaar', style: Theme.of(context).textTheme.headlineMedium)
//   Padding(padding: const EdgeInsets.all(AppSpacing.md))
//
// And in main.dart:
//
//   MaterialApp.router(
//     theme: AppTheme.build(settings),
//     routerConfig: router,
//   )
