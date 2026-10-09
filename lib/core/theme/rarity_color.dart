import 'package:flutter/material.dart';
import 'package:hypixel_tracker/core/theme/app_theme.dart';

// Colour of a SkyBlock rarity, from Hypixel's raw tier, e.g. "LEGENDARY".
Color rarityColor(String tier) => switch (tier) {
  'COMMON' => AppColors.rarityCommon,
  'UNCOMMON' => AppColors.rarityUncommon,
  'RARE' => AppColors.rarityRare,
  'EPIC' => AppColors.rarityEpic,
  'LEGENDARY' => AppColors.rarityLegendary,
  'MYTHIC' => AppColors.rarityMythic,
  'DIVINE' => AppColors.rarityDivine,
  'SPECIAL' || 'VERY_SPECIAL' => AppColors.raritySpecial,
  _ => AppColors.onSurfaceMuted,
};
