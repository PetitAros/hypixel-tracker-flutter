import 'package:flutter/material.dart';
import 'package:hypixel_tracker/core/theme/app_theme.dart';

// A 3D render of a player's head, with an icon when it cannot be loaded.
class PlayerHead extends StatelessWidget {
  const PlayerHead({super.key, required this.uuid, this.size = 64});

  final String uuid;
  final double size;

  // 128 px wide: twice the default size, so it stays sharp on dense screens.
  // Visage rather than mc-heads, which serves the default Steve head for
  // some accounts that do have a skin.
  static String _url(String uuid) =>
      'https://visage.surgeplay.com/head/128/$uuid';

  @override
  Widget build(BuildContext context) {
    return Image.network(
      _url(uuid),
      width: size,
      height: size,
      errorBuilder: (context, error, stackTrace) =>
          Icon(Icons.account_circle, size: size, color: AppColors.gold),
    );
  }
}
