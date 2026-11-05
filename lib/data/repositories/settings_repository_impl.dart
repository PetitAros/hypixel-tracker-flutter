import 'package:hypixel_tracker/data/datasources/local/preferences_local_datasource.dart';
import 'package:hypixel_tracker/domain/entities/app_settings.dart';
import 'package:hypixel_tracker/domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final PreferencesLocalDatasource local;

  SettingsRepositoryImpl({required this.local});

  @override
  AppSettings read() => local.readSettings();

  @override
  Future<void> save(AppSettings settings) => local.saveSettings(settings);
}
