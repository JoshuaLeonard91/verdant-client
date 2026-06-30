import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verdant_flutter/features/workspace/server_settings_workspace/server_settings_emoji_tab.dart';
import 'package:verdant_flutter/features/workspace/server_settings_workspace/server_settings_models.dart';
import 'package:verdant_flutter/features/workspace/server_settings_workspace/server_settings_service.dart';
import 'package:verdant_flutter/features/workspace/server_settings_workspace/server_settings_stickers_tab.dart';
import 'package:verdant_flutter/theme/verdant_theme.dart';

void main() {
  testWidgets('emoji tab renames and deletes existing emoji', (tester) async {
    final repository = _FakeEmojiRepository();
    var changedEmojis = const <ServerSettingsListItemSeed>[];

    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerdantTheme(),
        home: Scaffold(
          body: ServerSettingsEmojiTab(
            serverId: 'server-1',
            emojis: const [
              ServerSettingsListItemSeed(
                id: 'emoji-1',
                title: ':old_wave:',
                subtitle: 'Created by Joshy',
                trailing: '2026-06-10',
              ),
            ],
            canManageServer: true,
            emojiRepository: repository,
            onEmojisChanged: (emojis) => changedEmojis = emojis,
          ),
        ),
      ),
    );

    expect(find.text('Emoji'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('server-emoji-upload-name-field')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('server-emoji-select-file-button')),
      findsOneWidget,
    );
    expect(find.text(':old_wave:'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('server-emoji-edit-emoji-1')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('server-emoji-name-field-emoji-1')),
      'wave',
    );
    await tester.tap(find.byKey(const ValueKey('server-emoji-save-emoji-1')));
    await tester.pumpAndSettle();

    expect(repository.renamed, [
      (serverId: 'server-1', emojiId: 'emoji-1', name: 'wave'),
    ]);
    expect(find.text(':wave:'), findsOneWidget);
    expect(changedEmojis.single.title, ':wave:');

    await tester.tap(find.byKey(const ValueKey('server-emoji-delete-emoji-1')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('server-emoji-delete-confirm-emoji-1')),
    );
    await tester.pumpAndSettle();

    expect(repository.deleted, [(serverId: 'server-1', emojiId: 'emoji-1')]);
    expect(find.text(':wave:'), findsNothing);
  });

  testWidgets('emoji upload shows a selected image preview before submit', (
    tester,
  ) async {
    final repository = _FakeEmojiRepository();

    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerdantTheme(),
        home: Scaffold(
          body: ServerSettingsEmojiTab(
            serverId: 'server-1',
            emojis: const [],
            canManageServer: true,
            emojiRepository: repository,
            emojiUploadPicker: () async => ServerEmojiUploadSelection(
              upload: const ServerSettingsUpload(
                path: 'C:/tmp/catslam.webp',
                fileName: 'catslam.webp',
              ),
              previewBytes: Uint8List.fromList(_pngBytes),
              sizeBytes: _pngBytes.length,
            ),
          ),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('server-emoji-upload-name-field')),
      'catslam',
    );
    await tester.tap(
      find.byKey(const ValueKey('server-emoji-select-file-button')),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('server-emoji-upload-preview-image')),
      findsOneWidget,
    );
    expect(find.text('catslam.webp'), findsOneWidget);
    expect(find.text('Animated'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('server-emoji-upload-button')));
    await tester.pumpAndSettle();

    expect(repository.uploaded, [
      (serverId: 'server-1', name: 'catslam', fileName: 'catslam.webp'),
    ]);
  });

  testWidgets('sticker tab uploads and lists server stickers', (tester) async {
    final repository = _FakeEmojiRepository();
    var changedStickers = const <ServerSettingsListItemSeed>[];

    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerdantTheme(),
        home: Scaffold(
          body: ServerSettingsStickersTab(
            serverId: 'server-1',
            stickers: const [
              ServerSettingsListItemSeed(
                id: 'sticker-1',
                title: ':bonk:',
                subtitle: 'Created by Joshy',
                trailing: '2026-06-10',
              ),
            ],
            canManageServer: true,
            stickerRepository: repository,
            stickerUploadPicker: () async => ServerStickerUploadSelection(
              upload: const ServerSettingsUpload(
                path: 'C:/tmp/smokoko.webp',
                fileName: 'smokoko.webp',
              ),
              previewBytes: Uint8List.fromList(_pngBytes),
              sizeBytes: _pngBytes.length,
            ),
            onStickersChanged: (stickers) => changedStickers = stickers,
          ),
        ),
      ),
    );

    expect(find.text('Stickers'), findsOneWidget);
    expect(find.text(':bonk:'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('server-sticker-upload-name-field')),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const ValueKey('server-sticker-upload-name-field')),
      'smokoko',
    );
    await tester.tap(
      find.byKey(const ValueKey('server-sticker-select-file-button')),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('server-sticker-upload-preview-image')),
      findsOneWidget,
    );
    expect(find.text('smokoko.webp'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('server-sticker-upload-button')),
    );
    await tester.pumpAndSettle();

    expect(repository.uploaded, [
      (serverId: 'server-1', name: 'smokoko', fileName: 'smokoko.webp'),
    ]);
    expect(changedStickers.last.title, ':smokoko:');
  });
}

