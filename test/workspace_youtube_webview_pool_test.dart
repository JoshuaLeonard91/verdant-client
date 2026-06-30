import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verdant_flutter/features/workspace/shared/workspace_link_launcher.dart';
import 'package:verdant_flutter/features/workspace/shared/youtube_embed/workspace_youtube_preview.dart';
import 'package:verdant_flutter/features/workspace/shared/youtube_embed/workspace_youtube_webview_pool.dart';
import 'package:verdant_flutter/theme/verdant_theme.dart';

void main() {
  test('reuses the kept native player for the same video remount', () async {
    final disposed = <Object>[];
    final pool = WorkspaceYouTubeWebViewPool(
      maxKeepAlivePlayers: 2,
      disposeKeepAlive: (keepAlive) async => disposed.add(keepAlive),
    );

    final first = pool.acquire('k1_ODDevbY8');
    await pool.release(first);

    final second = pool.acquire('k1_ODDevbY8');

    expect(identical(second.keepAlive, first.keepAlive), isTrue);
    expect(second.reusedExistingPlayer, isTrue);
    expect(disposed, isEmpty);
  });

  test('evicts only idle kept players when the pool exceeds its cap', () async {
    final disposed = <Object>[];
    final pool = WorkspaceYouTubeWebViewPool(
      maxKeepAlivePlayers: 2,
      disposeKeepAlive: (keepAlive) async => disposed.add(keepAlive),
    );

    final first = pool.acquire('k1_ODDevbY8');
    final second = pool.acquire('dQw4w9WgXcQ');
    final third = pool.acquire('aqz-KE-bpKQ');

    expect(disposed, isEmpty);

    await pool.release(first);

    expect(disposed, [first.keepAlive]);

    await pool.release(second);
    await pool.release(third);
    await pool.clear();

    expect(
      disposed,
      containsAll(<Object>[first.keepAlive, second.keepAlive, third.keepAlive]),
    );
  });

  test(
    'keeps simultaneous same-video previews on separate native players',
    () async {
      final pool = WorkspaceYouTubeWebViewPool(maxKeepAlivePlayers: 4);

      final first = pool.acquire('message-preview-a', videoId: 'k1_ODDevbY8');
      final second = pool.acquire('message-preview-b', videoId: 'k1_ODDevbY8');

      expect(identical(second.keepAlive, first.keepAlive), isFalse);

      await pool.release(first);
      await pool.release(second);

      final firstAgain = pool.acquire(
        'message-preview-a',
        videoId: 'k1_ODDevbY8',
      );

      expect(identical(firstAgain.keepAlive, first.keepAlive), isTrue);
      expect(firstAgain.reusedExistingPlayer, isTrue);
    },
  );

  testWidgets('preview reuses its WebView lease after remount', (tester) async {
    final disposed = <Object>[];
    final leases = <WorkspaceYouTubeWebViewLease>[];
    final pool = WorkspaceYouTubeWebViewPool(
      maxKeepAlivePlayers: 2,
      disposeKeepAlive: (keepAlive) async => disposed.add(keepAlive),
    );

    Widget build({required bool showPreview}) {
      return MaterialApp(
        theme: buildVerdantTheme(),
        home: Scaffold(
          body: showPreview
              ? WorkspaceYouTubePreview(
                  url: 'https://www.youtube.com/watch?v=k1_ODDevbY8',
                  linkLauncher: const WorkspaceLinkLauncher(),
                  youtubeWebViewPool: pool,
                  onWebViewLeaseAcquired: leases.add,
                  youtubePlayerBuilder: (context, embedUri, watchUri) {
                    return const SizedBox(
                      key: ValueKey('pooled-youtube-player'),
                    );
                  },
                )
              : const SizedBox.shrink(),
        ),
      );
    }

    await tester.pumpWidget(build(showPreview: true));
    await tester.tap(
      find.byKey(const ValueKey('workspace-youtube-play-target')),
    );
    await tester.pump();

    final firstLease = leases.single;
    expect(firstLease.reusedExistingPlayer, isFalse);

    await tester.pumpWidget(build(showPreview: false));
    await tester.pump();
    await tester.pumpWidget(build(showPreview: true));
    await tester.tap(
      find.byKey(const ValueKey('workspace-youtube-play-target')),
    );
    await tester.pump();

    final secondLease = leases.last;
    expect(identical(secondLease.keepAlive, firstLease.keepAlive), isTrue);
    expect(secondLease.reusedExistingPlayer, isTrue);
    expect(disposed, isEmpty);
  });
}
