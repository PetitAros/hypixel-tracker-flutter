import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/bazaar_snapshot.dart';
import '../bazaar_controller.dart';

// Stays pinned above the list: refresh in progress, last update, or offline.
class BazaarStatusBar extends StatelessWidget {
  const BazaarStatusBar({
    super.key,
    required this.snapshot,
    required this.sync,
  });

  final BazaarSnapshot snapshot;
  final BazaarSync sync;

  @override
  Widget build(BuildContext context) {
    final updated = Formatters.dateTime(snapshot.lastUpdated);
    final offline = sync == BazaarSync.offline;
    final color = offline ? AppColors.warning : AppColors.onSurfaceMuted;

    return Material(
      color: AppColors.surfaceVariant,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Icon(
                  switch (sync) {
                    BazaarSync.refreshing => Icons.sync,
                    BazaarSync.upToDate => Icons.check_circle_outline,
                    BazaarSync.offline => Icons.cloud_off,
                  },
                  size: 16,
                  color: color,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    switch (sync) {
                      BazaarSync.refreshing =>
                        'Refreshing. Showing data from $updated',
                      BazaarSync.upToDate => 'Updated $updated',
                      BazaarSync.offline =>
                        'Offline. Showing saved data from $updated',
                    },
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: color),
                  ),
                ),
              ],
            ),
          ),
          // Fixed height so the list does not jump when the refresh ends.
          SizedBox(
            height: 2,
            child: sync == BazaarSync.refreshing
                ? const LinearProgressIndicator(minHeight: 2)
                : null,
          ),
        ],
      ),
    );
  }
}
