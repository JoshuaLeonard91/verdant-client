import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verdant_flutter/app/window_focus_scope.dart';
import 'package:verdant_flutter/features/workspace/chat_workspace/announcement_feed/announcement_card_preview.dart';
import 'package:verdant_flutter/features/workspace/chat_workspace/announcement_feed/announcement_content_models.dart';
import 'package:verdant_flutter/features/workspace/chat_workspace/announcement_feed/announcement_link_launcher.dart';
import 'package:verdant_flutter/features/workspace/chat_workspace/announcement_feed/announcement_youtube_playback_memory.dart';
import 'package:verdant_flutter/features/workspace/shared/media_residency_scope.dart';
import 'package:verdant_flutter/features/workspace/shared/media_residency_service.dart';
import 'package:verdant_flutter/features/workspace/shared/youtube_embed/workspace_youtube_preview.dart';
import 'package:verdant_flutter/theme/verdant_theme.dart';

void main() {
  testWidgets('youtube preview mounts a constrained playable frame', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final launcher = _RecordingAnnouncementLinkLauncher();

    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerdantTheme(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: AnnouncementCardPreview(
              linkLauncher: launcher,
              youtubePlayerBuilder: (context, embedUri, watchUri) {
                return Text(
                  'playing ${embedUri.host} ${watchUri.host}',
                  key: const ValueKey('announcement-youtube-test-player'),
                );
              },
              draft: const FeedAnnouncementDraft(
                title: 'Video post',
                color: '#1ee3b6',
                sections: [
                  FeedAnnouncementYouTubeSection(
                    url: 'https://www.youtube.com/watch?v=k1_ODDevbY8',
                    title: 'Release walkthrough video',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final playerShellSize = tester.getSize(
      find.byKey(
        const ValueKey('announcement-card-preview-youtube-0-player-shell'),
      ),
    );
    expect(playerShellSize.width, lessThanOrEqualTo(480));
    expect(
      find.byKey(
        const ValueKey('announcement-card-preview-youtube-0-play-placeholder'),
      ),
      findsNothing,
    );
    expect(
      find.byKey(
        const ValueKey('announcement-card-preview-youtube-0-thumbnail'),
      ),
      findsNothing,
    );
    expect(find.text('Play in feed'), findsNothing);
    expect(find.text('Open YouTube'), findsNothing);
    expect(
      find.byKey(const ValueKey('announcement-youtube-test-player')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('announcement-card-preview-youtube-0-open-action'),
      ),
      findsNothing,
    );
    expect(find.textContaining('www.youtube-nocookie.com'), findsOneWidget);
    expect(find.textContaining('www.youtube.com'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('youtube preview auto mounts without hover intent', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerdantTheme(),
        home: const WindowFocusScope(
          focused: true,
          child: Scaffold(
            body: SingleChildScrollView(
              child: AnnouncementCardPreview(
                youtubePlayerBuilder: _testYoutubePlayerBuilder,
                draft: FeedAnnouncementDraft(
                  title: 'Video post',
                  color: '#1ee3b6',
                  sections: [
                    FeedAnnouncementYouTubeSection(
                      url: 'https://www.youtube.com/watch?v=k1_ODDevbY8',
                      title: 'Release walkthrough video',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('announcement-youtube-test-player')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('announcement-card-preview-youtube-0-play-placeholder'),
      ),
      findsNothing,
    );
  });

  testWidgets('youtube sections use scoped per-section preview keys', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerdantTheme(),
        home: const WindowFocusScope(
          focused: false,
          child: Scaffold(
            body: SingleChildScrollView(
              child: AnnouncementCardPreview(
                youtubePreviewKeyPrefix: 'feed-record-123',
                draft: FeedAnnouncementDraft(
                  title: 'Two videos',
                  color: '#1ee3b6',
                  sections: [
                    FeedAnnouncementYouTubeSection(
                      url: 'https://www.youtube.com/watch?v=k1_ODDevbY8',
                      title: 'First video',
                    ),
                    FeedAnnouncementYouTubeSection(
                      url: 'https://youtu.be/dQw4w9WgXcQ',
                      title: 'Second video',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('feed-record-123-youtube-0-thumbnail')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('feed-record-123-youtube-1-thumbnail')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('announcement-youtube-thumbnail')),
      findsNothing,
    );
  });

  testWidgets('youtube preview keeps visible player mounted while unfocused', (
    tester,
  ) async {
    Widget build({required bool focused}) {
      return MaterialApp(
        theme: buildVerdantTheme(),
        home: WindowFocusScope(
          focused: focused,
          child: Scaffold(
            body: SingleChildScrollView(
              child: AnnouncementCardPreview(
                youtubePlayerBuilder: _testYoutubePlayerBuilder,
                draft: const FeedAnnouncementDraft(
                  title: 'Video post',
                  color: '#1ee3b6',
                  sections: [
                    FeedAnnouncementYouTubeSection(
                      url: 'https://www.youtube.com/watch?v=k1_ODDevbY8',
                      title: 'Release walkthrough video',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(build(focused: true));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('announcement-youtube-test-player')),
      findsOneWidget,
    );

    await tester.pumpWidget(build(focused: false));
    await tester.pump(const Duration(milliseconds: 2100));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('announcement-youtube-test-player')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('announcement-card-preview-youtube-0-thumbnail'),
      ),
      findsNothing,
    );
  });

  testWidgets('youtube player survives a transient focus handoff', (
    tester,
  ) async {
    Widget build({required bool focused}) {
      return MaterialApp(
        theme: buildVerdantTheme(),
        home: WindowFocusScope(
          focused: focused,
          child: Scaffold(
            body: SingleChildScrollView(
              child: AnnouncementCardPreview(
                youtubePlayerBuilder: _testYoutubePlayerBuilder,
                draft: const FeedAnnouncementDraft(
                  title: 'Video post',
                  color: '#1ee3b6',
                  sections: [
                    FeedAnnouncementYouTubeSection(
                      url: 'https://www.youtube.com/watch?v=k1_ODDevbY8',
                      title: 'Release walkthrough video',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(build(focused: true));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('announcement-youtube-test-player')),
      findsOneWidget,
    );

    await tester.pumpWidget(build(focused: false));
    await tester.pump(const Duration(milliseconds: 80));
    await tester.pumpWidget(build(focused: true));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('announcement-youtube-test-player')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('announcement-card-preview-youtube-0-play-placeholder'),
      ),
      findsNothing,
    );
  });

  testWidgets('youtube preview auto mounts when focused and visible', (
    tester,
  ) async {
    Widget build({required bool focused}) {
      return MaterialApp(
        theme: buildVerdantTheme(),
        home: WindowFocusScope(
          focused: focused,
          child: const Scaffold(
            body: SingleChildScrollView(
              child: AnnouncementCardPreview(
                youtubePlayerBuilder: _testYoutubePlayerBuilder,
                draft: FeedAnnouncementDraft(
                  title: 'Video post',
                  color: '#1ee3b6',
                  sections: [
                    FeedAnnouncementYouTubeSection(
                      url: 'https://www.youtube.com/watch?v=k1_ODDevbY8',
                      title: 'Release walkthrough video',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(build(focused: false));
    await tester.pumpAndSettle();
    expect(
      find.byKey(
        const ValueKey('announcement-card-preview-youtube-0-thumbnail'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('announcement-card-preview-youtube-0-play-placeholder'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('announcement-youtube-test-player')),
      findsNothing,
    );

    await tester.pumpWidget(build(focused: true));
    await tester.pumpAndSettle();

    expect(
      find.byKey(
        const ValueKey('announcement-card-preview-youtube-0-play-placeholder'),
      ),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('announcement-youtube-test-player')),
      findsOneWidget,
    );
  });

  testWidgets('youtube playback stays mounted while playing offscreen', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 320));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final playbackMemory = AnnouncementYouTubePlaybackMemory()
      ..record(
        const AnnouncementYouTubePlaybackUpdate(
          videoId: 'k1_ODDevbY8',
          positionSeconds: 32,
          state: 1,
          hasStarted: true,
          isPlaying: true,
        ),
      );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerdantTheme(),
        home: Scaffold(
          body: SizedBox(
            height: 240,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 900),
                  AnnouncementCardPreview(
                    youtubePlayerBuilder: _testYoutubePlayerBuilder,
                    youtubePlaybackMemory: playbackMemory,
                    draft: const FeedAnnouncementDraft(
                      title: 'Video post',
                      color: '#1ee3b6',
                      sections: [
                        FeedAnnouncementYouTubeSection(
                          url: 'https://www.youtube.com/watch?v=k1_ODDevbY8',
                          title: 'Release walkthrough video',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('announcement-youtube-test-player')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('announcement-card-preview-youtube-0-thumbnail'),
      ),
      findsNothing,
    );
  });

  testWidgets(
    'youtube player remains resident briefly after leaving viewport',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 320));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final scrollController = ScrollController();
      addTearDown(scrollController.dispose);
      final clock = _FakeClock(DateTime.utc(2026, 6, 14));
      final residency = MediaResidencyService(
        clock: clock.now,
        ttl: const Duration(minutes: 3),
        maxEntries: 8,
        maxBytes: 1024,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: buildVerdantTheme(),
          home: MediaResidencyScope(
            service: residency,
            child: Scaffold(
              body: SizedBox(
                height: 240,
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    children: [
                      AnnouncementCardPreview(
                        youtubePlayerBuilder: _testYoutubePlayerBuilder,
                        draft: const FeedAnnouncementDraft(
                          title: 'Video post',
                          color: '#1ee3b6',
                          sections: [
                            FeedAnnouncementYouTubeSection(
                              url:
                                  'https://www.youtube.com/watch?v=k1_ODDevbY8',
                              title: 'Release walkthrough video',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 900),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('announcement-youtube-test-player')),
        findsOneWidget,
      );

      scrollController.jumpTo(scrollController.position.maxScrollExtent);
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));

      expect(
        find.byKey(const ValueKey('announcement-youtube-test-player')),
        findsOneWidget,
      );
    },
  );

  testWidgets('youtube thumbnail eviction captures provider per video', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 480));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    debugResetWorkspaceYouTubeThumbnailEvictions();
    addTearDown(debugResetWorkspaceYouTubeThumbnailEvictions);

    final residency = MediaResidencyService(
      ttl: const Duration(minutes: 3),
      maxEntries: 8,
      maxBytes: 4 * 1024 * 1024,
    );

    Widget build(String videoUrl) {
      return MaterialApp(
        theme: buildVerdantTheme(),
        home: MediaResidencyScope(
          service: residency,
          child: WindowFocusScope(
            focused: false,
            child: Scaffold(
              body: SizedBox(
                width: 520,
                child: AnnouncementCardPreview(
                  draft: FeedAnnouncementDraft(
                    title: 'Video post',
                    color: '#1ee3b6',
                    sections: [
                      FeedAnnouncementYouTubeSection(
                        url: videoUrl,
                        title: 'Release walkthrough video',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(
      build('https://www.youtube.com/watch?v=k1_ODDevbY8'),
    );
    await tester.pump();

    await tester.pumpWidget(
      build('https://www.youtube.com/watch?v=dQw4w9WgXcQ'),
    );
    await tester.pump();

    residency.clearRoute('announcement-card-preview-youtube-0');

    final evictedUrls = debugWorkspaceYouTubeThumbnailEvictions();
    expect(evictedUrls.where((url) => url.contains('k1_ODDevbY8')), isNotEmpty);
    expect(evictedUrls.where((url) => url.contains('dQw4w9WgXcQ')), isNotEmpty);
  });

  testWidgets('youtube playback memory survives preview disposal', (
    tester,
  ) async {
    final playbackMemory = AnnouncementYouTubePlaybackMemory()
      ..record(
        const AnnouncementYouTubePlaybackUpdate(
          videoId: 'k1_ODDevbY8',
          positionSeconds: 48,
          state: 1,
          hasStarted: true,
          isPlaying: true,
        ),
      );

    Widget build({required bool show}) {
      return MaterialApp(
        theme: buildVerdantTheme(),
        home: Scaffold(
          body: show
              ? AnnouncementCardPreview(
                  youtubePlayerBuilder: _testYoutubePlayerBuilder,
                  youtubePlaybackMemory: playbackMemory,
                  draft: const FeedAnnouncementDraft(
                    title: 'Video post',
                    color: '#1ee3b6',
                    sections: [
                      FeedAnnouncementYouTubeSection(
                        url: 'https://www.youtube.com/watch?v=k1_ODDevbY8',
                        title: 'Release walkthrough video',
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      );
    }

    await tester.pumpWidget(build(show: true));
    await tester.pumpAndSettle();
    expect(playbackMemory.snapshotFor('k1_ODDevbY8').isPlaying, isTrue);

    await tester.pumpWidget(build(show: false));
    await tester.pumpAndSettle();

    final snapshot = playbackMemory.snapshotFor('k1_ODDevbY8');
    expect(snapshot.isPlaying, isTrue);
    expect(snapshot.positionSeconds, 48);
  });

  testWidgets('youtube preview omits redundant header external action', (
    tester,
  ) async {
    final launcher = _RecordingAnnouncementLinkLauncher();

    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerdantTheme(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: AnnouncementCardPreview(
              linkLauncher: launcher,
              youtubePlayerBuilder: _testYoutubePlayerBuilder,
              draft: const FeedAnnouncementDraft(
                title: 'Video post',
                color: '#1ee3b6',
                sections: [
                  FeedAnnouncementYouTubeSection(
                    url: 'https://www.youtube.com/watch?v=k1_ODDevbY8',
                    title: 'Release walkthrough video',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    expect(
      find.byKey(
        const ValueKey('announcement-card-preview-youtube-0-open-action'),
      ),
      findsNothing,
    );
    expect(launcher.opened, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('announcement preview renders supported chart styles', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerdantTheme(),
        home: const Scaffold(
          body: SingleChildScrollView(
            child: AnnouncementCardPreview(
              draft: FeedAnnouncementDraft(
                title: 'Analytics',
                color: '#1ee3b6',
                sections: [
                  FeedAnnouncementChartSection(
                    title: 'Bar',
                    data: 'Views: 8\nClicks: 4',
                  ),
                  FeedAnnouncementChartSection(
                    kind: FeedAnnouncementChartKind.line,
                    title: 'Line',
                    data: 'Mon: 4\nTue: 8\nWed: 12',
                  ),
                  FeedAnnouncementChartSection(
                    kind: FeedAnnouncementChartKind.donut,
                    title: 'Donut',
                    data: 'Desktop: 58\nMobile: 24',
                  ),
                  FeedAnnouncementChartSection(
                    kind: FeedAnnouncementChartKind.metrics,
                    title: 'Metrics',
                    data: 'Views: 1240\nReports: 0',
                  ),
                  FeedAnnouncementChartSection(
                    kind: FeedAnnouncementChartKind.progress,
                    title: 'Progress',
                    data: 'Client: 82\nServer: 45',
                  ),
                  FeedAnnouncementChartSection(
                    kind: FeedAnnouncementChartKind.sparkline,
                    title: 'Sparkline',
                    data: 'Mon: 42\nTue: 36\nWed: 31',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('BAR'), findsOneWidget);
    expect(find.text('LINE'), findsOneWidget);
    expect(find.text('DONUT'), findsOneWidget);
    expect(find.text('METRICS'), findsOneWidget);
    expect(find.text('PROGRESS'), findsOneWidget);
    expect(find.text('SPARKLINE'), findsOneWidget);
    expect(find.text('Release walkthrough video'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('announcement preview renders native rich text spans', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerdantTheme(),
        home: const Scaffold(
          body: SingleChildScrollView(
            child: AnnouncementCardPreview(
              draft: FeedAnnouncementDraft(
                title: 'Rich post',
                color: '#1ee3b6',
                sections: [
                  FeedAnnouncementRichTextSection(
                    spans: [
                      FeedAnnouncementRichTextSpan(
                        text: 'Important ',
                        style: FeedAnnouncementTextStyle(
                          weight: FeedAnnouncementTextWeight.bold,
                          italic: true,
                          strikethrough: true,
                        ),
                      ),
                      FeedAnnouncementRichTextSpan(
                        text: 'notice',
                        style: FeedAnnouncementTextStyle(
                          color: '#ff005b',
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final richText = tester.widget<RichText>(
      find.byKey(const ValueKey('announcement-rich-text-section')),
    );
    final root = richText.text as TextSpan;
    final first = root.children![0] as TextSpan;
    final second = root.children![1] as TextSpan;

    expect(root.toPlainText(), 'Important notice');
    expect(first.style?.fontWeight, FontWeight.w700);
    expect(first.style?.fontStyle, FontStyle.italic);
    expect(first.style?.decoration, TextDecoration.lineThrough);
    expect(second.style?.color, const Color(0xFFFF005B));
    expect(second.style?.fontSize, 16);
  });

  testWidgets('announcement preview preserves spaces between styled spans', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerdantTheme(),
        home: const Scaffold(
          body: SingleChildScrollView(
            child: AnnouncementCardPreview(
              draft: FeedAnnouncementDraft(
                title: 'Rich post',
                color: '#1ee3b6',
                sections: [
                  FeedAnnouncementRichTextSection(
                    spans: [
                      FeedAnnouncementRichTextSpan(text: 'Highlight'),
                      FeedAnnouncementRichTextSpan(text: ' '),
                      FeedAnnouncementRichTextSpan(
                        text: 'important',
                        style: FeedAnnouncementTextStyle(color: '#ff005b'),
                      ),
                      FeedAnnouncementRichTextSpan(text: ' '),
                      FeedAnnouncementRichTextSpan(
                        text: 'parts',
                        style: FeedAnnouncementTextStyle(
                          weight: FeedAnnouncementTextWeight.bold,
                        ),
                      ),
                      FeedAnnouncementRichTextSpan(
                        text: ' of the announcement.',
                        style: FeedAnnouncementTextStyle(strikethrough: true),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final richText = tester.widget<RichText>(
      find.byKey(const ValueKey('announcement-rich-text-section')),
    );
    final root = richText.text as TextSpan;

    expect(
      root.toPlainText(),
      'Highlight important parts of the announcement.',
    );
  });

  testWidgets('announcement preview recovers trimmed rich text boundaries', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerdantTheme(),
        home: const Scaffold(
          body: SingleChildScrollView(
            child: AnnouncementCardPreview(
              draft: FeedAnnouncementDraft(
                title: 'Bot post',
                color: '#1ee3b6',
                sections: [
                  FeedAnnouncementRichTextSection(
                    spans: [
                      FeedAnnouncementRichTextSpan(text: 'Status:'),
                      FeedAnnouncementRichTextSpan(
                        text: 'live from bot API',
                        style: FeedAnnouncementTextStyle(
                          weight: FeedAnnouncementTextWeight.bold,
                        ),
                      ),
                      FeedAnnouncementRichTextSpan(
                        text: 'with scoped feed allowlists.',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final richText = tester.widget<RichText>(
      find.byKey(const ValueKey('announcement-rich-text-section')),
    );
    final root = richText.text as TextSpan;

    expect(
      root.toPlainText(),
      'Status: live from bot API with scoped feed allowlists.',
    );
  });

  testWidgets('announcement preview renders bullet and numbered lists', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerdantTheme(),
        home: const Scaffold(
          body: SingleChildScrollView(
            child: AnnouncementCardPreview(
              draft: FeedAnnouncementDraft(
                title: 'List post',
                color: '#1ee3b6',
                sections: [
                  FeedAnnouncementListSection(
                    items: ['Prepare build', 'Notify members'],
                  ),
                  FeedAnnouncementListSection(
                    items: ['Stage release', 'Publish release'],
                    ordered: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('•'), findsNWidgets(2));
    expect(find.text('1.'), findsOneWidget);
    expect(find.text('2.'), findsOneWidget);
    expect(find.text('Prepare build'), findsOneWidget);
    expect(find.text('Publish release'), findsOneWidget);
  });

  testWidgets('announcement preview applies explicit text styles', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerdantTheme(),
        home: const Scaffold(
          body: SingleChildScrollView(
            child: AnnouncementCardPreview(
              draft: FeedAnnouncementDraft(
                title: 'Styled title',
                color: '#1ee3b6',
                titleStyle: FeedAnnouncementTextStyle(
                  color: '#ff5500',
                  fontSize: 17.5,
                  weight: FeedAnnouncementTextWeight.bold,
                  italic: true,
                ),
                description: 'Styled summary',
                descriptionStyle: FeedAnnouncementTextStyle(
                  size: FeedAnnouncementTextSize.sm,
                  weight: FeedAnnouncementTextWeight.medium,
                ),
                footer: 'Styled footer',
                footerStyle: FeedAnnouncementTextStyle(
                  color: '#7c3aed',
                  size: FeedAnnouncementTextSize.xs,
                  weight: FeedAnnouncementTextWeight.semibold,
                  strikethrough: true,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final title = tester.widget<Text>(find.text('Styled title'));
    final description = tester.widget<Text>(find.text('Styled summary'));
    final footer = tester.widget<Text>(find.text('Styled footer'));

    expect(title.style?.color, const Color(0xFFFF5500));
    expect(title.style?.fontSize, 17.5);
    expect(title.style?.fontWeight, FontWeight.w700);
    expect(title.style?.fontStyle, FontStyle.italic);
    expect(description.style?.fontSize, 13);
    expect(description.style?.fontWeight, FontWeight.w500);
    expect(footer.style?.color, const Color(0xFF7C3AED));
    expect(footer.style?.fontSize, 11);
    expect(footer.style?.fontWeight, FontWeight.w600);
    expect(footer.style?.decoration, TextDecoration.lineThrough);
  });
}

Widget _testYoutubePlayerBuilder(
  BuildContext context,
  Uri embedUri,
  Uri watchUri,
) {
  return ColoredBox(
    key: const ValueKey('announcement-youtube-test-player'),
    color: Colors.black,
    child: Text('${embedUri.host} ${watchUri.host}'),
  );
}

final class _RecordingAnnouncementLinkLauncher
    extends AnnouncementLinkLauncher {
  final opened = <Uri>[];

  @override
  Future<bool> openExternal(Uri uri) async {
    opened.add(uri);
    return true;
  }
}

final class _FakeClock {
  _FakeClock(this.value);

  DateTime value;

  DateTime now() => value;

  void advance(Duration duration) => value = value.add(duration);
}