final class _FakeEmojiRepository implements ServerSettingsEmojiRepository {
  final renamed = <({String serverId, String emojiId, String name})>[];
  final deleted = <({String serverId, String emojiId})>[];
  final uploaded = <({String serverId, String name, String fileName})>[];

  @override
  Future<ServerSettingsUploadPreview> loadEmojiUploadPreview({
    required ServerSettingsUpload upload,
  }) async {
    return ServerSettingsUploadPreview(
      previewBytes: Uint8List.fromList(_pngBytes),
      sizeBytes: _pngBytes.length,
    );
  }

  @override
  Future<ServerSettingsUploadPreview> loadStickerUploadPreview({
    required ServerSettingsUpload upload,
  }) async {
    return ServerSettingsUploadPreview(
      previewBytes: Uint8List.fromList(_pngBytes),
      sizeBytes: _pngBytes.length,
    );
  }

  @override
  Future<ServerSettingsListItemSeed> uploadEmoji({
    required String serverId,
    required String name,
    required ServerSettingsUpload upload,
  }) async {
    uploaded.add((serverId: serverId, name: name, fileName: upload.fileName));
    return ServerSettingsListItemSeed(
      id: 'emoji-uploaded',
      title: ':$name:',
      subtitle: 'Created by Joshy',
      trailing: '2026-06-10',
      avatarUrl: 'https://cdn.example.com/emojis/$name.webp',
    );
  }

  @override
  Future<ServerSettingsListItemSeed> uploadSticker({
    required String serverId,
    required String name,
    required ServerSettingsUpload upload,
  }) async {
    uploaded.add((serverId: serverId, name: name, fileName: upload.fileName));
    return ServerSettingsListItemSeed(
      id: 'sticker-uploaded',
      title: ':$name:',
      subtitle: 'Created by Joshy',
      trailing: '2026-06-10',
      avatarUrl: 'https://cdn.example.com/stickers/$name.webp',
    );
  }

  @override
  Future<ServerSettingsListItemSeed> renameEmoji({
    required String serverId,
    required String emojiId,
    required String name,
  }) async {
    renamed.add((serverId: serverId, emojiId: emojiId, name: name));
    return ServerSettingsListItemSeed(
      id: emojiId,
      title: ':$name:',
      subtitle: 'Created by Joshy',
      trailing: '2026-06-10',
    );
  }

  @override
  Future<ServerSettingsListItemSeed> renameSticker({
    required String serverId,
    required String stickerId,
    required String name,
  }) async {
    return ServerSettingsListItemSeed(
      id: stickerId,
      title: ':$name:',
      subtitle: 'Created by Joshy',
      trailing: '2026-06-10',
    );
  }

  @override
  Future<void> deleteEmoji({
    required String serverId,
    required String emojiId,
  }) async {
    deleted.add((serverId: serverId, emojiId: emojiId));
  }

  @override
  Future<void> deleteSticker({
    required String serverId,
    required String stickerId,
  }) async {}
}

const _pngBytes = <int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
];
