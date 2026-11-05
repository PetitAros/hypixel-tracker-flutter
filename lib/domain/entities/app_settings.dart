enum AppBrightness { light, dark }

// The colour that stands out across the app: buttons, selected tab,
// maxed skills...
enum AppAccent { hypixel, purple, green }

// How the user wants the app to look, picked in the options tab.
class AppSettings {
  final AppBrightness brightness;
  final AppAccent accent;

  const AppSettings({required this.brightness, required this.accent});

  static const defaults = AppSettings(
    brightness: AppBrightness.dark,
    accent: AppAccent.hypixel,
  );

  AppSettings copyWith({AppBrightness? brightness, AppAccent? accent}) {
    return AppSettings(
      brightness: brightness ?? this.brightness,
      accent: accent ?? this.accent,
    );
  }
}
