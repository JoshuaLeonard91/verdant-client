import '../server_settings_workspace/server_settings_models.dart';
import '../server_settings_workspace/server_media_url_policy.dart';
import '../shared/custom_expressive_asset.dart';
import '../workspace_local_id.dart';

List<ServerCustomEmoji> serverCustomEmojisFromSettings(
  ServerSettingsSeed settings,
) {
  final emojis = <ServerCustomEmoji>[];
  final seen = <String>{};
  for (final item in settings.emojis) {
    final id = item.id?.trim();
    final imageUrl = item.avatarUrl?.trim();
    final name = normalizeCustomEmojiName(item.title);
    if (id == null ||
        id.isEmpty ||
        imageUrl == null ||
        imageUrl.isEmpty ||
        !isValidCustomEmojiName(name)) {
      continue;
    }
    final String localId;
    try {
      localId = safeWorkspaceLocalId(id, allowScopedPrefix: true);
    } on FormatException {
      continue;
    }
    final key = '${settings.networkId}/$localId/${name.toLowerCase()}';
    if (!seen.add(key)) {
      continue;
    }
    emojis.add(
      ServerCustomEmoji(
        id: localId,
        name: name,
        imageUrl: imageUrl,
        serverId: settings.localServerId,
        networkId: settings.networkId,
        animated: isAnimatedCustomExpressionImageUrl(imageUrl),
      ),
    );
  }
  return List.unmodifiable(emojis);
}

List<ServerCustomSticker> serverCustomStickersFromSettings(
  ServerSettingsSeed settings,
) {
  final stickers = <ServerCustomSticker>[];
  final seen = <String>{};
  for (final item in settings.stickers) {
    final id = item.id?.trim();
    final imageUrl = item.avatarUrl?.trim();
    final name = normalizeCustomStickerName(item.title);
    if (id == null ||
        id.isEmpty ||
        imageUrl == null ||
        imageUrl.isEmpty ||
        !isValidCustomStickerName(name)) {
      continue;
    }
    final String localId;
    try {
      localId = safeWorkspaceLocalId(id, allowScopedPrefix: true);
    } on FormatException {
      continue;
    }
    final key = '${settings.networkId}/$localId/${name.toLowerCase()}';
    if (!seen.add(key)) {
      continue;
    }
    stickers.add(
      ServerCustomSticker(
        id: localId,
        name: name,
        imageUrl: imageUrl,
        serverId: settings.localServerId,
        networkId: settings.networkId,
        animated: isAnimatedCustomExpressionImageUrl(imageUrl),
      ),
    );
  }
  return List.unmodifiable(stickers);
}

List<ServerCustomEmojiGroup> serverCustomEmojiGroupsFromSettings(
  ServerSettingsSeed settings, {
  ServerMediaPolicy? mediaPolicy,
}) {
  final emojis = serverCustomEmojisFromSettings(settings);
  if (emojis.isEmpty) {
    return const [];
  }
  return [
    ServerCustomEmojiGroup(
      serverId: settings.localServerId,
      networkId: settings.networkId,
      label: settings.serverName,
      emojis: emojis,
      mediaPolicy: mediaPolicy,
    ),
  ];
}

List<ServerCustomStickerGroup> serverCustomStickerGroupsFromSettings(
  ServerSettingsSeed settings, {
  ServerMediaPolicy? mediaPolicy,
}) {
  final stickers = serverCustomStickersFromSettings(settings);
  if (stickers.isEmpty) {
    return const [];
  }
  return [
    ServerCustomStickerGroup(
      serverId: settings.localServerId,
      networkId: settings.networkId,
      label: settings.serverName,
      stickers: stickers,
      mediaPolicy: mediaPolicy,
    ),
  ];
}

ServerCustomEmoji? resolveServerCustomEmoji(
  String value,
  List<ServerCustomEmoji> emojis,
) {
  final normalized = normalizeCustomEmojiName(value).toLowerCase();
  if (normalized.isEmpty || emojis.isEmpty) {
    return null;
  }
  final localId = _localEmojiIdOrNull(value);
  for (final emoji in emojis) {
    if (emoji.name.toLowerCase() == normalized) {
      return emoji;
    }
    if (localId != null && emoji.id == localId) {
      return emoji;
    }
  }
  return null;
}

ServerCustomSticker? resolveServerCustomSticker(
  String value,
  List<ServerCustomSticker> stickers,
) {
  final normalized = normalizeCustomStickerName(value).toLowerCase();
  if (normalized.isEmpty || stickers.isEmpty) {
    return null;
  }
  final localId = _localEmojiIdOrNull(value);
  for (final sticker in stickers) {
    if (sticker.name.toLowerCase() == normalized) {
      return sticker;
    }
    if (localId != null && sticker.id == localId) {
      return sticker;
    }
  }
  return null;
}

String? _localEmojiIdOrNull(String value) {
  try {
    return safeWorkspaceLocalId(value, allowScopedPrefix: true);
  } on FormatException {
    return null;
  }
}
