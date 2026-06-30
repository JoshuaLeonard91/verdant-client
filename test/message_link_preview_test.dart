import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verdant_flutter/app/window_focus_scope.dart';
import 'package:verdant_flutter/features/workspace/chat_workspace/announcement_feed/announcement_link_launcher.dart';
import 'package:verdant_flutter/features/workspace/chat_workspace/link_preview_service.dart';
import 'package:verdant_flutter/features/workspace/chat_workspace/message_item.dart';
import 'package:verdant_flutter/features/workspace/chat_workspace/message_link_preview.dart';
import 'package:verdant_flutter/features/workspace/server_settings_workspace/server_media_url_policy.dart';
import 'package:verdant_flutter/features/workspace/workspace_seed.dart';
import 'package:verdant_flutter/theme/verdant_theme.dart';

void main() {
  setUp(debugResetMessageLinkPreviewAutoLoadGate);
  tearDown(debugResetMessageLinkPreviewAutoLoadGate);

  test('extracts safe generic and YouTube link previews', () {
    final previews = extractMessageLinkPreviews(
      'Read https://example.com/releases and watch '
      'https://www.youtube.com/watch?v=k1_ODDevbY8.',
    );

    expect(previews, hasLength(2));
    expect(previews.first.kind, MessageLinkPreviewKind.generic);
    expect(previews.first.hostLabel, 'example.com');
    expect(previews.last.kind, MessageLinkPreviewKind.youtube);
    expect(previews.last.youtubeEmbed?.videoId, 'k1_ODDevbY8');
  });

  test('dedupes, caps, and rejects unsafe preview URLs', () {
    final previews = extractMessageLinkPreviews(
      'x https://example.com/a https://example.com/a '
      'https://user:pass@example.com/secret '
      'https://localhost/admin '
      'https://192.168.1.3/router '
      'https://example.net/b '
      'https://example.org/c '
      'https://example.dev/d',
    );

    expect(previews.map((preview) => preview.uri.toString()), [
      'https://example.com/a',
      'https://example.net/b',
      'https://example.org/c',
    ]);
  });

  test('removes rendered preview URLs from the message body', () {
    final body =
        'Watch this https://www.youtube.com/watch?v=k1_ODDevbY8 and read '
        'https://example.com/releases.';
    final previews = extractMessageLinkPreviews(body);

    expect(
      removePreviewedLinksFromMessageBody(body, previews),
      'Watch this and read',
    );
  });

  testWidgets('generic link preview opens through warning-approved launcher', (
    tester,
  ) async {
    final launcher = _RecordingLinkLauncher();
    final previewService = _FakeMessageLinkPreviewService(
      metadata: MessageLinkPreviewMetadata(
        url: Uri.parse('https://example.com/release'),
        title: 'Release notes',
        description: 'A compact page preview.',
        siteName: 'Example Docs',
        imageProxyUrl:
            '/api/link-previews/image?url=https%3A%2F%2Fexample.com%2Fcard.png',
      ),
      imageBytes: _onePixelPng,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerdantTheme(),
        home: Scaffold(
          body: MessageLinkPreviews(
            messageId: 'official/message-link-preview',
            previews: extractMessageLinkPreviews('https://example.com/release'),
            linkPreviewService: previewService,
            linkLauncher: launcher,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(previewService.previewLoads, 1);
    expect(find.text('Release notes'), findsOneWidget);
    expect(find.text('A compact page preview.'), findsOneWidget);
    expect(find.text('Example Docs'), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey(
          'message-link-preview-image-https://example.com/release',
        ),
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(
        const ValueKey(
          'message-link-preview-generic-official/message-link-preview-0',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('external-link-warning-dialog')),
      findsOneWidget,
    );
    expect(launcher.opened, isEmpty);

    await tester.tap(find.byKey(const ValueKey('external-link-warning-open')));
    await tester.pumpAndSettle();

    expect(launcher.opened, [Uri.parse('https://example.com/release')]);
  });

  testWidgets('failed generic previews stay stable across focus changes', (
    tester,
  ) async {
    final uri = Uri.parse('https://github.com/verdant/release');
    final previewService = _FakeMessageLinkPreviewService();

    Widget buildPane({required bool focused}) {
      return MaterialApp(
        theme: buildVerdantTheme(),
        home: WindowFocusScope(
          focused: focused,
          child: Scaffold(
            body: MessageLinkPreviews(
              messageId: 'official/message-link-preview-failed',
              previews: [
                MessageLinkPreviewData(
                  kind: MessageLinkPreviewKind.generic,
                  uri: uri,
                ),
              ],
              linkPreviewService: previewService,
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildPane(focused: true));
    await tester.pumpAndSettle();

    expect(previewService.previewLoads, 1);
    expect(
      find.text('Preview unavailable. You can still open this link.'),
      findsNothing,
    );
    expect(find.text(uri.toString()), findsOneWidget);
    expect(find.text('Open with warning'), findsNothing);

    await tester.pumpWidget(buildPane(focused: false));
    await tester.pumpAndSettle();
    await tester.pumpWidget(buildPane(focused: true));
    await tester.pumpAndSettle();

    expect(previewService.previewLoads, 1);
    expect(find.text(uri.toString()), findsOneWidget);
  });

  testWidgets('automatic generic previews dedupe duplicate URL loads', (
    tester,
  ) async {
    final uri = Uri.parse('https://example.com/release');
    final previewService = _DelayedMessageLinkPreviewService();

    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerdantTheme(),
        home: Scaffold(
          body: Column(
            children: [
              MessageLinkPreviews(
                messageId: 'official/message-link-preview-a',
                previews: [
                  MessageLinkPreviewData(
                    kind: MessageLinkPreviewKind.generic,
                    uri: uri,
                  ),
                ],
                linkPreviewService: previewService,
              ),
              MessageLinkPreviews(
                messageId: 'official/message-link-preview-b',
                previews: [
                  MessageLinkPreviewData(
                    kind: MessageLinkPreviewKind.generic,
                    uri: uri,
                  ),
                ],
                linkPreviewService: previewService,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(previewService.previewLoads, 1);
    expect(previewService.activeLoads, [uri]);

    previewService.completePreview(
      uri,
      _metadataFor(
        uri,
        title: 'Shared link',
        imageProxyUrl:
            '/api/link-previews/image?url=https%3A%2F%2Fexample.com%2Fcard.png',
      ),
    );
    await tester.pumpAndSettle();

    expect(previewService.imageLoads, 1);
    expect(find.text('Shared link'), findsNWidgets(2));
  });

  testWidgets('automatic generic previews keep cache entries network scoped', (
    tester,
  ) async {
    final uri = Uri.parse('https://example.com/release');
    final officialService = _FakeMessageLinkPreviewService(
      metadata: _metadataFor(uri, title: 'Official preview'),
    );
    final selfHostService = _FakeMessageLinkPreviewService(
      metadata: _metadataFor(uri, title: 'Self-host preview'),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerdantTheme(),
        home: Scaffold(
          body: Column(
            children: [
              MessageLinkPreviews(
                messageId: 'official/message-link-preview',
                cacheScope: 'origin:https%3A%2F%2Fapi.verdant.chat',
                previews: [
                  MessageLinkPreviewData(
                    kind: MessageLinkPreviewKind.generic,
                    uri: uri,
                  ),
                ],
                linkPreviewService: officialService,
              ),
              MessageLinkPreviews(
                messageId: 'selfhost/message-link-preview',
                cacheScope: 'origin:https%3A%2F%2Fselfhost.example',
                previews: [
                  MessageLinkPreviewData(
                    kind: MessageLinkPreviewKind.generic,
                    uri: uri,
                  ),
                ],
                linkPreviewService: selfHostService,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(officialService.previewLoads, 1);
    expect(selfHostService.previewLoads, 1);
    expect(find.text('Official preview'), findsOneWidget);
    expect(find.text('Self-host preview'), findsOneWidget);
  });

  testWidgets('automatic generic previews retain cache entries within ttl', (
    tester,
  ) async {
    final clock = _FakeClock(DateTime.utc(2026, 6, 14));
    debugConfigureMessageLinkPreviewAutoLoadGate(
      clock: clock.now,
      cacheTtl: const Duration(minutes: 3),
    );
    final uri = Uri.parse('https://example.com/release');
    final previewService = _FakeMessageLinkPreviewService(
      metadata: _metadataFor(
        uri,
        title: 'Release preview',
        imageProxyUrl:
            '/api/link-previews/image?url=https%3A%2F%2Fcdn.example%2Fcard.png',
      ),
      imageBytes: _onePixelPng,
    );

    Widget buildPreview(String messageId) {
      return MaterialApp(
        theme: buildVerdantTheme(),
        home: Scaffold(
          body: MessageLinkPreviews(
            messageId: messageId,
            cacheScope: 'origin:https%3A%2F%2Fapi.verdant.chat',
            previews: [
              MessageLinkPreviewData(
                kind: MessageLinkPreviewKind.generic,
                uri: uri,
              ),
            ],
            linkPreviewService: previewService,
          ),
        ),
      );
    }

    await tester.pumpWidget(buildPreview('message-a'));
    await tester.pumpAndSettle();
    expect(previewService.previewLoads, 1);
    expect(previewService.imageLoads, 1);

    await tester.pumpWidget(
      MaterialApp(theme: buildVerdantTheme(), home: const SizedBox.shrink()),
    );
    await tester.pumpAndSettle();
    clock.advance(const Duration(minutes: 2));
    await tester.pumpWidget(buildPreview('message-b'));
    await tester.pumpAndSettle();

    expect(previewService.previewLoads, 1);
    expect(previewService.imageLoads, 1);

    await tester.pumpWidget(
      MaterialApp(theme: buildVerdantTheme(), home: const SizedBox.shrink()),
    );
    await tester.pumpAndSettle();
    clock.advance(const Duration(minutes: 4));
    await tester.pumpWidget(buildPreview('message-c'));
    await tester.pumpAndSettle();

    expect(previewService.previewLoads, 2);
    expect(previewService.imageLoads, 2);
  });

  testWidgets('automatic generic preview image cache evicts older entries', (
    tester,
  ) async {
    final uris = [
      for (var index = 0; index < 70; index += 1)
        Uri.parse('https://example.com/release-$index'),
    ];
    final imageUrls = [
      for (var index = 0; index < uris.length; index += 1)
        '/api/link-previews/image?url=https%3A%2F%2Fcdn.example%2Fcard-$index.png',
    ];
    final previewService = _FakeMessageLinkPreviewService(
      metadataByUri: {
        for (var index = 0; index < uris.length; index += 1)
          uris[index]: _metadataFor(
            uris[index],
            title: 'Preview $index',
            imageProxyUrl: imageUrls[index],
          ),
      },
      imageBytes: _onePixelPng,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerdantTheme(),
        home: Scaffold(
          body: SizedBox(
            width: 700,
            height: 600,
            child: SingleChildScrollView(
              child: MessageLinkPreviews(
                messageId: 'official/message-link-preview-eviction',
                cacheScope: 'origin:https%3A%2F%2Fapi.verdant.chat',
                previews: [
                  for (final uri in uris.take(49))
                    MessageLinkPreviewData(
                      kind: MessageLinkPreviewKind.generic,
                      uri: uri,
                    ),
                ],
                linkPreviewService: previewService,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(previewService.imageLoads, 49);

    await tester.pumpWidget(
      MaterialApp(theme: buildVerdantTheme(), home: const SizedBox.shrink()),
    );
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerdantTheme(),
        home: Scaffold(
          body: SizedBox(
            width: 700,
            height: 600,
            child: SingleChildScrollView(
              child: MessageLinkPreviews(
                messageId: 'official/message-link-preview-eviction-second',
                cacheScope: 'origin:https%3A%2F%2Fapi.verdant.chat',
                previews: [
                  for (final uri in uris.skip(49))
                    MessageLinkPreviewData(
                      kind: MessageLinkPreviewKind.generic,
                      uri: uri,
                    ),
                ],
                linkPreviewService: previewService,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(previewService.imageLoads, uris.length);

    await tester.pumpWidget(
      MaterialApp(theme: buildVerdantTheme(), home: const SizedBox.shrink()),
    );
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerdantTheme(),
        home: Scaffold(
          body: MessageLinkPreviews(
            messageId: 'official/message-link-preview-evicted',
            cacheScope: 'origin:https%3A%2F%2Fapi.verdant.chat',
            previews: [
              MessageLinkPreviewData(
                kind: MessageLinkPreviewKind.generic,
                uri: uris.first,
              ),
            ],
            linkPreviewService: previewService,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(previewService.imageLoads, uris.length + 1);
  });

  testWidgets('automatic generic previews cap concurrent URL loads', (
    tester,
  ) async {
    final uris = [
      Uri.parse('https://alpha.example/release'),
      Uri.parse('https://beta.example/release'),
      Uri.parse('https://gamma.example/release'),
    ];
    final previewService = _DelayedMessageLinkPreviewService();

    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerdantTheme(),
        home: Scaffold(
          body: MessageLinkPreviews(
            messageId: 'official/message-link-preview-concurrency',
            previews: [
              for (final uri in uris)
                MessageLinkPreviewData(
                  kind: MessageLinkPreviewKind.generic,
                  uri: uri,
                ),
            ],
            linkPreviewService: previewService,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(previewService.previewLoads, 2);
    expect(previewService.activeLoads, [uris[0], uris[1]]);

    previewService.completePreview(uris[0], _metadataFor(uris[0]));
    await tester.pump();
    await tester.pump();

    expect(previewService.previewLoads, 3);
    expect(previewService.activeLoads, [uris[1], uris[2]]);

    previewService.completePreview(uris[1], _metadataFor(uris[1]));
    previewService.completePreview(uris[2], _metadataFor(uris[2]));
    await tester.pumpAndSettle();
  });

  testWidgets('automatic generic previews cancel disposed queued URL loads', (
    tester,
  ) async {
    final uris = [
      Uri.parse('https://example.com/release-a'),
      Uri.parse('https://example.com/release-b'),
      Uri.parse('https://example.com/release-c'),
    ];
    final previewService = _DelayedMessageLinkPreviewService();

    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerdantTheme(),
        home: Scaffold(
          body: MessageLinkPreviews(
            messageId: 'official/message-link-preview-cancel',
            previews: [
              for (final uri in uris)
                MessageLinkPreviewData(
                  kind: MessageLinkPreviewKind.generic,
                  uri: uri,
                ),
            ],
            linkPreviewService: previewService,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(previewService.previewLoads, 1);
    expect(previewService.activeLoads, [uris.first]);

    await tester.pumpWidget(
      MaterialApp(theme: buildVerdantTheme(), home: const SizedBox.shrink()),
    );
    await tester.pump();

    previewService.completePreview(uris.first, _metadataFor(uris.first));
    await tester.pump();
    await tester.pump();

    expect(previewService.previewLoads, 1);
    expect(previewService.activeLoads, isEmpty);
  });

  testWidgets(
    'automatic generic previews pause queued URL loads while hidden',
    (tester) async {
      final uris = [
        Uri.parse('https://example.com/hidden-a'),
        Uri.parse('https://example.com/hidden-b'),
        Uri.parse('https://example.com/hidden-c'),
      ];
      final previewService = _DelayedMessageLinkPreviewService();

      Widget buildPreviewPane({required bool visible}) {
        return MaterialApp(
          theme: buildVerdantTheme(),
          home: Scaffold(
            body: TickerMode(
              enabled: visible,
              child: MessageLinkPreviews(
                messageId: 'official/message-link-preview-hidden',
                previews: [
                  for (final uri in uris)
                    MessageLinkPreviewData(
                      kind: MessageLinkPreviewKind.generic,
                      uri: uri,
                    ),
                ],
                linkPreviewService: previewService,
              ),
            ),
          ),
        );
      }

      await tester.pumpWidget(buildPreviewPane(visible: true));
      await tester.pump();

      expect(previewService.previewLoads, 1);
      expect(previewService.activeLoads, [uris.first]);

      await tester.pumpWidget(buildPreviewPane(visible: false));
      await tester.pump();

      previewService.completePreview(uris.first, _metadataFor(uris.first));
      await tester.pump();
      await tester.pump();

      expect(previewService.previewLoads, 1);
      expect(previewService.activeLoads, isEmpty);

      await tester.pumpWidget(buildPreviewPane(visible: true));
      await tester.pump();

      expect(previewService.previewLoads, 2);
      expect(previewService.activeLoads, hasLength(1));
      expect(uris, contains(previewService.activeLoads.single));
    },
  );

  testWidgets('automatic generic previews cap queued URL loads', (
    tester,
  ) async {
    final uris = [
      for (var index = 0; index < 80; index += 1)
        Uri.parse('https://example.com/release-$index'),
    ];
    final previewService = _DelayedMessageLinkPreviewService();

    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerdantTheme(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: MessageLinkPreviews(
              messageId: 'official/message-link-preview-queue-cap',
              previews: [
                for (final uri in uris)
                  MessageLinkPreviewData(
                    kind: MessageLinkPreviewKind.generic,
                    uri: uri,
                  ),
              ],
              linkPreviewService: previewService,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(previewService.previewLoads, 1);

    var completed = 0;
    while (previewService.activeLoads.isNotEmpty) {
      final active = previewService.activeLoads.single;
      previewService.completePreview(active, _metadataFor(active));
      completed += 1;
      await tester.pump();
      await tester.pump();
      expect(completed, lessThan(uris.length));
    }

    expect(previewService.previewLoads, 49);
  });

  testWidgets('message item renders generic and YouTube preview cards', (
    tester,
  ) async {
    const messageId = 'official/message-url-previews';

    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerdantTheme(),
        home: Scaffold(
          body: SizedBox(
            width: 720,
            child: MessageItem(
              message: const MessageSeed(
                id: messageId,
                authorId: 'official/user-joshy',
                author: 'Joshy',
                time: 'Today at 2:20 PM',
                body:
                    'Release notes: https://example.com/releases and '
                    'https://www.youtube.com/watch?v=k1_ODDevbY8',
                initials: 'JO',
              ),
              showHeader: true,
              mediaPolicy: ServerMediaPolicy.fromOrigins(
                apiOrigin: 'https://api.verdant.chat',
              ),
              youtubePlayerBuilder: _testYoutubePlayerBuilder,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('message-link-preview-list-$messageId')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('message-link-preview-generic-$messageId-0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('message-link-preview-youtube-$messageId-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey(
          'message-link-preview-youtube-$messageId-1-player-shell',
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('message-link-preview-youtube-test-player')),
      findsOneWidget,
    );
    expect(find.textContaining('https://www.youtube.com/watch'), findsNothing);
    expect(find.textContaining('https://example.com/releases'), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey('message-link-preview-youtube-$messageId-1-play-target'),
      ),
      findsNothing,
    );
  });
}

Widget _testYoutubePlayerBuilder(
  BuildContext context,
  Uri embedUri,
  Uri watchUri,
) {
  return ColoredBox(
    key: const ValueKey('message-link-preview-youtube-test-player'),
    color: Colors.black,
    child: Text('${embedUri.host} ${watchUri.host}'),
  );
}

final class _RecordingLinkLauncher extends AnnouncementLinkLauncher {
  final opened = <Uri>[];

  @override
  Future<bool> openExternal(Uri uri) async {
    opened.add(uri);
    return true;
  }
}

final class _FakeMessageLinkPreviewService
    implements MessageLinkPreviewService {
  _FakeMessageLinkPreviewService({
    this.metadata,
    this.metadataByUri = const {},
    this.imageBytes,
  });

  final MessageLinkPreviewMetadata? metadata;
  final Map<Uri, MessageLinkPreviewMetadata> metadataByUri;
  final Uint8List? imageBytes;
  var previewLoads = 0;
  var imageLoads = 0;

  @override
  Future<MessageLinkPreviewMetadata?> loadPreview(Uri uri) async {
    previewLoads += 1;
    return metadataByUri[uri] ?? metadata;
  }

  @override
  Future<Uint8List?> loadPreviewImage(String imageProxyUrl) async {
    imageLoads += 1;
    return imageBytes;
  }
}

final class _DelayedMessageLinkPreviewService
    implements MessageLinkPreviewService {
  final _pendingPreviews = <Uri, Completer<MessageLinkPreviewMetadata?>>{};
  var previewLoads = 0;
  var imageLoads = 0;

  List<Uri> get activeLoads => List.unmodifiable(_pendingPreviews.keys);

  @override
  Future<MessageLinkPreviewMetadata?> loadPreview(Uri uri) {
    previewLoads += 1;
    final completer = Completer<MessageLinkPreviewMetadata?>();
    _pendingPreviews[uri] = completer;
    return completer.future;
  }

  void completePreview(Uri uri, MessageLinkPreviewMetadata? metadata) {
    final completer = _pendingPreviews.remove(uri);
    if (completer == null || completer.isCompleted) {
      return;
    }
    completer.complete(metadata);
  }

  @override
  Future<Uint8List?> loadPreviewImage(String imageProxyUrl) async {
    imageLoads += 1;
    return _onePixelPng;
  }
}

MessageLinkPreviewMetadata _metadataFor(
  Uri uri, {
  String? title,
  String? imageProxyUrl,
}) {
  return MessageLinkPreviewMetadata(
    url: uri,
    title: title ?? uri.host,
    description: 'Preview metadata',
    siteName: uri.host,
    imageProxyUrl: imageProxyUrl,
  );
}

final class _FakeClock {
  _FakeClock(this.value);

  DateTime value;

  DateTime now() => value;

  void advance(Duration duration) => value = value.add(duration);
}

final _onePixelPng = Uint8List.fromList([
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
]);
