import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verdant_flutter/app/window_focus_scope.dart';
import 'package:verdant_flutter/features/workspace/server_settings_workspace/server_media_image.dart';
import 'package:verdant_flutter/features/workspace/server_settings_workspace/server_media_url_policy.dart';
import 'package:verdant_flutter/features/workspace/shared/media_residency_scope.dart';
import 'package:verdant_flutter/features/workspace/shared/media_residency_service.dart';

void main() {
  final policy = ServerMediaPolicy.fromOrigins(
    apiOrigin: 'https://api.verdant.chat',
    cdnUrl: 'https://media.verdant.chat',
  );

  tearDown(() {
    debugConfigureServerMediaImageCacheForTesting();
    debugSetServerMediaWidgetLoader(null);
  });

  testWidgets('evicts old media bytes when cache exceeds entry cap', (
    tester,
  ) async {
    debugConfigureServerMediaImageCacheForTesting(maxEntries: 2, maxBytes: 64);
    var loadCount = 0;
    debugSetServerMediaWidgetLoader((uri, {required policy, maxBytes}) async {
      loadCount += 1;
      return Uint8List.fromList([loadCount, uri.pathSegments.last.length]);
    });

    await _pumpMedia(
      tester,
      'https://media.verdant.chat/avatars/a.webp',
      policy,
    );
    await _pumpMedia(
      tester,
      'https://media.verdant.chat/avatars/b.webp',
      policy,
    );
    await _pumpMedia(
      tester,
      'https://media.verdant.chat/avatars/c.webp',
      policy,
    );

    expect(loadCount, 3);

    await _pumpMedia(
      tester,
      'https://media.verdant.chat/avatars/a.webp',
      policy,
    );

    expect(loadCount, 4);
  });

  testWidgets('evicts old media bytes when cache exceeds byte cap', (
    tester,
  ) async {
    debugConfigureServerMediaImageCacheForTesting(maxEntries: 8, maxBytes: 5);
    var loadCount = 0;
    debugSetServerMediaWidgetLoader((uri, {required policy, maxBytes}) async {
      loadCount += 1;
      return Uint8List.fromList([1, 2, 3]);
    });

    await _pumpMedia(
      tester,
      'https://media.verdant.chat/avatars/a.webp',
      policy,
    );
    await _pumpMedia(
      tester,
      'https://media.verdant.chat/avatars/b.webp',
      policy,
    );

    expect(loadCount, 2);

    await _pumpMedia(
      tester,
      'https://media.verdant.chat/avatars/a.webp',
      policy,
    );

    expect(loadCount, 3);
  });

  testWidgets('clearServerMediaImageCache drops retained media bytes', (
    tester,
  ) async {
    debugConfigureServerMediaImageCacheForTesting(maxEntries: 8, maxBytes: 64);
    var loadCount = 0;
    debugSetServerMediaWidgetLoader((uri, {required policy, maxBytes}) async {
      loadCount += 1;
      return Uint8List.fromList([1, 2, 3]);
    });

    await _pumpMedia(
      tester,
      'https://media.verdant.chat/avatars/a.webp',
      policy,
    );
    await _pumpMedia(
      tester,
      'https://media.verdant.chat/avatars/a.webp',
      policy,
    );

    expect(loadCount, 1);

    clearServerMediaImageCache();
    await _pumpMedia(
      tester,
      'https://media.verdant.chat/avatars/a.webp',
      policy,
    );

    expect(loadCount, 2);
  });

  testWidgets('coalesces concurrent requests for the same media URL', (
    tester,
  ) async {
    debugConfigureServerMediaImageCacheForTesting(maxEntries: 8, maxBytes: 64);
    final loadCompleter = Completer<Uint8List>();
    var loadCount = 0;
    debugSetServerMediaWidgetLoader((uri, {required policy, maxBytes}) async {
      loadCount += 1;
      return loadCompleter.future;
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Column(
          children: [
            _mediaImage('https://media.verdant.chat/avatars/a.webp', policy),
            _mediaImage('https://media.verdant.chat/avatars/a.webp', policy),
          ],
        ),
      ),
    );
    await tester.pump();

    expect(loadCount, 1);

    loadCompleter.complete(Uint8List.fromList([1, 2, 3]));
    await tester.pump();
    await tester.pump();

    expect(find.text('loaded'), findsNWidgets(2));
  });

  testWidgets('warmServerMediaImageCache populates cache before render', (
    tester,
  ) async {
    debugConfigureServerMediaImageCacheForTesting(maxEntries: 8, maxBytes: 128);
    var loadCount = 0;
    debugSetServerMediaWidgetLoader((uri, {required policy, maxBytes}) async {
      loadCount += 1;
      return Uint8List.fromList([1, 2, 3]);
    });

    final uri = Uri.parse('https://media.verdant.chat/server-icons/a.webp');
    await warmServerMediaImageCache([
      ServerMediaWarmRequest(
        uri: uri,
        policy: policy,
        surface: ServerMediaSurface.serverIcon,
      ),
    ]);

    expect(loadCount, 1);
    expect(debugServerMediaImageCacheEntryCount(), 1);

    await tester.pumpWidget(
      MaterialApp(
        home: SafeServerMediaImage(
          uri: uri,
          policy: policy,
          surface: ServerMediaSurface.serverIcon,
          loadWhenVisible: false,
          fallback: const Text('fallback'),
          builder: (context, imageProvider) => const Text('loaded'),
        ),
      ),
    );
    await tester.pump();

    expect(loadCount, 1);
    expect(find.text('loaded'), findsOneWidget);
    expect(find.text('fallback'), findsNothing);
  });

  testWidgets('uses warmed cache on first visible frame', (tester) async {
    debugConfigureServerMediaImageCacheForTesting(maxEntries: 8, maxBytes: 128);
    var loadCount = 0;
    debugSetServerMediaWidgetLoader((uri, {required policy, maxBytes}) async {
      loadCount += 1;
      return Uint8List.fromList([1, 2, 3]);
    });

    final uri = Uri.parse('https://media.verdant.chat/server-icons/a.webp');
    await warmServerMediaImageCache([
      ServerMediaWarmRequest(
        uri: uri,
        policy: policy,
        surface: ServerMediaSurface.serverIcon,
      ),
    ]);

    expect(loadCount, 1);

    await tester.pumpWidget(
      MaterialApp(
        home: SafeServerMediaImage(
          uri: uri,
          policy: policy,
          surface: ServerMediaSurface.serverIcon,
          fallback: const Text('fallback'),
          loading: const Text('loading'),
          builder: (context, imageProvider) => const Text('loaded'),
        ),
      ),
    );

    expect(loadCount, 1);
    expect(find.text('loaded'), findsOneWidget);
    expect(find.text('loading'), findsNothing);
    expect(find.text('fallback'), findsNothing);
  });

  testWidgets('does not cache a single response larger than the byte cap', (
    tester,
  ) async {
    debugConfigureServerMediaImageCacheForTesting(maxEntries: 8, maxBytes: 2);
    var loadCount = 0;
    debugSetServerMediaWidgetLoader((uri, {required policy, maxBytes}) async {
      loadCount += 1;
      return Uint8List.fromList([1, 2, 3]);
    });

    await _pumpMedia(
      tester,
      'https://media.verdant.chat/avatars/a.webp',
      policy,
    );
    await _pumpMedia(
      tester,
      'https://media.verdant.chat/avatars/a.webp',
      policy,
    );

    expect(loadCount, 2);
  });

  testWidgets('unmounts loaded media while the app window is unfocused', (
    tester,
  ) async {
    debugConfigureServerMediaImageCacheForTesting(maxEntries: 8, maxBytes: 64);
    var loadCount = 0;
    debugSetServerMediaWidgetLoader((uri, {required policy, maxBytes}) async {
      loadCount += 1;
      return Uint8List.fromList([1, 2, 3]);
    });

    await _pumpFocusedMedia(
      tester,
      focused: true,
      url: 'https://media.verdant.chat/avatars/a.webp',
      policy: policy,
    );

    expect(find.text('loaded'), findsOneWidget);
    expect(find.text('fallback'), findsNothing);
    expect(loadCount, 1);

    await _pumpFocusedMedia(
      tester,
      focused: false,
      url: 'https://media.verdant.chat/avatars/a.webp',
      policy: policy,
    );

    expect(find.text('loaded'), findsNothing);
    expect(find.text('fallback'), findsOneWidget);
    expect(debugServerMediaImageEvictionCount(), 1);

    await _pumpFocusedMedia(
      tester,
      focused: true,
      url: 'https://media.verdant.chat/avatars/a.webp',
      policy: policy,
    );

    expect(find.text('loaded'), findsOneWidget);
    expect(loadCount, 1);
  });

  testWidgets('retains resident image provider across short focus loss', (
    tester,
  ) async {
    debugConfigureServerMediaImageCacheForTesting(maxEntries: 8, maxBytes: 64);
    final clock = _FakeClock(DateTime.utc(2026, 6, 14));
    final residency = MediaResidencyService(
      clock: clock.now,
      ttl: const Duration(minutes: 3),
      maxEntries: 8,
      maxBytes: 64,
    );
    var loadCount = 0;
    debugSetServerMediaWidgetLoader((uri, {required policy, maxBytes}) async {
      loadCount += 1;
      return Uint8List.fromList([1, 2, 3]);
    });

    await _pumpFocusedResidentMedia(
      tester,
      focused: true,
      url: 'https://media.verdant.chat/avatars/a.webp',
      policy: policy,
      residency: residency,
    );

    expect(find.text('loaded'), findsOneWidget);
    expect(loadCount, 1);

    await _pumpFocusedResidentMedia(
      tester,
      focused: false,
      url: 'https://media.verdant.chat/avatars/a.webp',
      policy: policy,
      residency: residency,
    );

    expect(find.text('loaded'), findsNothing);
    expect(find.text('frozen'), findsOneWidget);
    expect(find.text('fallback'), findsNothing);
    expect(debugServerMediaImageEvictionCount(), 0);

    clock.advance(const Duration(minutes: 2));
    await _pumpFocusedResidentMedia(
      tester,
      focused: true,
      url: 'https://media.verdant.chat/avatars/a.webp',
      policy: policy,
      residency: residency,
    );

    expect(find.text('loaded'), findsOneWidget);
    expect(loadCount, 1);
    expect(debugServerMediaImageEvictionCount(), 0);
  });

  testWidgets('renders retained media on the first focused frame after blur', (
    tester,
  ) async {
    final debugMessages = <String>[];
    final previousDebugPrint = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) {
        debugMessages.add(message);
      }
      previousDebugPrint(message, wrapWidth: wrapWidth);
    };
    try {
      debugConfigureServerMediaImageCacheForTesting(
        maxEntries: 8,
        maxBytes: 64,
      );
      final residency = MediaResidencyService(ttl: const Duration(minutes: 3));
      var loadCount = 0;
      debugSetServerMediaWidgetLoader((uri, {required policy, maxBytes}) async {
        loadCount += 1;
        return Uint8List.fromList([1, 2, 3]);
      });

      Widget build({required bool focused}) {
        return MaterialApp(
          home: MediaResidencyScope(
            service: residency,
            child: WindowFocusScope(
              focused: focused,
              child: _mediaImage(
                'https://media.verdant.chat/avatars/a.webp',
                policy,
              ),
            ),
          ),
        );
      }

      await tester.pumpWidget(build(focused: true));
      await tester.pump();
      await tester.pump();

      expect(find.text('loaded'), findsOneWidget);
      expect(loadCount, 1);

      await tester.pumpWidget(build(focused: false));
      await tester.pump();

      expect(find.text('frozen'), findsOneWidget);
      expect(find.text('fallback'), findsNothing);

      debugMessages.clear();
      await tester.pumpWidget(build(focused: true));
      await tester.pump();

      expect(
        debugMessages.any(
          (message) =>
              message.contains('verdant.media render.branch') &&
              message.contains('branch: futureWaiting'),
        ),
        isFalse,
      );
      expect(find.text('loaded'), findsOneWidget);
      expect(find.text('fallback'), findsNothing);
      expect(loadCount, 1);
    } finally {
      debugPrint = previousDebugPrint;
    }
  });

  testWidgets('server media icon freezes retained media while unfocused', (
    tester,
  ) async {
    debugConfigureServerMediaImageCacheForTesting(maxEntries: 8, maxBytes: 128);
    final residency = MediaResidencyService(ttl: const Duration(minutes: 3));
    var loadCount = 0;
    debugSetServerMediaWidgetLoader((uri, {required policy, maxBytes}) async {
      loadCount += 1;
      return Uint8List.fromList(_onePixelPng);
    });

    Widget buildIcon({required bool focused, required bool animate}) {
      return MaterialApp(
        home: MediaResidencyScope(
          service: residency,
          child: WindowFocusScope(
            focused: focused,
            child: Center(
              child: ServerMediaIcon(
                name: 'Verdant',
                iconUrl: 'https://media.verdant.chat/server-icons/a.webp',
                mediaPolicy: policy,
                size: 48,
                animate: animate,
                imageKey: const ValueKey('server-icon-test-media'),
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildIcon(focused: true, animate: true));
    await tester.pump();
    await tester.pump();

    expect(loadCount, 1);
    expect(find.byType(Image), findsOneWidget);
    expect(find.byType(StaticFirstFrameImage), findsNothing);

    await tester.pumpWidget(buildIcon(focused: false, animate: true));
    await tester.pump();

    expect(loadCount, 1);
    expect(find.byType(Image), findsNothing);
    expect(find.byType(StaticFirstFrameImage), findsOneWidget);

    await tester.pumpWidget(buildIcon(focused: true, animate: false));
    await tester.pump();

    expect(loadCount, 1);
    expect(find.byType(Image), findsNothing);
    expect(find.byType(StaticFirstFrameImage), findsOneWidget);
  });

  testWidgets(
    'server media icon keeps a frozen frame while unfocused without residency',
    (tester) async {
      debugConfigureServerMediaImageCacheForTesting(
        maxEntries: 8,
        maxBytes: 128,
      );
      var loadCount = 0;
      debugSetServerMediaWidgetLoader((uri, {required policy, maxBytes}) async {
        loadCount += 1;
        return Uint8List.fromList(_onePixelPng);
      });

      Widget buildIcon({required bool focused}) {
        return MaterialApp(
          home: WindowFocusScope(
            focused: focused,
            child: Center(
              child: ServerMediaIcon(
                name: 'Verdant',
                iconUrl: 'https://media.verdant.chat/server-icons/a.webp',
                mediaPolicy: policy,
                size: 48,
                animate: true,
                imageKey: const ValueKey('server-icon-test-media'),
              ),
            ),
          ),
        );
      }

      await tester.pumpWidget(buildIcon(focused: true));
      await tester.pump();
      await tester.pump();

      expect(loadCount, 1);
      expect(find.byType(Image), findsOneWidget);

      await tester.pumpWidget(buildIcon(focused: false));
      await tester.pump();

      expect(loadCount, 1);
      expect(find.byType(Image), findsNothing);
      expect(find.byType(StaticFirstFrameImage), findsOneWidget);
      expect(find.byType(ServerIconInitials), findsNothing);

      await tester.pumpWidget(buildIcon(focused: true));
      await tester.pump();

      expect(loadCount, 1);
      expect(find.byType(Image), findsOneWidget);
    },
  );

  testWidgets('retain-on-blur media caches pending loads after focus loss', (
    tester,
  ) async {
    debugConfigureServerMediaImageCacheForTesting(maxEntries: 8, maxBytes: 128);
    final loadCompleter = Completer<Uint8List>();
    var loadCount = 0;
    debugSetServerMediaWidgetLoader((uri, {required policy, maxBytes}) async {
      loadCount += 1;
      return loadCompleter.future;
    });

    Widget build({required bool focused}) {
      return MaterialApp(
        home: WindowFocusScope(
          focused: focused,
          child: SafeServerMediaImage(
            uri: Uri.parse('https://media.verdant.chat/server-icons/a.webp'),
            policy: policy,
            surface: ServerMediaSurface.serverIcon,
            retainWhenUnfocused: true,
            fallback: const Text('fallback'),
            builder: (context, imageProvider) => const Text('loaded'),
          ),
        ),
      );
    }

    await tester.pumpWidget(build(focused: true));
    await tester.pump();

    expect(loadCount, 1);
    expect(find.text('fallback'), findsOneWidget);

    await tester.pumpWidget(build(focused: false));
    await tester.pump();

    loadCompleter.complete(Uint8List.fromList(_onePixelPng));
    await tester.pump();
    await tester.pump();

    expect(debugServerMediaImageCacheEntryCount(), 1);

    await tester.pumpWidget(build(focused: true));
    await tester.pump();

    expect(loadCount, 1);
    expect(find.text('loaded'), findsOneWidget);
    expect(find.text('fallback'), findsNothing);
  });

  testWidgets('cropped banner media freezes unless animation is focused', (
    tester,
  ) async {
    final provider = MemoryImage(Uint8List.fromList(_onePixelPng));

    Widget buildBanner({required bool focused, required bool animate}) {
      return MaterialApp(
        home: WindowFocusScope(
          focused: focused,
          child: SizedBox(
            width: 240,
            height: 80,
            child: CroppedServerBannerImage(
              imageProvider: provider,
              animate: animate,
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildBanner(focused: true, animate: true));
    await tester.pump();

    expect(find.byType(Image), findsOneWidget);
    expect(find.byType(CroppedStaticFirstFrameBannerImage), findsNothing);

    await tester.pumpWidget(buildBanner(focused: false, animate: true));
    await tester.pump();

    expect(find.byType(Image), findsNothing);
    expect(find.byType(CroppedStaticFirstFrameBannerImage), findsOneWidget);

    await tester.pumpWidget(buildBanner(focused: true, animate: false));
    await tester.pump();

    expect(find.byType(Image), findsNothing);
    expect(find.byType(CroppedStaticFirstFrameBannerImage), findsOneWidget);
  });
}

Future<void> _pumpMedia(
  WidgetTester tester,
  String url,
  ServerMediaPolicy policy,
) async {
  await tester.pumpWidget(MaterialApp(home: _mediaImage(url, policy)));
  await tester.pump();
  await tester.pump();
  expect(find.text('loaded'), findsOneWidget);
  await tester.pumpWidget(const SizedBox.shrink());
}

Widget _mediaImage(String url, ServerMediaPolicy policy) {
  return SafeServerMediaImage(
    uri: Uri.parse(url),
    policy: policy,
    fallback: const Text('fallback'),
    builder: (context, imageProvider) => const Text('loaded'),
    frozenBuilder: (context, imageProvider, bytes) => const Text('frozen'),
  );
}

Future<void> _pumpFocusedMedia(
  WidgetTester tester, {
  required bool focused,
  required String url,
  required ServerMediaPolicy policy,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: WindowFocusScope(focused: focused, child: _mediaImage(url, policy)),
    ),
  );
  await tester.pump();
  await tester.pump();
}

Future<void> _pumpFocusedResidentMedia(
  WidgetTester tester, {
  required bool focused,
  required String url,
  required ServerMediaPolicy policy,
  required MediaResidencyService residency,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: MediaResidencyScope(
        service: residency,
        child: WindowFocusScope(
          focused: focused,
          child: _mediaImage(url, policy),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

final class _FakeClock {
  _FakeClock(this.value);

  DateTime value;

  DateTime now() => value;

  void advance(Duration duration) => value = value.add(duration);
}

final _onePixelPng = <int>[
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
