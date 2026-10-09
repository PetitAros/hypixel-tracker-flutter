import 'package:flutter/material.dart';

// A chip that opens a menu of choices, e.g. "Sort: Price".
class MenuChip<T> extends StatelessWidget {
  const MenuChip({
    super.key,
    required this.label,
    required this.values,
    required this.labelOf,
    required this.onSelected,
    this.highlighted = false,
  });

  final String label;
  final List<T> values;
  final String Function(T value) labelOf;
  final ValueChanged<T> onSelected;

  /// True when the choice differs from the default, to make it stand out.
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    // The menu works on positions, not on the values themselves: Flutter
    // reads a null result as "menu dismissed", so a null value (such as
    // "any rarity") could never be picked.
    return PopupMenuButton<int>(
      onSelected: (index) => onSelected(values[index]),
      tooltip: label,
      itemBuilder: (context) => [
        for (final (index, value) in values.indexed)
          PopupMenuItem<int>(value: index, child: Text(labelOf(value))),
      ],
      child: Chip(
        side: highlighted ? BorderSide(color: colors.primary) : null,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [Text(label), const Icon(Icons.arrow_drop_down, size: 18)],
        ),
      ),
    );
  }
}
