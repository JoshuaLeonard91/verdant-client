import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verdant_flutter/features/workspace/chat_workspace/announcement_feed/announcement_content_models.dart';
import 'package:verdant_flutter/features/workspace/chat_workspace/announcement_feed/announcement_feed_service.dart';
import 'package:verdant_flutter/features/workspace/chat_workspace/announcement_feed/announcement_youtube_playback_memory.dart';
import 'package:verdant_flutter/features/workspace/chat_workspace/announcement_feed_workspace.dart';
import 'package:verdant_flutter/features/workspace/server_settings_workspace/server_settings_models.dart';
import 'package:verdant_flutter/features/workspace/workspace_seed.dart';
import 'package:verdant_flutter/shared/smooth_single_child_scroll_view.dart';
import 'package:verdant_flutter/theme/verdant_theme.dart';

void main() {
  testWidgets('announcement feed loads persisted backend announcements', (
    tester,
  ) async {
    final repository = _FakeAnnouncementFeedRepository(
      records: [
        _record(
          id: 'ann-new',
          draft: const FeedAnnouncementDraft(
            title: 'Latest persisted announcement',
            description: 'Loaded from the feed API.',
            color: '#1ee3b6',
          ),
        ),
        _record(
          id: 'ann-old',
          draft: const FeedAnnouncementDraft(
            title: 'Older persisted announcement',
            description: 'Also loaded from the feed API.',
            color: '#1ee3b6',
          ),
        ),
      ],
    );

    await _pumpFeed(tester, repository: repository);

    expect(repository.listCalls, [
      (serverId: WorkspaceSeed.sample.serverId, feedId: 'feed-1'),
    ]);
    expect(find.text('Announcement builder preview'), findsNothing);
    expect(
      find.text(
        'Local preview data until feed hydration and publishing are wired.',
      ),
      findsNothing,
    );
    expect(find.text('Older persisted announcement'), findsOneWidget);
    expect(find.text('Latest persisted announcement'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('announcement-feed-timeline-list')),
      findsOneWidget,
    );
  });

  testWidgets(
    'active YouTube announcements stay alive when scrolled offscreen',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 420));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final playbackMemory = AnnouncementYouTubePlaybackMemory()
        ..record(
          const AnnouncementYouTubePlaybackUpdate(
            videoId: 'k1_ODDevbY8',
            positionSeconds: 18,
            state: 1,
            hasStarted: true,
            isPlaying: true,
          ),
        );
      final repository = _FakeAnnouncementFeedRepository(
        records: [
          for (var index = 0; index < 8; index++)
            _record(
              id: 'ann-old-$index',
              draft: FeedAnnouncementDraft(
                title: 'Older announcement $index',
                description: 'History row $index',
                color: '#1ee3b6',
                sections: const [
                  FeedAnnouncementTextSection(content: 'Older feed content.'),
                ],
              ),
            ),
          _record(
            id: 'ann-video',
            draft: const FeedAnnouncementDraft(
              title: 'Video announcement',
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
      );

      await _pumpFeed(
        tester,
        repository: repository,
        youtubePlaybackMemory: playbackMemory,
      );

      expect(
        find.byKey(
          const ValueKey('announcement-feed-test-youtube-player'),
          skipOffstage: false,
        ),
        findsOneWidget,
      );

      await tester.drag(
        find.byKey(const ValueKey('announcement-feed-timeline-list')),
        const Offset(0, 900),
      );
      await tester.pumpAndSettle();

      expect(playbackMemory.snapshotFor('k1_ODDevbY8').isPlaying, isTrue);
      expect(
        find.byKey(
          const ValueKey('announcement-feed-test-youtube-player'),
          skipOffstage: false,
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('announcement feed stops YouTube playback on route change', (
    tester,
  ) async {
    final playbackMemory = AnnouncementYouTubePlaybackMemory()
      ..record(
        const AnnouncementYouTubePlaybackUpdate(
          videoId: 'k1_ODDevbY8',
          positionSeconds: 18,
          state: 1,
          hasStarted: true,
          isPlaying: true,
        ),
      );
    final repository = _FakeAnnouncementFeedRepository(
      records: [
        _record(
          id: 'ann-video',
          draft: const FeedAnnouncementDraft(
            title: 'Video announcement',
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
    );

    await _pumpFeed(
      tester,
      repository: repository,
      youtubePlaybackMemory: playbackMemory,
    );

    expect(playbackMemory.snapshotFor('k1_ODDevbY8').isPlaying, isTrue);

    await _pumpFeed(
      tester,
      repository: repository,
      youtubePlaybackMemory: playbackMemory,
      feed: const ServerSettingsListItemSeed(
        id: 'feed-2',
        title: 'Change Logs',
        subtitle: 'Client and server notes',
      ),
    );

    expect(playbackMemory.snapshotFor('k1_ODDevbY8').isPlaying, isFalse);
  });

  testWidgets('announcement feed starts anchored at the newest bottom record', (
    tester,
  ) async {
    final records = [
      for (var index = 24; index >= 0; index -= 1)
        _record(
          id: 'ann-$index',
          draft: FeedAnnouncementDraft(
            title: index == 24
                ? 'Newest bottom announcement'
                : 'Announcement $index',
            description: 'Body for announcement $index',
            color: '#1ee3b6',
          ),
        ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerdantTheme(),
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 620,
            child: AnnouncementFeedWorkspace(
              feed: _feed,
              seed: WorkspaceSeed.sample,
              announcementRepository: _FakeAnnouncementFeedRepository(
                records: records,
              ),
              youtubePlayerBuilder: _testYoutubePlayerBuilder,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SmoothWheelScroll), findsOneWidget);

    final scrollableState = tester.state<ScrollableState>(
      find.descendant(
        of: find.byKey(const ValueKey('announcement-feed-timeline-list')),
        matching: find.byType(Scrollable),
      ),
    );
    final position = scrollableState.position;
    expect(position.pixels, closeTo(position.maxScrollExtent, 0.5));

    final latestCard = find.byKey(
      const ValueKey('announcement-feed-card-ann-24'),
    );
    expect(latestCard, findsOneWidget);
    final timelineRect = tester.getRect(
      find.byKey(const ValueKey('announcement-feed-timeline-list')),
    );
    final latestRect = tester.getRect(latestCard);
    expect(latestRect.bottom, greaterThan(timelineRect.bottom - 48));

    final latestPreview = find.descendant(
      of: latestCard,
      matching: find.byKey(const ValueKey('announcement-feed-preview-card')),
    );
    expect(latestPreview, findsOneWidget);
    final latestPreviewRect = tester.getRect(latestPreview);
    expect(
      timelineRect.bottom - latestPreviewRect.bottom,
      lessThanOrEqualTo(24),
    );
  });

  testWidgets('announcement feed publishes builder draft through repository', (
    tester,
  ) async {
    final repository = _FakeAnnouncementFeedRepository();

    await _pumpFeed(tester, repository: repository);

    await tester.tap(
      find.byKey(const ValueKey('announcement-feed-create-button')),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('announcement-builder-title-field')),
      'Patch 0.0.261',
    );
    await tester.enterText(
      find.byKey(const ValueKey('announcement-builder-description-field')),
      '<script>alert(1)</script> stays literal text',
    );
    await tester.tap(
      find.byKey(const ValueKey('announcement-builder-publish-button')),
    );
    await tester.pumpAndSettle();

    expect(
      repository.createCalls.single.serverId,
      WorkspaceSeed.sample.serverId,
    );
    expect(repository.createCalls.single.feedId, 'feed-1');
    expect(repository.createCalls.single.draft.title, 'Patch 0.0.261');
    expect(
      repository.createCalls.single.draft.description,
      '<script>alert(1)</script> stays literal text',
    );
    expect(
      find.byKey(const ValueKey('announcement-feed-builder-panel')),
      findsNothing,
    );
    expect(find.text('Patch 0.0.261'), findsOneWidget);
    expect(
      find.text('<script>alert(1)</script> stays literal text'),
      findsOneWidget,
    );
  });

  testWidgets('announcement feed shows empty persisted state without samples', (
    tester,
  ) async {
    await _pumpFeed(tester, repository: _FakeAnnouncementFeedRepository());

    expect(find.text('No announcements yet'), findsOneWidget);
    expect(find.text('Newest appears at the bottom.'), findsNothing);
    expect(find.text('Maintenance window'), findsNothing);
    expect(find.text('Quick video example'), findsNothing);
  });

  testWidgets(
    'announcement feed uses an admin-only bottom-right create action',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildVerdantTheme(),
          home: Scaffold(
            body: SizedBox(
              width: 1200,
              height: 800,
              child: AnnouncementFeedWorkspace(
                feed: _feed,
                seed: WorkspaceSeed.sample,
                announcementRepository: _FakeAnnouncementFeedRepository(),
                youtubePlayerBuilder: _testYoutubePlayerBuilder,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Create announcement'), findsNothing);
      expect(
        find.byKey(const ValueKey('announcement-feed-header-actions')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('announcement-feed-header-pin-action')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('announcement-feed-header-members-action')),
        findsOneWidget,
      );
      expect(find.text('Newest appears at the bottom.'), findsNothing);
      expect(find.text('0'), findsNothing);

      final action = find.byKey(
        const ValueKey('announcement-feed-create-button'),
      );
      expect(action, findsOneWidget);

      final workspaceRect = tester.getRect(
        find.byKey(const ValueKey('announcement-feed-workspace-surface')),
      );
      final actionRect = tester.getRect(action);

      expect(actionRect.center.dx, greaterThan(workspaceRect.right - 80));
      expect(actionRect.center.dy, greaterThan(workspaceRect.bottom - 80));
    },
  );

  testWidgets('announcement feed hides create action from viewers', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerdantTheme(),
        home: Scaffold(
          body: AnnouncementFeedWorkspace(
            feed: _feed,
            seed: _viewerSeed,
            announcementRepository: _FakeAnnouncementFeedRepository(),
            youtubePlayerBuilder: _testYoutubePlayerBuilder,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('announcement-feed-create-button')),
      findsNothing,
    );
    expect(find.text('Create announcement'), findsNothing);
  });

  testWidgets('announcement feed surfaces load failures without samples', (
    tester,
  ) async {
    await _pumpFeed(
      tester,
      repository: _FakeAnnouncementFeedRepository(
        loadError: const AnnouncementFeedException('Feed unavailable'),
      ),
    );

    expect(find.text('Feed unavailable'), findsWidgets);
    expect(find.text('Welcome to Announcements'), findsNothing);
  });

  testWidgets('announcement feed timeline spans the full workspace width', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerdantTheme(),
        home: Scaffold(
          body: SizedBox(
            width: 1600,
            height: 900,
            child: AnnouncementFeedWorkspace(
              feed: _feed,
              seed: WorkspaceSeed.sample,
              announcementRepository: _FakeAnnouncementFeedRepository(
                records: [
                  _record(
                    id: 'ann-1',
                    draft: const FeedAnnouncementDraft(
                      title: 'Full width announcement',
                      color: '#1ee3b6',
                    ),
                  ),
                ],
              ),
              youtubePlayerBuilder: _testYoutubePlayerBuilder,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final workspaceWidth = tester
        .getSize(
          find.byKey(const ValueKey('announcement-feed-workspace-surface')),
        )
        .width;
    final timelineWidth = tester
        .getSize(find.byKey(const ValueKey('announcement-feed-timeline-list')))
        .width;

    expect(timelineWidth, greaterThan(workspaceWidth - 8));
  });

  testWidgets('announcement feed opens a native structured builder', (
    tester,
  ) async {
    await _pumpFeed(tester, repository: _FakeAnnouncementFeedRepository());

    expect(find.text('Announcements'), findsWidgets);
    expect(
      find.byKey(const ValueKey('announcement-feed-builder-panel')),
      findsNothing,
    );

    await tester.tap(
      find.byKey(const ValueKey('announcement-feed-create-button')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('announcement-feed-builder-panel')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('announcement-feed-preview-card')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('announcement-builder-preview-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('announcement-builder-full-preview')),
      findsNothing,
    );
    await tester.tap(
      find.byKey(const ValueKey('announcement-builder-preview-button')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('announcement-builder-full-preview')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('announcement-feed-preview-card')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('announcement-builder-preview-close')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('announcement-builder-full-preview')),
      findsNothing,
    );
    expect(find.text('Create announcement'), findsNothing);
    expect(find.text('Structured card for Announcements'), findsNothing);
    expect(
      find.byKey(const ValueKey('announcement-builder-accent-color-picker')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('announcement-builder-accent-color-anchor')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('announcement-builder-accent-hex-field')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('announcement-builder-accent-field')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('announcement-builder-accent-color-popover')),
      findsNothing,
    );
    expect(
      find.byKey(
        const ValueKey('announcement-builder-accent-saturation-value'),
      ),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('announcement-builder-accent-hue-slider')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('announcement-builder-footer-field')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('announcement-builder-title-style-controls')),
      findsNothing,
    );
    expect(
      find.byKey(
        const ValueKey('announcement-builder-description-style-controls'),
      ),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('announcement-builder-footer-style-controls')),
      findsNothing,
    );
    await tester.tap(
      find.byKey(const ValueKey('announcement-builder-accent-color-anchor')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('announcement-builder-accent-color-popover')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('announcement-builder-accent-saturation-value'),
      ),
      findsOneWidget,
    );
    expect(
      tester
          .getSize(
            find.byKey(
              const ValueKey('announcement-builder-accent-saturation-value'),
            ),
          )
          .width,
      lessThanOrEqualTo(224),
    );
    expect(
      find.byKey(const ValueKey('announcement-builder-accent-hue-slider')),
      findsOneWidget,
    );
    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('announcement-builder-title-field')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('announcement-builder-title-style-controls')),
      findsOneWidget,
    );
    final titleRect = tester.getRect(
      find.byKey(const ValueKey('announcement-builder-title-field')),
    );
    final titleStyleRect = tester.getRect(
      find.byKey(const ValueKey('announcement-builder-title-style-controls')),
    );
    expect(titleStyleRect.bottom, lessThanOrEqualTo(titleRect.top));
    expect((titleStyleRect.width - titleRect.width).abs(), lessThan(1));
    expect(titleStyleRect.height, lessThanOrEqualTo(36));
    final sizeFieldRect = tester.getRect(
      find.byKey(const ValueKey('announcement-builder-title-font-size-field')),
    );
    final sizeField = tester.widget<TextField>(
      find.byKey(const ValueKey('announcement-builder-title-font-size-field')),
    );
    expect(sizeField.expands, isTrue);
    expect(sizeField.decoration, isNull);
    final incrementRect = tester.getRect(
      find.byKey(
        const ValueKey('announcement-builder-title-font-size-increment'),
      ),
    );
    final decrementRect = tester.getRect(
      find.byKey(
        const ValueKey('announcement-builder-title-font-size-decrement'),
      ),
    );
    expect(incrementRect.left, greaterThanOrEqualTo(sizeFieldRect.right));
    expect(decrementRect.left, greaterThanOrEqualTo(sizeFieldRect.right));
    expect(incrementRect.bottom, lessThanOrEqualTo(decrementRect.top));
    expect(find.text('Title style'), findsNothing);
    expect(find.text('Summary style'), findsNothing);
    expect(find.text('Footer style'), findsNothing);
    expect(
      find.byKey(
        const ValueKey('announcement-builder-description-style-controls'),
      ),
      findsNothing,
    );
    await tester.tap(
      find.byKey(const ValueKey('announcement-builder-description-field')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('announcement-builder-title-style-controls')),
      findsNothing,
    );
    expect(
      find.byKey(
        const ValueKey('announcement-builder-description-style-controls'),
      ),
      findsOneWidget,
    );
    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();

    expect(
      find.byKey(
        const ValueKey('announcement-builder-description-style-controls'),
      ),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('announcement-builder-add-code')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('announcement-builder-add-chart')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('announcement-builder-add-youtube')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('announcement-builder-add-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('announcement-builder-add-rich-text')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('announcement-builder-add-text')),
      findsNothing,
    );

    await tester.enterText(
      find.byKey(const ValueKey('announcement-builder-title-field')),
      'Patch 0.0.260',
    );
    await tester.enterText(
      find.byKey(const ValueKey('announcement-builder-description-field')),
      '<script>alert(1)</script> rendered as text',
    );
    final addTextButton = find.byKey(
      const ValueKey('announcement-builder-add-rich-text'),
    );
    await tester.ensureVisible(addTextButton);
    await tester.tap(addTextButton);
    await tester.pump();

    expect(
      find.byKey(const ValueKey('announcement-builder-section-0-transition')),
      findsOneWidget,
    );
    expect(find.text('Patch 0.0.260'), findsWidgets);
    expect(
      find.text('<script>alert(1)</script> rendered as text'),
      findsWidgets,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'announcement builder commits accent color from color picker hex',
    (tester) async {
      final repository = _FakeAnnouncementFeedRepository();
      await _pumpFeed(tester, repository: repository);

      await tester.tap(
        find.byKey(const ValueKey('announcement-feed-create-button')),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('announcement-builder-title-field')),
        'Custom accent',
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('announcement-builder-accent-hex-field')),
      );
      await tester.enterText(
        find.byKey(const ValueKey('announcement-builder-accent-hex-field')),
        '#ff5500',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      await tester.tap(
        find.byKey(const ValueKey('announcement-builder-publish-button')),
      );
      await tester.pumpAndSettle();

      expect(repository.createCalls.single.draft.color, '#ff5500');
    },
  );

  testWidgets('announcement builder keeps style color picker stable', (
    tester,
  ) async {
    await _pumpFeed(tester, repository: _FakeAnnouncementFeedRepository());

    await tester.tap(
      find.byKey(const ValueKey('announcement-feed-create-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('announcement-builder-title-field')),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('announcement-builder-title-color-anchor')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('announcement-builder-title-color-popover')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('announcement-builder-title-saturation-value')),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      find.byKey(const ValueKey('announcement-builder-title-style-controls')),
      findsOneWidget,
    );
  });

  testWidgets('announcement builder publishes explicit text styles', (
    tester,
  ) async {
    final repository = _FakeAnnouncementFeedRepository();
    await _pumpFeed(tester, repository: repository);

    await tester.tap(
      find.byKey(const ValueKey('announcement-feed-create-button')),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('announcement-builder-title-field')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('announcement-builder-title-field')),
      'Styled post',
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('announcement-builder-title-style-controls')),
      findsOneWidget,
    );
    await tester.enterText(
      find.byKey(const ValueKey('announcement-builder-title-font-size-field')),
      '17.5',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('announcement-builder-title-weight-bold')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('announcement-builder-title-style-italic')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('announcement-builder-description-field')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(
        const ValueKey('announcement-builder-description-font-size-field'),
      ),
      '13',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('announcement-builder-footer-field')),
    );
    await tester.tap(
      find.byKey(const ValueKey('announcement-builder-footer-field')),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('announcement-builder-footer-weight-bold')),
    );
    await tester.tap(
      find.byKey(const ValueKey('announcement-builder-footer-weight-bold')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const ValueKey('announcement-builder-footer-style-strikethrough'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('announcement-builder-publish-button')),
    );
    await tester.tap(
      find.byKey(const ValueKey('announcement-builder-publish-button')),
    );
    await tester.pumpAndSettle();

    final draft = repository.createCalls.single.draft;
    expect(draft.titleStyle?.fontSize, 17.5);
    expect(draft.titleStyle?.size, isNull);
    expect(draft.titleStyle?.weight, FeedAnnouncementTextWeight.bold);
    expect(draft.titleStyle?.italic, isTrue);
    expect(draft.descriptionStyle?.fontSize, 13);
    expect(draft.footerStyle?.weight, FeedAnnouncementTextWeight.bold);
    expect(draft.footerStyle?.strikethrough, isTrue);
  });

  testWidgets(
    'announcement builder styles selected text in one rich text field',
    (tester) async {
      final repository = _FakeAnnouncementFeedRepository();
      await _pumpFeed(tester, repository: repository);

      await tester.tap(
        find.byKey(const ValueKey('announcement-feed-create-button')),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('announcement-builder-title-field')),
        'Rich announcement',
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('announcement-builder-add-rich-text')),
      );
      await tester.tap(
        find.byKey(const ValueKey('announcement-builder-add-rich-text')),
      );
      await tester.pumpAndSettle();

      final richTextField = find.byKey(
        const ValueKey('announcement-builder-rich-text-0-field'),
      );
      await tester.ensureVisible(richTextField);
      await tester.pumpAndSettle();
      await tester.enterText(richTextField, 'Important notice');
      await tester.showKeyboard(richTextField);
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: 'Important notice',
          selection: TextSelection(baseOffset: 0, extentOffset: 10),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey(
            'announcement-builder-rich-text-0-selection-style-controls',
          ),
        ),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(
          const ValueKey(
            'announcement-builder-rich-text-0-selection-weight-bold',
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const ValueKey(
            'announcement-builder-rich-text-0-selection-style-italic',
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const ValueKey(
            'announcement-builder-rich-text-0-selection-style-strikethrough',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(
          const ValueKey(
            'announcement-builder-rich-text-0-selection-style-controls',
          ),
        ),
        findsOneWidget,
      );

      await tester.showKeyboard(richTextField);
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: 'Important notice',
          selection: TextSelection(baseOffset: 10, extentOffset: 16),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(
          const ValueKey(
            'announcement-builder-rich-text-0-selection-font-size-field',
          ),
        ),
        '16',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('announcement-builder-publish-button')),
      );
      await tester.tap(
        find.byKey(const ValueKey('announcement-builder-publish-button')),
      );
      await tester.pumpAndSettle();

      final richText =
          repository.createCalls.single.draft.sections.single
              as FeedAnnouncementRichTextSection;
      expect(richText.spans, hasLength(2));
      expect(richText.spans[0].text, 'Important ');
      expect(richText.spans[0].style?.weight, FeedAnnouncementTextWeight.bold);
      expect(richText.spans[0].style?.italic, isTrue);
      expect(richText.spans[0].style?.strikethrough, isTrue);
      expect(richText.spans[1].text, 'notice');
      expect(richText.spans[1].style?.fontSize, 16);
    },
  );

  testWidgets(
    'announcement builder wraps compact style controls at narrow widths',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(560, 820));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repository = _FakeAnnouncementFeedRepository();
      await _pumpFeed(tester, repository: repository);

      await tester.tap(
        find.byKey(const ValueKey('announcement-feed-create-button')),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('announcement-builder-add-rich-text')),
      );
      await tester.tap(
        find.byKey(const ValueKey('announcement-builder-add-rich-text')),
      );
      await tester.pumpAndSettle();

      final richTextField = find.byKey(
        const ValueKey('announcement-builder-rich-text-0-field'),
      );
      await tester.ensureVisible(richTextField);
      await tester.enterText(richTextField, 'Small client selection');
      await tester.showKeyboard(richTextField);
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: 'Small client selection',
          selection: TextSelection(baseOffset: 0, extentOffset: 6),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey(
            'announcement-builder-rich-text-0-selection-style-controls',
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey(
            'announcement-builder-rich-text-0-selection-font-size-increment',
          ),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('announcement builder publishes bullet and numbered lists', (
    tester,
  ) async {
    final repository = _FakeAnnouncementFeedRepository();
    await _pumpFeed(tester, repository: repository);

    await tester.tap(
      find.byKey(const ValueKey('announcement-feed-create-button')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('announcement-builder-title-field')),
      'List post',
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('announcement-builder-add-bullet-list')),
    );
    await tester.tap(
      find.byKey(const ValueKey('announcement-builder-add-bullet-list')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('announcement-builder-section-0-field')),
      'First item\nSecond item',
    );
    await tester.tap(
      find.byKey(const ValueKey('announcement-builder-add-number-list')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('announcement-builder-section-1-field')),
      'Step one\nStep two',
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('announcement-builder-publish-button')),
    );
    await tester.tap(
      find.byKey(const ValueKey('announcement-builder-publish-button')),
    );
    await tester.pumpAndSettle();

    final sections = repository.createCalls.single.draft.sections;
    expect(sections[0], isA<FeedAnnouncementListSection>());
    expect((sections[0] as FeedAnnouncementListSection).ordered, isFalse);
    expect((sections[0] as FeedAnnouncementListSection).items, [
      'First item',
      'Second item',
    ]);
    expect((sections[1] as FeedAnnouncementListSection).ordered, isTrue);
    expect((sections[1] as FeedAnnouncementListSection).items, [
      'Step one',
      'Step two',
    ]);
  });
}

const _feed = ServerSettingsListItemSeed(
  id: 'feed-1',
  title: 'Announcements',
  subtitle: 'Release notes and maintenance windows',
);

Future<void> _pumpFeed(
  WidgetTester tester, {
  required AnnouncementFeedRepository repository,
  AnnouncementYouTubePlaybackMemory? youtubePlaybackMemory,
  ServerSettingsListItemSeed feed = _feed,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildVerdantTheme(),
      home: Scaffold(
        body: AnnouncementFeedWorkspace(
          feed: feed,
          seed: WorkspaceSeed.sample,
          announcementRepository: repository,
          youtubePlayerBuilder: _testYoutubePlayerBuilder,
          youtubePlaybackMemory: youtubePlaybackMemory,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

FeedAnnouncementRecord _record({
  required String id,
  required FeedAnnouncementDraft draft,
}) {
  return FeedAnnouncementRecord(
    id: id,
    feedId: 'feed-1',
    serverId: WorkspaceSeed.sample.serverId,
    draft: draft,
    createdAt: '2026-06-12T12:00:00Z',
  );
}

final class _FakeAnnouncementFeedRepository
    implements AnnouncementFeedRepository {
  _FakeAnnouncementFeedRepository({
    List<FeedAnnouncementRecord> records = const [],
    this.loadError,
  }) : records = [...records];

  final List<FeedAnnouncementRecord> records;
  final Object? loadError;
  final listCalls = <({String serverId, String feedId})>[];
  final createCalls =
      <({String serverId, String feedId, FeedAnnouncementDraft draft})>[];

  @override
  Future<List<FeedAnnouncementRecord>> listFeedAnnouncements({
    required String serverId,
    required String feedId,
    int limit = 25,
    String? beforeAnnouncementId,
  }) async {
    listCalls.add((serverId: serverId, feedId: feedId));
    final error = loadError;
    if (error != null) {
      throw error;
    }
    return records;
  }

  @override
  Future<FeedAnnouncementRecord> createFeedAnnouncement({
    required String serverId,
    required String feedId,
    required FeedAnnouncementDraft draft,
  }) async {
    createCalls.add((serverId: serverId, feedId: feedId, draft: draft));
    final record = FeedAnnouncementRecord(
      id: 'ann-${records.length + 1}',
      feedId: feedId,
      serverId: serverId,
      draft: draft,
      createdAt: '2026-06-12T12:01:00Z',
    );
    records.insert(0, record);
    return record;
  }

  @override
  Future<FeedAnnouncementRecord> updateFeedAnnouncement({
    required String serverId,
    required String feedId,
    required String announcementId,
    required FeedAnnouncementDraft draft,
  }) async {
    final index = records.indexWhere((record) => record.id == announcementId);
    final record = FeedAnnouncementRecord(
      id: announcementId,
      feedId: feedId,
      serverId: serverId,
      draft: draft,
      createdAt: '2026-06-12T12:01:00Z',
      updatedAt: '2026-06-12T12:02:00Z',
    );
    if (index >= 0) {
      records[index] = record;
    }
    return record;
  }

  @override
  Future<void> deleteFeedAnnouncement({
    required String serverId,
    required String feedId,
    required String announcementId,
  }) async {
    records.removeWhere((record) => record.id == announcementId);
  }
}

final _viewerSeed = WorkspaceSeed(
  networkId: WorkspaceSeed.sample.networkId,
  serverId: WorkspaceSeed.sample.serverId,
  serverName: WorkspaceSeed.sample.serverName,
  serverOwnerId: WorkspaceSeed.sample.serverOwnerId,
  serverIconUrl: WorkspaceSeed.sample.serverIconUrl,
  serverBannerUrl: WorkspaceSeed.sample.serverBannerUrl,
  serverBannerCrop: WorkspaceSeed.sample.serverBannerCrop,
  memberCount: WorkspaceSeed.sample.memberCount,
  channels: WorkspaceSeed.sample.channels,
  members: WorkspaceSeed.sample.members,
  messages: WorkspaceSeed.sample.messages,
  serverSettings: WorkspaceSeed.sample.serverSettings.copyWith(
    canManageServer: false,
  ),
  mediaPolicy: WorkspaceSeed.sample.mediaPolicy,
  activeFeedId: WorkspaceSeed.sample.activeFeedId,
);

Widget _testYoutubePlayerBuilder(
  BuildContext context,
  Uri embedUri,
  Uri watchUri,
) {
  return ColoredBox(
    key: const ValueKey('announcement-feed-test-youtube-player'),
    color: Colors.black,
    child: Text('${embedUri.host} ${watchUri.host}'),
  );
}
