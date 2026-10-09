import 'package:flutter/material.dart';
import 'package:hypixel_tracker/core/theme/app_theme.dart';
import 'package:hypixel_tracker/core/utils/formatters.dart';

// Where the current price sits between the lowest and highest of the day:
// a track with a dot, green when the price is a good one.
class PriceRangeBar extends StatelessWidget {
  const PriceRangeBar({
    super.key,
    required this.label,
    required this.low,
    required this.high,
    required this.current,
    required this.lowIsGood,
  });

  final String label;
  final double low;
  final double high;
  final double current;

  /// True for a price you pay (lower is better), false for one you receive.
  final bool lowIsGood;

  static const _trackHeight = 4.0;
  static const _dotSize = 12.0;

  // The bottom and top thirds of the range count as good or bad.
  static const _third = 1 / 3;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final span = high - low;
    final position = span <= 0 ? 0.5 : ((current - low) / span).clamp(0.0, 1.0);
    final goodness = lowIsGood ? 1 - position : position;
    final color = goodness > 1 - _third
        ? AppColors.success
        : goodness < _third
        ? AppColors.danger
        : AppColors.onSurfaceMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: textTheme.bodyMedium)),
            Text(
              Formatters.compact(current),
              style: textTheme.bodyLarge?.copyWith(color: color),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        SizedBox(
          height: _dotSize,
          child: LayoutBuilder(
            builder: (context, constraints) => Stack(
              alignment: Alignment.centerLeft,
              children: [
                Container(
                  height: _trackHeight,
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.sm,
                  ),
                ),
                Positioned(
                  left: (constraints.maxWidth - _dotSize) * position,
                  child: Container(
                    width: _dotSize,
                    height: _dotSize,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Text(Formatters.compact(low), style: textTheme.bodyMedium),
            const Spacer(),
            Text(Formatters.compact(high), style: textTheme.bodyMedium),
          ],
        ),
      ],
    );
  }
}
