import 'package:flutter/material.dart';
import 'package:hypixel_tracker/core/theme/app_theme.dart';
import 'package:hypixel_tracker/domain/entities/player_profiles.dart';
import 'package:hypixel_tracker/domain/repositories/player_repository.dart';
import 'package:hypixel_tracker/features/profile/widgets/collections_section.dart';
import 'package:hypixel_tracker/features/profile/widgets/player_model.dart';
import 'package:hypixel_tracker/features/profile/widgets/skills_section.dart';

// The followed player's progress: who they are, their skills, their
// collections.
class ProfileDashboard extends StatelessWidget {
  const ProfileDashboard({
    super.key,
    required this.profile,
    required this.repository,
  });

  final PlayerProfile profile;
  final PlayerRepository repository; // for the skin

  @override
  Widget build(BuildContext context) {
    // Starts below the app bar and ends above the navigation bar.
    final inset = MediaQuery.paddingOf(context);

    return ListView(
      padding: EdgeInsets.only(
        top: inset.top + AppSpacing.sm,
        bottom: inset.bottom + AppSpacing.sm,
      ),
      children: [
        _Header(profile: profile, repository: repository),
        const _SectionTitle('Skills'),
        SkillsSection(skills: profile.skills),
        const _SectionTitle('Collections'),
        CollectionsSection(
          playerName: profile.player.name,
          collections: profile.collections,
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.profile, required this.repository});

  final PlayerProfile profile;
  final PlayerRepository repository;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            PlayerModel(player: profile.player, repository: repository),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.player.name,
                    style: textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Profile ${profile.profileName}',
                    style: textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Skill average '
                    '${profile.skillAverage.toStringAsFixed(1)}',
                    style: textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            // The numbers may be out of date.
            if (profile.fromCache) const Chip(label: Text('Offline')),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: Text(text, style: Theme.of(context).textTheme.headlineMedium),
    );
  }
}
