import 'package:flutter/material.dart';
import 'package:hypixel_tracker/core/theme/app_theme.dart';
import 'package:hypixel_tracker/core/utils/formatters.dart';
import 'package:hypixel_tracker/domain/entities/player_profiles.dart';

// One card listing every skill with its level and progress bar.
class SkillsSection extends StatelessWidget {
  const SkillsSection({super.key, required this.skills});

  final List<SkillProgress> skills;

  static const _icons = {
    'Farming': Icons.agriculture,
    'Mining': Icons.hardware,
    'Combat': Icons.shield,
    'Foraging': Icons.forest,
    'Fishing': Icons.phishing,
    'Enchanting': Icons.auto_fix_high,
    'Alchemy': Icons.science,
    'Taming': Icons.pets,
    'Carpentry': Icons.carpenter,
    'Runecrafting': Icons.auto_awesome,
    'Social': Icons.groups,
  };

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          spacing: AppSpacing.md,
          children: [
            for (final skill in skills)
              _SkillRow(
                skill: skill,
                icon: _icons[skill.name] ?? Icons.star_outline,
              ),
          ],
        ),
      ),
    );
  }
}

class _SkillRow extends StatelessWidget {
  const _SkillRow({required this.skill, required this.icon});

  final SkillProgress skill;
  final IconData icon;

  static const _barHeight = 6.0;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final maxed = skill.level >= skill.maxLevel;

    return Row(
      children: [
        Icon(icon, color: maxed ? AppColors.gold : AppColors.onSurfaceMuted),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(skill.name, style: textTheme.titleMedium),
                  ),
                  Text(
                    maxed
                        ? 'Level ${skill.level} (max)'
                        : 'Level ${skill.level}',
                    style: textTheme.bodyLarge,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              LinearProgressIndicator(
                value: skill.progress,
                minHeight: _barHeight,
                borderRadius: AppRadius.sm,
                backgroundColor: AppColors.surface,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${Formatters.compact(skill.experience)} XP',
                style: textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
