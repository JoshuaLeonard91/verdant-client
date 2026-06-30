import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RendererBinding, ScrollDirection;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verdant_flutter/app/window_focus_scope.dart';
import 'package:verdant_flutter/features/auth/auth_models.dart';
import 'package:verdant_flutter/features/workspace/chat_workspace/chat_invite_link.dart';
import 'package:verdant_flutter/features/workspace/chat_workspace/chat_workspace.dart';
import 'package:verdant_flutter/features/workspace/chat_workspace/link_preview_service.dart';
import 'package:verdant_flutter/features/workspace/chat_workspace/announcement_feed/announcement_link_launcher.dart';
import 'package:verdant_flutter/features/workspace/chat_workspace/announcement_feed/announcement_youtube_playback_memory.dart';
import 'package:verdant_flutter/features/workspace/chat_workspace/message_item.dart';
import 'package:verdant_flutter/features/workspace/chat_workspace/message_link_preview.dart';
import 'package:verdant_flutter/features/workspace/chat_workspace/message_media_preview.dart';
import 'package:verdant_flutter/features/workspace/chat_workspace/message_mentions.dart';
import 'package:verdant_flutter/features/workspace/chat_workspace/message_reaction_chip.dart';
import 'package:verdant_flutter/features/workspace/chat_workspace/message_timeline.dart';
import 'package:verdant_flutter/features/workspace/direct_messages_workspace/direct_messages_models.dart';
import 'package:verdant_flutter/features/workspace/direct_messages_workspace/dm_conversation_module.dart';
import 'package:verdant_flutter/features/workspace/server_settings_workspace/server_media_image.dart';
import 'package:verdant_flutter/features/workspace/server_settings_workspace/server_settings_models.dart';
import 'package:verdant_flutter/features/workspace/server_settings_workspace/server_media_url_policy.dart';
import 'package:verdant_flutter/features/workspace/shared/custom_expressive_asset.dart';
import 'package:verdant_flutter/features/workspace/shared/member_profile_popover.dart';
import 'package:verdant_flutter/features/workspace/shared/media_residency_scope.dart';
import 'package:verdant_flutter/features/workspace/shared/media_residency_service.dart';
import 'package:verdant_flutter/features/workspace/workspace_shell/workspace_shell.dart';
import 'package:verdant_flutter/features/workspace/workspace_seed.dart';
import 'package:verdant_flutter/theme/verdant_theme.dart';

