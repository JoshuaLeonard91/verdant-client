import 'package:flutter/material.dart';

import '../../../theme/verdant_theme.dart';
import '../server_settings_workspace/server_media_image.dart';
import '../server_settings_workspace/server_media_url_policy.dart';

String safeCustomExpressionServerLabel(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return 'Unknown server';
  }
  return trimmed;
}

class CustomExpressionServerIcon extends StatelessWidget {
  const CustomExpressionServerIcon({
    required this.uri,
    required this.label,
    required this.mediaPolicy,
    this.size = 24,
    super.key,
  });

  final Uri? uri;
  final String label;
  final ServerMediaPolicy mediaPolicy;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fallback = CustomExpressionServerIconFallback(
      label: label,
      size: size,
    );
    if (uri == null) {
      return fallback;
    }
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(4)),
      child: SizedBox.square(
        dimension: size,
        child: SafeServerMediaImage(
          uri: uri!,
          policy: mediaPolicy,
          surface: ServerMediaSurface.serverIcon,
          fallback: fallback,
          builder: (context, imageProvider) => Image(
            image: imageProvider,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            filterQuality: FilterQuality.medium,
            semanticLabel: label,
          ),
        ),
      ),
    );
  }
}

class CustomExpressionServerIconFallback extends StatelessWidget {
  const CustomExpressionServerIconFallback({
    required this.label,
    this.size = 24,
    super.key,
  });

  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    final trimmed = label.trim();
    final initial = trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: VerdantColors.actionMuted,
        borderRadius: const BorderRadius.all(Radius.circular(4)),
        border: Border.all(color: VerdantColors.border),
      ),
      child: SizedBox.square(
        dimension: size,
        child: Center(
          child: Text(
            initial,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: VerdantColors.accentStrong,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}
