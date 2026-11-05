import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hypixel_tracker/core/theme/app_theme.dart';
import 'package:hypixel_tracker/core/widgets/fading_app_bar.dart';
import 'package:hypixel_tracker/domain/entities/app_settings.dart';
import 'package:hypixel_tracker/features/events/background/events_notifier.dart';
import 'package:hypixel_tracker/features/settings/settings_controller.dart';

// The options tab: light or dark theme, the accent colour, and the event
// alerts.
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
        // Alerts are Android only, like the background sync behind them.
        if (defaultTargetPlatform == TargetPlatform.android)
          const _SettingCard(title: 'Notifications', child: _AlertsSetting()),
        const _AboutCard(),
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

// Turns the event alerts on (the Android notification permission), or
// sends a test once they are on.
class _AlertsSetting extends StatefulWidget {
  const _AlertsSetting();

  @override
  State<_AlertsSetting> createState() => _AlertsSettingState();
}

class _AlertsSettingState extends State<_AlertsSetting> {
  // Null until the permission was checked.
  bool? _enabled;

  // The permission can change in the system settings while the app is in
  // the background: check again when it comes back.
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _check);
    _check();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    final enabled = await EventsNotifier.areEnabled();
    if (mounted) setState(() => _enabled = enabled);
  }

  Future<void> _turnOn() async {
    final messenger = ScaffoldMessenger.of(context);
    final granted = await EventsNotifier.requestPermission();
    if (!mounted) return;

    setState(() => _enabled = granted);
    if (!granted) {
      // Android stops asking after two refusals.
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Notifications are blocked. Allow them in Android settings, '
            'under Apps > hypixel_tracker > Notifications.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final enabled = _enabled;
    if (enabled == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.md,
      children: [
        Text(
          enabled
              ? 'On. You get an alert when a fire sale is announced or '
                    'starts, when the mayor election opens and closes, when '
                    'Bingo starts or has a day left, and when a festival '
                    '(Spooky Festival, Traveling Zoo, Season of Jerry, New '
                    'Year) starts.'
              : 'Off. Turn them on to hear about fire sales, mayor '
                    'elections, Bingo and festivals, even with the app '
                    'closed.',
          style: textTheme.bodyMedium,
        ),
        if (enabled)
          OutlinedButton.icon(
            onPressed: EventsNotifier.showTest,
            icon: const Icon(Icons.notifications_active_outlined),
            label: const Text('Send a test notification'),
          )
        else
          ElevatedButton.icon(
            onPressed: _turnOn,
            icon: const Icon(Icons.notifications_outlined),
            label: const Text('Turn on alerts'),
          ),
      ],
    );
  }
}

// The app icon and name, with the disclaimer the stores expect from a fan
// app.
class _AboutCard extends StatelessWidget {
  const _AboutCard();

  static const _iconSize = 64.0;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: AppRadius.md,
              child: Image.asset(
                'assets/icon/app_icon_256.png',
                width: _iconSize,
                height: _iconSize,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hypixel Tracker', style: textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Not affiliated with or endorsed by Hypixel Inc. '
                    'or Mojang.',
                    style: textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
