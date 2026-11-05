import 'package:hypixel_tracker/domain/entities/app_settings.dart';

abstract interface class SettingsRepository {
  /// The saved settings, or [AppSettings.defaults] on first launch.
  AppSettings read();

  Future<void> save(AppSettings settings);
}
