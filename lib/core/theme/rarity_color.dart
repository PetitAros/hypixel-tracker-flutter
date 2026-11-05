import 'package:flutter/material.dart';
import 'package:hypixel_tracker/core/theme/app_theme.dart';

// Colour of a SkyBlock rarity, from Hypixel's raw tier, e.g. "LEGENDARY".
// Common is white in the game: it follows the text colour instead, so it
// stays readable on the light theme.
Color rarityColor(BuildContext context, String tier) => switch (tier) {
  'COMMON' => context.palette.onBackground,
  'UNCOMMON' => AppColors.rarityUncommon,
  'RARE' => AppColors.rarityRare,
  'EPIC' => AppColors.rarityEpic,
  'LEGENDARY' => AppColors.rarityLegendary,
  'MYTHIC' => AppColors.rarityMythic,
  'DIVINE' => AppColors.rarityDivine,
  'SPECIAL' || 'VERY_SPECIAL' => AppColors.raritySpecial,
  _ => context.palette.onSurfaceMuted,
};