void main() {
  tearDown(() {
    debugSetServerMediaWidgetLoader(null);
    debugConfigureServerMediaImageCacheForTesting();
    debugClearMessageTimelineScrollState();
  });

  testWidgets('chat timeline uses lazy keyed rows for a dense fake history', (
    tester,
  ) async {
    final messages = WorkspaceSeed.sample.messages;

    expect(messages.length, greaterThanOrEqualTo(200));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MessageTimeline(messages: messages, stickToBottom: false),
        ),
      ),
    );

    expect(find.byKey(ValueKey('message-row-${messages.first.id}')), findsOne);
    expect(
      find.byKey(ValueKey('message-row-${messages.last.id}')),
      findsNothing,
    );
  });

  testWidgets('chat timeline keeps playing YouTube row alive offscreen', (
    tester,
  ) async {
    const storageKey = 'youtube-playback-keepalive-timeline';
    await tester.binding.setSurfaceSize(const Size(900, 420));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final playbackMemory = AnnouncementYouTubePlaybackMemory()
      ..record(
        const AnnouncementYouTubePlaybackUpdate(
          videoId: 'k1_ODDevbY8',
          positionSeconds: 21,
          state: 1,
          hasStarted: true,
          isPlaying: true,
        ),
      );
    final messages = [
      for (var index = 0; index < 14; index++)
        MessageSeed(
          id: 'history-$index',
          authorId: 'official/user-joshy',
          author: 'Joshy',
          time: 'Today at 2:$index PM',
          body: 'History message $index',
          initials: 'JO',
        ),
      const MessageSeed(
        id: 'video-message',
        authorId: 'official/user-joshy',
        author: 'Joshy',
        time: 'Today at 2:40 PM',
        body: 'Watch https://www.youtube.com/watch?v=k1_ODDevbY8',
        initials: 'JO',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MessageTimeline(
            messages: messages,
            pageStorageKey: storageKey,
            youtubePlayerBuilder: _testYoutubePlayerBuilder,
            youtubePlaybackMemory: playbackMemory,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(
        const ValueKey('chat-timeline-test-youtube-player'),
        skipOffstage: false,
      ),
      findsOneWidget,
    );

    await tester.drag(
      find.byKey(const ValueKey('message-timeline-scrollable-$storageKey')),
      const Offset(0, 900),
    );
    await tester.pumpAndSettle();

    expect(playbackMemory.snapshotFor('k1_ODDevbY8').isPlaying, isTrue);
    expect(
      find.byKey(
        const ValueKey('chat-timeline-test-youtube-player'),
        skipOffstage: false,
      ),
      findsOneWidget,
    );
  });

  testWidgets('chat timeline exposes stable driver anchors', (tester) async {
    const storageKey = 'memory-profile-channel';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MessageTimeline(
            messages: WorkspaceSeed.sample.messages.take(3).toList(),
            pageStorageKey: storageKey,
            stickToBottom: false,
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('message-timeline-module')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('message-timeline-module-page-$storageKey')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('message-timeline-scrollable-$storageKey')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('message-timeline-start-$storageKey')),
      findsOneWidget,
    );
  });

  testWidgets('chat timeline uses its smoothed visual scrollbar', (
    tester,
  ) async {
    final messages = [
      for (var index = 0; index < 80; index += 1)
        MessageSeed(
          id: 'official/visual-scrollbar-$index',
          authorId: 'official/user-${index % 2}',
          author: index.isEven ? 'Joshy' : 'Mira',
          time: 'Today at 6:${index.toString().padLeft(2, '0')} PM',
          createdAt: DateTime(2026, 6, 5, 18, index).toUtc().toIso8601String(),
          body: 'Visual scrollbar row ${index + 1}',
          initials: index.isEven ? 'JO' : 'MI',
        ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 720,
            height: 420,
            child: MessageTimeline(
              messages: messages,
              pageStorageKey: 'visual-scrollbar-timeline',
            ),
          ),
        ),
      ),
    );
    for (var frame = 0; frame < 8; frame += 1) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    final timeline = find.byKey(const ValueKey('message-timeline-module'));
    expect(
      find.byKey(
        const ValueKey(
          'message-timeline-scroll-configuration-visual-scrollbar-timeline',
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey(
          'message-timeline-scroll-indicator-visual-scrollbar-timeline',
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey(
          'message-timeline-scroll-thumb-visual-scrollbar-timeline',
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: timeline, matching: find.byType(Scrollbar)),
      findsNothing,
    );
  });

  testWidgets('visual scrollbar waits for dynamic extent changes to settle', (
    tester,
  ) async {
    const storageKey = 'stable-visual-scrollbar-timeline';
    var messages = [
      for (var index = 0; index < 24; index += 1)
        MessageSeed(
          id: 'official/stable-scrollbar-base-$index',
          authorId: 'official/user-${index % 2}',
          author: index.isEven ? 'Joshy' : 'Mira',
          time: 'Today at 6:${index.toString().padLeft(2, '0')} PM',
          createdAt: DateTime(2026, 6, 5, 18, index).toUtc().toIso8601String(),
          body: 'Stable visual scrollbar base row ${index + 1}',
          initials: index.isEven ? 'JO' : 'MI',
        ),
    ];
    StateSetter? updateTimeline;

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          updateTimeline = setState;
          return MaterialApp(
            theme: buildVerdantTheme(),
            home: Scaffold(
              body: SizedBox(
                width: 720,
                height: 420,
                child: MessageTimeline(
                  messages: messages,
                  pageStorageKey: storageKey,
                ),
              ),
            ),
          );
        },
      ),
    );
    for (var frame = 0; frame < 10; frame += 1) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    final thumbFinder = find.byKey(
      const ValueKey('message-timeline-scroll-thumb-$storageKey'),
    );
    expect(thumbFinder, findsOneWidget);
    final beforeThumb = tester.widget<AnimatedPositioned>(thumbFinder);
    final beforeHeight = beforeThumb.height!;

    updateTimeline!(() {
      messages = [
        for (var index = 0; index < 160; index += 1)
          MessageSeed(
            id: 'official/stable-scrollbar-older-$index',
            authorId: 'official/user-${index % 2}',
            author: index.isEven ? 'Joshy' : 'Mira',
            time: 'Today at 5:${index.toString().padLeft(2, '0')} PM',
            createdAt: DateTime(
              2026,
              6,
              5,
              17,
              index,
            ).toUtc().toIso8601String(),
            body:
                'Older dynamic row ${index + 1}. '
                'This mimics media-heavy history increasing measured extent '
                'after the viewport anchor is already stable.',
            initials: index.isEven ? 'JO' : 'MI',
          ),
        ...messages,
      ];
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    final immediateThumb = tester.widget<AnimatedPositioned>(thumbFinder);
    expect(immediateThumb.height, closeTo(beforeHeight, 0.1));

    await tester.pump(const Duration(milliseconds: 220));
    await tester.pump(const Duration(milliseconds: 16));

    final settledThumb = tester.widget<AnimatedPositioned>(thumbFinder);
    expect(settledThumb.height, lessThan(beforeHeight - 1));
  });

  testWidgets('visual scrollbar thumb can be dragged vertically', (
    tester,
  ) async {
    const storageKey = 'draggable-visual-scrollbar-timeline';
    final messages = [
      for (var index = 0; index < 120; index += 1)
        MessageSeed(
          id: 'official/draggable-scrollbar-$index',
          authorId: 'official/user-${index % 2}',
          author: index.isEven ? 'Joshy' : 'Mira',
          time: 'Today at 6:${index.toString().padLeft(2, '0')} PM',
          createdAt: DateTime(2026, 6, 5, 18, index).toUtc().toIso8601String(),
          body: 'Draggable visual scrollbar row ${index + 1}',
          initials: index.isEven ? 'JO' : 'MI',
        ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerdantTheme(),
        home: Scaffold(
          body: SizedBox(
            width: 720,
            height: 420,
            child: MessageTimeline(
              messages: messages,
              pageStorageKey: storageKey,
            ),
          ),
        ),
      ),
    );
    for (var frame = 0; frame < 10; frame += 1) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    final scrollable = tester.state<ScrollableState>(
      find.byType(Scrollable).last,
    );
    scrollable.position.jumpTo(scrollable.position.minScrollExtent);
    await tester.pump(const Duration(milliseconds: 16));
    final beforeOffset = scrollable.position.pixels;

    final hitTarget = find.byKey(
      const ValueKey('message-timeline-scrollbar-hit-$storageKey'),
    );
    expect(hitTarget, findsOneWidget);

    await tester.drag(hitTarget, const Offset(0, 160));
    await tester.pump(const Duration(milliseconds: 16));

    expect(scrollable.position.pixels, greaterThan(beforeOffset + 400));
  });

  testWidgets('message body text follows the active theme color', (
    tester,
  ) async {
    const body = 'Light mode message text should stay readable';

    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerdantTheme(mode: VerdantThemeMode.light),
        home: Scaffold(
          body: MessageItem(
            message: MessageSeed(
              id: 'official/light-text-message',
              authorId: 'official/176495712701775872',
              author: 'Joshy',
              time: 'Today at 7:30 PM',
              createdAt: DateTime(2026, 6, 6, 19, 30).toIso8601String(),
              body: body,
              initials: 'JO',
            ),
            showHeader: true,
            mediaPolicy: ServerMediaPolicy.fromOrigins(
              apiOrigin: 'https://api.verdant.chat',
            ),
          ),
        ),
      ),
    );

    final text = tester.widget<Text>(find.text(body));

    expect(text.style?.color, VerdantThemeColors.light.text);
  });

  testWidgets('message avatar stays aligned with author beside tall media', (
    tester,
  ) async {
    const networkId = 'origin:https%3A%2F%2Fapi.verdant.chat';
    const authorId = '$networkId/user-cyra';
    const messageId = '$networkId/message-tall-media';

    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerdantTheme(),
        home: Scaffold(
          body: SizedBox(
            width: 720,
            child: MessageItem(
              message: const MessageSeed(
                id: messageId,
                authorId: authorId,
                author: 'Cyra Loop',
                time: '06/10/2026 at 1:59 PM',
                createdAt: '2026-06-10T17:59:00.000Z',
                body: '[flutter-media-fixture:151] Cyra Loop animated probe',
                initials: 'CL',
                media: MessageMediaSeed(
                  id: '$messageId/media',
                  label: 'Klipy media',
                  kind: MessageMediaKind.webp,
                  width: 640,
                  height: 480,
                ),
              ),
              showHeader: true,
              mediaPolicy: ServerMediaPolicy.fromOrigins(
                apiOrigin: officialApiOrigin,
              ),
            ),
          ),
        ),
      ),
    );

    final avatar = find.byKey(const ValueKey('message-avatar-$authorId'));
    final authorName = find.byKey(
      const ValueKey('message-author-name-$authorId'),
    );

    expect(avatar, findsOneWidget);
    expect(authorName, findsOneWidget);
    expect(
      (tester.getTopLeft(avatar).dy - tester.getTopLeft(authorName).dy).abs(),
      lessThanOrEqualTo(6),
    );
  });

  testWidgets('message body highlights scoped member mentions', (tester) async {
    const networkId = 'origin:https%3A%2F%2Fapi-test.pryzmapp.com';

    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerdantTheme(),
        home: Scaffold(
          body: SizedBox(
            width: 720,
            height: 420,
            child: MessageTimeline(
              networkId: networkId,
              stickToBottom: false,
              members: const [
                MemberSeed(
                  id: '$networkId/user-joshy',
                  name: 'Joshy',
                  status: 'Online',
                  initials: 'JO',
                ),
              ],
              messages: const [
                MessageSeed(
                  id: '$networkId/message-mention',
                  authorId: '$networkId/user-avery',
                  author: 'Avery',
                  time: '6:46 PM',
                  body: 'Ship this with @{Joshy}',
                  initials: 'AV',
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final mention = find.byKey(
      const ValueKey(
        'message-mention-pill-$networkId/message-mention-user-joshy',
      ),
    );
    expect(mention, findsOneWidget);
    expect(
      find.descendant(of: mention, matching: find.text('@Joshy')),
      findsOneWidget,
    );

    final surface = tester.widget<AnimatedContainer>(
      find.descendant(of: mention, matching: find.byType(AnimatedContainer)),
    );
    final decoration = surface.decoration! as BoxDecoration;
    expect(decoration.color, const Color(0x264ADE80));

    final mentionText = tester.widget<Text>(
      find.descendant(of: mention, matching: find.text('@Joshy')),
    );
    expect(mentionText.style?.color, const Color(0xFF4ADE80));
    expect(mentionText.style?.backgroundColor, Colors.transparent);
    expect(
      tester
          .widgetList<MouseRegion>(
            find.descendant(of: mention, matching: find.byType(MouseRegion)),
          )
          .any((region) => region.cursor == SystemMouseCursors.click),
      isTrue,
    );
    await _expectActiveMouseCursor(tester, mention, SystemMouseCursors.click);
  });

  testWidgets('loaded scoped mention tokens render as member pills', (
    tester,
  ) async {
    const networkId = 'origin:https%3A%2F%2Fapi-test.pryzmapp.com';
    const messageId = '$networkId/message-encoded-scoped-mention';

    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerdantTheme(),
        home: Scaffold(
          body: SizedBox(
            width: 720,
            height: 420,
            child: MessageTimeline(
              networkId: networkId,
              stickToBottom: false,
              members: const [
                MemberSeed(
                  id: '$networkId/user-joshy',
                  name: 'Joshy',
                  username: 'joshy',
                  status: 'Online',
                  initials: 'JO',
                ),
              ],
              messages: const [
                MessageSeed(
                  id: messageId,
                  authorId: '$networkId/user-avery',
                  author: 'Avery',
                  time: '6:46 PM',
                  body:
                      'Ship this with @origin:https%3A%2F%2Fapi-test.pryzmapp.com%2Fuser-joshy',
                  initials: 'AV',
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final mention = find.byKey(
      const ValueKey('message-mention-pill-$messageId-user-joshy'),
    );
    expect(mention, findsOneWidget);
    expect(
      find.descendant(of: mention, matching: find.text('@Joshy')),
      findsOneWidget,
    );
  });

  testWidgets('broadcast mentions use uniform clickable mention pills', (
    tester,
  ) async {
    const networkId = 'origin:https%3A%2F%2Fapi.verdant.chat';
    const messageId = '$networkId/message-broadcast-mentions';

    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerdantTheme(),
        home: Scaffold(
          body: SizedBox(
            width: 720,
            height: 420,
            child: MessageItem(
              message: const MessageSeed(
                id: messageId,
                authorId: '$networkId/user-avery',
                author: 'Avery',
                time: '6:46 PM',
                body: 'Ping @here and @everyone',
                initials: 'AV',
              ),
              networkId: networkId,
              showHeader: true,
              mediaPolicy: ServerMediaPolicy.fromOrigins(
                apiOrigin: officialApiOrigin,
              ),
            ),
          ),
        ),
      ),
    );

    final hereMention = find.byKey(
      const ValueKey('message-mention-pill-$messageId-here'),
    );
    final everyoneMention = find.byKey(
      const ValueKey('message-mention-pill-$messageId-everyone'),
    );
    expect(hereMention, findsOneWidget);
    expect(everyoneMention, findsOneWidget);

    for (final mention in [hereMention, everyoneMention]) {
      final mentionText = tester.widget<Text>(
        find.descendant(of: mention, matching: find.byType(Text)),
      );
      expect(mentionText.style?.color, const Color(0xFF4ADE80));
      expect(mentionText.style?.backgroundColor, Colors.transparent);
      expect(
        tester
            .widgetList<MouseRegion>(
              find.descendant(of: mention, matching: find.byType(MouseRegion)),
            )
            .any((region) => region.cursor == SystemMouseCursors.click),
        isTrue,
      );
      await _expectActiveMouseCursor(tester, mention, SystemMouseCursors.click);
    }

    expect(
      tester.getSize(hereMention).height,
      tester.getSize(everyoneMention).height,
    );
  });

  testWidgets('message mention rendering ignores other network members', (
    tester,
  ) async {
    const officialNetworkId = 'origin:https%3A%2F%2Fapi.verdant.chat';
    const selfHostNetworkId = 'origin:https%3A%2F%2Fapi-test.pryzmapp.com';

    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerdantTheme(),
        home: Scaffold(
          body: SizedBox(
            width: 720,
            height: 420,
            child: MessageTimeline(
              networkId: officialNetworkId,
              stickToBottom: false,
              members: const [
                MemberSeed(
                  id: '$selfHostNetworkId/user-joshy',
                  name: 'Joshy',
                  status: 'Online',
                  initials: 'JO',
                ),
                MemberSeed(
                  id: '$officialNetworkId/user-avery',
                  name: 'Avery',
                  status: 'Online',
                  initials: 'AV',
                ),
              ],
              messages: const [
                MessageSeed(
                  id: '$officialNetworkId/message-mention',
                  authorId: '$officialNetworkId/user-avery',
                  author: 'Avery',
                  time: '6:46 PM',
                  body: 'Ping @{Joshy} and @{Avery}',
                  initials: 'AV',
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final unresolvedBodyFinder = find.byWidgetPredicate(
      (widget) =>
          widget is Text &&
          _textWidgetText(widget).contains('Ping @{Joshy} and '),
    );
    expect(unresolvedBodyFinder, findsOneWidget);

    expect(
      find.byKey(
        const ValueKey(
          'message-mention-pill-$officialNetworkId/message-mention-user-joshy',
        ),
      ),
      findsNothing,
    );
    final averyMention = find.byKey(
      const ValueKey(
        'message-mention-pill-$officialNetworkId/message-mention-user-avery',
      ),
    );
    expect(averyMention, findsOneWidget);
    expect(
      find.descendant(of: averyMention, matching: find.text('@Avery')),
      findsOneWidget,
    );
  });

  testWidgets('message mention tokens resolve through the active network id', (
    tester,
  ) async {
    const officialNetworkId = 'origin:https%3A%2F%2Fapi.verdant.chat';
    const selfHostNetworkId = 'origin:https%3A%2F%2Fapi-test.pryzmapp.com';

    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerdantTheme(),
        home: Scaffold(
          body: SizedBox(
            width: 720,
            height: 420,
            child: MessageTimeline(
              networkId: officialNetworkId,
              stickToBottom: false,
              members: const [
                MemberSeed(
                  id: '$selfHostNetworkId/user-joshy',
                  name: 'Self-host Joshy',
                  status: 'Online',
                  initials: 'SJ',
                ),
                MemberSeed(
                  id: '$officialNetworkId/user-joshy',
                  name: 'Official Joshy',
                  status: 'Online',
                  initials: 'OJ',
                ),
              ],
              messages: const [
                MessageSeed(
                  id: '$officialNetworkId/message-network-mention',
                  authorId: '$officialNetworkId/user-avery',
                  author: 'Avery',
                  time: '6:46 PM',
                  body: 'Ping @user-joshy',
                  initials: 'AV',
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final mention = find.byKey(
      const ValueKey(
        'message-mention-pill-$officialNetworkId/message-network-mention-user-joshy',
      ),
    );
    expect(mention, findsOneWidget);
    expect(
      find.descendant(of: mention, matching: find.text('@Official Joshy')),
      findsOneWidget,
    );
    expect(find.text('@Self-host Joshy'), findsNothing);
  });

  testWidgets(
    'message name mentions collapse duplicate same-user projections',
    (tester) async {
      const networkId = 'origin:https%3A%2F%2Fapi.verdant.chat';
      const messageId = '$networkId/message-duplicate-projection-mention';

      await tester.pumpWidget(
        MaterialApp(
          theme: buildVerdantTheme(),
          home: Scaffold(
            body: SizedBox(
              width: 720,
              height: 420,
              child: MessageTimeline(
                networkId: networkId,
                stickToBottom: false,
                members: const [
                  MemberSeed(
                    id: '$networkId/user-joshy',
                    name: 'Joshy',
                    username: 'Josh',
                    status: 'Online',
                    initials: 'JO',
                  ),
                  MemberSeed(
                    id: 'user-joshy',
                    name: 'Joshy',
                    username: 'Josh',
                    status: 'Online',
                    initials: 'JO',
                  ),
                ],
                messages: const [
                  MessageSeed(
                    id: messageId,
                    authorId: '$networkId/user-avery',
                    author: 'Avery',
                    time: '6:46 PM',
                    body: 'Ping @Joshy and @Josh',
                    initials: 'AV',
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      final mention = find.byKey(
        const ValueKey('message-mention-pill-$messageId-user-joshy'),
      );
      expect(mention, findsNWidgets(2));
      expect(
        find.descendant(of: mention.first, matching: find.text('@Joshy')),
        findsOneWidget,
      );
    },
  );

  testWidgets('message user mentions open profiles and copy only user id', (
    tester,
  ) async {
    const networkId = 'origin:https%3A%2F%2Fapi.verdant.chat';
    const memberId = '$networkId/user-joshy';
    const messageId = '$networkId/message-mention-click';
    final clipboardWrites = <Object?>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboardWrites.add(call.arguments);
        }
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerdantTheme(),
        home: Scaffold(
          body: SizedBox(
            width: 720,
            height: 420,
            child: MessageItem(
              message: const MessageSeed(
                id: messageId,
                authorId: '$networkId/user-avery',
                author: 'Avery',
                time: '6:46 PM',
                body: 'Ping @user-joshy, @here, and @everyone',
                initials: 'AV',
              ),
              networkId: networkId,
              mentionMembers: const [
                MemberSeed(
                  id: memberId,
                  name: 'Joshy',
                  username: 'joshy',
                  status: 'Online',
                  initials: 'JO',
                ),
              ],
              showHeader: true,
              mediaPolicy: ServerMediaPolicy.fromOrigins(
                apiOrigin: officialApiOrigin,
              ),
            ),
          ),
        ),
      ),
    );

    final mention = find.byKey(
      const ValueKey('message-mention-pill-$messageId-user-joshy'),
    );
    expect(mention, findsOneWidget);
    expect(
      find.byKey(const ValueKey('message-mention-pill-$messageId-here')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('message-mention-pill-$messageId-everyone')),
      findsOneWidget,
    );

    await tester.tap(mention);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('member-profile-popover-$memberId')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('member-profile-backend-$memberId')),
      findsNothing,
    );
    expect(find.textContaining('Homeserver:'), findsNothing);
    expect(
      find.byKey(const ValueKey('member-profile-copy-origin-id-$memberId')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('member-profile-copy-user-id-$memberId')),
      findsOneWidget,
    );
    final fallbackBanner = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byKey(const ValueKey('member-banner-fallback-$memberId')),
        matching: find.byType(DecoratedBox),
      ),
    );
    final fallbackDecoration = fallbackBanner.decoration as BoxDecoration;
    final fallbackGradient = fallbackDecoration.gradient as LinearGradient;
    expect(fallbackGradient.colors.first, isNot(VerdantColors.panelRaised));
    final profileCard = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('member-profile-popover-card-$memberId')),
    );
    final profileDecoration = profileCard.decoration as BoxDecoration;
    final profileShadows = profileDecoration.boxShadow ?? const <BoxShadow>[];
    expect(profileShadows.length, greaterThanOrEqualTo(3));
    expect(
      profileShadows.any((shadow) => shadow.color != const Color(0x88000000)),
      isTrue,
    );
    final overlayRect = tester.getRect(
      find.byKey(const ValueKey('member-profile-popover-$memberId')),
    );
    final clientRect = tester.getRect(find.byType(Scaffold));
    expect(overlayRect.left, greaterThanOrEqualTo(clientRect.left));
    expect(overlayRect.top, greaterThanOrEqualTo(clientRect.top));
    expect(overlayRect.right, lessThanOrEqualTo(clientRect.right));
    expect(overlayRect.bottom, lessThanOrEqualTo(clientRect.bottom));

    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();

    await tester.tapAt(
      tester.getCenter(mention),
      buttons: kSecondaryMouseButton,
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(
        const ValueKey('message-mention-context-menu-$messageId-user-joshy'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('message-context-menu-$messageId')),
      findsNothing,
    );
    expect(find.text('Copy User ID'), findsOneWidget);
    expect(find.text('Profile'), findsNothing);
    expect(find.text('Copy Text'), findsNothing);
    expect(find.text('Add Reaction'), findsNothing);
    expect(find.text('Select all'), findsNothing);
    expect(find.text('Select All'), findsNothing);

    await tester.tap(
      find.byKey(
        const ValueKey('message-context-menu-item-surface-copy_user_id'),
      ),
    );
    await tester.pumpAndSettle();

    expect(clipboardWrites, [
      {'text': 'origin:https%3A%2F%2Fapi.verdant.chat/user-joshy'},
    ]);
  });

  testWidgets('member profile can copy federated origin id', (tester) async {
    const networkId = 'origin:https%3A%2F%2Fapi-test.pryzmapp.com';
    const memberId = '$networkId/fed_129fa6f4b31ac2c4a38906be';
    const messageId = '$networkId/message-origin-profile';
    final clipboardWrites = <Map<String, Object?>>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboardWrites.add(Map<String, Object?>.from(call.arguments as Map));
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerdantTheme(),
        home: Scaffold(
          body: SizedBox(
            width: 360,
            height: 360,
            child: MessageItem(
              message: const MessageSeed(
                id: messageId,
                authorId: '$networkId/user-avery',
                author: 'Avery',
                time: '6:52 PM',
                body: 'Ping @fed_129fa6f4b31ac2c4a38906be',
                initials: 'AV',
              ),
              networkId: networkId,
              mentionMembers: const [
                MemberSeed(
                  id: memberId,
                  name: 'Joshy',
                  username: 'fed_129fa6f4b31ac2c4a38906be',
                  status: 'Online',
                  initials: 'JO',
                  originIdentity: FederatedOriginIdentity(
                    homePeerId: 'host:api.verdant.chat',
                    remoteUserId: '42',
                    remoteUsername: 'joshy',
                  ),
                ),
              ],
              showHeader: true,
              mediaPolicy: ServerMediaPolicy.fromOrigins(
                apiOrigin: 'https://api-test.pryzmapp.com',
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(
      find.byKey(
        const ValueKey(
          'message-mention-pill-$messageId-fed_129fa6f4b31ac2c4a38906be',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Homeserver:'), findsNothing);
    expect(find.text('Copy Origin ID'), findsOneWidget);
    expect(find.text('Copy User ID'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('member-profile-copy-origin-id-$memberId')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('member-profile-copy-user-id-$memberId')),
      findsOneWidget,
    );
    final overlayRect = tester.getRect(
      find.byKey(const ValueKey('member-profile-popover-$memberId')),
    );
    final clientRect = tester.getRect(find.byType(Scaffold));
    expect(overlayRect.bottom, lessThanOrEqualTo(clientRect.bottom));

    await tester.tap(
      find.byKey(const ValueKey('member-profile-copy-origin-id-$memberId')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('member-profile-copy-user-id-$memberId')),
    );
    await tester.pumpAndSettle();

    expect(clipboardWrites, [
      {'text': 'host:api.verdant.chat/42'},
      {
        'text':
            'origin:https%3A%2F%2Fapi-test.pryzmapp.com/fed_129fa6f4b31ac2c4a38906be',
      },
    ]);
  });

  testWidgets('member profile fallback banner uses configured base color', (
    tester,
  ) async {
    const networkId = 'origin:https%3A%2F%2Fapi.verdant.chat';
    const memberId = '$networkId/user-joshy';
    const messageId = '$networkId/message-mention-color';
    const baseColor = Color(0xFF2EC4B6);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerdantTheme(),
        home: Scaffold(
          body: SizedBox(
            width: 720,
            height: 420,
            child: MessageItem(
              message: const MessageSeed(
                id: messageId,
                authorId: '$networkId/user-avery',
                author: 'Avery',
                time: '6:46 PM',
                body: 'Ping @user-joshy',
                initials: 'AV',
              ),
              networkId: networkId,
              mentionMembers: const [
                MemberSeed(
                  id: memberId,
                  name: 'Joshy',
                  username: 'joshy',
                  status: 'Online',
                  initials: 'JO',
                  bannerBaseColor: baseColor,
                ),
              ],
              showHeader: true,
              mediaPolicy: ServerMediaPolicy.fromOrigins(
                apiOrigin: officialApiOrigin,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey('message-mention-pill-$messageId-user-joshy')),
    );
    await tester.pumpAndSettle();

    final fallbackBanner = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byKey(const ValueKey('member-banner-fallback-$memberId')),
        matching: find.byType(DecoratedBox),
      ),
    );
    final fallbackDecoration = fallbackBanner.decoration as BoxDecoration;
    final fallbackGradient = fallbackDecoration.gradient as LinearGradient;
    expect(fallbackGradient.colors.first, baseColor);
    expect(
      tester
          .getSize(
            find.byKey(const ValueKey('member-banner-fallback-$memberId')),
          )
          .height,
      108,
    );
  });

  testWidgets(
    'chat author member identity popover uses message banner base color',
    (tester) async {
      const networkId = 'origin:https%3A%2F%2Fapi.verdant.chat';
      const authorId = '$networkId/user-joshy';
      const messageId = '$networkId/message-author-banner-color';
      const baseColor = Color(0xFF2EC4B6);
      final avatarColor = avatarColorFor('Joshy');

      await tester.pumpWidget(
        MaterialApp(
          theme: buildVerdantTheme(),
          home: Scaffold(
            body: SizedBox(
              width: 720,
              height: 420,
              child: MessageItem(
                message: const MessageSeed(
                  id: messageId,
                  authorId: authorId,
                  author: 'Joshy',
                  time: '6:46 PM',
                  body: 'This should show my default banner color.',
                  initials: 'JO',
                  authorBannerBaseColor: baseColor,
                ),
                networkId: networkId,
                showHeader: true,
                mediaPolicy: ServerMediaPolicy.fromOrigins(
                  apiOrigin: officialApiOrigin,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey('message-author-name-$authorId')),
      );
      await tester.pumpAndSettle();

      final fallbackBanner = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byKey(const ValueKey('member-banner-fallback-$authorId')),
          matching: find.byType(DecoratedBox),
        ),
      );
      final fallbackDecoration = fallbackBanner.decoration as BoxDecoration;
      final fallbackGradient = fallbackDecoration.gradient as LinearGradient;
      expect(fallbackGradient.colors.first, baseColor);
      expect(
        tester
            .getSize(
              find.byKey(const ValueKey('member-banner-fallback-$authorId')),
            )
            .height,
        108,
      );

      final avatarDecorations = find
          .descendant(
            of: find.byKey(const ValueKey('member-avatar-fallback-$authorId')),
            matching: find.byType(DecoratedBox),
          )
          .evaluate()
          .map((element) => (element.widget as DecoratedBox).decoration)
          .whereType<BoxDecoration>()
          .toList();
      expect(
        avatarDecorations.any((decoration) => decoration.color == avatarColor),
        isTrue,
      );
      expect(
        avatarDecorations.any((decoration) => decoration.color == baseColor),
        isFalse,
      );
    },
  );

  testWidgets(
    'chat workspace renders backend mention tokens as highlighted names',
    (tester) async {
      const networkId = 'origin:https%3A%2F%2Fapi-test.pryzmapp.com';
      final seed = _workspaceSeedWithMembersAndMessages(
        networkId: networkId,
        members: const [
          MemberSeed(
            id: '$networkId/user-joshy',
            name: 'Joshy',
            status: 'Online',
            initials: 'JO',
          ),
        ],
        messages: const [
          MessageSeed(
            id: '$networkId/message-token-mention',
            authorId: '$networkId/user-avery',
            author: 'Avery',
            time: '6:46 PM',
            body: 'Ship this with @user-joshy',
            initials: 'AV',
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: buildVerdantTheme(),
          home: Scaffold(
            body: SizedBox(
              width: 900,
              height: 700,
              child: ChatWorkspace(
                seed: seed,
                currentUserId: 'user-avery',
                currentUserName: 'Avery',
                currentUserInitials: 'AV',
              ),
            ),
          ),
        ),
      );

      final mention = find.byKey(
        const ValueKey(
          'message-mention-pill-$networkId/message-token-mention-user-joshy',
        ),
      );
      expect(mention, findsOneWidget);
      expect(
        find.descendant(of: mention, matching: find.text('@Joshy')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'chat workspace resolves mentions from the full hydrated member list',
    (tester) async {
      const networkId = 'origin:https%3A%2F%2Fapi-test.pryzmapp.com';
      const messageId = '$networkId/message-full-member-list-mention';
      final settings = ServerSettingsData(
        networkId: networkId,
        server: const ServerSettingsServer(
          id: 'server-1',
          name: 'Verdant',
          ownerId: 'user-0',
          voiceBitrate: 64000,
          bannerOffsetY: 50,
          memberCount: 30,
          large: false,
          createdAt: '',
          updatedAt: '',
        ),
        channels: const [
          ServerSettingsChannelSeed(id: 'general', name: 'general'),
        ],
        emojis: const <ServerSettingsListItemSeed>[],
        invites: const <ServerSettingsListItemSeed>[],
        roles: const <ServerSettingsListItemSeed>[],
        members: [
          for (var index = 0; index < 30; index += 1)
            ServerSettingsListItemSeed(
              userId: 'user-$index',
              title: index == 29 ? 'Joshy' : 'Member $index',
              username: index == 29 ? 'joshy' : 'member$index',
              subtitle: 'offline - joined Jun 1',
              trailing: '0 roles',
            ),
        ],
        auditEvents: const <ServerSettingsListItemSeed>[],
        feeds: const <ServerSettingsListItemSeed>[],
        bots: const <ServerSettingsListItemSeed>[],
      );
      final seed = WorkspaceSeed.fromSettingsData(
        settings,
        currentUserId: 'user-0',
        currentUserName: 'Member 0',
        currentUserInitials: 'M0',
        messages: const [
          MessageSeed(
            id: messageId,
            authorId: 'user-0',
            author: 'Member 0',
            time: '6:46 PM',
            body: 'Ping @user-29',
            initials: 'M0',
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: buildVerdantTheme(),
          home: Scaffold(
            body: SizedBox(
              width: 900,
              height: 700,
              child: ChatWorkspace(
                seed: seed,
                currentUserId: 'user-0',
                currentUserName: 'Member 0',
                currentUserInitials: 'M0',
              ),
            ),
          ),
        ),
      );

      final mention = find.byKey(
        const ValueKey('message-mention-pill-$messageId-user-29'),
      );
      expect(mention, findsOneWidget);
      expect(
        find.descendant(of: mention, matching: find.text('@Joshy')),
        findsOneWidget,
      );
    },
  );

  testWidgets('chat workspace sends typed member mentions as local tokens', (
    tester,
  ) async {
    const networkId = 'origin:https%3A%2F%2Fapi-test.pryzmapp.com';
    final sent = <String>[];
    final seed = _workspaceSeedWithMembersAndMessages(
      networkId: networkId,
      members: const [
        MemberSeed(
          id: '$networkId/user-joshy',
          name: 'Joshy',
          status: 'Online',
          initials: 'JO',
        ),
      ],
      messages: const [],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerdantTheme(),
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 700,
            child: ChatWorkspace(
              seed: seed,
              currentUserId: 'user-avery',
              currentUserName: 'Avery',
              currentUserInitials: 'AV',
              onSendMessage: (body) async => sent.add(body),
            ),
          ),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('composer-message-field')),
      'ship it @Joshy',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('composer-send-button')));
    await tester.pump();

    expect(sent, ['ship it @user-joshy']);
  });

  testWidgets(
    'chat workspace mention suggestions prefer richer duplicate projections',
    (tester) async {
      const networkId = 'origin:https%3A%2F%2Fapi-test.pryzmapp.com';
      final seed = _workspaceSeedWithMembersAndMessages(
        networkId: networkId,
        members: const [],
        messages: const [],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: buildVerdantTheme(),
          home: Scaffold(
            body: SizedBox(
              width: 900,
              height: 700,
              child: ChatWorkspace(
                seed: seed,
                currentUserId: 'user-avery',
                currentUserName: 'Avery',
                currentUserInitials: 'AV',
                identityMembers: const [
                  MemberSeed(
                    id: '$networkId/user-joshy',
                    name: 'Joshy',
                    username: 'temp_joshy',
                    status: 'Offline',
                    initials: 'JO',
                  ),
                  MemberSeed(
                    id: '$networkId/user-joshy',
                    name: 'Joshy',
                    username: 'joshy_perm',
                    status: 'dnd',
                    initials: 'JO',
                    avatarUrl: 'https://cdn.pryzmapp.com/avatars/joshy.webp',
                    bannerUrl: 'https://cdn.pryzmapp.com/banners/joshy.webp',
                    memberListBannerUrl:
                        'https://cdn.pryzmapp.com/member-list/joshy.webp',
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const ValueKey('composer-message-field')),
        '@Jo',
      );
      await tester.pump();

      expect(
        find.byKey(const ValueKey('composer-mention-suggestion-user-joshy')),
        findsOneWidget,
      );
      expect(find.text('@joshy_perm'), findsOneWidget);
      expect(find.text('@temp_joshy'), findsNothing);
      expect(
        find.byKey(
          const ValueKey('composer-mention-suggestion-avatar-user-joshy'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('composer-mention-suggestion-banner-user-joshy'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'chat workspace mention suggestions collapse duplicate permanent usernames',
    (tester) async {
      const networkId = 'origin:https%3A%2F%2Fapi-test.pryzmapp.com';
      final sent = <String>[];
      final seed = _workspaceSeedWithMembersAndMessages(
        networkId: networkId,
        members: const [],
        messages: const [],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: buildVerdantTheme(),
          home: Scaffold(
            body: SizedBox(
              width: 900,
              height: 700,
              child: ChatWorkspace(
                seed: seed,
                currentUserId: 'user-avery',
                currentUserName: 'Avery',
                currentUserInitials: 'AV',
                identityMembers: const [
                  MemberSeed(
                    id: '$networkId/user-stale',
                    name: 'Joshy',
                    username: 'joshy_perm',
                    status: 'Offline',
                    initials: 'JO',
                  ),
                  MemberSeed(
                    id: '$networkId/user-joshy',
                    name: 'Joshy',
                    username: 'joshy_perm',
                    status: 'dnd',
                    initials: 'JO',
                    avatarUrl: 'https://cdn.pryzmapp.com/avatars/joshy.webp',
                  ),
                ],
                onSendMessage: (body) async => sent.add(body),
              ),
            ),
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const ValueKey('composer-message-field')),
        '@joshy',
      );
      await tester.pump();

      expect(
        find.byKey(const ValueKey('composer-mention-suggestion-user-stale')),
        findsNothing,
      );
      final suggestion = find.byKey(
        const ValueKey('composer-mention-suggestion-user-joshy'),
      );
      expect(suggestion, findsOneWidget);
      expect(find.text('@joshy_perm'), findsOneWidget);

      await tester.tap(suggestion);
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('composer-send-button')));
      await tester.pump();

      expect(sent, ['@user-joshy']);
    },
  );

  testWidgets('chat workspace mention suggestions never expose raw user ids', (
    tester,
  ) async {
    const networkId = 'origin:https%3A%2F%2Fapi-test.pryzmapp.com';
    const localUserId = '176495712701775872';
    final seed = _workspaceSeedWithMembersAndMessages(
      networkId: networkId,
      members: const [],
      messages: const [],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerdantTheme(),
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 700,
            child: ChatWorkspace(
              seed: seed,
              currentUserId: 'user-avery',
              currentUserName: 'Avery',
              currentUserInitials: 'AV',
              identityMembers: const [
                MemberSeed(
                  id: '$networkId/$localUserId',
                  name: 'Joshy',
                  username: 'Josh',
                  status: 'Online',
                  initials: 'JO',
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('composer-message-field')),
      '@Jo',
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('composer-mention-suggestion-$localUserId')),
      findsOneWidget,
    );
    expect(find.text('@$localUserId'), findsNothing);
    expect(find.text('@Josh'), findsOneWidget);
    expect(find.text('Member'), findsNothing);
  });

  test(
    'workspace shell member merge keeps usernames from scoped server rows',
    () {
      const networkId = 'origin:https%3A%2F%2Fapi-test.pryzmapp.com';
      const localUserId = '176495712701775872';

      final merged = debugMergeChatMembersForTesting(
        const [
          MemberSeed(
            id: '$networkId/$localUserId',
            name: 'Joshy',
            username: 'Josh',
            status: 'dnd',
            initials: 'JO',
            role: 'Purple',
            avatarUrl: 'https://cdn.pryzmapp.com/avatars/joshy.webp',
            memberListBannerUrl:
                'https://cdn.pryzmapp.com/member-list/joshy.webp',
          ),
        ],
        const [
          MemberSeed(
            id: localUserId,
            name: 'Joshy',
            status: 'Online',
            initials: 'JO',
          ),
        ],
      );

      expect(merged, hasLength(1));
      expect(merged.single.id, '$networkId/$localUserId');
      expect(merged.single.username, 'Josh');
      expect(merged.single.role, 'Purple');
      expect(merged.single.status, 'Online');
      expect(merged.single.avatarUrl, contains('/avatars/joshy.webp'));
      expect(
        merged.single.memberListBannerUrl,
        contains('/member-list/joshy.webp'),
      );
    },
  );

  test(
    'workspace shell member merge collapses duplicate active projections',
    () {
      const networkId = 'origin:https%3A%2F%2Fapi-test.pryzmapp.com';
      const localUserId = '176495712701775872';

      final merged = debugMergeChatMembersForTesting(const [], const [
        MemberSeed(
          id: localUserId,
          name: 'Joshy',
          status: 'Online',
          initials: 'JO',
        ),
        MemberSeed(
          id: '$networkId/$localUserId',
          name: 'Joshy',
          username: 'Josh',
          status: 'dnd',
          initials: 'JO',
          avatarUrl: 'https://cdn.pryzmapp.com/avatars/joshy.webp',
        ),
      ]);

      expect(merged, hasLength(1));
      expect(merged.single.id, '$networkId/$localUserId');
      expect(merged.single.username, 'Josh');
      expect(merged.single.status, 'Online');
      expect(merged.single.avatarUrl, contains('/avatars/joshy.webp'));
    },
  );

  testWidgets(
    'chat workspace mention suggestions use separated animated media surface',
    (tester) async {
      const networkId = 'origin:https%3A%2F%2Fapi-test.pryzmapp.com';
      final seed = _workspaceSeedWithMembersAndMessages(
        networkId: networkId,
        members: const [],
        messages: const [],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: buildVerdantTheme(),
          home: Scaffold(
            body: SizedBox(
              width: 900,
              height: 700,
              child: ChatWorkspace(
                seed: seed,
                currentUserId: 'user-avery',
                currentUserName: 'Avery',
                currentUserInitials: 'AV',
                identityMembers: const [
                  MemberSeed(
                    id: '$networkId/user-joshy',
                    name: 'Joshy',
                    username: 'Josh',
                    status: 'Online',
                    initials: 'JO',
                    avatarUrl: 'https://cdn.pryzmapp.com/avatars/joshy.webp',
                    memberListBannerUrl:
                        'https://cdn.pryzmapp.com/member-list/joshy.webp',
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const ValueKey('composer-message-field')),
        '@Jo',
      );
      await tester.pump();

      final panel = tester.widget<Container>(
        find.byKey(const ValueKey('composer-mention-suggestions')),
      );
      final panelDecoration = panel.decoration as BoxDecoration;
      expect(panelDecoration.color, VerdantColors.panel);
      expect(panelDecoration.boxShadow?.length, greaterThanOrEqualTo(2));

      final suggestion = find.byKey(
        const ValueKey('composer-mention-suggestion-user-joshy'),
      );
      expect(suggestion, findsOneWidget);
      final surface = find.byKey(
        const ValueKey('composer-mention-suggestion-surface-user-joshy'),
      );
      expect(surface, findsOneWidget);
      expect(tester.getSize(surface), tester.getSize(suggestion));
      final surfaceBox = tester.widget<DecoratedBox>(surface);
      final surfaceDecoration = surfaceBox.decoration as BoxDecoration;
      expect(surfaceDecoration.border, isNull);

      final avatar = tester.widget<MemberMediaAvatar>(
        find.descendant(
          of: suggestion,
          matching: find.byType(MemberMediaAvatar),
        ),
      );
      expect(avatar.playAnimatedMedia, isTrue);

      final banner = tester.widget<MemberMediaBanner>(
        find.descendant(
          of: suggestion,
          matching: find.byType(MemberMediaBanner),
        ),
      );
      expect(banner.playAnimatedMedia, isTrue);
      expect(
        banner.bannerUrlOverride,
        'https://cdn.pryzmapp.com/member-list/joshy.webp',
      );
    },
  );

  testWidgets(
    'channel search field stays borderless inside header search box',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildVerdantTheme(mode: VerdantThemeMode.light),
          home: Scaffold(
            body: SizedBox(
              width: 980,
              child: ChannelHeaderModule(
                channelName: 'general',
                seed: WorkspaceSeed.sample,
                messages: WorkspaceSeed.sample.messages,
                members: WorkspaceSeed.sample.members,
              ),
            ),
          ),
        ),
      );

      final field = tester.widget<TextField>(
        find.byKey(const ValueKey('channel-message-search-field')),
      );

      expect(field.decoration?.border, InputBorder.none);
      expect(field.decoration?.enabledBorder, InputBorder.none);
      expect(field.decoration?.focusedBorder, InputBorder.none);
      expect(field.decoration?.disabledBorder, InputBorder.none);
      expect(field.decoration?.errorBorder, InputBorder.none);
      expect(field.decoration?.focusedErrorBorder, InputBorder.none);
      expect(field.decoration?.filled, isFalse);
      expect(field.style?.color, VerdantThemeColors.light.text);
      expect(field.cursorColor, VerdantThemeColors.light.action);
    },
  );

  testWidgets('chat timeline requests older messages near the top', (
    tester,
  ) async {
    var loadCount = 0;
    final messages = List<MessageSeed>.generate(
      90,
      (index) => MessageSeed(
        id: 'official/${181215028619407360 + index}',
        authorId: 'official/176495712701775872',
        author: 'Joshy',
        time: 'Today at 6:${index.toString().padLeft(2, '0')} PM',
        createdAt: DateTime(2026, 6, 5, 18, index).toUtc().toIso8601String(),
        body: 'Plain text history row ${index + 1}',
        initials: 'JO',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerdantTheme(),
        home: Scaffold(
          body: SizedBox(
            width: 720,
            height: 420,
            child: MessageTimeline(
              messages: messages,
              pageStorageKey: 'load-older-timeline',
              hasOlderMessages: true,
              onLoadOlderMessages: () async {
                loadCount += 1;
              },
            ),
          ),
        ),
      ),
    );
    for (var frame = 0; frame < 10; frame += 1) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    final scrollable = tester.state<ScrollableState>(
      find.byType(Scrollable).last,
    );
    scrollable.position.jumpTo(0);
    await tester.pump(const Duration(milliseconds: 16));

    expect(loadCount, 1);
  });

  testWidgets(
    'chat timeline preserves the scroll anchor when older rows prepend',
    (tester) async {
      var loadCount = 0;
      var messages = List<MessageSeed>.generate(
        70,
        (index) => MessageSeed(
          id: 'official/prepend-base-$index',
          authorId: 'official/user-${index % 2}',
          author: index.isEven ? 'Joshy' : 'Mira',
          time: 'Today at 6:${index.toString().padLeft(2, '0')} PM',
          createdAt: DateTime(2026, 6, 5, 18, index).toUtc().toIso8601String(),
          body: 'Anchor-preserving base row ${index + 1}',
          initials: index.isEven ? 'JO' : 'MI',
        ),
      );

      Widget buildTimeline(StateSetter setState) {
        return MaterialApp(
          theme: buildVerdantTheme(),
          home: Scaffold(
            body: SizedBox(
              width: 720,
              height: 420,
              child: MessageTimeline(
                messages: messages,
                pageStorageKey: 'prepend-anchor-timeline',
                hasOlderMessages: true,
                onLoadOlderMessages: () async {
                  loadCount += 1;
                  setState(() {
                    messages = [
                      for (var index = 0; index < 24; index += 1)
                        MessageSeed(
                          id: 'official/prepend-older-$index',
                          authorId: 'official/user-${index % 2}',
                          author: index.isEven ? 'Joshy' : 'Mira',
                          time:
                              'Today at 5:${index.toString().padLeft(2, '0')} PM',
                          createdAt: DateTime(
                            2026,
                            6,
                            5,
                            17,
                            index,
                          ).toUtc().toIso8601String(),
                          body: 'Prepended history row ${index + 1}',
                          initials: index.isEven ? 'JO' : 'MI',
                        ),
                      ...messages,
                    ];
                  });
                },
              ),
            ),
          ),
        );
      }

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => buildTimeline(setState),
        ),
      );
      for (var frame = 0; frame < 10; frame += 1) {
        await tester.pump(const Duration(milliseconds: 16));
      }

      final scrollable = tester.state<ScrollableState>(
        find.byType(Scrollable).last,
      );
      scrollable.position.jumpTo(0);
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));

      expect(loadCount, 1);
      expect(
        find.byKey(const ValueKey('message-row-official/prepend-base-0')),
        findsOneWidget,
      );
      expect(
        scrollable.position.maxScrollExtent - scrollable.position.pixels,
        greaterThan(1000),
      );

      await tester.pump(const Duration(milliseconds: 80));
      expect(loadCount, 1);
    },
  );

  testWidgets('plain-text history prepend keeps the visible row anchored', (
    tester,
  ) async {
    final loadCompleter = Completer<void>();
    var messages = List<MessageSeed>.generate(
      90,
      (index) => MessageSeed(
        id: 'official/plain-anchor-base-$index',
        authorId: 'official/user-${index % 2}',
        author: index.isEven ? 'Joshy' : 'Mira',
        time: 'Today at 6:${index.toString().padLeft(2, '0')} PM',
        createdAt: DateTime(2026, 6, 5, 18, index).toUtc().toIso8601String(),
        body: 'Plain anchor base row ${index + 1}',
        initials: index.isEven ? 'JO' : 'MI',
      ),
    );

    Widget buildTimeline(StateSetter setState) {
      return MaterialApp(
        theme: buildVerdantTheme(),
        home: Scaffold(
          body: SizedBox(
            width: 720,
            height: 420,
            child: MessageTimeline(
              messages: messages,
              pageStorageKey: 'plain-history-anchor-timeline',
              hasOlderMessages: true,
              onLoadOlderMessages: () async {
                await loadCompleter.future;
                setState(() {
                  messages = [
                    for (var index = 0; index < 60; index += 1)
                      MessageSeed(
                        id: 'official/plain-anchor-older-$index',
                        authorId: 'official/user-${index % 2}',
                        author: index.isEven ? 'Joshy' : 'Mira',
                        time:
                            'Today at 5:${index.toString().padLeft(2, '0')} PM',
                        createdAt: DateTime(
                          2026,
                          6,
                          5,
                          17,
                          index,
                        ).toUtc().toIso8601String(),
                        body:
                            'Prepended plain text row ${index + 1}. '
                            'This deliberately has no media and should not '
                            'steal the viewport when the page appears.',
                        initials: index.isEven ? 'JO' : 'MI',
                      ),
                    ...messages,
                  ];
                });
              },
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(
      StatefulBuilder(builder: (context, setState) => buildTimeline(setState)),
    );
    for (var frame = 0; frame < 10; frame += 1) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    final scrollable = tester.state<ScrollableState>(
      find.byType(Scrollable).last,
    );
    scrollable.position.jumpTo(0);
    await tester.pump(const Duration(milliseconds: 16));

    final anchoredRow = find.byKey(
      const ValueKey('message-row-official/plain-anchor-base-0'),
    );
    expect(anchoredRow, findsOneWidget);
    final anchoredTopBefore = tester.getTopLeft(anchoredRow).dy;

    loadCompleter.complete();
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 16));

    expect(anchoredRow, findsOneWidget);
    expect(tester.getTopLeft(anchoredRow).dy, closeTo(anchoredTopBefore, 2));
    expect(
      scrollable.position.maxScrollExtent - scrollable.position.pixels,
      greaterThan(1000),
    );
  });

  testWidgets('pending bottom scroll does not override history traversal', (
    tester,
  ) async {
    var messages = List<MessageSeed>.generate(
      80,
      (index) => MessageSeed(
        id: 'official/pending-bottom-base-$index',
        authorId: 'official/user-${index % 2}',
        author: index.isEven ? 'Joshy' : 'Mira',
        time: 'Today at 6:${index.toString().padLeft(2, '0')} PM',
        createdAt: DateTime(2026, 6, 5, 18, index).toUtc().toIso8601String(),
        body: 'Pending bottom base row ${index + 1}',
        initials: index.isEven ? 'JO' : 'MI',
      ),
    );

    Widget buildTimeline(StateSetter setState) {
      return MaterialApp(
        theme: buildVerdantTheme(),
        home: Scaffold(
          body: SizedBox(
            width: 720,
            height: 420,
            child: MessageTimeline(
              messages: messages,
              pageStorageKey: 'pending-bottom-history-timeline',
              hasOlderMessages: true,
              onLoadOlderMessages: () async {
                setState(() {
                  messages = [
                    for (var index = 0; index < 40; index += 1)
                      MessageSeed(
                        id: 'official/pending-bottom-older-$index',
                        authorId: 'official/user-${index % 2}',
                        author: index.isEven ? 'Joshy' : 'Mira',
                        time:
                            'Today at 5:${index.toString().padLeft(2, '0')} PM',
                        createdAt: DateTime(
                          2026,
                          6,
                          5,
                          17,
                          index,
                        ).toUtc().toIso8601String(),
                        body: 'Older plain text row ${index + 1}',
                        initials: index.isEven ? 'JO' : 'MI',
                      ),
                    ...messages,
                  ];
                });
              },
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(
      StatefulBuilder(builder: (context, setState) => buildTimeline(setState)),
    );
    await tester.pump();

    final scrollable = tester.state<ScrollableState>(
      find.byType(Scrollable).last,
    );
    scrollable.position.jumpTo(0);
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 16));

    expect(
      scrollable.position.maxScrollExtent - scrollable.position.pixels,
      greaterThan(1000),
    );
  });

  testWidgets(
    'same author messages split headers after the Tauri time window',
    (tester) async {
      const messages = [
        MessageSeed(
          id: 'official/message-555',
          authorId: 'official/user-1',
          author: 'Joshy',
          time: '5:55 PM',
          body: 'first message',
          initials: 'JO',
        ),
        MessageSeed(
          id: 'official/message-646',
          authorId: 'official/user-1',
          author: 'Joshy',
          time: '6:46 PM',
          body: 'later message',
          initials: 'JO',
        ),
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 720,
              height: 420,
              child: MessageTimeline(messages: messages, stickToBottom: false),
            ),
          ),
        ),
      );

      expect(find.text('5:55 PM'), findsOneWidget);
      expect(find.text('6:46 PM'), findsOneWidget);
    },
  );

  testWidgets('chat author name inherits matched member role color', (
    tester,
  ) async {
    const roleColor = Color(0xFF7CFFDE);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 720,
            height: 420,
            child: MessageTimeline(
              networkId: 'official',
              stickToBottom: false,
              members: [
                MemberSeed(
                  id: 'official/user-avery',
                  name: 'Avery',
                  status: 'Online',
                  initials: 'AV',
                  role: 'Purple',
                  displayColor: roleColor,
                ),
              ],
              messages: [
                MessageSeed(
                  id: 'official/message-role-color',
                  authorId: 'user-avery',
                  author: 'Avery',
                  time: '6:46 PM',
                  body: 'role color should show',
                  initials: 'AV',
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final author = tester.widget<Text>(find.text('Avery'));
    expect(author.style?.color, roleColor);
  });

  testWidgets('chat timestamps use slash date formatting and time', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en', 'US'),
        home: Scaffold(
          body: SizedBox(
            width: 720,
            height: 420,
            child: MessageTimeline(
              stickToBottom: false,
              messages: [
                MessageSeed(
                  id: 'official/message-old-date',
                  authorId: 'official/user-avery',
                  author: 'Avery',
                  time: '2026-05-01 09:15',
                  createdAt: '2026-05-01T09:15:00',
                  body: 'old date should use slashes',
                  initials: 'AV',
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('05/01/2026 at 9:15 AM'), findsOneWidget);
    expect(find.textContaining('2026-05-01'), findsNothing);
  });

  testWidgets('server chat local echo uses the active user identity', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerdantTheme(),
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 700,
            child: ChatWorkspace(
              seed: _workspaceSeedWithMessages(const []),
              currentUserId: 'active-user-42',
              currentUserName: 'Current User',
              currentUserInitials: 'CU',
            ),
          ),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('composer-message-field')),
      'hi',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('composer-send-button')));
    await tester.pump();

    expect(find.text('Current User'), findsOneWidget);
    expect(find.text('Joshy'), findsNothing);
    expect(find.text('CU'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget.key is ValueKey<String> &&
            (widget.key! as ValueKey<String>).value.startsWith(
              'message-row-official/local-message-',
            ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('chat invite link previews and joins through handlers', (
    tester,
  ) async {
    final previewedTargets = <ChatInviteTarget>[];
    final acceptedTargets = <ChatInviteTarget>[];
    final requestedPaths = <String>[];
    debugSetServerMediaWidgetLoader((uri, {required policy, maxBytes}) async {
      requestedPaths.add(uri.path);
      return Uint8List.fromList(_pngBytes);
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerdantTheme(),
        home: Scaffold(
          body: SizedBox(
            width: 720,
            height: 420,
            child: MessageTimeline(
              stickToBottom: false,
              mediaPolicy: const ServerMediaPolicy(
                allowedOrigins: {'https://media.verdant.chat'},
                allowLocalHttp: false,
              ),
              messages: const [
                MessageSeed(
                  id: 'official/message-invite',
                  authorId: 'official/user-avery',
                  author: 'Avery',
                  time: '1:15 PM',
                  body: 'Join us https://verdant.chat/invite/ABC123',
                  initials: 'AV',
                ),
              ],
              onPreviewInvite: (target) async {
                previewedTargets.add(target);
                return const ServerInvitePreview(
                  code: 'ABC123',
                  server: ServerSettingsServer(
                    id: 'joined-server',
                    name: 'Joined Server',
                    ownerId: 'user-avery',
                    iconUrl:
                        'https://media.verdant.chat/server-icons/joined.webp',
                    voiceBitrate: 64000,
                    bannerUrl:
                        'https://media.verdant.chat/server-banners/joined.webp',
                    bannerOffsetY: 50,
                    memberCount: 8,
                    large: false,
                    createdAt: '',
                    updatedAt: '',
                  ),
                  inviterUsername: 'Avery',
                  isMember: false,
                );
              },
              onAcceptInvite: (target, _) async {
                acceptedTargets.add(target);
                return const ServerSettingsServer(
                  id: 'joined-server',
                  name: 'Joined Server',
                  ownerId: 'user-avery',
                  voiceBitrate: 64000,
                  bannerOffsetY: 50,
                  memberCount: 8,
                  large: false,
                  createdAt: '',
                  updatedAt: '',
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    expect(previewedTargets, isEmpty);
    await tester.tap(
      find.byKey(const ValueKey('message-invite-preview-button')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    expect(
      find.textContaining('https://verdant.chat/invite/ABC123'),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('message-invite-card-official/message-invite')),
      findsOneWidget,
    );
    expect(previewedTargets, [
      const ChatInviteTarget(code: 'ABC123', apiOrigin: officialApiOrigin),
    ]);
    expect(find.text('Joined Server'), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey('message-invite-banner-official/message-invite'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('message-invite-icon-official/message-invite')),
      findsOneWidget,
    );
    expect(requestedPaths, contains('/server-banners/joined.webp'));
    expect(requestedPaths, contains('/server-icons/joined.webp'));
    expect(find.text('Server invite'), findsOneWidget);
    expect(find.text('Backend: api.verdant.chat'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('message-invite-copy-official/message-invite')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('message-invite-join-official/message-invite')),
    );
    await tester.pumpAndSettle();

    expect(acceptedTargets, previewedTargets);
    expect(find.text('Joined'), findsOneWidget);
  });

  testWidgets('chat invite card uses animated icon backdrop without a banner', (
    tester,
  ) async {
    final requestedPaths = <String>[];
    debugSetServerMediaWidgetLoader((uri, {required policy, maxBytes}) async {
      requestedPaths.add(uri.path);
      return Uint8List.fromList(_pngBytes);
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 520,
            height: 260,
            child: MessageTimeline(
              stickToBottom: false,
              mediaPolicy: const ServerMediaPolicy(
                allowedOrigins: {'https://media.verdant.chat'},
                allowLocalHttp: false,
              ),
              messages: const [
                MessageSeed(
                  id: 'official/message-invite-fallback',
                  authorId: 'official/user-avery',
                  author: 'Avery',
                  time: '1:15 PM',
                  body: 'Join us https://verdant.chat/invite/FALLBACK1',
                  initials: 'AV',
                ),
              ],
              onPreviewInvite: (target) async {
                return const ServerInvitePreview(
                  code: 'FALLBACK1',
                  server: ServerSettingsServer(
                    id: 'fallback-server',
                    name: 'Fallback Server',
                    ownerId: 'user-avery',
                    iconUrl:
                        'https://media.verdant.chat/server-icons/fallback.webp',
                    voiceBitrate: 64000,
                    bannerOffsetY: 50,
                    memberCount: 4,
                    large: false,
                    createdAt: '',
                    updatedAt: '',
                  ),
                  inviterUsername: 'Avery',
                  isMember: false,
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    expect(requestedPaths, isEmpty);
    await tester.tap(
      find.byKey(const ValueKey('message-invite-preview-button')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    final fallbackBackdrop = tester.widget<StaticFirstFrameImage>(
      find.byKey(
        const ValueKey(
          'message-invite-fallback-banner-official/message-invite-fallback',
        ),
      ),
    );
    expect(fallbackBackdrop.fit, BoxFit.fitHeight);
    expect(fallbackBackdrop.alignment, Alignment.centerRight);
    expect(
      find.byKey(
        const ValueKey('message-invite-icon-official/message-invite-fallback'),
      ),
      findsOneWidget,
    );
    expect(requestedPaths, contains('/server-icons/fallback.webp'));
  });

  testWidgets('chat invite preview is retained across callback rebuilds', (
    tester,
  ) async {
    var previewCount = 0;

    Widget timeline(VoidCallback onRebuild) {
      return MaterialApp(
        theme: buildVerdantTheme(),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                children: [
                  TextButton(
                    key: const ValueKey('invite-rebuild-button'),
                    onPressed: () {
                      onRebuild();
                      setState(() {});
                    },
                    child: const Text('rebuild'),
                  ),
                  Expanded(
                    child: MessageTimeline(
                      stickToBottom: false,
                      mediaPolicy: const ServerMediaPolicy(
                        allowedOrigins: {},
                        allowLocalHttp: false,
                      ),
                      messages: const [
                        MessageSeed(
                          id: 'official/message-invite-rebuild',
                          authorId: 'official/user-avery',
                          author: 'Avery',
                          time: '1:15 PM',
                          body: 'Join us https://verdant.chat/invite/REBUILD1',
                          initials: 'AV',
                        ),
                      ],
                      onPreviewInvite: (target) async {
                        previewCount += 1;
                        return const ServerInvitePreview(
                          code: 'REBUILD1',
                          server: ServerSettingsServer(
                            id: 'rebuild-server',
                            name: 'Rebuild Server',
                            ownerId: 'user-avery',
                            voiceBitrate: 64000,
                            bannerOffsetY: 50,
                            memberCount: 2,
                            large: false,
                            createdAt: '',
                            updatedAt: '',
                          ),
                          inviterUsername: 'Avery',
                          isMember: false,
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    }

    var rebuildCount = 0;
    await tester.pumpWidget(timeline(() => rebuildCount += 1));
    await tester.pump();
    await tester.pump();

    expect(previewCount, 0);
    await tester.tap(
      find.byKey(const ValueKey('message-invite-preview-button')),
    );
    await tester.pump();
    await tester.pump();

    expect(previewCount, 1);
    expect(find.text('Rebuild Server'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('invite-rebuild-button')));
    await tester.pump();
    await tester.pump();

    expect(rebuildCount, 1);
    expect(previewCount, 1);
    expect(find.text('Rebuild Server'), findsOneWidget);
    expect(find.text('Loading invite'), findsNothing);
  });

  testWidgets('channel header search supports from autocomplete and results', (
    tester,
  ) async {
    final seed = WorkspaceSeed(
      networkId: 'official',
      serverId: 'server-1',
      serverName: 'Verdant',
      serverOwnerId: 'user-joshy',
      serverIconUrl: null,
      serverBannerUrl: null,
      serverBannerCrop: null,
      memberCount: 2,
      channels: [
        ChannelSeed(id: 'channel-general', name: 'general', selected: true),
      ],
      members: [
        MemberSeed(
          id: 'official/user-joshy',
          name: 'Joshy',
          status: 'Online',
          initials: 'JO',
        ),
        MemberSeed(
          id: 'official/user-avery',
          name: 'Avery',
          status: 'Online',
          initials: 'AV',
        ),
      ],
      messages: [
        MessageSeed(
          id: 'official/message-1',
          authorId: 'official/user-joshy',
          author: 'Joshy',
          time: '1:00 PM',
          body: 'deployment notes',
          initials: 'JO',
        ),
        MessageSeed(
          id: 'official/message-2',
          authorId: 'official/user-avery',
          author: 'Avery',
          time: '1:04 PM',
          body: 'deployment approved',
          initials: 'AV',
        ),
      ],
      serverSettings: ServerSettingsSeed(
        networkId: 'official',
        localServerId: 'server-1',
        serverName: 'Verdant',
        description: '',
        memberCount: 2,
        ownerName: 'Joshy',
        createdLabel: 'Today',
        channels: [],
        emojis: [],
        invites: [],
        roles: [],
        members: [],
        auditEvents: [],
        feeds: [],
        bots: [],
      ),
      mediaPolicy: ServerMediaPolicy(allowedOrigins: {}, allowLocalHttp: false),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 920,
            height: 220,
            child: ChannelHeaderModule(
              channelName: 'general',
              seed: seed,
              messages: seed.messages,
              members: seed.members,
            ),
          ),
        ),
      ),
    );

    final field = find.byKey(const ValueKey('channel-message-search-field'));
    await tester.enterText(field, 'from:av');
    await tester.pump();
    expect(find.text('Avery'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(find.text('from: Avery'), findsOneWidget);

    await tester.enterText(field, 'deployment');
    await tester.pump(const Duration(milliseconds: 320));
    expect(find.text('deployment approved'), findsOneWidget);
    expect(find.text('deployment notes'), findsNothing);
  });

  testWidgets('channel header keeps fixed slots for long channel names', (
    tester,
  ) async {
    Future<Map<String, Rect>> pumpHeader(String channelName) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 920,
              height: 80,
              child: ChannelHeaderModule(channelName: channelName),
            ),
          ),
        ),
      );
      await tester.pump();
      return {
        'title': tester.getRect(
          find.byKey(const ValueKey('channel-header-title-slot')),
        ),
        'welcome': tester.getRect(
          find.byKey(const ValueKey('channel-header-welcome-slot')),
        ),
        'actions': tester.getRect(
          find.byKey(const ValueKey('channel-header-actions-slot')),
        ),
        'search': tester.getRect(
          find.byKey(const ValueKey('channel-message-search-box')),
        ),
      };
    }

    final shortRects = await pumpHeader('general');
    final longRects = await pumpHeader(
      'general-with-a-very-long-name-that-should-not-move-actions',
    );

    for (final key in shortRects.keys) {
      expect(longRects[key]!.left, shortRects[key]!.left);
      expect(longRects[key]!.width, shortRects[key]!.width);
    }
  });

  testWidgets('channel header lets feed titles use available wide space', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1800, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1800,
            height: 80,
            child: ChannelHeaderModule(channelName: 'Announcements'),
          ),
        ),
      ),
    );
    await tester.pump();

    final titleRect = tester.getRect(
      find.byKey(const ValueKey('channel-header-title-slot')),
    );
    final welcomeRect = tester.getRect(
      find.byKey(const ValueKey('channel-header-welcome-slot')),
    );

    expect(titleRect.width, greaterThan(260));
    expect(welcomeRect.width, greaterThan(360));
  });

  testWidgets('remote typing indicator reserves space and animates dots', (
    tester,
  ) async {
    final sample = WorkspaceSeed.sample;
    final seed = WorkspaceSeed(
      networkId: sample.networkId,
      serverId: sample.serverId,
      serverName: sample.serverName,
      serverOwnerId: sample.serverOwnerId,
      serverIconUrl: sample.serverIconUrl,
      serverBannerUrl: sample.serverBannerUrl,
      serverBannerCrop: sample.serverBannerCrop,
      memberCount: sample.memberCount,
      channels: sample.channels,
      members: sample.members,
      messages: [
        for (var index = 0; index < 12; index += 1)
          MessageSeed(
            id: 'official/typing-room-$index',
            authorId: 'official/user-joshy',
            author: 'Joshy',
            time: '1:0$index PM',
            body: 'typing room message $index',
            initials: 'JO',
          ),
      ],
      serverSettings: sample.serverSettings,
      mediaPolicy: sample.mediaPolicy,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 760,
            height: 500,
            child: ChatWorkspace(
              seed: seed,
              currentUserId: 'user-joshy',
              currentUserName: 'Joshy',
              currentUserInitials: 'JO',
              typingMembers: const [
                MemberSeed(
                  id: 'official/user-avery',
                  name: 'Avery',
                  status: 'Online',
                  initials: 'AV',
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final timeline = find.byKey(
      const ValueKey(
        'message-timeline-scrollable-chat-message-timeline-official-fake-server-1-general',
      ),
    );
    final timelinePadding = tester.widget<SliverPadding>(
      find.descendant(of: timeline, matching: find.byType(SliverPadding)).last,
    );
    expect(find.byKey(const ValueKey('chat-typing-strip')), findsOneWidget);
    expect((timelinePadding.padding as EdgeInsets).bottom, 14);
    expect(find.byKey(const ValueKey('chat-typing-indicator')), findsOneWidget);
    expect(find.text('Avery is typing'), findsOneWidget);

    final firstOpacity = tester
        .widget<Opacity>(find.byKey(const ValueKey('typing-dot-0')))
        .opacity;
    await tester.pump(const Duration(milliseconds: 260));
    final nextOpacity = tester
        .widget<Opacity>(find.byKey(const ValueKey('typing-dot-0')))
        .opacity;

    expect(nextOpacity, isNot(firstOpacity));
  });

  testWidgets('DM local echo uses the current DM user identity', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerdantTheme(),
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 700,
            child: DmConversationModule(
              conversation: const DmConversationPreviewSeed(
                channelId: 'official/dm-1',
                localChannelId: 'dm-1',
                networkId: 'official',
                displayName: 'Friend',
                initials: 'FR',
                status: 'Online',
                lastMessage: 'No messages yet',
                localUserId: 'friend-1',
              ),
              messages: const DmConversationMessages(
                channelId: 'official/dm-1',
                messages: [],
              ),
              isLoading: false,
              error: null,
              mediaPolicy: ServerMediaPolicy.fromOrigins(
                apiOrigin: officialApiOrigin,
              ),
              currentUserId: 'active-user-42',
              currentUserName: 'Current User',
              currentUserInitials: 'CU',
            ),
          ),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('composer-message-field')),
      'dm',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('composer-send-button')));
    await tester.pump();

    expect(find.text('Current User'), findsOneWidget);
    expect(find.text('Joshy'), findsNothing);
    expect(find.text('CU'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget.key is ValueKey<String> &&
            (widget.key! as ValueKey<String>).value.startsWith(
              'message-row-official/local-dm-message-',
            ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('DM submit uses the backend send callback when available', (
    tester,
  ) async {
    final sent = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerdantTheme(),
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 700,
            child: DmConversationModule(
              conversation: const DmConversationPreviewSeed(
                channelId: 'official/dm-1',
                localChannelId: 'dm-1',
                networkId: 'official',
                displayName: 'Friend',
                initials: 'FR',
                status: 'Online',
                lastMessage: 'No messages yet',
                localUserId: 'friend-1',
              ),
              messages: const DmConversationMessages(
                channelId: 'official/dm-1',
                messages: [],
              ),
              isLoading: false,
              error: null,
              mediaPolicy: ServerMediaPolicy.fromOrigins(
                apiOrigin: officialApiOrigin,
              ),
              currentUserId: 'active-user-42',
              currentUserName: 'Current User',
              currentUserInitials: 'CU',
              onSendMessage: (message) async => sent.add(message),
            ),
          ),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('composer-message-field')),
      'hello from dm',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('composer-send-button')));
    await tester.pump();

    expect(sent, ['hello from dm']);
    expect(find.text('Current User'), findsNothing);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget.key is ValueKey<String> &&
            (widget.key! as ValueKey<String>).value.startsWith(
              'message-row-official/local-dm-message-',
            ),
      ),
      findsNothing,
    );
  });

  testWidgets('media previews keep a stable frame after load state changes', (
    tester,
  ) async {
    const media = MessageMediaSeed(
      id: 'official/media-1',
      label: 'Klipy launch loop',
      kind: MessageMediaKind.gif,
      width: 320,
      height: 180,
    );
    const previewKey = ValueKey('stable-media-preview');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 520,
            child: MessageMediaPreview(
              key: previewKey,
              media: media,
              mediaPolicy: ServerMediaPolicy.fromOrigins(
                apiOrigin: officialApiOrigin,
              ),
              loadState: MediaPreviewLoadState.loading,
            ),
          ),
        ),
      ),
    );

    final loadingSize = tester.getSize(find.byKey(previewKey));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 520,
            child: MessageMediaPreview(
              key: previewKey,
              media: media,
              mediaPolicy: ServerMediaPolicy.fromOrigins(
                apiOrigin: officialApiOrigin,
              ),
              loadState: MediaPreviewLoadState.ready,
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byKey(previewKey)), loadingSize);
  });

  test('media preview sizing preserves natural aspect within chat bounds', () {
    expect(
      mediaPreviewSizeFor(
        constraints: const BoxConstraints(maxWidth: 620),
        naturalSize: const Size(500, 250),
      ),
      const Size(480, 240),
    );
    final constrained = mediaPreviewSizeFor(
      constraints: const BoxConstraints(maxWidth: 620),
      naturalSize: const Size(640, 480),
    );

    expect(constrained.width, closeTo(426.67, 0.01));
    expect(constrained.height, 320);
  });

  testWidgets('media previews render allowed public image bytes', (
    tester,
  ) async {
    final requestedPaths = <String>[];
    debugSetServerMediaWidgetLoader((uri, {required policy, maxBytes}) async {
      requestedPaths.add(uri.path);
      return Uint8List.fromList(_pngBytes);
    });

    const media = MessageMediaSeed(
      id: 'official/media-2',
      label: 'Animated banner',
      kind: MessageMediaKind.webp,
      width: 320,
      height: 180,
      url: 'https://cdn.pryzmapp.com/server-banners/1/banner.webp',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 520,
            child: MessageMediaPreview(
              media: media,
              mediaPolicy: ServerMediaPolicy.fromOrigins(
                apiOrigin: officialApiOrigin,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('message-media-image-official/media-2')),
      findsOneWidget,
    );
    expect(requestedPaths, contains('/server-banners/1/banner.webp'));
  });

  testWidgets('message media keeps resident bytes across short focus loss', (
    tester,
  ) async {
    final service = MediaResidencyService(ttl: const Duration(minutes: 3));
    var requestCount = 0;
    debugSetServerMediaWidgetLoader((uri, {required policy, maxBytes}) async {
      requestCount += 1;
      return Uint8List.fromList(_pngBytes);
    });

    const media = MessageMediaSeed(
      id: 'official/resident-klipy-media',
      label: 'Resident Klipy loop',
      kind: MessageMediaKind.gif,
      width: 320,
      height: 180,
      url: 'https://static.klipy.com/i/resident.gif',
    );

    Widget build({required bool focused}) {
      return MediaResidencyScope(
        service: service,
        child: MaterialApp(
          home: WindowFocusScope(
            focused: focused,
            child: Scaffold(
              body: SizedBox(
                width: 520,
                child: MessageMediaPreview(
                  media: media,
                  mediaPolicy: ServerMediaPolicy.fromOrigins(
                    apiOrigin: officialApiOrigin,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(build(focused: true));
    await tester.pumpAndSettle();

    expect(requestCount, 1);
    expect(debugServerMediaImageEvictionCount(), 0);
    expect(
      find.byKey(
        const ValueKey('message-media-image-official/resident-klipy-media'),
      ),
      findsOneWidget,
    );

    await tester.pumpWidget(build(focused: false));
    await tester.pump();

    expect(requestCount, 1);
    expect(debugServerMediaImageEvictionCount(), 0);

    await tester.pumpWidget(build(focused: true));
    await tester.pumpAndSettle();

    expect(requestCount, 1);
    expect(debugServerMediaImageEvictionCount(), 0);
    expect(
      find.byKey(
        const ValueKey('message-media-image-official/resident-klipy-media'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('message deletion keeps shifted avatar media mounted', (
    tester,
  ) async {
    var requestCount = 0;
    debugSetServerMediaWidgetLoader((uri, {required policy, maxBytes}) async {
      requestCount += 1;
      return Uint8List.fromList(_pngBytes);
    });

    List<MessageSeed> buildMessages() {
      return [
        for (var index = 0; index < 6; index += 1)
          MessageSeed(
            id: 'official/delete-avatar-$index',
            authorId: 'official/user-$index',
            author: 'User $index',
            time: 'Today at 8:0$index PM',
            body: 'Avatar row $index',
            initials: 'U$index',
            avatarUrl: 'https://cdn.pryzmapp.com/avatars/user-$index.png',
          ),
      ];
    }

    Widget build(List<MessageSeed> messages) {
      return MaterialApp(
        theme: buildVerdantTheme(),
        home: Scaffold(
          body: SizedBox(
            width: 720,
            height: 460,
            child: MessageTimeline(
              messages: messages,
              mediaPolicy: ServerMediaPolicy.fromOrigins(
                apiOrigin: officialApiOrigin,
              ),
              stickToBottom: false,
            ),
          ),
        ),
      );
    }

    final messages = buildMessages();
    await tester.pumpWidget(build(messages));
    await tester.pumpAndSettle();

    expect(requestCount, 6);
    expect(debugServerMediaImageEvictionCount(), 0);

    await tester.pumpWidget(build(messages.skip(1).toList(growable: false)));

    await tester.pump(const Duration(milliseconds: 50));

    expect(requestCount, 6);
    expect(debugServerMediaImageEvictionCount(), 0);
    expect(
      find.byKey(const ValueKey('message-row-official/delete-avatar-0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('message-avatar-image-official/user-1')),
      findsOneWidget,
    );

    await tester.pumpAndSettle();

    expect(requestCount, 6);
    expect(debugServerMediaImageEvictionCount(), 1);
    expect(
      find.byKey(const ValueKey('message-row-official/delete-avatar-0')),
      findsNothing,
    );
  });

  testWidgets('decoded media dimensions do not resize the timeline frame', (
    tester,
  ) async {
    debugSetServerMediaWidgetLoader((uri, {required policy, maxBytes}) async {
      return Uint8List.fromList(_pngBytes);
    });

    const media = MessageMediaSeed(
      id: 'official/stable-decoded-media',
      label: 'Stable GIF frame',
      kind: MessageMediaKind.gif,
      width: 480,
      height: 320,
      url: 'https://static.klipy.com/i/stable-decoded.gif',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 520,
            child: MessageMediaPreview(
              media: media,
              mediaPolicy: ServerMediaPolicy.fromOrigins(
                apiOrigin: officialApiOrigin,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final reservedSize = tester.getSize(
      find.byKey(
        const ValueKey('message-media-surface-official/stable-decoded-media'),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      tester.getSize(
        find.byKey(
          const ValueKey('message-media-surface-official/stable-decoded-media'),
        ),
      ),
      reservedSize,
    );
  });

  testWidgets('message media previews allow approved Klipy GIF URLs', (
    tester,
  ) async {
    final requestedHosts = <String>[];
    debugSetServerMediaWidgetLoader((uri, {required policy, maxBytes}) async {
      requestedHosts.add(uri.host);
      return Uint8List.fromList(_pngBytes);
    });

    const media = MessageMediaSeed(
      id: 'official/klipy-media-1',
      label: 'Klipy loop',
      kind: MessageMediaKind.gif,
      width: 320,
      height: 180,
      url: 'https://static.klipy.com/i/test.gif',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 520,
            child: MessageMediaPreview(
              media: media,
              mediaPolicy: ServerMediaPolicy.fromOrigins(
                apiOrigin: officialApiOrigin,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('message-media-image-official/klipy-media-1')),
      findsOneWidget,
    );
    expect(requestedHosts, contains('static.klipy.com'));
  });

  testWidgets('media previews preload near the viewport before animating', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    final requestedPaths = <String>[];
    debugSetServerMediaWidgetLoader((uri, {required policy, maxBytes}) async {
      requestedPaths.add(uri.path);
      return Uint8List.fromList(_pngBytes);
    });

    const media = MessageMediaSeed(
      id: 'official/near-viewport-gif',
      label: 'Near viewport loop',
      kind: MessageMediaKind.gif,
      width: 320,
      height: 180,
      url: 'https://static.klipy.com/i/near-viewport.gif',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 520,
            height: 200,
            child: SingleChildScrollView(
              controller: controller,
              child: Column(
                children: [
                  const SizedBox(height: 240),
                  MessageMediaPreview(
                    media: media,
                    mediaPolicy: ServerMediaPolicy.fromOrigins(
                      apiOrigin: officialApiOrigin,
                    ),
                    preloadExtent: 80,
                    animateExtent: 0,
                  ),
                  const SizedBox(height: 320),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(requestedPaths, contains('/i/near-viewport.gif'));
    expect(
      find.byKey(
        const ValueKey('message-media-static-image-official/near-viewport-gif'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('message-media-image-official/near-viewport-gif'),
      ),
      findsNothing,
    );

    controller.jumpTo(120);
    await tester.pump();
    await tester.pump();

    expect(
      find.byKey(
        const ValueKey('message-media-image-official/near-viewport-gif'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('media previews defer byte loading while far outside viewport', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    final requestedPaths = <String>[];
    debugSetServerMediaWidgetLoader((uri, {required policy, maxBytes}) async {
      requestedPaths.add(uri.path);
      return Uint8List.fromList(_pngBytes);
    });

    const media = MessageMediaSeed(
      id: 'official/far-viewport-gif',
      label: 'Far viewport loop',
      kind: MessageMediaKind.gif,
      width: 320,
      height: 180,
      url: 'https://static.klipy.com/i/far-viewport.gif',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 520,
            height: 200,
            child: SingleChildScrollView(
              controller: controller,
              child: Column(
                children: [
                  const SizedBox(height: 600),
                  MessageMediaPreview(
                    media: media,
                    mediaPolicy: ServerMediaPolicy.fromOrigins(
                      apiOrigin: officialApiOrigin,
                    ),
                    preloadExtent: 80,
                    animateExtent: 0,
                  ),
                  const SizedBox(height: 320),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(requestedPaths, isEmpty);
    expect(
      find.byKey(
        const ValueKey('message-media-image-official/far-viewport-gif'),
      ),
      findsNothing,
    );

    controller.jumpTo(460);
    await tester.pump();
    await tester.pumpAndSettle();

    expect(requestedPaths, contains('/i/far-viewport.gif'));
  });

  testWidgets('abandoned media loads do not populate the global byte cache', (
    tester,
  ) async {
    debugConfigureServerMediaImageCacheForTesting(maxEntries: 8, maxBytes: 256);
    final pendingLoad = Completer<Uint8List>();
    debugSetServerMediaWidgetLoader((uri, {required policy, maxBytes}) {
      return pendingLoad.future;
    });

    const media = MessageMediaSeed(
      id: 'official/abandoned-klipy-media',
      label: 'Klipy loop',
      kind: MessageMediaKind.gif,
      width: 320,
      height: 180,
      url: 'https://static.klipy.com/i/abandoned.gif',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 520,
            child: MessageMediaPreview(
              media: media,
              mediaPolicy: ServerMediaPolicy.fromOrigins(
                apiOrigin: officialApiOrigin,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(debugServerMediaImageCacheEntryCount(), 0);

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pump();
    pendingLoad.complete(Uint8List.fromList(_pngBytes));
    await tester.pumpAndSettle();

    expect(debugServerMediaImageCacheEntryCount(), 0);
    expect(debugServerMediaImageCacheTotalBytes(), 0);
  });

  testWidgets('media previews apply bounded image cache budgets', (
    tester,
  ) async {
    debugSetServerMediaWidgetLoader((uri, {required policy, maxBytes}) async {
      return Uint8List.fromList(_pngBytes);
    });

    const media = MessageMediaSeed(
      id: 'official/cache-budget-klipy-media',
      label: 'Klipy loop',
      kind: MessageMediaKind.gif,
      width: 320,
      height: 180,
      url: 'https://static.klipy.com/i/cache-budget.gif',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 520,
            child: MessageMediaPreview(
              media: media,
              mediaPolicy: ServerMediaPolicy.fromOrigins(
                apiOrigin: officialApiOrigin,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(debugFlutterImageCacheMaximumSize(), lessThanOrEqualTo(256));
    expect(
      debugFlutterImageCacheMaximumSizeBytes(),
      lessThanOrEqualTo(48 * 1024 * 1024),
    );
  });

  testWidgets('unmounted media previews evict decoded image cache entries', (
    tester,
  ) async {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    debugSetServerMediaWidgetLoader((uri, {required policy, maxBytes}) async {
      return Uint8List.fromList(_pngBytes);
    });

    const media = MessageMediaSeed(
      id: 'official/evict-klipy-media',
      label: 'Klipy loop',
      kind: MessageMediaKind.gif,
      width: 320,
      height: 180,
      url: 'https://static.klipy.com/i/evict.gif',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 520,
            child: MessageMediaPreview(
              media: media,
              mediaPolicy: ServerMediaPolicy.fromOrigins(
                apiOrigin: officialApiOrigin,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(debugServerMediaImageEvictionCount(), 0);

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pumpAndSettle();

    expect(debugServerMediaImageEvictionCount(), 1);
  });

  testWidgets('message body Klipy GIF URLs mount as media previews', (
    tester,
  ) async {
    final requestedHosts = <String>[];
    debugSetServerMediaWidgetLoader((uri, {required policy, maxBytes}) async {
      requestedHosts.add(uri.host);
      return Uint8List.fromList(_pngBytes);
    });

    const message = MessageSeed(
      id: 'official/message-body-klipy',
      authorId: 'official/user-1',
      author: 'Joshy',
      time: '8:25 AM',
      body:
          'https://static.klipy.com/ii/d7aec6f6171607374b2065c836f92f4/ec/f3/UKQXellq.webp',
      initials: 'JO',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 620,
            child: MessageItem(
              message: message,
              showHeader: true,
              mediaPolicy: ServerMediaPolicy.fromOrigins(
                apiOrigin: officialApiOrigin,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(
        const ValueKey(
          'message-media-image-official/message-body-klipy/klipy-0',
        ),
      ),
      findsOneWidget,
    );
    expect(find.text(message.body), findsNothing);
    expect(requestedHosts, contains('static.klipy.com'));
  });

  testWidgets('inline Klipy media opens an expanded viewer', (tester) async {
    debugSetServerMediaWidgetLoader((uri, {required policy, maxBytes}) async {
      return Uint8List.fromList(_pngBytes);
    });

    const message = MessageSeed(
      id: 'official/message-body-klipy-expand',
      authorId: 'official/user-1',
      author: 'Joshy',
      time: '8:25 AM',
      body:
          'https://static.klipy.com/ii/d7aec6f6171607374b2065c836f92f4/ec/f3/UKQXellq.webp',
      initials: 'JO',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 620,
            child: MessageItem(
              message: message,
              showHeader: true,
              mediaPolicy: ServerMediaPolicy.fromOrigins(
                apiOrigin: officialApiOrigin,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(
        const ValueKey(
          'message-media-image-official/message-body-klipy-expand/klipy-0',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(
        const ValueKey(
          'message-media-lightbox-image-official/message-body-klipy-expand/klipy-0',
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey(
          'message-media-download-official/message-body-klipy-expand/klipy-0',
        ),
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(
        const ValueKey(
          'message-media-close-official/message-body-klipy-expand/klipy-0',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(
        const ValueKey(
          'message-media-lightbox-image-official/message-body-klipy-expand/klipy-0',
        ),
      ),
      findsNothing,
    );
  });

  testWidgets('hovering loaded Klipy media does not reload the placeholder', (
    tester,
  ) async {
    var loadCount = 0;
    debugSetServerMediaWidgetLoader((uri, {required policy, maxBytes}) async {
      loadCount += 1;
      return Uint8List.fromList(_pngBytes);
    });

    const message = MessageSeed(
      id: 'official/message-body-klipy-hover',
      authorId: 'official/user-1',
      author: 'Joshy',
      time: '8:25 AM',
      body:
          'https://static.klipy.com/ii/d7aec6f6171607374b2065c836f92f4/ec/f3/UKQXellq.webp',
      initials: 'JO',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 620,
            child: MessageItem(
              message: message,
              showHeader: true,
              mediaPolicy: ServerMediaPolicy.fromOrigins(
                apiOrigin: officialApiOrigin,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final imageFinder = find.byKey(
      const ValueKey(
        'message-media-image-official/message-body-klipy-hover/klipy-0',
      ),
    );
    expect(imageFinder, findsOneWidget);
    expect(find.text('Preview ready'), findsNothing);
    expect(loadCount, 1);

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();
    addTearDown(gesture.removePointer);
    await gesture.moveTo(
      tester.getCenter(
        find.byKey(
          const ValueKey(
            'message-hover-surface-official/message-body-klipy-hover',
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 80));

    expect(imageFinder, findsOneWidget);
    expect(find.text('Preview ready'), findsNothing);
    expect(loadCount, 1);
  });

  testWidgets('timeline opens at newest messages when no saved offset exists', (
    tester,
  ) async {
    debugSetServerMediaWidgetLoader((uri, {required policy, maxBytes}) async {
      return Uint8List.fromList(_pngBytes);
    });
    final messages = [
      for (var index = 0; index < 45; index += 1)
        MessageSeed(
          id: 'official/initial-bottom-$index',
          authorId: 'official/user-1',
          author: 'Joshy',
          time: '8:25 AM',
          body: index == 4
              ? 'https://static.klipy.com/ii/d7aec6f6171607374b2065c836f92f4/ec/f3/UKQXellq.webp'
              : 'message $index',
          initials: 'JO',
        ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 360,
            width: 640,
            child: MessageTimeline(
              messages: messages,
              pageStorageKey: 'timeline-initial-bottom-test',
              mediaPolicy: ServerMediaPolicy.fromOrigins(
                apiOrigin: officialApiOrigin,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump();

    final position = tester
        .state<ScrollableState>(
          find.descendant(
            of: find.byKey(
              const ValueKey(
                'message-timeline-scrollable-timeline-initial-bottom-test',
              ),
            ),
            matching: find.byType(Scrollable),
          ),
        )
        .position;
    expect(position.maxScrollExtent - position.pixels, lessThanOrEqualTo(1));
  });

  testWidgets(
    'timeline restores bottom after invite preview increases history',
    (tester) async {
      final previewCompleter = Completer<ServerInvitePreview>();
      final baseMessages = [
        for (var index = 0; index < 35; index += 1)
          MessageSeed(
            id: 'official/invite-bottom-base-$index',
            authorId: 'official/user-1',
            author: 'Joshy',
            time: '8:25 AM',
            body: 'message $index',
            initials: 'JO',
          ),
      ];
      final inviteMessages = [
        ...baseMessages,
        const MessageSeed(
          id: 'official/invite-bottom-card',
          authorId: 'official/user-1',
          author: 'Joshy',
          time: '8:26 AM',
          body: 'Join us https://verdant.chat/invite/BOTTOM1',
          initials: 'JO',
        ),
      ];

      Widget timeline(List<MessageSeed> messages) {
        return MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 360,
              width: 640,
              child: MessageTimeline(
                messages: messages,
                pageStorageKey: 'timeline-invite-restores-bottom-test',
                mediaPolicy: ServerMediaPolicy.fromOrigins(
                  apiOrigin: officialApiOrigin,
                ),
                onPreviewInvite: (_) => previewCompleter.future,
              ),
            ),
          ),
        );
      }

      await tester.pumpWidget(timeline(baseMessages));
      await tester.pump();
      await tester.pump();
      await tester.pump();

      var scrollable = find.descendant(
        of: find.byKey(
          const ValueKey(
            'message-timeline-scrollable-timeline-invite-restores-bottom-test',
          ),
        ),
        matching: find.byType(Scrollable),
      );
      var position = tester.state<ScrollableState>(scrollable).position;
      expect(position.maxScrollExtent - position.pixels, lessThanOrEqualTo(1));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.pumpWidget(timeline(inviteMessages));
      await tester.pump();
      await tester.pump();

      await tester.tap(
        find.byKey(const ValueKey('message-invite-preview-button')),
      );
      await tester.pump();

      previewCompleter.complete(
        const ServerInvitePreview(
          code: 'BOTTOM1',
          server: ServerSettingsServer(
            id: 'invite-server',
            name: 'Invite Server',
            ownerId: 'user-1',
            voiceBitrate: 64000,
            bannerOffsetY: 50,
            memberCount: 3,
            large: false,
            createdAt: '',
            updatedAt: '',
          ),
          inviterUsername: 'Joshy',
          isMember: false,
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 220));

      scrollable = find.descendant(
        of: find.byKey(
          const ValueKey(
            'message-timeline-scrollable-timeline-invite-restores-bottom-test',
          ),
        ),
        matching: find.byType(Scrollable),
      );
      position = tester.state<ScrollableState>(scrollable).position;
      expect(position.maxScrollExtent - position.pixels, lessThanOrEqualTo(1));
      expect(
        find.byKey(
          const ValueKey('message-invite-card-official/invite-bottom-card'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('timeline keeps newest visible after link preview hydrates', (
    tester,
  ) async {
    final previewService = _CompletingMessageLinkPreviewService();
    final messages = [
      for (var index = 0; index < 60; index += 1)
        MessageSeed(
          id: 'official/link-bottom-$index',
          authorId: 'official/user-${index % 2}',
          author: index.isEven ? 'Joshy' : 'Mira',
          time: '8:25 AM',
          body: index == 59
              ? 'latest message https://example.com/release'
              : 'link preview bottom message $index',
          initials: index.isEven ? 'JO' : 'MI',
        ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 360,
            width: 640,
            child: MessageTimeline(
              messages: messages,
              pageStorageKey: 'timeline-link-preview-bottom-test',
              linkPreviewService: previewService,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));
    await tester.pump(const Duration(milliseconds: 220));

    final scrollable = find.descendant(
      of: find.byKey(
        const ValueKey(
          'message-timeline-scrollable-timeline-link-preview-bottom-test',
        ),
      ),
      matching: find.byType(Scrollable),
    );
    final position = tester.state<ScrollableState>(scrollable).position;
    expect(position.maxScrollExtent - position.pixels, lessThanOrEqualTo(1));

    previewService.completeMetadata(
      MessageLinkPreviewMetadata(
        url: Uri.parse('https://example.com/release'),
        title: 'A longer release preview title',
        description:
            'A hydrated summary that is intentionally longer than the fallback URL.',
        siteName: 'Example Docs',
        imageProxyUrl:
            '/api/link-previews/image?url=https%3A%2F%2Fexample.com%2Fcard.png',
      ),
    );
    await tester.pump();
    previewService.completeImage(Uint8List.fromList(_pngBytes));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));
    await tester.pump(const Duration(milliseconds: 220));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));

    expect(find.text('A longer release preview title'), findsOneWidget);
    expect(find.text('Example Docs'), findsOneWidget);
    expect(position.maxScrollExtent - position.pixels, lessThanOrEqualTo(1));
  });

  testWidgets('unavailable link preview opens on first click after warning', (
    tester,
  ) async {
    final launcher = _RecordingAnnouncementLinkLauncher();
    final uri = Uri.parse('https://example.com/no-preview');

    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerdantTheme(),
        home: Scaffold(
          body: MessageLinkPreviews(
            messageId: 'official/link-warning-message',
            previews: [
              MessageLinkPreviewData(
                kind: MessageLinkPreviewKind.generic,
                uri: uri,
              ),
            ],
            linkPreviewService: const _UnavailableMessageLinkPreviewService(),
            linkLauncher: launcher,
          ),
        ),
      ),
    );

    final previewCard = find.byKey(
      const ValueKey(
        'message-link-preview-generic-official/link-warning-message-0',
      ),
    );
    expect(previewCard, findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text(uri.toString()), findsOneWidget);
    expect(find.text('Open with warning'), findsNothing);
    expect(launcher.openedUris, isEmpty);

    await tester.tap(previewCard);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('external-link-warning-dialog')),
      findsOneWidget,
    );
    expect(find.text('Open external link?'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('external-link-warning-dialog')),
        matching: find.text('example.com'),
      ),
      findsOneWidget,
    );
    expect(launcher.openedUris, isEmpty);

    await tester.tap(find.byKey(const ValueKey('external-link-warning-open')));
    await tester.pumpAndSettle();

    expect(launcher.openedUris, [uri]);
  });

  testWidgets('mounted media does not force bottom after the user scrolls up', (
    tester,
  ) async {
    debugSetServerMediaWidgetLoader((uri, {required policy, maxBytes}) async {
      return Uint8List.fromList(_pngBytes);
    });
    final messages = [
      for (var index = 0; index < 70; index += 1)
        MessageSeed(
          id: 'official/media-scroll-$index',
          authorId: 'official/user-${index % 2}',
          author: index.isEven ? 'Joshy' : 'Mira',
          time: '8:25 AM',
          body: index == 2
              ? 'https://static.klipy.com/ii/d7aec6f6171607374b2065c836f92f4/ec/f3/UKQXellq.webp'
              : 'scroll position message $index',
          initials: index.isEven ? 'JO' : 'MI',
        ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 360,
            width: 640,
            child: MessageTimeline(
              messages: messages,
              pageStorageKey: 'timeline-media-scroll-up-test',
              mediaPolicy: ServerMediaPolicy.fromOrigins(
                apiOrigin: officialApiOrigin,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump();

    final scrollable = find.descendant(
      of: find.byKey(
        const ValueKey(
          'message-timeline-scrollable-timeline-media-scroll-up-test',
        ),
      ),
      matching: find.byType(Scrollable),
    );
    final position = tester.state<ScrollableState>(scrollable).position;
    position.jumpTo(position.maxScrollExtent);
    await tester.pump();
    expect(position.maxScrollExtent - position.pixels, lessThanOrEqualTo(1));

    position.jumpTo(0);
    await tester.pump();
    position.jumpTo(80);
    await tester.pumpAndSettle();

    expect(position.pixels, closeTo(80, 1));
    expect(position.maxScrollExtent - position.pixels, greaterThan(1000));
  });

  testWidgets('small user scroll up disables bottom stickiness immediately', (
    tester,
  ) async {
    var messages = [
      for (var index = 0; index < 80; index += 1)
        MessageSeed(
          id: 'official/slow-wheel-$index',
          authorId: 'official/user-${index % 2}',
          author: index.isEven ? 'Joshy' : 'Mira',
          time: '8:25 AM',
          body: 'slow wheel message $index',
          initials: index.isEven ? 'JO' : 'MI',
        ),
    ];

    Widget timeline() {
      return MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 360,
            width: 640,
            child: MessageTimeline(
              messages: messages,
              pageStorageKey: 'timeline-slow-wheel-scroll-up-test',
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(timeline());
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump();

    final scrollable = find.descendant(
      of: find.byKey(
        const ValueKey(
          'message-timeline-scrollable-timeline-slow-wheel-scroll-up-test',
        ),
      ),
      matching: find.byType(Scrollable),
    );
    final position = tester.state<ScrollableState>(scrollable).position;
    position.jumpTo(position.maxScrollExtent);
    await tester.pump();
    expect(position.maxScrollExtent - position.pixels, lessThanOrEqualTo(1));

    await tester.drag(scrollable, const Offset(0, 48));
    await tester.pump(const Duration(milliseconds: 80));
    final distanceFromBottom = position.maxScrollExtent - position.pixels;
    expect(distanceFromBottom, lessThan(160));

    messages = [
      ...messages,
      const MessageSeed(
        id: 'official/slow-wheel-new-message',
        authorId: 'official/user-2',
        author: 'Avery',
        time: '8:26 AM',
        body: 'new realtime message should not steal scroll',
        initials: 'AV',
      ),
    ];
    await tester.pumpWidget(timeline());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 240));

    final updatedDistanceFromBottom =
        position.maxScrollExtent - position.pixels;
    expect(updatedDistanceFromBottom, greaterThan(distanceFromBottom));
    expect(updatedDistanceFromBottom, lessThan(220));
  });

  testWidgets('small wheel scroll up disables bottom stickiness immediately', (
    tester,
  ) async {
    var messages = [
      for (var index = 0; index < 80; index += 1)
        MessageSeed(
          id: 'official/slow-wheel-event-$index',
          authorId: 'official/user-${index % 2}',
          author: index.isEven ? 'Joshy' : 'Mira',
          time: '8:25 AM',
          body: 'slow wheel event message $index',
          initials: index.isEven ? 'JO' : 'MI',
        ),
    ];

    Widget timeline() {
      return MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 360,
            width: 640,
            child: MessageTimeline(
              messages: messages,
              pageStorageKey: 'timeline-slow-wheel-event-scroll-up-test',
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(timeline());
    for (var frame = 0; frame < 6; frame += 1) {
      await tester.pump();
    }

    final scrollable = find.descendant(
      of: find.byKey(
        const ValueKey(
          'message-timeline-scrollable-timeline-slow-wheel-event-scroll-up-test',
        ),
      ),
      matching: find.byType(Scrollable),
    );
    final position = tester.state<ScrollableState>(scrollable).position;
    position.jumpTo(position.maxScrollExtent);
    await tester.pump();
    expect(position.maxScrollExtent - position.pixels, lessThanOrEqualTo(1));

    final scrollCenter = tester.getCenter(scrollable);
    for (var tick = 0; tick < 3; tick += 1) {
      tester.binding.handlePointerEvent(
        PointerScrollEvent(
          position: scrollCenter,
          scrollDelta: const Offset(0, -32),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
    }

    final distanceFromBottom = position.maxScrollExtent - position.pixels;
    expect(distanceFromBottom, greaterThan(1));
    expect(distanceFromBottom, lessThan(160));

    messages = [
      ...messages,
      const MessageSeed(
        id: 'official/slow-wheel-event-new-message',
        authorId: 'official/user-2',
        author: 'Avery',
        time: '8:26 AM',
        body: 'new realtime message should not steal wheel scroll',
        initials: 'AV',
      ),
    ];
    await tester.pumpWidget(timeline());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 240));

    final updatedDistanceFromBottom =
        position.maxScrollExtent - position.pixels;
    expect(updatedDistanceFromBottom, greaterThan(distanceFromBottom));
    expect(updatedDistanceFromBottom, lessThan(220));
  });

  testWidgets('bottom user scroll notification does not undo wheel-up pinning', (
    tester,
  ) async {
    var messages = [
      for (var index = 0; index < 80; index += 1)
        MessageSeed(
          id: 'official/wheel-bottom-notification-$index',
          authorId: 'official/user-${index % 2}',
          author: index.isEven ? 'Joshy' : 'Mira',
          time: '8:25 AM',
          body: 'wheel bottom notification message $index',
          initials: index.isEven ? 'JO' : 'MI',
        ),
    ];

    Widget timeline() {
      return MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 360,
            width: 640,
            child: MessageTimeline(
              messages: messages,
              pageStorageKey: 'timeline-wheel-bottom-notification-test',
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(timeline());
    for (var frame = 0; frame < 6; frame += 1) {
      await tester.pump();
    }

    final scrollable = find.descendant(
      of: find.byKey(
        const ValueKey(
          'message-timeline-scrollable-timeline-wheel-bottom-notification-test',
        ),
      ),
      matching: find.byType(Scrollable),
    );
    final scrollableState = tester.state<ScrollableState>(scrollable);
    final position = scrollableState.position;
    position.jumpTo(position.maxScrollExtent);
    await tester.pump();
    expect(position.maxScrollExtent - position.pixels, lessThanOrEqualTo(1));

    final scrollCenter = tester.getCenter(scrollable);
    tester.binding.handlePointerEvent(
      PointerScrollEvent(
        position: scrollCenter,
        scrollDelta: const Offset(0, -32),
      ),
    );
    UserScrollNotification(
      metrics: position,
      context: scrollableState.context,
      direction: ScrollDirection.forward,
    ).dispatch(scrollableState.context);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    final distanceFromBottom = position.maxScrollExtent - position.pixels;
    expect(distanceFromBottom, greaterThan(1));

    messages = [
      ...messages,
      const MessageSeed(
        id: 'official/wheel-bottom-notification-new-message',
        authorId: 'official/user-2',
        author: 'Avery',
        time: '8:26 AM',
        body: 'new message should not re-stick after wheel notification',
        initials: 'AV',
      ),
    ];
    await tester.pumpWidget(timeline());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 240));

    final updatedDistanceFromBottom =
        position.maxScrollExtent - position.pixels;
    expect(updatedDistanceFromBottom, greaterThan(distanceFromBottom));
    expect(updatedDistanceFromBottom, lessThan(220));
  });

  testWidgets('timeline restores the saved scroll offset on remount', (
    tester,
  ) async {
    final messages = [
      for (var index = 0; index < 80; index += 1)
        MessageSeed(
          id: 'official/saved-scroll-$index',
          authorId: 'official/user-${index % 2}',
          author: index.isEven ? 'Joshy' : 'Mira',
          time: '8:25 AM',
          body: 'saved scroll message $index',
          initials: index.isEven ? 'JO' : 'MI',
        ),
    ];

    Widget timeline() {
      return MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 360,
            width: 640,
            child: MessageTimeline(
              messages: messages,
              pageStorageKey: 'timeline-saved-offset-test',
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(timeline());
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump();

    final firstScrollable = find.descendant(
      of: find.byKey(
        const ValueKey(
          'message-timeline-scrollable-timeline-saved-offset-test',
        ),
      ),
      matching: find.byType(Scrollable),
    );
    final position = tester.state<ScrollableState>(firstScrollable).position;
    position.jumpTo(240);
    await tester.pump();

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(timeline());
    await tester.pump();
    await tester.pump();

    final restored = tester.state<ScrollableState>(firstScrollable).position;
    expect(restored.pixels, closeTo(240, 1));
  });

  testWidgets('reaction pills toggle the local count with animation', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerdantTheme(),
        home: Scaffold(
          body: MessageReactionBar(
            messageId: 'official/message-1',
            initialReactions: [ReactionSeed(emoji: '\u{1F44D}', count: 1)],
            mediaPolicy: ServerMediaPolicy.fromOrigins(
              apiOrigin: officialApiOrigin,
            ),
          ),
        ),
      ),
    );

    expect(find.text('1'), findsOneWidget);

    await tester.tap(
      find.byKey(
        const ValueKey('message-reaction-official/message-1-\u{1F44D}'),
      ),
    );
    await tester.pump(const Duration(milliseconds: 220));

    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('messages render server custom emoji images by shortcode', (
    tester,
  ) async {
    debugSetServerMediaWidgetLoader((uri, {required policy, maxBytes}) async {
      return Uint8List.fromList(_pngBytes);
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerdantTheme(),
        home: Scaffold(
          body: MessageItem(
            message: const MessageSeed(
              id: 'official/message-custom-emoji',
              authorId: 'official/user-1',
              author: 'Joshy',
              time: '8:25 AM',
              body: 'ship it :verdant:',
              initials: 'JO',
            ),
            showHeader: true,
            mediaPolicy: ServerMediaPolicy.fromOrigins(
              apiOrigin: officialApiOrigin,
            ),
            customEmojis: const [
              ServerCustomEmoji(
                id: 'emoji-1',
                name: 'verdant',
                imageUrl: 'https://cdn.pryzmapp.com/emojis/emoji-1.webp',
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(
        const ValueKey(
          'message-custom-emoji-official/message-custom-emoji-emoji-1',
        ),
      ),
      findsOneWidget,
    );
    expect(
      tester.getSize(
        find.byKey(
          const ValueKey(
            'message-custom-emoji-official/message-custom-emoji-emoji-1',
          ),
        ),
      ),
      const Size.square(48),
    );
  });

  testWidgets('message custom emoji context menu shows source metadata', (
    tester,
  ) async {
    debugSetServerMediaWidgetLoader((uri, {required policy, maxBytes}) async {
      return Uint8List.fromList(_pngBytes);
    });
    const emoji = ServerCustomEmoji(
      id: 'emoji-1',
      name: 'verdant',
      imageUrl: 'https://cdn.pryzmapp.com/emojis/emoji-1.webp',
      networkId: 'origin:https%3A%2F%2Fapi.verdant.chat',
      serverId: 'server-1',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerdantTheme(),
        home: Scaffold(
          body: MessageItem(
            message: const MessageSeed(
              id: 'official/message-custom-emoji',
              authorId: 'official/user-1',
              author: 'Joshy',
              time: '8:25 AM',
              body: 'ship it :verdant:',
              initials: 'JO',
            ),
            showHeader: true,
            mediaPolicy: ServerMediaPolicy.fromOrigins(
              apiOrigin: officialApiOrigin,
            ),
            customEmojis: const [emoji],
            customExpressionSources: {
              customExpressionSourceKey(emoji): const CustomExpressionSource(
                serverId: 'server-1',
                networkId: 'origin:https%3A%2F%2Fapi.verdant.chat',
                label: 'Verdant',
                iconUrl: 'https://cdn.pryzmapp.com/server-icons/server-1.webp',
              ),
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    const itemKey =
        'message-custom-emoji-official/message-custom-emoji-emoji-1';
    await tester.tapAt(
      tester.getCenter(find.byKey(const ValueKey(itemKey))),
      buttons: kSecondaryMouseButton,
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(
        const ValueKey('custom-expression-context-shortcode-$itemKey'),
      ),
      findsOneWidget,
    );
    expect(find.text(':verdant:'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(
          const ValueKey('custom-expression-context-server-$itemKey'),
        ),
        matching: find.text('Verdant'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('message-context-menu-official/message-custom-emoji'),
      ),
      findsNothing,
    );
  });

  testWidgets('messages render server custom sticker images by shortcode', (
    tester,
  ) async {
    debugSetServerMediaWidgetLoader((uri, {required policy, maxBytes}) async {
      return Uint8List.fromList(_pngBytes);
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerdantTheme(),
        home: Scaffold(
          body: MessageItem(
            message: const MessageSeed(
              id: 'official/message-custom-sticker',
              authorId: 'official/user-1',
              author: 'Joshy',
              time: '8:25 AM',
              body: 'bonk :smokoko:',
              initials: 'JO',
            ),
            showHeader: true,
            mediaPolicy: ServerMediaPolicy.fromOrigins(
              apiOrigin: officialApiOrigin,
            ),
            customStickers: const [
              ServerCustomSticker(
                id: 'sticker-1',
                name: 'smokoko',
                imageUrl: 'https://cdn.pryzmapp.com/stickers/sticker-1.webp',
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(
        const ValueKey(
          'message-custom-sticker-official/message-custom-sticker-sticker-1',
        ),
      ),
      findsOneWidget,
    );
    expect(
      tester.getSize(
        find.byKey(
          const ValueKey(
            'message-custom-sticker-official/message-custom-sticker-sticker-1',
          ),
        ),
      ),
      const Size.square(96),
    );
  });

  testWidgets('message custom sticker context menu shows source metadata', (
    tester,
  ) async {
    debugSetServerMediaWidgetLoader((uri, {required policy, maxBytes}) async {
      return Uint8List.fromList(_pngBytes);
    });
    const sticker = ServerCustomSticker(
      id: 'sticker-1',
      name: 'smokoko',
      imageUrl: 'https://cdn.pryzmapp.com/stickers/sticker-1.webp',
      networkId: 'origin:https%3A%2F%2Fapi.verdant.chat',
      serverId: 'server-1',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerdantTheme(),
        home: Scaffold(
          body: MessageItem(
            message: const MessageSeed(
              id: 'official/message-custom-sticker',
              authorId: 'official/user-1',
              author: 'Joshy',
              time: '8:25 AM',
              body: 'bonk :smokoko:',
              initials: 'JO',
            ),
            showHeader: true,
            mediaPolicy: ServerMediaPolicy.fromOrigins(
              apiOrigin: officialApiOrigin,
            ),
            customStickers: const [sticker],
            customExpressionSources: {
              customExpressionSourceKey(sticker): const CustomExpressionSource(
                serverId: 'server-1',
                networkId: 'origin:https%3A%2F%2Fapi.verdant.chat',
                label: 'Verdant stickers',
                iconUrl: 'https://cdn.pryzmapp.com/server-icons/server-1.webp',
              ),
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    const itemKey =
        'message-custom-sticker-official/message-custom-sticker-sticker-1';
    await tester.tapAt(
      tester.getCenter(find.byKey(const ValueKey(itemKey))),
      buttons: kSecondaryMouseButton,
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(
        const ValueKey('custom-expression-context-shortcode-$itemKey'),
      ),
      findsOneWidget,
    );
    expect(find.text(':smokoko:'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(
          const ValueKey('custom-expression-context-server-$itemKey'),
        ),
        matching: find.text('Verdant stickers'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('message-context-menu-official/message-custom-sticker'),
      ),
      findsNothing,
    );
  });

  testWidgets('messages cap rendered server custom sticker shortcode images', (
    tester,
  ) async {
    debugSetServerMediaWidgetLoader((uri, {required policy, maxBytes}) async {
      return Uint8List.fromList(_pngBytes);
    });

    final repeatedStickerBody = List.filled(
      maxInlineStickerSpansPerMessage + 3,
      ':smokoko:',
    ).join(' ');

    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerdantTheme(),
        home: Scaffold(
          body: MessageItem(
            message: MessageSeed(
              id: 'official/message-custom-sticker-cap',
              authorId: 'official/user-1',
              author: 'Joshy',
              time: '8:25 AM',
              body: repeatedStickerBody,
              initials: 'JO',
            ),
            showHeader: true,
            mediaPolicy: ServerMediaPolicy.fromOrigins(
              apiOrigin: officialApiOrigin,
            ),
            customStickers: const [
              ServerCustomSticker(
                id: 'sticker-1',
                name: 'smokoko',
                imageUrl: 'https://cdn.pryzmapp.com/stickers/sticker-1.webp',
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(
        const ValueKey(
          'message-custom-sticker-official/message-custom-sticker-cap-sticker-1',
        ),
      ),
      findsNWidgets(maxInlineStickerSpansPerMessage),
    );
  });

  testWidgets('chat workspace renders only active-server custom emoji images', (
    tester,
  ) async {
    debugSetServerMediaWidgetLoader((uri, {required policy, maxBytes}) async {
      return Uint8List.fromList(_pngBytes);
    });
    const networkId = 'origin:https%3A%2F%2Fapi-test.pryzmapp.com';
    final serverSettings = WorkspaceSeed.sample.serverSettings.copyWith(
      networkId: networkId,
      localServerId: 'fake-server-1',
      emojis: const [
        ServerSettingsListItemSeed(
          id: 'emoji-active',
          title: ':smokoko:',
          subtitle: 'Created by Joshy',
          trailing: 'Today',
          avatarUrl: 'https://cdn.pryzmapp.com/emojis/smokoko.webp',
        ),
      ],
    );
    final seed = _workspaceSeedWithMembersAndMessages(
      networkId: networkId,
      members: const [
        MemberSeed(
          id: '$networkId/user-joshy',
          name: 'Joshy',
          status: 'Online',
          initials: 'JO',
        ),
      ],
      messages: const [
        MessageSeed(
          id: '$networkId/message-grouped-custom-emoji',
          authorId: '$networkId/user-joshy',
          author: 'Joshy',
          time: '8:25 AM',
          body: 'still here :smokoko:',
          initials: 'JO',
        ),
      ],
      serverSettings: serverSettings,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerdantTheme(),
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 700,
            child: ChatWorkspace(
              seed: seed,
              currentUserId: 'user-joshy',
              currentUserName: 'Joshy',
              currentUserInitials: 'JO',
              customEmojiGroups: const [
                ServerCustomEmojiGroup(
                  serverId: 'other-server',
                  networkId: networkId,
                  label: 'Other Server',
                  emojis: [
                    ServerCustomEmoji(
                      id: 'emoji-other',
                      name: 'smokoko',
                      imageUrl:
                          'https://cdn.pryzmapp.com/emojis/other-smokoko.webp',
                      serverId: 'other-server',
                      networkId: networkId,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(
        const ValueKey(
          'message-custom-emoji-$networkId/message-grouped-custom-emoji-emoji-active',
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey(
          'message-custom-emoji-$networkId/message-grouped-custom-emoji-emoji-other',
        ),
      ),
      findsNothing,
    );
  });

  testWidgets('reaction chips render server custom emoji images', (
    tester,
  ) async {
    debugSetServerMediaWidgetLoader((uri, {required policy, maxBytes}) async {
      return Uint8List.fromList(_pngBytes);
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerdantTheme(),
        home: Scaffold(
          body: MessageReactionBar(
            messageId: 'official/message-custom-reaction',
            initialReactions: const [
              ReactionSeed(emoji: ':verdant:', emojiId: 'emoji-1', count: 2),
            ],
            mediaPolicy: ServerMediaPolicy.fromOrigins(
              apiOrigin: officialApiOrigin,
            ),
            customEmojis: const [
              ServerCustomEmoji(
                id: 'emoji-1',
                name: 'verdant',
                imageUrl: 'https://cdn.pryzmapp.com/emojis/emoji-1.webp',
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('message-reaction-custom-emoji-emoji-1')),
      findsOneWidget,
    );
    expect(
      tester.getSize(
        find.byKey(const ValueKey('message-reaction-custom-emoji-emoji-1')),
      ),
      const Size.square(25),
    );
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('plain messages hide below-message add reaction affordance', (
    tester,
  ) async {
    const message = MessageSeed(
      id: 'official/message-no-reactions',
      authorId: 'official/user-1',
      author: 'Joshy',
      time: '8:25 AM',
      body: 'No reactions yet.',
      initials: 'JO',
      isOwnMessage: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerdantTheme(),
        home: Scaffold(
          body: SizedBox(
            width: 520,
            child: MessageItem(
              message: message,
              showHeader: true,
              mediaPolicy: ServerMediaPolicy.fromOrigins(
                apiOrigin: officialApiOrigin,
              ),
            ),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('add-reaction-official/message-no-reactions')),
      findsNothing,
    );
    expect(
      find.byKey(
        const ValueKey('message-action-bar-official/message-no-reactions'),
      ),
      findsNothing,
    );
  });

  testWidgets('message hover shows action bar and more opens context menu', (
    tester,
  ) async {
    const message = MessageSeed(
      id: 'official/message-actions',
      authorId: 'official/user-1',
      author: 'Joshy',
      time: '8:25 AM',
      body: 'Hover actions.',
      initials: 'JO',
      isOwnMessage: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerdantTheme(),
        home: Scaffold(
          body: SizedBox(
            width: 520,
            child: MessageItem(
              message: message,
              showHeader: true,
              mediaPolicy: ServerMediaPolicy.fromOrigins(
                apiOrigin: officialApiOrigin,
              ),
            ),
          ),
        ),
      ),
    );

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();
    addTearDown(gesture.removePointer);
    await gesture.moveTo(
      tester.getCenter(
        find.byKey(
          const ValueKey('message-hover-surface-official/message-actions'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('message-action-bar-official/message-actions')),
      findsOneWidget,
    );
    final actionBarTopRect = tester.getRect(
      find.byKey(const ValueKey('message-action-bar-official/message-actions')),
    );
    await gesture.moveTo(
      Offset(actionBarTopRect.center.dx, actionBarTopRect.top + 2),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('message-action-bar-official/message-actions')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(
        const ValueKey('message-action-more-official/message-actions'),
      ),
    );
    await tester.pumpAndSettle();

    final actionBarRect = tester.getRect(
      find.byKey(const ValueKey('message-action-bar-official/message-actions')),
    );
    final menuRect = tester.getRect(
      find.byKey(
        const ValueKey('message-context-menu-official/message-actions'),
      ),
    );

    expect((menuRect.right - actionBarRect.right).abs(), lessThanOrEqualTo(2));
    expect(menuRect.top, greaterThanOrEqualTo(actionBarRect.bottom));
    expect(find.text('Add Reaction'), findsOneWidget);
    expect(find.text('Reply'), findsOneWidget);
    expect(find.text('Edit Message'), findsOneWidget);
    expect(find.text('Copy Text'), findsOneWidget);

    final addReactionSurface = find.byKey(
      const ValueKey('message-context-menu-item-surface-react'),
    );
    expect(addReactionSurface, findsOneWidget);
    final beforeHover = tester.widget<AnimatedContainer>(addReactionSurface);
    expect(
      (beforeHover.decoration! as BoxDecoration).color,
      Colors.transparent,
    );

    await gesture.moveTo(tester.getCenter(addReactionSurface));
    await tester.pump(const Duration(milliseconds: 140));

    final afterHover = tester.widget<AnimatedContainer>(addReactionSurface);
    expect(
      (afterHover.decoration! as BoxDecoration).color,
      VerdantColors.panelHover,
    );
  });

  testWidgets('own message context menu can delete the message', (
    tester,
  ) async {
    const message = MessageSeed(
      id: 'official/message-delete-own',
      authorId: 'official/user-1',
      author: 'Joshy',
      time: '8:25 AM',
      body: 'Delete my message.',
      initials: 'JO',
      isOwnMessage: true,
    );
    MessageSeed? deletedMessage;

    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerdantTheme(),
        home: Scaffold(
          body: SizedBox(
            width: 520,
            child: MessageItem(
              message: message,
              showHeader: true,
              mediaPolicy: ServerMediaPolicy.fromOrigins(
                apiOrigin: officialApiOrigin,
              ),
              onDelete: (value) => deletedMessage = value,
            ),
          ),
        ),
      ),
    );

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();
    addTearDown(gesture.removePointer);
    await gesture.moveTo(
      tester.getCenter(
        find.byKey(
          const ValueKey('message-hover-surface-official/message-delete-own'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(
        const ValueKey('message-action-more-official/message-delete-own'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Delete Message'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('message-context-menu-item-surface-delete')),
    );
    await tester.pumpAndSettle();

    expect(deletedMessage, message);
  });

  testWidgets('manage messages permission can delete another user message', (
    tester,
  ) async {
    const message = MessageSeed(
      id: 'official/message-delete-managed',
      authorId: 'official/user-2',
      author: 'Avery',
      time: '8:25 AM',
      body: 'Moderate this message.',
      initials: 'AV',
      isOwnMessage: false,
    );
    MessageSeed? deletedMessage;

    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerdantTheme(),
        home: Scaffold(
          body: SizedBox(
            width: 520,
            child: MessageItem(
              message: message,
              showHeader: true,
              mediaPolicy: ServerMediaPolicy.fromOrigins(
                apiOrigin: officialApiOrigin,
              ),
              canManageMessages: true,
              onDelete: (value) => deletedMessage = value,
            ),
          ),
        ),
      ),
    );

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();
    addTearDown(gesture.removePointer);
    await gesture.moveTo(
      tester.getCenter(
        find.byKey(
          const ValueKey(
            'message-hover-surface-official/message-delete-managed',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(
        const ValueKey('message-action-more-official/message-delete-managed'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Delete Message'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('message-context-menu-item-surface-delete')),
    );
    await tester.pumpAndSettle();

    expect(deletedMessage, message);
  });

  testWidgets('non-moderator context menu cannot delete another user message', (
    tester,
  ) async {
    const message = MessageSeed(
      id: 'official/message-delete-denied',
      authorId: 'official/user-2',
      author: 'Avery',
      time: '8:25 AM',
      body: 'Leave this message visible.',
      initials: 'AV',
      isOwnMessage: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerdantTheme(),
        home: Scaffold(
          body: SizedBox(
            width: 520,
            child: MessageItem(
              message: message,
              showHeader: true,
              mediaPolicy: ServerMediaPolicy.fromOrigins(
                apiOrigin: officialApiOrigin,
              ),
              onDelete: (_) {},
            ),
          ),
        ),
      ),
    );

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();
    addTearDown(gesture.removePointer);
    await gesture.moveTo(
      tester.getCenter(
        find.byKey(
          const ValueKey(
            'message-hover-surface-official/message-delete-denied',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(
        const ValueKey('message-action-more-official/message-delete-denied'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Delete Message'), findsNothing);
  });

  testWidgets('message action smiley creates the first reaction row', (
    tester,
  ) async {
    const message = MessageSeed(
      id: 'official/message-first-reaction',
      authorId: 'official/user-1',
      author: 'Joshy',
      time: '8:25 AM',
      body: 'React from hover.',
      initials: 'JO',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerdantTheme(),
        home: Scaffold(
          body: SizedBox(
            width: 520,
            child: MessageItem(
              message: message,
              showHeader: true,
              mediaPolicy: ServerMediaPolicy.fromOrigins(
                apiOrigin: officialApiOrigin,
              ),
            ),
          ),
        ),
      ),
    );

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();
    addTearDown(gesture.removePointer);
    await gesture.moveTo(
      tester.getCenter(
        find.byKey(
          const ValueKey(
            'message-hover-surface-official/message-first-reaction',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(
        const ValueKey('message-action-react-official/message-first-reaction'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('emoji-picker-popover')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('emoji-picker-item-smileys-8')));
    await tester.pump(const Duration(milliseconds: 220));

    expect(
      find.byKey(
        const ValueKey('message-reaction-official/message-first-reaction-🙂'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('add-reaction-official/message-first-reaction'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('new bottom reaction keeps timeline scrolled to reveal chip', (
    tester,
  ) async {
    final messages = [
      for (var index = 0; index < 36; index += 1)
        MessageSeed(
          id: 'official/reaction-scroll-$index',
          authorId: 'official/user-1',
          author: 'Joshy',
          time: '8:25 AM',
          body: 'reaction scroll message $index',
          initials: 'JO',
        ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerdantTheme(),
        home: Scaffold(
          body: SizedBox(
            height: 360,
            width: 640,
            child: MessageTimeline(
              messages: messages,
              pageStorageKey: 'timeline-reaction-scroll-test',
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump();

    final scrollable = find.descendant(
      of: find.byKey(
        const ValueKey(
          'message-timeline-scrollable-timeline-reaction-scroll-test',
        ),
      ),
      matching: find.byType(Scrollable),
    );
    final position = tester.state<ScrollableState>(scrollable).position;
    expect(position.maxScrollExtent - position.pixels, lessThanOrEqualTo(1));

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('message-row-official/reaction-scroll-35')),
      260,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();
    addTearDown(gesture.removePointer);
    await gesture.moveTo(
      tester.getCenter(
        find.byKey(
          const ValueKey('message-hover-surface-official/reaction-scroll-35'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(
        const ValueKey('message-action-react-official/reaction-scroll-35'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('emoji-picker-item-smileys-0')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));
    await tester.pump(const Duration(milliseconds: 260));

    final chipRect = tester.getRect(find.byType(MessageReactionChip).last);
    final timelineRect = tester.getRect(
      find.byKey(
        const ValueKey(
          'message-timeline-scrollable-timeline-reaction-scroll-test',
        ),
      ),
    );
    expect(chipRect.bottom, lessThanOrEqualTo(timelineRect.bottom + 4));
  });
}

WorkspaceSeed _workspaceSeedWithMessages(List<MessageSeed> messages) {
  final sample = WorkspaceSeed.sample;
  return WorkspaceSeed(
    networkId: sample.networkId,
    serverId: sample.serverId,
    serverName: sample.serverName,
    serverOwnerId: sample.serverOwnerId,
    serverIconUrl: sample.serverIconUrl,
    serverBannerUrl: sample.serverBannerUrl,
    serverBannerCrop: sample.serverBannerCrop,
    memberCount: sample.memberCount,
    channels: sample.channels,
    members: sample.members,
    messages: messages,
    serverSettings: sample.serverSettings,
    mediaPolicy: sample.mediaPolicy,
  );
}

WorkspaceSeed _workspaceSeedWithMembersAndMessages({
  required String networkId,
  required List<MemberSeed> members,
  required List<MessageSeed> messages,
  ServerSettingsSeed? serverSettings,
}) {
  final sample = WorkspaceSeed.sample;
  final settings = serverSettings ?? sample.serverSettings;
  return WorkspaceSeed(
    networkId: networkId,
    serverId: '$networkId/fake-server-1',
    serverName: sample.serverName,
    serverOwnerId: '$networkId/user-joshy',
    serverIconUrl: sample.serverIconUrl,
    serverBannerUrl: sample.serverBannerUrl,
    serverBannerCrop: sample.serverBannerCrop,
    memberCount: members.length,
    channels: sample.channels,
    members: members,
    messages: messages,
    serverSettings: settings,
    mediaPolicy: sample.mediaPolicy,
  );
}

String _textWidgetText(Text widget) {
  final data = widget.data;
  if (data != null) {
    return data;
  }
  return _plainSpanText(widget.textSpan);
}

String _plainSpanText(InlineSpan? span) {
  if (span == null) {
    return '';
  }
  if (span is! TextSpan) {
    return '';
  }
  final buffer = StringBuffer(span.text ?? '');
  for (final child in span.children ?? const <InlineSpan>[]) {
    buffer.write(_plainSpanText(child));
  }
  return buffer.toString();
}

final class _CompletingMessageLinkPreviewService
    implements MessageLinkPreviewService {
  final _metadataCompleter = Completer<MessageLinkPreviewMetadata?>();
  final _imageCompleter = Completer<Uint8List?>();

  @override
  Future<MessageLinkPreviewMetadata?> loadPreview(Uri uri) =>
      _metadataCompleter.future;

  @override
  Future<Uint8List?> loadPreviewImage(String imageProxyUrl) =>
      _imageCompleter.future;

  void completeMetadata(MessageLinkPreviewMetadata metadata) {
    _metadataCompleter.complete(metadata);
  }

  void completeImage(Uint8List bytes) {
    _imageCompleter.complete(bytes);
  }
}

final class _UnavailableMessageLinkPreviewService
    implements MessageLinkPreviewService {
  const _UnavailableMessageLinkPreviewService();

  @override
  Future<MessageLinkPreviewMetadata?> loadPreview(Uri uri) async => null;

  @override
  Future<Uint8List?> loadPreviewImage(String imageProxyUrl) async => null;
}

final class _RecordingAnnouncementLinkLauncher
    extends AnnouncementLinkLauncher {
  final openedUris = <Uri>[];

  @override
  Future<bool> openExternal(Uri uri) async {
    openedUris.add(uri);
    return true;
  }
}

Future<void> _expectActiveMouseCursor(
  WidgetTester tester,
  Finder finder,
  MouseCursor expected,
) async {
  final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await gesture.addPointer(location: Offset.zero);
  try {
    await gesture.moveTo(tester.getCenter(finder));
    await tester.pump();

    expect(
      RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
      expected,
    );
  } finally {
    await gesture.removePointer();
  }
}

Widget _testYoutubePlayerBuilder(
  BuildContext context,
  Uri embedUri,
  Uri watchUri,
) {
  return ColoredBox(
    key: const ValueKey('chat-timeline-test-youtube-player'),
    color: Colors.black,
    child: Text('${embedUri.host} ${watchUri.host}'),
  );
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
