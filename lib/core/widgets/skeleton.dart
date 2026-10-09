import 'package:flutter/material.dart';
import 'package:hypixel_tracker/core/theme/app_theme.dart';

// Pulsing placeholder cards shown while a list loads, so the page already
// has its shape and nothing jumps when the data arrives.
class SkeletonList extends StatefulWidget {
  const SkeletonList({
    super.key,
    this.itemCount = 8,
    this.itemHeight = 72,
    this.columns = 1,
  });

  final int itemCount;
  final double itemHeight;

  /// 1 for a list of cards, more for a grid.
  final int columns;

  @override
  State<SkeletonList> createState() => _SkeletonListState();
}

class _SkeletonListState extends State<SkeletonList>
    with SingleTickerProviderStateMixin {
  static const _pulse = Duration(milliseconds: 900);
  static const _dimmest = 0.35;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _pulse,
  )..repeat(reverse: true);

  late final Animation<double> _opacity = Tween<double>(
    begin: _dimmest,
    end: 1,
  ).animate(_controller);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Starts below a see-through app bar, like the list it stands for.
    final inset = MediaQuery.paddingOf(context);

    return Semantics(
      label: 'Loading',
      child: FadeTransition(
        opacity: _opacity,
        child: widget.columns == 1
            ? ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.itemCount,
                itemBuilder: (context, index) =>
                    Card(child: SizedBox(height: widget.itemHeight)),
              )
            : GridView.count(
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  inset.top + AppSpacing.sm,
                  AppSpacing.md,
                  inset.bottom + AppSpacing.sm,
                ),
                crossAxisCount: widget.columns,
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                childAspectRatio: 1.25,
                children: [
                  for (var i = 0; i < widget.itemCount; i++)
                    const Card(margin: EdgeInsets.zero),
                ],
              ),
      ),
    );
  }
}
