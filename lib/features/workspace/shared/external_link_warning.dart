import 'dart:async';

import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../theme/verdant_theme.dart';
import 'workspace_link_launcher.dart';

Future<void> openExternalLinkWithWarning({
  required BuildContext context,
  required Uri uri,
  required WorkspaceLinkLauncher linkLauncher,
}) async {
  final approved = await showExternalLinkWarning(context: context, uri: uri);
  if (!approved || !context.mounted) {
    return;
  }
  unawaited(linkLauncher.openExternal(uri));
}

Future<bool> showExternalLinkWarning({
  required BuildContext context,
  required Uri uri,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (context) => _ExternalLinkWarningDialog(uri: uri),
  );
  return result ?? false;
}

class _ExternalLinkWarningDialog extends StatelessWidget {
  const _ExternalLinkWarningDialog({required this.uri});

  final Uri uri;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final host = uri.host.toLowerCase();
    return AlertDialog(
      key: const ValueKey('external-link-warning-dialog'),
      backgroundColor: colors.panel,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colors.border),
      ),
      titlePadding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
      contentPadding: const EdgeInsets.fromLTRB(22, 12, 22, 4),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      title: Row(
        children: [
          Icon(
            PhosphorIcons.warningCircle,
            size: 21,
            color: colors.accentStrong,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'Open external link?',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This link opens outside Verdant. Only continue if you trust the destination.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colors.textMuted),
          ),
          const SizedBox(height: 14),
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.panelRaised,
              border: Border.all(color: colors.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    host.isEmpty ? 'External site' : host,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: VerdantFontWeights.black,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    uri.toString(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: colors.textMuted),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          key: const ValueKey('external-link-warning-cancel'),
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const ValueKey('external-link-warning-open'),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Open link'),
        ),
      ],
    );
  }
}
