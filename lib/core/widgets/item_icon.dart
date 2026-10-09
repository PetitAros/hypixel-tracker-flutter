import 'package:flutter/material.dart';
import 'package:hypixel_tracker/core/theme/app_theme.dart';

// The texture of a SkyBlock item, with a plain icon while it loads,
// when it fails, or when there is no url.
class ItemIcon extends StatelessWidget {
  const ItemIcon({
    super.key,
    required this.url,
    this.size = 32,
    this.fallback = Icons.inventory_2_outlined,
  });

  final String? url;
  final double size;
  final IconData fallback;

  @override
  Widget build(BuildContext context) {
    final url = this.url;
    final placeholder = Icon(
      fallback,
      size: size,
      color: AppColors.onSurfaceMuted,
    );
    if (url == null) return placeholder;

    // Decode at the displayed size: thousands of rows share the image cache.
    final cacheSize = (size * MediaQuery.devicePixelRatioOf(context)).round();

    return Image.network(
      url,
      width: size,
      height: size,
      cacheWidth: cacheSize,
      // Textures are pixel art: keep the pixels sharp when scaled up.
      filterQuality: FilterQuality.none,
      errorBuilder: (context, error, stackTrace) => placeholder,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) =>
          frame == null ? placeholder : child,
    );
  }
}
