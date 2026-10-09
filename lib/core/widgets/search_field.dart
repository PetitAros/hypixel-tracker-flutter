import 'package:flutter/material.dart';
import 'package:hypixel_tracker/core/theme/app_theme.dart';

// A search box sized to sit in the bottom slot of a FadingAppBar,
// with a clear button once something is typed.
class SearchField extends StatelessWidget implements PreferredSizeWidget {
  const SearchField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    this.icon = Icons.search,
  });

  final TextEditingController controller;
  final String hintText;

  /// Also called with an empty string when the field is cleared.
  final ValueChanged<String> onChanged;
  final IconData icon;

  static const height = 56.0;

  @override
  Size get preferredSize => const Size.fromHeight(height);

  void _clear() {
    controller.clear();
    onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: SizedBox(
        height: height,
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          autocorrect: false,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: Icon(icon),
            suffixIcon: ListenableBuilder(
              listenable: controller,
              builder: (context, _) => controller.text.isEmpty
                  ? const SizedBox.shrink()
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      tooltip: 'Clear',
                      onPressed: _clear,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
