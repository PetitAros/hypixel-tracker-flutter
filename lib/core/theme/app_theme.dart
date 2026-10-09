import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// 1. Raw design tokens — the ONLY place literal values are allowed to live.
// ---------------------------------------------------------------------------

class AppColors {
  AppColors._();

  // Brand
  static const gold = Color(0xFFF4C430); // Hypixel/SkyBlock gold accent
  static const goldDark = Color(0xFFB8860B);

  // Semantic
  static const success = Color(0xFF4CAF50); // e.g. bazaar sell price up
  static const danger = Color(0xFFE53935); // e.g. price drop, error state
  static const warning = Color(0xFFFFA726); // e.g. auction ending soon

  // Neutrals (dark theme, fits a Minecraft/SkyBlock aesthetic)
  static const background = Color(0xFF121212);
  static const surface = Color(0xFF1E1E1E);
  static const surfaceVariant = Color(0xFF2A2A2A);
  static const onBackground = Color(0xFFEDEDED);
  static const onSurfaceMuted = Color(0xFFA0A0A0);

  // SkyBlock rarities (Minecraft chat colours)
  static const rarityCommon = Color(0xFFFFFFFF);
  static const rarityUncommon = Color(0xFF55FF55);
  static const rarityRare = Color(0xFF5555FF);
  static const rarityEpic = Color(0xFFAA00AA);
  static const rarityLegendary = Color(0xFFFFAA00);
  static const rarityMythic = Color(0xFFFF55FF);
  static const rarityDivine = Color(0xFF55FFFF);
  static const raritySpecial = Color(0xFFFF5555);
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

  static const TextTheme textTheme = TextTheme(
    headlineLarge: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: AppColors.onBackground,
    ),
    headlineMedium: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: AppColors.onBackground,
    ),
    titleMedium: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 17,
      fontWeight: FontWeight.w600,
      color: AppColors.onBackground,
    ),
    bodyLarge: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 15,
      fontWeight: FontWeight.w400,
      color: AppColors.onBackground,
    ),
    bodyMedium: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 13,
      fontWeight: FontWeight.w400,
      color: AppColors.onSurfaceMuted,
    ),
    labelLarge: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppColors.background,
    ),
  );
}

// ---------------------------------------------------------------------------
// 3. The actual ThemeData consumed by MaterialApp.
// ---------------------------------------------------------------------------

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final colorScheme = const ColorScheme.dark(
      primary: AppColors.gold,
      onPrimary: AppColors.background,
      secondary: AppColors.goldDark,
      error: AppColors.danger,
      surface: AppColors.surface,
      onSurface: AppColors.onBackground,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: AppTextStyles.textTheme,

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: false,
      ).copyWith(titleTextStyle: AppTextStyles.textTheme.headlineMedium),

      cardTheme: CardThemeData(
        color: AppColors.surfaceVariant,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lg),
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.background,
          textStyle: AppTextStyles.textTheme.labelLarge,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.lg),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant,
        contentPadding: const EdgeInsets.all(AppSpacing.md),
        border: OutlineInputBorder(
          borderRadius: AppRadius.xl,
          borderSide: BorderSide.none,
        ),
        hintStyle: AppTextStyles.textTheme.bodyMedium,
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.surfaceVariant,
        thickness: 1,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariant,
        labelStyle: AppTextStyles.textTheme.bodyMedium,
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
//     theme: AppTheme.dark,
//     routerConfig: router,
//   )
