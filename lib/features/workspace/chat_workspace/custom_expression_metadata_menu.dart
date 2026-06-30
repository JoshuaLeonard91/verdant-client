import 'dart:async';

import 'package:flutter/material.dart';

import '../../../theme/verdant_theme.dart';
import '../server_settings_workspace/server_media_url_policy.dart';
import '../shared/custom_expressive_asset.dart';
import '../shared/user_context_menu.dart';
import 'custom_expression_server_icon.dart';

void showCustomExpressionMetadataMenu({
  required BuildContext context,
  required Offset globalPosition,
  required CustomExpressiveAsset asset,
  required ServerMediaPolicy mediaPolicy,
  required String itemKey,
  CustomExpressionSource? source,
}) {
  final effectiveSource = source;
  final effectiveMediaPolicy = effectiveSource?.mediaPolicy ?? mediaPolicy;
  unawaited(
    showWorkspaceUserContextMenu(
      context: context,
      globalPosition: globalPosition,
      entries: [
        WorkspaceUserContextMenuCustom(
          estimatedHeight: 78,
          child: CustomExpressionInfoMenu(
            itemKey: itemKey,
            shortcode: asset.shortcode,
            serverLabel: safeCustomExpressionServerLabel(
              effectiveSource?.label,
            ),
            serverIconUrl: effectiveSource?.iconUrl,
            mediaPolicy: effectiveMediaPolicy,
          ),
        ),
      ],
    ),
  );
}

class CustomExpressionInfoMenu extends StatelessWidget {
  const CustomExpressionInfoMenu({
    required this.itemKey,
    required this.shortcode,
    required this.serverLabel,
    required this.mediaPolicy,
    this.serverIconUrl,
    super.key,
  });

  final String itemKey;
  final String shortcode;
  final String serverLabel;
  final String? serverIconUrl;
  final ServerMediaPolicy mediaPolicy;

  @override
  Widget build(BuildContext context) {
    final iconUri = serverIconUrl == null
        ? null
        : safeServerMediaUri(serverIconUrl!, policy: mediaPolicy);
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 190, maxWidth: 240),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(
              shortcode,
              key: ValueKey('custom-expression-context-shortcode-$itemKey'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: VerdantColors.text,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 9),
            Row(
              key: ValueKey('custom-expression-context-server-$itemKey'),
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomExpressionServerIcon(
                  uri: iconUri,
                  label: serverLabel,
                  mediaPolicy: mediaPolicy,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    serverLabel,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: VerdantColors.textMuted,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
