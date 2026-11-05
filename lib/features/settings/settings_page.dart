import 'package:flutter/material.dart';
import 'package:hypixel_tracker/core/theme/app_theme.dart';
import 'package:hypixel_tracker/core/widgets/fading_app_bar.dart';
import 'package:hypixel_tracker/domain/entities/app_settings.dart';
import 'package:hypixel_tracker/features/settings/settings_controller.dart';

// The options tab: light or dark theme, and the accent colour.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.controller});

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const FadingAppBar(title: 'Options'),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) => _SettingsList(controller: controller),
      ),
    );
  }
}

class _SettingsList extends StatelessWidget {
  const _SettingsList({required this.controller});

  final SettingsController controller;

  static String _accentLabel(AppAccent accent) => switch (accent) {
    AppAccent.hypixel => 'Hypixel',
    AppAccent.purple => 'Purple',
    AppAccent.green => 'Green',
  };

  @override
  Widget build(BuildContext context) {
    final settings = controller.settings;

    // Starts below the app bar and ends above the navigation bar.
    final inset = MediaQuery.paddingOf(context);

    return ListView(
      padding: EdgeInsets.only(
        top: inset.top + AppSpacing.sm,
        bottom: inset.bottom + AppSpacing.sm,
      ),
      children: [
        _SettingCard(
          title: 'Theme',
          child: SegmentedButton<AppBrightness>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                value: AppBrightness.light,
                icon: Icon(Icons.light_mode),
                label: Text('Light'),
              ),
              ButtonSegment(
                value: AppBrightness.dark,
                icon: Icon(Icons.dark_mode),
                label: Text('Dark'),
              ),
            ],
            selected: {settings.brightness},
            onSelectionChanged: (selected) =>
                controller.setBrightness(selected.single),
          ),
        ),
        _SettingCard(
          title: 'Accent colour',
          child: SegmentedButton<AppAccent>(
            showSelectedIcon: false,
            segments: [
              for (final accent in AppAccent.values)
                ButtonSegment(
                  value: accent,
                  // A swatch of the accent as it looks in the current theme.
                  icon: Icon(
                    Icons.circle,
                    color: AppPalette.of(accent, settings.brightness).accent,
                  ),
                  label: Text(_accentLabel(accent)),
                ),
            ],
            selected: {settings.accent},
            onSelectionChanged: (selected) =>
                controller.setAccent(selected.single),
          ),
        ),
      ],
    );
  }
}

class _SettingCard extends StatelessWidget {
  const _SettingCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.md,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            child,
          ],
        ),
      ),
    );
  }
}
