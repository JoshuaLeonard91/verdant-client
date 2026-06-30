import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verdant_flutter/features/auth/auth_models.dart';
import 'package:verdant_flutter/features/workspace/chat_workspace/emoji_picker_popover.dart';
import 'package:verdant_flutter/features/workspace/chat_workspace/message_reaction_chip.dart';
import 'package:verdant_flutter/features/workspace/chat_workspace/message_timeline.dart';
import 'package:verdant_flutter/features/workspace/context_workspace/context_workspace.dart';
import 'package:verdant_flutter/features/workspace/server_settings_workspace/server_media_image.dart';
import 'package:verdant_flutter/features/workspace/server_settings_workspace/server_media_url_policy.dart';
import 'package:verdant_flutter/features/workspace/server_settings_workspace/server_settings_models.dart';
import 'package:verdant_flutter/features/workspace/shared/member_profile_popover.dart';
import 'package:verdant_flutter/features/workspace/workspace_seed.dart';
import 'package:verdant_flutter/theme/verdant_theme.dart';

void main() {
  final mediaPolicy = ServerMediaPolicy.fromOrigins(
    apiOrigin: officialApiOrigin,
  );
  final avery = MemberSeed(
    id: 'official/user-avery',
    name: 'Avery',
    status: 'Online',
    initials: 'AV',
    role: 'Moderator',
    displayColor: const Color(0xff67e8f9),
    avatarUrl: '$officialApiOrigin/media/avatars/avery.png',
    bannerUrl: '$officialApiOrigin/media/banners/avery.png',
    bannerCrop: BannerCrop(x: 8, y: 12, width: 84, height: 60),
    memberListBannerUrl:
        '$officialApiOrigin/media/member-list-banners/avery.png',
    memberListBannerCrop: BannerCrop(x: 18, y: 4, width: 66, height: 44),
    isActive: true,
  );

  setUp(() {
    debugSetServerMediaWidgetLoader((_, {required policy, maxBytes}) async {
      return Uint8List.fromList(_transparentPngBytes);
    });
  });

  tearDown(() => debugSetServerMediaWidgetLoader(null));

  testWidgets('emoji picker cells expose a hover highlight surface', (
    tester,
  ) async {
    await tester.pumpWidget(
      _Harness(
        child: EmojiPickerPopover(mediaPolicy: mediaPolicy, onSelected: (_) {}),
      ),
    );

    final item = find.byKey(const ValueKey('emoji-picker-item-smileys-0'));
    final surface = find.byKey(
      const ValueKey('emoji-picker-item-smileys-0-surface'),
    );

    expect(item, findsOneWidget);
    expect(surface, findsOneWidget);
    expect(_containerColor(tester, surface), Colors.transparent);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer();
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(item));
    await tester.pump(const Duration(milliseconds: 160));

    expect(_containerColor(tester, surface), isNot(Colors.transparent));
  });

  testWidgets('reaction chips are square leaning and highlight on hover', (
    tester,
  ) async {
    await tester.pumpWidget(
      _Harness(
        child: MessageReactionChip(
          key: const ValueKey('reaction-chip-test'),
          reaction: const ReactionSeed(emoji: '👍', count: 3),
          onPressed: () {},
        ),
      ),
    );

    final chip = find.byKey(const ValueKey('reaction-chip-test'));
    final surface = find.byKey(const ValueKey('message-reaction-surface-👍'));

    expect(chip, findsOneWidget);
    expect(surface, findsOneWidget);
    final size = tester.getSize(chip);
    expect(size.height, greaterThanOrEqualTo(34));
    expect(size.width, lessThanOrEqualTo(size.height + 8));

    final before = _containerColor(tester, surface);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer();
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(chip));
    await tester.pump(const Duration(milliseconds: 160));

    expect(_containerColor(tester, surface), isNot(before));
  });

  testWidgets('reaction chip hover exposes an animated accent ring', (
    tester,
  ) async {
    await tester.pumpWidget(
      _Harness(
        child: MessageReactionChip(
          key: const ValueKey('reaction-chip-hover-ring-test'),
          reaction: const ReactionSeed(emoji: '🙂', count: 2),
          onPressed: () {},
        ),
      ),
    );

    final chip = find.byKey(const ValueKey('reaction-chip-hover-ring-test'));
    final ring = find.byKey(const ValueKey('message-reaction-hover-ring-🙂'));
    expect(chip, findsOneWidget);
    expect(ring, findsOneWidget);
    expect(_containerBorderColor(tester, ring), Colors.transparent);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer();
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(chip));
    await tester.pump(const Duration(milliseconds: 180));

    expect(_containerBorderColor(tester, ring), isNot(Colors.transparent));
  });

  testWidgets('message action buttons show explicit hover feedback', (
    tester,
  ) async {
    await tester.pumpWidget(
      _Harness(
        child: SizedBox(
          width: 720,
          height: 360,
          child: MessageTimeline(
            messages: [_messageFrom(avery)],
            members: [avery],
            mediaPolicy: mediaPolicy,
            stickToBottom: false,
          ),
        ),
      ),
    );

    final message = find.byKey(
      const ValueKey('message-hover-surface-official/message-actions'),
    );
    final reactSurface = find.byKey(
      const ValueKey('message-action-react-official/message-actions-surface'),
    );

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer();
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(message));
    await tester.pumpAndSettle();

    expect(reactSurface, findsOneWidget);
    final before = _containerColor(tester, reactSurface);

    await mouse.moveTo(tester.getCenter(reactSurface));
    await tester.pump(const Duration(milliseconds: 160));

    expect(_containerColor(tester, reactSurface), isNot(before));
  });

  testWidgets('context member list slides between active and all views', (
    tester,
  ) async {
    await tester.pumpWidget(
      _Harness(
        child: SizedBox(
          width: 360,
          height: 420,
          child: ContextWorkspace(
            members: [
              avery,
              avery.copyWith(
                id: 'official/user-offline',
                name: 'Blair',
                status: 'Offline',
                initials: 'BL',
                isActive: false,
              ),
            ],
            mediaPolicy: mediaPolicy,
            width: 320,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('context-members-toggle')));
    await tester.pump(const Duration(milliseconds: 80));

    final switcher = find.byKey(
      const ValueKey('context-members-list-switcher'),
    );
    expect(switcher, findsOneWidget);
    expect(
      find.ancestor(of: switcher, matching: find.byType(ClipRect)),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('context-active-members-list')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('context-all-members-list')),
      findsOneWidget,
    );
  });

  testWidgets('context member rows group by role and hide inline status text', (
    tester,
  ) async {
    await tester.pumpWidget(
      _Harness(
        child: SizedBox(
          width: 360,
          height: 420,
          child: ContextWorkspace(
            members: [avery],
            mediaPolicy: mediaPolicy,
            width: 320,
          ),
        ),
      ),
    );

    expect(find.text('Moderator - 1'), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey('context-member-presence-dot-official/user-avery'),
      ),
      findsOneWidget,
    );
    expect(find.text('Online'), findsNothing);
  });

  testWidgets('context member rows make bots visually distinct', (
    tester,
  ) async {
    const human = MemberSeed(
      id: 'official/user-joshy',
      name: 'Joshy',
      status: 'Online',
      initials: 'JO',
      role: 'Owner',
      isActive: true,
    );
    const bot = MemberSeed(
      id: 'official/bot-codex-feed',
      name: 'Codex Feed Bot',
      status: 'Online',
      initials: 'CB',
      role: 'Bot',
      isActive: true,
    );

    await tester.pumpWidget(
      _Harness(
        child: ContextWorkspace(
          width: 280,
          members: const [human, bot],
          activeMembers: const [human, bot],
          mediaPolicy: mediaPolicy,
        ),
      ),
    );

    expect(
      find.byKey(
        const ValueKey('context-member-bot-pill-official/bot-codex-feed'),
      ),
      findsOneWidget,
    );
    expect(find.text('BOT'), findsOneWidget);
  });

  testWidgets('member profile waits for prepared data before opening', (
    tester,
  ) async {
    final prepared = Completer<MemberSeed>();
    await tester.pumpWidget(
      _Harness(
        child: SizedBox(
          width: 720,
          height: 420,
          child: Align(
            alignment: Alignment.centerRight,
            child: ContextWorkspace(
              members: [avery.copyWith(bannerUrl: null)],
              mediaPolicy: mediaPolicy,
              width: 320,
              onPrepareMemberProfile: (_) => prepared.future,
            ),
          ),
        ),
      ),
    );

    final row = find.byKey(
      const ValueKey('context-member-row-official/user-avery'),
    );
    await tester.tap(row);
    await tester.pump();

    expect(
      find.byKey(const ValueKey('member-profile-popover-official/user-avery')),
      findsNothing,
    );

    prepared.complete(avery);
    await tester.pump();
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('member-profile-popover-official/user-avery')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('member-profile-banner-image-official/user-avery'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('member rows render static webp avatar and banner before hover', (
    tester,
  ) async {
    final animatedMember = avery.copyWith(
      avatarUrl: '$officialApiOrigin/media/avatars/avery.webp',
      bannerUrl: '$officialApiOrigin/media/banners/avery.webp',
      memberListBannerUrl:
          '$officialApiOrigin/media/member-list-banners/avery.webp',
    );

    await tester.pumpWidget(
      _Harness(
        child: SizedBox(
          width: 360,
          height: 420,
          child: ContextWorkspace(
            members: [animatedMember],
            mediaPolicy: mediaPolicy,
            width: 320,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(
        const ValueKey(
          'context-member-avatar-image-static-official/user-avery',
        ),
      ),
      findsOneWidget,
    );
    expect(find.byType(CroppedStaticFirstFrameBannerImage), findsOneWidget);
  });

  testWidgets('member rows use member-list banner while profiles use banner', (
    tester,
  ) async {
    final loadedUris = <Uri>[];
    debugSetServerMediaWidgetLoader((uri, {required policy, maxBytes}) async {
      loadedUris.add(uri);
      return Uint8List.fromList(_transparentPngBytes);
    });

    await tester.pumpWidget(
      _Harness(
        child: SizedBox(
          width: 720,
          height: 420,
          child: Align(
            alignment: Alignment.centerRight,
            child: ContextWorkspace(
              members: [avery],
              mediaPolicy: mediaPolicy,
              width: 320,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(
        const ValueKey('context-member-banner-image-official/user-avery'),
      ),
      findsOneWidget,
    );
    expect(
      tester
          .widget<Opacity>(
            find.byKey(
              const ValueKey(
                'context-member-banner-opacity-official/user-avery',
              ),
            ),
          )
          .opacity,
      closeTo(0.96, 0.001),
    );
    expect(
      loadedUris.map((uri) => uri.path).join('\n'),
      contains('/member-list-banners/avery.png'),
    );

    final row = find.byKey(
      const ValueKey('context-member-row-official/user-avery'),
    );
    final banner = find.byKey(
      const ValueKey('context-member-banner-official/user-avery'),
    );
    expect(tester.getSize(row).height, 68);
    expect(tester.getSize(banner).height, 64);
    expect(tester.getTopLeft(banner).dx, tester.getTopLeft(row).dx);
    expect(tester.getTopRight(banner).dx, tester.getTopRight(row).dx);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer();
    await mouse.moveTo(tester.getCenter(row));
    await tester.pump(const Duration(milliseconds: 130));
    expect(
      tester
          .widget<Opacity>(
            find.byKey(
              const ValueKey(
                'context-member-banner-opacity-official/user-avery',
              ),
            ),
          )
          .opacity,
      closeTo(1, 0.001),
    );
    await mouse.removePointer();

    await tester.tap(row);
    await tester.pump();
    await tester.pumpAndSettle();

    expect(
      find.byKey(
        const ValueKey('member-profile-banner-image-official/user-avery'),
      ),
      findsOneWidget,
    );
    expect(
      loadedUris.map((uri) => uri.path).join('\n'),
      contains('/banners/avery.png'),
    );
  });

  testWidgets('context member avatar avoids initials while known media loads', (
    tester,
  ) async {
    final mediaLoad = Completer<Uint8List>();
    debugSetServerMediaWidgetLoader((_, {required policy, maxBytes}) {
      return mediaLoad.future;
    });

    await tester.pumpWidget(
      _Harness(
        child: SizedBox(
          width: 320,
          height: 300,
          child: ContextWorkspace(
            width: 320,
            activeMembers: [avery],
            members: [avery],
            mediaPolicy: mediaPolicy,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('AV'), findsNothing);

    mediaLoad.complete(Uint8List.fromList(_transparentPngBytes));
    await tester.pumpAndSettle();

    expect(
      find.byKey(
        const ValueKey('context-member-avatar-image-official/user-avery'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('no-avatar context member still renders initials fallback', (
    tester,
  ) async {
    const noAvatar = MemberSeed(
      id: 'official/user-joshy',
      name: 'Joshy',
      status: 'Online',
      initials: 'JO',
      role: 'Moderator',
      displayColor: Color(0xff67e8f9),
      isActive: true,
    );

    await tester.pumpWidget(
      _Harness(
        child: SizedBox(
          width: 320,
          height: 300,
          child: ContextWorkspace(
            width: 320,
            members: [noAvatar],
            mediaPolicy: mediaPolicy,
          ),
        ),
      ),
    );

    final fallback = find.byKey(
      const ValueKey('member-avatar-fallback-official/user-joshy'),
    );

    expect(find.text('JO'), findsOneWidget);
    expect(fallback, findsOneWidget);
    expect(_decoratedBoxColor(tester, fallback), const Color(0xffe67e22));
    expect(
      tester.widget<ClipRRect>(fallback).borderRadius,
      const BorderRadius.all(Radius.circular(8)),
    );
    expect(find.text('Moderator - 1'), findsOneWidget);
  });

  testWidgets('clicking a right-panel member opens a left anchored profile', (
    tester,
  ) async {
    await tester.pumpWidget(
      _Harness(
        child: SizedBox(
          width: 720,
          height: 420,
          child: Align(
            alignment: Alignment.centerRight,
            child: ContextWorkspace(
              members: [avery],
              mediaPolicy: mediaPolicy,
              width: 320,
            ),
          ),
        ),
      ),
    );

    final row = find.byKey(
      const ValueKey('context-member-row-official/user-avery'),
    );
    await tester.tap(row);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 180));
    await tester.pumpAndSettle();

    final popover = find.byKey(
      const ValueKey('member-profile-popover-official/user-avery'),
    );
    expect(popover, findsOneWidget);
    expect(
      tester.getRect(popover).right,
      lessThanOrEqualTo(tester.getRect(row).left + 1),
    );
    expect(
      find.byKey(
        const ValueKey('member-profile-banner-image-official/user-avery'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('member-profile-avatar-image-official/user-avery'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('clicking a chat author opens a right anchored profile', (
    tester,
  ) async {
    await tester.pumpWidget(
      _Harness(
        child: SizedBox(
          width: 720,
          height: 360,
          child: MessageTimeline(
            messages: [_messageFrom(avery)],
            members: [avery],
            mediaPolicy: mediaPolicy,
            stickToBottom: false,
          ),
        ),
      ),
    );

    final avatar = find.byKey(
      const ValueKey('message-avatar-official/user-avery'),
    );
    await tester.tap(avatar);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 180));

    final popover = find.byKey(
      const ValueKey('member-profile-popover-official/user-avery'),
    );
    expect(popover, findsOneWidget);
    expect(
      tester.getRect(popover).left,
      greaterThanOrEqualTo(tester.getRect(avatar).right - 1),
    );
  });

  testWidgets(
    'chat author profile waits for prepared member data before opening',
    (tester) async {
      final prepared = Completer<MemberSeed>();
      final staleAuthor = avery.copyWith(
        avatarUrl: null,
        bannerUrl: null,
        memberListBannerUrl: null,
      );
      await tester.pumpWidget(
        _Harness(
          child: SizedBox(
            width: 720,
            height: 360,
            child: MessageTimeline(
              messages: [_messageFrom(staleAuthor)],
              members: [staleAuthor],
              mediaPolicy: mediaPolicy,
              stickToBottom: false,
              onPrepareMemberProfile: (_) => prepared.future,
            ),
          ),
        ),
      );

      final avatar = find.byKey(
        const ValueKey('message-avatar-official/user-avery'),
      );
      await tester.tap(avatar);
      await tester.pump();

      expect(
        find.byKey(
          const ValueKey('member-profile-popover-official/user-avery'),
        ),
        findsNothing,
      );

      prepared.complete(avery);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey('member-profile-popover-official/user-avery'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('member-profile-banner-image-official/user-avery'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('member-profile-avatar-image-official/user-avery'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('clicking a chat author name opens the member profile', (
    tester,
  ) async {
    await tester.pumpWidget(
      _Harness(
        child: SizedBox(
          width: 720,
          height: 360,
          child: MessageTimeline(
            messages: [_messageFrom(avery)],
            members: [avery],
            mediaPolicy: mediaPolicy,
            stickToBottom: false,
          ),
        ),
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey('message-author-name-official/user-avery')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 180));

    expect(
      find.byKey(const ValueKey('member-profile-popover-official/user-avery')),
      findsOneWidget,
    );
  });

  testWidgets('profile popover lowers avatar beside identity and status', (
    tester,
  ) async {
    await tester.pumpWidget(
      _Harness(
        child: SizedBox(
          width: 720,
          height: 420,
          child: Stack(
            children: [
              MemberProfilePopoverOverlay(
                member: avery,
                mediaPolicy: mediaPolicy,
                anchorRect: const Rect.fromLTWH(80, 24, 48, 48),
                side: MemberProfilePopoverSide.right,
                onDismiss: () {},
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final bannerSlot = find.byKey(
      const ValueKey('member-profile-banner-slot-official/user-avery'),
    );
    final avatarFrame = find.byKey(
      const ValueKey('member-profile-avatar-frame-official/user-avery'),
    );
    final summaryColumn = find.byKey(
      const ValueKey('member-profile-summary-column-official/user-avery'),
    );
    final identityRow = find.byKey(
      const ValueKey('member-profile-identity-row-official/user-avery'),
    );

    expect(bannerSlot, findsOneWidget);
    expect(avatarFrame, findsOneWidget);
    expect(summaryColumn, findsOneWidget);
    expect(identityRow, findsOneWidget);

    final bannerRect = tester.getRect(bannerSlot);
    final avatarRect = tester.getRect(avatarFrame);
    final summaryRect = tester.getRect(summaryColumn);

    expect(avatarRect.top, greaterThanOrEqualTo(bannerRect.bottom + 24));
    expect(summaryRect.left, greaterThan(avatarRect.right + 8));
    expect(
      summaryRect.center.dy,
      inInclusiveRange(avatarRect.top, avatarRect.bottom),
    );
  });

  testWidgets('profile popover labels cosmetic name color separately', (
    tester,
  ) async {
    await tester.pumpWidget(
      _Harness(
        child: SizedBox(
          width: 720,
          height: 420,
          child: Stack(
            children: [
              MemberProfilePopoverOverlay(
                member: avery.copyWith(
                  role: 'Member',
                  displayColor: const Color(0xff22c55e),
                  nameColorName: 'Mint',
                ),
                mediaPolicy: mediaPolicy,
                anchorRect: const Rect.fromLTWH(80, 24, 48, 48),
                side: MemberProfilePopoverSide.right,
                onDismiss: () {},
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Member'), findsOneWidget);
    expect(find.text('Name Color'), findsOneWidget);
    expect(find.text('Mint'), findsOneWidget);
  });

  testWidgets('profile popover clamps inside the visible client bounds', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            key: const ValueKey('profile-clamp-client'),
            width: 360,
            height: 340,
            child: Stack(
              children: [
                MemberProfilePopoverOverlay(
                  member: avery,
                  mediaPolicy: mediaPolicy,
                  anchorRect: const Rect.fromLTWH(314, 220, 42, 42),
                  side: MemberProfilePopoverSide.right,
                  viewportRect: const Rect.fromLTWH(0, 0, 360, 340),
                  onDismiss: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final popover = find.byKey(
      const ValueKey('member-profile-popover-official/user-avery'),
    );
    expect(popover, findsOneWidget);
    final clientRect = tester.getRect(
      find.byKey(const ValueKey('profile-clamp-client')),
    );
    final rect = tester.getRect(popover);
    expect(rect.left, greaterThanOrEqualTo(clientRect.left + 8));
    expect(rect.top, greaterThanOrEqualTo(clientRect.top + 8));
    expect(rect.right, lessThanOrEqualTo(clientRect.right));
    expect(rect.bottom, lessThanOrEqualTo(clientRect.bottom));
  });

  testWidgets('profile popover uses media skeletons while images are pending', (
    tester,
  ) async {
    final mediaLoad = Completer<Uint8List>();
    debugSetServerMediaWidgetLoader((_, {required policy, maxBytes}) {
      return mediaLoad.future;
    });

    await tester.pumpWidget(
      _Harness(
        child: SizedBox(
          width: 720,
          height: 420,
          child: Stack(
            children: [
              MemberProfilePopoverOverlay(
                member: avery,
                mediaPolicy: mediaPolicy,
                anchorRect: const Rect.fromLTWH(80, 24, 48, 48),
                side: MemberProfilePopoverSide.right,
                onDismiss: () {},
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(
        const ValueKey('member-profile-banner-loading-official/user-avery'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('member-profile-avatar-loading-official/user-avery'),
      ),
      findsOneWidget,
    );
    expect(find.text('AV'), findsNothing);

    mediaLoad.complete(Uint8List.fromList(_transparentPngBytes));
    await tester.pumpAndSettle();

    expect(
      find.byKey(
        const ValueKey('member-profile-banner-image-official/user-avery'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('member-profile-avatar-image-official/user-avery'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('profile popover plays and crops media while open', (
    tester,
  ) async {
    final animatedMember = avery.copyWith(
      avatarUrl: '$officialApiOrigin/media/avatars/avery.webp',
      bannerUrl: '$officialApiOrigin/media/banners/avery.webp',
    );

    await tester.pumpWidget(
      _Harness(
        child: SizedBox(
          width: 720,
          height: 420,
          child: Stack(
            children: [
              MemberProfilePopoverOverlay(
                member: animatedMember,
                mediaPolicy: mediaPolicy,
                anchorRect: const Rect.fromLTWH(80, 24, 48, 48),
                side: MemberProfilePopoverSide.right,
                onDismiss: () {},
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(
        const ValueKey('member-profile-banner-image-official/user-avery'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey(
          'member-profile-banner-image-static-official/user-avery',
        ),
      ),
      findsNothing,
    );
    expect(
      find.byKey(
        const ValueKey('member-profile-avatar-image-official/user-avery'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey(
          'member-profile-avatar-image-static-official/user-avery',
        ),
      ),
      findsNothing,
    );
  });

  testWidgets(
    'chat author webp avatar renders before hover as a static image',
    (tester) async {
      final animatedMember = avery.copyWith(
        avatarUrl: '$officialApiOrigin/media/avatars/avery.webp',
        bannerUrl: '$officialApiOrigin/media/banners/avery.webp',
      );

      await tester.pumpWidget(
        _Harness(
          child: SizedBox(
            width: 720,
            height: 360,
            child: MessageTimeline(
              networkId: 'official',
              messages: [_messageFrom(animatedMember)],
              members: [animatedMember],
              mediaPolicy: mediaPolicy,
              stickToBottom: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey('message-avatar-image-static-official/user-avery'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('chat author avatar avoids initials while known media loads', (
    tester,
  ) async {
    final mediaLoad = Completer<Uint8List>();
    debugSetServerMediaWidgetLoader((_, {required policy, maxBytes}) {
      return mediaLoad.future;
    });

    await tester.pumpWidget(
      _Harness(
        child: SizedBox(
          width: 720,
          height: 360,
          child: MessageTimeline(
            networkId: 'official',
            messages: [_messageFrom(avery)],
            members: [avery],
            mediaPolicy: mediaPolicy,
            stickToBottom: false,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('AV'), findsNothing);

    mediaLoad.complete(Uint8List.fromList(_transparentPngBytes));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('message-avatar-image-official/user-avery')),
      findsOneWidget,
    );
  });

  testWidgets('cached chat author avatar remounts without initials frame', (
    tester,
  ) async {
    var loadCount = 0;
    debugSetServerMediaWidgetLoader((_, {required policy, maxBytes}) async {
      loadCount += 1;
      return Uint8List.fromList(_transparentPngBytes);
    });

    Widget timelineWithKey(String key) {
      return _Harness(
        child: SizedBox(
          key: ValueKey(key),
          width: 720,
          height: 360,
          child: MessageTimeline(
            networkId: 'official',
            messages: [_messageFrom(avery)],
            members: [avery],
            mediaPolicy: mediaPolicy,
            stickToBottom: false,
          ),
        ),
      );
    }

    await tester.pumpWidget(timelineWithKey('first-mount'));
    await tester.pumpAndSettle();

    expect(loadCount, 1);
    expect(
      find.byKey(const ValueKey('message-avatar-image-official/user-avery')),
      findsOneWidget,
    );

    await tester.pumpWidget(timelineWithKey('second-mount'));
    await tester.pump();

    expect(loadCount, 1);
    expect(find.text('AV'), findsNothing);
    expect(
      find.byKey(const ValueKey('message-avatar-image-official/user-avery')),
      findsOneWidget,
    );
  });

  testWidgets('chat author profiles ignore duplicate display names', (
    tester,
  ) async {
    final victim = avery.copyWith(
      id: 'official/user-victim',
      name: 'Avery',
      status: 'Online',
      avatarUrl: '$officialApiOrigin/media/avatars/victim.png',
      bannerUrl: '$officialApiOrigin/media/banners/victim.png',
    );
    final sender = avery.copyWith(
      id: 'official/user-sender',
      name: 'Avery',
      status: 'Idle',
      avatarUrl: '$officialApiOrigin/media/avatars/sender.png',
      bannerUrl: '$officialApiOrigin/media/banners/sender.png',
      displayColor: const Color(0xffffd166),
    );

    await tester.pumpWidget(
      _Harness(
        child: SizedBox(
          width: 720,
          height: 360,
          child: MessageTimeline(
            networkId: 'official',
            messages: [
              MessageSeed(
                id: 'official/message-duplicate-name',
                authorId: 'user-sender',
                author: 'Avery',
                initials: 'AV',
                authorColor: sender.displayColor,
                avatarUrl: sender.avatarUrl,
                time: 'now',
                body: 'Name collision',
              ),
            ],
            members: [victim, sender],
            mediaPolicy: mediaPolicy,
            stickToBottom: false,
          ),
        ),
      ),
    );

    final avatar = find.byKey(
      const ValueKey('message-avatar-official/user-sender'),
    );
    await tester.tap(avatar);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 180));

    expect(
      find.byKey(const ValueKey('member-profile-popover-official/user-sender')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('member-profile-popover-official/user-victim')),
      findsNothing,
    );
  });
}

MessageSeed _messageFrom(MemberSeed member) {
  return MessageSeed(
    id: 'official/message-actions',
    authorId: member.id!,
    author: member.name,
    initials: member.initials,
    authorColor: member.displayColor,
    avatarUrl: member.avatarUrl,
    time: 'now',
    body: 'Hover me',
    reactions: const [],
  );
}

class _Harness extends StatelessWidget {
  const _Harness({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: buildVerdantTheme(),
      home: Scaffold(body: Center(child: child)),
    );
  }
}

Color? _containerColor(WidgetTester tester, Finder finder) {
  final widget = tester.widget<AnimatedContainer>(finder);
  final decoration = widget.decoration;
  return decoration is BoxDecoration ? decoration.color : null;
}

Color? _containerBorderColor(WidgetTester tester, Finder finder) {
  final widget = tester.widget<AnimatedContainer>(finder);
  final decoration = widget.decoration;
  final border = decoration is BoxDecoration ? decoration.border : null;
  return border is Border ? border.top.color : null;
}

Color? _decoratedBoxColor(WidgetTester tester, Finder finder) {
  final widget = tester.widget<ClipRRect>(finder);
  final child = widget.child;
  if (child is DecoratedBox) {
    final decoration = child.decoration;
    return decoration is BoxDecoration ? decoration.color : null;
  }
  return null;
}

const _transparentPngBytes = <int>[
  0x89,
  0x50,
  0x4e,
  0x47,
  0x0d,
  0x0a,
  0x1a,
  0x0a,
  0x00,
  0x00,
  0x00,
  0x0d,
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
  0x1f,
  0x15,
  0xc4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0a,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9c,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0d,
  0x0a,
  0x2d,
  0xb4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4e,
  0x44,
  0xae,
  0x42,
  0x60,
  0x82,
];
