import '../server_settings_workspace/server_media_url_policy.dart';

enum CustomExpressiveAssetKind { emoji, sticker }

const customExpressionImageExtensions = {'png', 'jpg', 'jpeg', 'gif', 'webp'};
const customEmojiMaxBytes = 256 * 1024;
const customStickerMaxBytes = 512 * 1024;

final _customExpressionNamePattern = RegExp(r'^[A-Za-z0-9_]{2,32}$');

extension CustomExpressiveAssetKindDetails on CustomExpressiveAssetKind {
  String get label => switch (this) {
    CustomExpressiveAssetKind.emoji => 'emoji',
    CustomExpressiveAssetKind.sticker => 'sticker',
  };

  String get titleLabel => switch (this) {
    CustomExpressiveAssetKind.emoji => 'Emoji',
    CustomExpressiveAssetKind.sticker => 'Sticker',
  };

  int get maxBytes => switch (this) {
    CustomExpressiveAssetKind.emoji => customEmojiMaxBytes,
    CustomExpressiveAssetKind.sticker => customStickerMaxBytes,
  };
}

class CustomExpressiveAsset {
  const CustomExpressiveAsset({
    required this.kind,
    required this.id,
    required this.name,
    required this.imageUrl,
    this.serverId,
    this.networkId,
    this.animated = false,
  });

  final CustomExpressiveAssetKind kind;
  final String id;
  final String name;
  final String imageUrl;
  final String? serverId;
  final String? networkId;
  final bool animated;

  String get shortcode => ':$name:';
}

final class ServerCustomEmoji extends CustomExpressiveAsset {
  const ServerCustomEmoji({
    required super.id,
    required super.name,
    required super.imageUrl,
    super.serverId,
    super.networkId,
    super.animated,
  }) : super(kind: CustomExpressiveAssetKind.emoji);
}

final class ServerCustomSticker extends CustomExpressiveAsset {
  const ServerCustomSticker({
    required super.id,
    required super.name,
    required super.imageUrl,
    super.serverId,
    super.networkId,
    super.animated,
  }) : super(kind: CustomExpressiveAssetKind.sticker);
}

final class ServerCustomEmojiGroup {
  const ServerCustomEmojiGroup({
    required this.serverId,
    required this.networkId,
    required this.label,
    required this.emojis,
    this.iconUrl,
    this.mediaPolicy,
  });

  final String serverId;
  final String networkId;
  final String label;
  final String? iconUrl;
  final List<ServerCustomEmoji> emojis;
  final ServerMediaPolicy? mediaPolicy;
}

final class ServerCustomStickerGroup {
  const ServerCustomStickerGroup({
    required this.serverId,
    required this.networkId,
    required this.label,
    required this.stickers,
    this.iconUrl,
    this.mediaPolicy,
  });

  final String serverId;
  final String networkId;
  final String label;
  final String? iconUrl;
  final List<ServerCustomSticker> stickers;
  final ServerMediaPolicy? mediaPolicy;
}

final class CustomExpressionSource {
  const CustomExpressionSource({
    required this.serverId,
    required this.networkId,
    required this.label,
    this.iconUrl,
    this.mediaPolicy,
  });

  final String serverId;
  final String networkId;
  final String label;
  final String? iconUrl;
  final ServerMediaPolicy? mediaPolicy;
}

String customExpressionSourceKey(CustomExpressiveAsset asset) {
  return customExpressionSourceKeyFor(
    kind: asset.kind,
    id: asset.id,
    name: asset.name,
    serverId: asset.serverId,
    networkId: asset.networkId,
  );
}

String customExpressionSourceKeyFor({
  required CustomExpressiveAssetKind kind,
  required String id,
  required String name,
  String? serverId,
  String? networkId,
}) {
  return [
    kind.name,
    networkId?.trim() ?? '',
    serverId?.trim() ?? '',
    id.trim(),
    normalizeCustomExpressionName(name).toLowerCase(),
  ].join('/');
}

String normalizeCustomEmojiName(String value) {
  return normalizeCustomExpressionName(value);
}

bool isValidCustomEmojiName(String value) {
  return isValidCustomExpressionName(value);
}

String? validateCustomEmojiName(String value) {
  return validateCustomExpressionName(
    kind: CustomExpressiveAssetKind.emoji,
    value: value,
  );
}

String normalizeCustomStickerName(String value) {
  return normalizeCustomExpressionName(value);
}

bool isValidCustomStickerName(String value) {
  return isValidCustomExpressionName(value);
}

String? validateCustomStickerName(String value) {
  return validateCustomExpressionName(
    kind: CustomExpressiveAssetKind.sticker,
    value: value,
  );
}

String normalizeCustomExpressionName(String value) {
  return value.trim().replaceAll(RegExp(r'^:+|:+$'), '');
}

bool isValidCustomExpressionName(String value) {
  return _customExpressionNamePattern.hasMatch(
    normalizeCustomExpressionName(value),
  );
}

String? validateCustomExpressionName({
  required CustomExpressiveAssetKind kind,
  required String value,
}) {
  final normalized = normalizeCustomExpressionName(value);
  if (normalized.isEmpty) {
    return '${kind.titleLabel} name is required.';
  }
  if (!_customExpressionNamePattern.hasMatch(normalized)) {
    return 'Use 2-32 letters, numbers, or underscores.';
  }
  return null;
}

int customExpressionMaxBytes(CustomExpressiveAssetKind kind) {
  return kind.maxBytes;
}

bool isCustomExpressionImageFileName(String fileName) {
  final extension = customExpressionFileExtension(fileName);
  return extension != null &&
      customExpressionImageExtensions.contains(extension);
}

bool isAnimatedCustomExpressionImageUrl(String value) {
  final path = value.split('#').first.split('?').first;
  final extension = customExpressionFileExtension(path);
  return extension == 'gif' || extension == 'webp';
}

String? customExpressionFileExtension(String fileName) {
  final trimmed = fileName.trim().toLowerCase();
  final dot = trimmed.lastIndexOf('.');
  if (dot < 0 || dot == trimmed.length - 1) {
    return null;
  }
  return trimmed.substring(dot + 1);
}
