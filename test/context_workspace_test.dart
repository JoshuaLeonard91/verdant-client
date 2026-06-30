import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verdant_flutter/features/workspace/context_workspace/context_workspace.dart';
import 'package:verdant_flutter/features/workspace/server_settings_workspace/server_media_image.dart';
import 'package:verdant_flutter/features/workspace/server_settings_workspace/server_media_url_policy.dart';
import 'package:verdant_flutter/features/workspace/server_settings_workspace/server_settings_models.dart';
import 'package:verdant_flutter/features/workspace/shared/member_profile_popover.dart';
import 'package:verdant_flutter/features/workspace/workspace_seed.dart';
import 'package:verdant_flutter/theme/verdant_theme.dart';

void main() {
  tearDown(() {
    debugSetServerMediaWidgetLoader(null);
  });

  testWidgets('context workspace toggles active and all member lists', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerdantTheme(),
        home: const Scaffold(
          body: ContextWorkspace(
            width: 320,
            activeMembers: [
              MemberSeed(
                id: 'official/user-avery',
                name: 'Avery',
                status: 'Online',
                initials: 'AV',
                role: 'Admin',
                displayColor: Color(0xFF7CFFDE),
              ),
            ],
            members: [
              MemberSeed(
                id: 'official/user-avery',
                name: 'Avery',
                status: 'Online',
                initials: 'AV',
                role: 'Admin',
                displayColor: Color(0xFF7CFFDE),
              ),
              MemberSeed(
                id: 'official/user-morgan',
                name: 'Morgan',
                status: 'Offline',
                initials: 'MO',
                role: 'Member',
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Active in this channel'), findsOneWidget);
    expect(find.text('Avery'), findsOneWidget);
    expect(find.text('Morgan'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('context-members-toggle')));
    await tester.pumpAndSettle();

    expect(find.text('All members'), findsOneWidget);
    expect(find.text('Avery'), findsOneWidget);
    expect(find.text('Morgan'), findsOneWidget);
    expect(find.text('Admin - 1'), findsOneWidget);
  });

  testWidgets('explicit active member list still filters inactive rows', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerdantTheme(),
        home: const Scaffold(
          body: ContextWorkspace(
            width: 320,
            activeMembers: [
              MemberSeed(
                id: 'official/user-avery',
                name: 'Avery',
                status: 'Online',
                initials: 'AV',
                isActive: false,
              ),
              MemberSeed(
                id: 'official/user-riley',
                name: 'Riley',
                status: 'Online',
                initials: 'RI',
              ),
              MemberSeed(
                id: 'official/user-morgan',
                name: 'Morgan',
                status: 'Offline',
                initials: 'MO',
              ),
            ],
            members: [
              MemberSeed(
                id: 'official/user-avery',
                name: 'Avery',
                status: 'Online',
                initials: 'AV',
                isActive: false,
              ),
              MemberSeed(
                id: 'official/user-riley',
                name: 'Riley',
                status: 'Online',
                initials: 'RI',
              ),
              MemberSeed(
                id: 'official/user-morgan',
                name: 'Morgan',
                status: 'Offline',
                initials: 'MO',
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Riley'), findsOneWidget);
    expect(find.text('Avery'), findsNothing);
    expect(find.text('Morgan'), findsNothing);
  });

  testWidgets(
    'explicit active member list does not pull active bots from all members',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildVerdantTheme(),
          home: const Scaffold(
            body: ContextWorkspace(
              width: 320,
              activeMembers: [
                MemberSeed(
                  id: 'official/user-joshy',
                  name: 'Joshy',
                  status: 'Online',
                  initials: 'JO',
                  isActive: true,
                ),
              ],
              members: [
                MemberSeed(
                  id: 'official/user-joshy',
                  name: 'Joshy',
                  status: 'Online',
                  initials: 'JO',
                  isActive: true,
                ),
                MemberSeed(
                  id: 'official/bot-verdant',
                  name: 'Verdant Bot',
                  status: 'Online',
                  initials: 'VB',
                  role: 'Bot',
                  isBot: true,
                  isActive: true,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Joshy'), findsOneWidget);
      expect(find.text('Verdant Bot'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('context-members-toggle')));
      await tester.pumpAndSettle();

      expect(find.text('Joshy'), findsOneWidget);
      expect(find.text('Verdant Bot'), findsOneWidget);
      expect(
        find.byKey(
          const ValueKey('context-member-bot-pill-official/bot-verdant'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('member list media loads only when rows enter the viewport', (
    tester,
  ) async {
    final requestedPaths = <String>[];
    debugSetServerMediaWidgetLoader((uri, {required policy, maxBytes}) async {
      requestedPaths.add(uri.path);
      return Uint8List.fromList(_onePixelPng);
    });

    final members = List.generate(24, (index) {
      return MemberSeed(
        id: 'official/user-$index',
        name: 'User $index',
        status: 'Online',
        initials: 'U$index',
        avatarUrl: 'https://media.verdant.chat/avatars/user-$index.webp',
        memberListBannerUrl:
            'https://media.verdant.chat/member-list-banners/user-$index.webp',
      );
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerdantTheme(),
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 190,
            child: ContextWorkspace(
              width: 320,
              members: members,
              mediaPolicy: const ServerMediaPolicy(
                allowedOrigins: {'https://media.verdant.chat'},
                allowLocalHttp: false,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(requestedPaths.any((path) => path.contains('user-20')), isFalse);

    await tester.scrollUntilVisible(
      find.text('User 20'),
      260,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('context-active-members-list')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(requestedPaths.any((path) => path.contains('user-20')), isTrue);
  });

  testWidgets('member rows expose right-click context menu access', (
    tester,
  ) async {
    String? openedMemberId;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerdantTheme(),
        home: Scaffold(
          body: ContextWorkspace(
            width: 320,
            onOpenMemberContextMenu: (member, position) {
              openedMemberId = member.id;
            },
            members: const [
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
    );

    final row = find.byKey(
      const ValueKey('context-member-row-official/user-avery'),
    );
    final gesture = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    addTearDown(gesture.removePointer);
    await gesture.down(tester.getCenter(row));
    await gesture.up();
    await tester.pump();

    expect(openedMemberId, 'official/user-avery');
  });

  testWidgets(
    'member-list animated banner uses cropped static first-frame renderer',
    (tester) async {
      debugSetServerMediaWidgetLoader((uri, {required policy, maxBytes}) async {
        return Uint8List.fromList(_onePixelPng);
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: buildVerdantTheme(),
          home: const Scaffold(
            body: SizedBox(
              key: ValueKey('member-list-banner-test-surface'),
              width: 284,
              height: 56,
              child: MemberMediaBanner(
                mediaPolicy: ServerMediaPolicy(
                  allowedOrigins: {'https://media.verdant.chat'},
                  allowLocalHttp: false,
                ),
                playAnimatedMedia: false,
                imageKeyPrefix: 'context-member-banner-image',
                bannerUrlOverride:
                    'https://media.verdant.chat/member-list-banners/avery.webp',
                bannerCropOverride: BannerCrop(
                  x: 25,
                  y: 10,
                  width: 50,
                  height: 40,
                ),
                member: MemberSeed(
                  id: 'official/user-avery',
                  name: 'Avery',
                  status: 'Online',
                  initials: 'AV',
                  role: 'Admin',
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(CroppedStaticFirstFrameBannerImage), findsOneWidget);
      expect(find.byType(StaticFirstFrameImage), findsNothing);
    },
  );

  testWidgets('cropped static first-frame banner applies crop geometry', (
    tester,
  ) async {
    final image = await _createTestImage();
    addTearDown(image.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerdantTheme(),
        home: Scaffold(
          body: SizedBox(
            key: const ValueKey('member-list-banner-test-surface'),
            width: 284,
            height: 56,
            child: CroppedStaticFirstFrameBannerImage(
              key: const ValueKey(
                'context-member-banner-image-static-official/user-avery',
              ),
              imageProvider: _SynchronousImageProvider(image),
              crop: const BannerCrop(x: 25, y: 10, width: 50, height: 40),
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    final banner = tester.getRect(
      find.byKey(const ValueKey('member-list-banner-test-surface')),
    );
    final staticBanner = find.byKey(
      const ValueKey('context-member-banner-image-static-official/user-avery'),
    );
    expect(staticBanner, findsOneWidget);
    final renderedImage = tester.getRect(
      find.descendant(of: staticBanner, matching: find.byType(RawImage)),
    );

    expect(renderedImage.width, greaterThan(banner.width * 1.9));
    expect(renderedImage.height, greaterThan(banner.height * 2.4));
    expect(renderedImage.left, lessThan(banner.left));
    expect(renderedImage.top, lessThan(banner.top));
  });
}

Future<ui.Image> _createTestImage() {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, 4, 4),
    Paint()..color = const Color(0xFF00FFAA),
  );
  return recorder.endRecording().toImage(4, 4);
}

final class _SynchronousImageProvider
    extends ImageProvider<_SynchronousImageProvider> {
  const _SynchronousImageProvider(this.image);

  final ui.Image image;

  @override
  Future<_SynchronousImageProvider> obtainKey(
    ImageConfiguration configuration,
  ) {
    return SynchronousFuture<_SynchronousImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadImage(
    _SynchronousImageProvider key,
    ImageDecoderCallback decode,
  ) {
    return OneFrameImageStreamCompleter(
      SynchronousFuture<ImageInfo>(ImageInfo(image: image)),
    );
  }
}

const _onePixelPng = <int>[
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
