import 'package:flutter/material.dart';
import 'package:hypixel_tracker/core/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

// The attribution SkyCofl asks for on every page showing their data:
// a link to the item page when there is one, to their data page otherwise.
// https://sky.coflnet.com/wiki/api#attribution
const _host = 'sky.coflnet.com';

Future<void> _openCoflnet(BuildContext context, String? itemTag) async {
  final messenger = ScaffoldMessenger.of(context);
  final uri = Uri.https(_host, itemTag == null ? '/data' : '/item/$itemTag');

  var opened = false;
  try {
    opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    // Reported below, like a refused launch.
  }
  if (!opened) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Could not open $_host')),
    );
  }
}

// The credit as a band at the bottom of a page.
class CoflnetCredit extends StatelessWidget {
  const CoflnetCredit({super.key, this.itemTag});

  final String? itemTag;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: AppColors.onSurfaceMuted,
      decoration: TextDecoration.underline,
      decorationColor: AppColors.onSurfaceMuted,
    );

    return Material(
      color: AppColors.surfaceVariant,
      child: InkWell(
        onTap: () => _openCoflnet(context, itemTag),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  itemTag == null
                      ? 'Data provided by SkyCofl'
                      : 'Prices provided by SkyCofl',
                  style: style,
                ),
                const SizedBox(width: AppSpacing.xs),
                const Icon(
                  Icons.open_in_new,
                  size: 14,
                  color: AppColors.onSurfaceMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// The credit as an app bar action, for pages whose bottom is taken.
class CoflnetCreditButton extends StatelessWidget {
  const CoflnetCreditButton({super.key});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => _openCoflnet(context, null),
      style: TextButton.styleFrom(foregroundColor: AppColors.onSurfaceMuted),
      icon: const Icon(Icons.open_in_new, size: 14),
      iconAlignment: IconAlignment.end,
      label: const Text('Data by SkyCofl'),
    );
  }
}
