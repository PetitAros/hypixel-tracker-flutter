import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hypixel_tracker/core/theme/app_theme.dart';
import 'package:hypixel_tracker/core/utils/formatters.dart';

// The time left before [endsAt], kept up to date while it is on screen.
// Turns to the warning colour in the last minutes.
class Countdown extends StatefulWidget {
  const Countdown({super.key, required this.endsAt, this.style});

  final DateTime endsAt;
  final TextStyle? style;

  @override
  State<Countdown> createState() => _CountdownState();
}

class _CountdownState extends State<Countdown> {
  static const _endingSoon = Duration(minutes: 5);

  // Seconds are shown under five minutes; before that, minutes are enough.
  static const _fastTick = Duration(seconds: 1);
  static const _slowTick = Duration(seconds: 20);

  Timer? _timer;

  Duration get _remaining => widget.endsAt.difference(DateTime.now());

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  @override
  void didUpdateWidget(Countdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.endsAt != widget.endsAt) _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    final remaining = _remaining;
    // Nothing left to count once it has ended.
    if (remaining <= Duration.zero) return;

    final tick = remaining < _endingSoon + _slowTick ? _fastTick : _slowTick;
    _timer = Timer(tick, () {
      setState(() {});
      _schedule();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _remaining;
    final urgent = remaining > Duration.zero && remaining < _endingSoon;

    return Text(
      Formatters.timeLeft(remaining),
      style: urgent
          ? widget.style?.copyWith(color: AppColors.warning)
          : widget.style,
    );
  }
}
