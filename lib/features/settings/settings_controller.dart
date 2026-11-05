import 'package:flutter/foundation.dart';
import 'package:hypixel_tracker/domain/entities/app_settings.dart';
import 'package:hypixel_tracker/domain/repositories/settings_repository.dart';

// The look of the app. App-wide state: one instance, created in main.dart,
// that MaterialApp listens to so a change restyles every page at once.
class SettingsController extends ChangeNotifier {
  final SettingsRepository _repository;

  SettingsController(this._repository) : _settings = _repository.read();

  AppSettings _settings;
  AppSettings get settings => _settings;

  void setBrightness(AppBrightness brightness) =>
      _update(_settings.copyWith(brightness: brightness));

  void setAccent(AppAccent accent) =>
      _update(_settings.copyWith(accent: accent));

  void _update(AppSettings settings) {
    _settings = settings;
    notifyListeners();
    _repository.save(settings);
  }
}
