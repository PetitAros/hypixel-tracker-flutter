import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/bazaar_item.dart';
import '../../domain/entities/bazaar_snapshot.dart';
import '../../domain/repositories/bazaar_repository.dart';
import 'bazaar_controller.dart';

class BazaarPage extends StatefulWidget {
  const BazaarPage({super.key, required this.repository});

  final BazaarRepository repository;

  @override
  State<BazaarPage> createState() => _BazaarPageState();
}

class _BazaarPageState extends State<BazaarPage> {
  late final BazaarController _controller;

  @override
  void initState() {
    super.initState();
    _controller = BazaarController(widget.repository)..load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bazaar')),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) => switch (_controller.state) {
          BazaarLoading() => const Center(child: CircularProgressIndicator()),
          BazaarEmpty() => const _Message(text: 'No bazaar items to show.'),
          BazaarError() => _Message(
            text: 'Could not load the bazaar. Check your connection.',
            onRetry: _controller.load,
          ),
          BazaarData(:final snapshot, :final sync) => Column(
            children: [
              _StatusBar(snapshot: snapshot, sync: sync),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _controller.load,
                  child: _BazaarList(snapshot: snapshot),
                ),
              ),
            ],
          ),
        },
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, this.onRetry});

  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.md),
              ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}

// Stays pinned above the list: refresh in progress, last update, or offline.
class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.snapshot, required this.sync});

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
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: color),
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

class _BazaarList extends StatelessWidget {
  const _BazaarList({required this.snapshot});

  final BazaarSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      // Keeps pull-to-refresh working when the list is shorter than the screen.
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      itemCount: snapshot.items.length,
      itemBuilder: (context, index) =>
          _BazaarItemCard(item: snapshot.items[index]),
    );
  }
}

class _BazaarItemCard extends StatelessWidget {
  const _BazaarItemCard({required this.item});

  final BazaarItem item;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.displayName,
                    style: textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Weekly volume ${Formatters.compact(item.weeklyVolume)}',
                    style: textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Buy ${Formatters.compact(item.buyPrice)}',
                  style: textTheme.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Sell ${Formatters.compact(item.sellPrice)}',
                  style: textTheme.bodyMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
