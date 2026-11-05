import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hypixel_tracker/core/theme/app_theme.dart';
import 'package:hypixel_tracker/core/utils/formatters.dart';
import 'package:hypixel_tracker/core/widgets/countdown.dart';
import 'package:hypixel_tracker/core/widgets/item_icon.dart';
import 'package:hypixel_tracker/domain/entities/player_profiles.dart';
import 'package:hypixel_tracker/features/profile/profile_controller.dart';

// The followed player's forge: one gauge per busy slot.
class ForgeCard extends StatefulWidget {
  const ForgeCard({super.key});

  @override
  State<ForgeCard> createState() => _ForgeCardState();
}

class _ForgeCardState extends State<ForgeCard> {
  // The gauges move slowly: a refresh a minute is enough.
  static const _tick = Duration(minutes: 1);

  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_tick, (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;
    final state = ProfileScope.of(context).state;

    final Widget content = switch (state) {
      ProfileLoaded(:final profile) when profile.forge.isNotEmpty =>
        _ForgeGauges(slots: profile.forge, now: DateTime.now()),
      ProfileLoaded() => _message(context, 'Nothing in the forge.'),
      ProfileLoading() => _message(context, 'Loading the profile…'),
      ProfileNone() => _message(
        context,
        'Follow a player in the Profile tab to see their forge.',
      ),
      ProfileEmpty() ||
      ProfileFailed() => _message(context, 'The forge could not be loaded.'),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.md,
          children: [
            Row(
              children: [
                Icon(Icons.local_fire_department, color: palette.accent),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: Text('Forge', style: textTheme.titleMedium)),
              ],
            ),
            content,
          ],
        ),
      ),
    );
  }

  static Widget _message(BuildContext context, String text) {
    return Text(text, style: Theme.of(context).textTheme.bodyLarge);
  }
}

// Two gauges per row.
class _ForgeGauges extends StatelessWidget {
  const _ForgeGauges({required this.slots, required this.now});

  final List<ForgeSlot> slots;
  final DateTime now;

  static const _columns = 2;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            (constraints.maxWidth - AppSpacing.sm * (_columns - 1)) / _columns;
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final slot in slots)
              SizedBox(
                width: width,
                child: _ForgeTile(slot: slot, now: now),
              ),
          ],
        );
      },
    );
  }
}

class _ForgeTile extends StatelessWidget {
  const _ForgeTile({required this.slot, required this.now});

  final ForgeSlot slot;
  final DateTime now;

  static const _gaugeSize = 96.0;
  static const _iconSize = 28.0;
  static const _trackOpacity = 0.25;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;
    final progress = slot.progressAt(now);
    final readyAt = slot.readyAt;
    final ready = progress == 1;

    final status = switch ((progress, readyAt)) {
      (null, _) || (_, null) => 'Unknown duration',
      _ when ready => 'Ready',
      (_, final at?) => 'Ready in ${Formatters.timeLeft(at.difference(now))}',
    };

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: [
        'Slot ${slot.slot}, ${slot.itemName}',
        if (progress != null) '${(progress * 100).round()} percent',
        status,
      ].join(', '),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: AppRadius.md,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            spacing: AppSpacing.sm,
            children: [
              SizedBox.square(
                dimension: _gaugeSize,
                child: CustomPaint(
                  painter: _GaugePainter(
                    progress: progress ?? 0,
                    trackColor: palette.onSurfaceMuted.withValues(
                      alpha: _trackOpacity,
                    ),
                    color: ready ? AppColors.success : palette.accent,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ItemIcon(url: slot.iconUrl, size: _iconSize),
                        Text(
                          progress == null
                              ? '?'
                              : '${(progress * 100).floor()}%',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Text(
                slot.itemName,
                style: textTheme.bodyLarge,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (readyAt != null && !ready)
                Countdown(endsAt: readyAt, style: textTheme.bodyMedium)
              else
                Text(
                  ready ? 'Ready' : 'Unknown duration',
                  style: textTheme.bodyMedium,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// A 270° ring, open at the bottom, filled clockwise with [progress].
class _GaugePainter extends CustomPainter {
  const _GaugePainter({
    required this.progress,
    required this.trackColor,
    required this.color,
  });

  final double progress;
  final Color trackColor;
  final Color color;

  static const _strokeWidth = 8.0;
  static const _startAngle = 0.75 * pi;
  static const _sweep = 1.5 * pi;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: (size.shortestSide - _strokeWidth) / 2,
    );
    Paint stroke(Color color) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, _startAngle, _sweep, false, stroke(trackColor));
    if (progress > 0) {
      canvas.drawArc(
        rect,
        _startAngle,
        _sweep * progress,
        false,
        stroke(color),
      );
    }
  }

  @override
  bool shouldRepaint(_GaugePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.trackColor != trackColor;
  }
}
