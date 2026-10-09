import 'package:flutter/material.dart';
import 'package:hypixel_tracker/core/theme/app_theme.dart';
import 'package:hypixel_tracker/core/utils/formatters.dart';
import 'package:hypixel_tracker/domain/entities/bazaar_item_detail.dart';

// The buy and sell prices over time, as two lines on the same scale.
class PriceChart extends StatelessWidget {
  const PriceChart({super.key, required this.points});

  /// Oldest first. Needs at least two points to draw a line.
  final List<BazaarPricePoint> points;

  static const _height = 140.0;
  static const _buyColor = AppColors.gold;
  static const _sellColor = AppColors.success;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    var low = points.first.sell;
    var high = points.first.buy;
    for (final point in points) {
      for (final price in [point.buy, point.sell]) {
        if (price < low) low = price;
        if (price > high) high = price;
      }
    }

    Widget legend(Color color, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: AppSpacing.sm,
          height: AppSpacing.sm,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: textTheme.bodyMedium),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            legend(_buyColor, 'Buy'),
            const SizedBox(width: AppSpacing.md),
            legend(_sellColor, 'Sell'),
            const Spacer(),
            Text(
              'High ${Formatters.compact(high)}',
              style: textTheme.bodyMedium,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: _height,
          width: double.infinity,
          child: CustomPaint(
            painter: _ChartPainter(
              points: points,
              low: low,
              high: high,
              buyColor: _buyColor,
              sellColor: _sellColor,
              gridColor: AppColors.surface,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Text('24 h ago', style: textTheme.bodyMedium),
            const Spacer(),
            Text('Low ${Formatters.compact(low)}', style: textTheme.bodyMedium),
            const Spacer(),
            Text('Now', style: textTheme.bodyMedium),
          ],
        ),
      ],
    );
  }
}

class _ChartPainter extends CustomPainter {
  const _ChartPainter({
    required this.points,
    required this.low,
    required this.high,
    required this.buyColor,
    required this.sellColor,
    required this.gridColor,
  });

  final List<BazaarPricePoint> points;
  final double low;
  final double high;
  final Color buyColor;
  final Color sellColor;
  final Color gridColor;

  static const _lineWidth = 2.0;
  static const _gridLines = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 0; i <= _gridLines; i++) {
      final y = size.height * i / _gridLines;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    if (points.length < 2) return;

    // A flat price would divide by zero: draw it in the middle instead.
    final span = high - low;
    final start = points.first.time.millisecondsSinceEpoch;
    final duration = points.last.time.millisecondsSinceEpoch - start;

    Offset place(BazaarPricePoint point, double price) {
      final x = duration == 0
          ? 0.0
          : (point.time.millisecondsSinceEpoch - start) / duration;
      final y = span == 0 ? 0.5 : (high - price) / span;
      return Offset(x * size.width, y * size.height);
    }

    void line(Color color, double Function(BazaarPricePoint) priceOf) {
      final path = Path();
      for (final (index, point) in points.indexed) {
        final offset = place(point, priceOf(point));
        index == 0
            ? path.moveTo(offset.dx, offset.dy)
            : path.lineTo(offset.dx, offset.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = _lineWidth
          ..strokeJoin = StrokeJoin.round,
      );
    }

    line(sellColor, (point) => point.sell);
    line(buyColor, (point) => point.buy);
  }

  @override
  bool shouldRepaint(_ChartPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}
