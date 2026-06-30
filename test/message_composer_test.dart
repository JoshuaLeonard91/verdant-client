import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:verdant_flutter/features/auth/auth_models.dart';
import 'package:verdant_flutter/features/workspace/chat_workspace/emoji_picker_popover.dart';
import 'package:verdant_flutter/features/workspace/chat_workspace/klipy_media_picker.dart';
import 'package:verdant_flutter/features/workspace/chat_workspace/klipy_media_repository.dart';
import 'package:verdant_flutter/features/workspace/chat_workspace/message_composer.dart';
import 'package:verdant_flutter/features/workspace/server_settings_workspace/server_media_image.dart';
import 'package:verdant_flutter/features/workspace/server_settings_workspace/server_media_url_policy.dart';
import 'package:verdant_flutter/features/workspace/shared/custom_expressive_asset.dart';
import 'package:verdant_flutter/features/workspace/workspace_seed.dart';
import 'package:verdant_flutter/theme/verdant_theme.dart';

void main() {
  tearDown(() {
    debugSetServerMediaWidgetLoader(null);
  });

  testWidgets('pressing Enter sends the composer message', (tester) async {
    final sent = <String>[];
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      _TestShell(child: MessageComposer(onSubmit: sent.add)),
    );

    await tester.tap(find.byKey(const ValueKey('composer-message-field')));
    await tester.enterText(
      find.byKey(const ValueKey('composer-message-field')),
      'hello',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(sent, ['hello']);
    expect(find.text('hello'), findsNothing);
  });

  testWidgets('composer keeps multiline draft text before send', (
    tester,
  ) async {
    final sent = <String>[];
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      _TestShell(child: MessageComposer(onSubmit: sent.add)),
    );

    await tester.enterText(
      find.byKey(const ValueKey('composer-message-field')),
      'hello\nthere',
    );
    await tester.pump();

    expect(sent, isEmpty);
    expect(find.textContaining('hello'), findsOneWidget);
  });

  testWidgets('composer emits typing only for non-empty drafts', (
    tester,
  ) async {
    var typingCount = 0;
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      _TestShell(child: MessageComposer(onTyping: () => typingCount += 1)),
    );

    final field = find.byKey(const ValueKey('composer-message-field'));
    await tester.enterText(field, '   ');
    await tester.pump();
    await tester.enterText(field, 'hello');
    await tester.pump();

    expect(typingCount, 1);
  });

  testWidgets('composer text field stays borderless inside framed composer', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      const _TestShell(
        themeMode: VerdantThemeMode.light,
        child: MessageComposer(),
      ),
    );

    final field = tester.widget<TextField>(
      find.byKey(const ValueKey('composer-message-field')),
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
  });

  testWidgets('composer text lane has a tall click target', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const _TestShell(child: MessageComposer()));

    final hitTarget = find.byKey(const ValueKey('composer-message-hit-target'));
    final field = find.byKey(const ValueKey('composer-message-field'));

    expect(
      tester.getSize(hitTarget).height,
      greaterThan(tester.getSize(field).height),
    );

    final targetRect = tester.getTopLeft(hitTarget) & tester.getSize(hitTarget);
    await tester.tapAt(targetRect.topLeft + const Offset(8, 4));
    await tester.pump();

    expect(tester.testTextInput.hasAnyClients, isTrue);

    await tester.tapAt(targetRect.bottomLeft + const Offset(8, -4));
    await tester.pump();

    expect(tester.testTextInput.hasAnyClients, isTrue);
  });

  testWidgets('emoji picker inserts into the composer and can send', (
    tester,
  ) async {
    final sent = <String>[];
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      _TestShell(
        child: MessageComposer(
          onSubmit: sent.add,
          mediaPolicy: ServerMediaPolicy.fromOrigins(
            apiOrigin: officialApiOrigin,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('composer-emoji-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byKey(const ValueKey('emoji-picker-popover')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('emoji-picker-category-rail')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('emoji-picker-item-smileys-0')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('emoji-picker-item-smileys-0')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('composer-send-button')));
    await tester.pump();

    expect(sent.single, isNotEmpty);
    expect(find.byKey(const ValueKey('emoji-picker-popover')), findsNothing);
  });

  testWidgets('emoji picker inserts server custom emoji shortcodes', (
    tester,
  ) async {
    final sent = <String>[];
    SharedPreferences.setMockInitialValues({});
    debugSetServerMediaWidgetLoader((uri, {required policy, maxBytes}) async {
      return Uint8List.fromList(_pngBytes);
    });

    await tester.pumpWidget(
      _TestShell(
        child: MessageComposer(
          onSubmit: sent.add,
          mediaPolicy: ServerMediaPolicy.fromOrigins(
            apiOrigin: officialApiOrigin,
          ),
          customEmojis: const [
            ServerCustomEmoji(
              id: 'emoji-1',
              name: 'verdant',
              imageUrl: 'https://cdn.pryzmapp.com/emojis/emoji-1.webp',
              networkId: 'origin:https%3A%2F%2Fapi.verdant.chat',
              serverId: 'server-1',
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('composer-emoji-button')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(
        const ValueKey(
          'emoji-picker-category-server-custom_origin_https_3A_2F_2Fapi_verdant_chat_server-1',
        ),
      ),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('emoji-picker-custom-item-emoji-1')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('composer-send-button')));
    await tester.pump();

    expect(sent, [':verdant:']);
  });

  testWidgets('emoji picker inserts server sticker shortcodes', (tester) async {
    final sent = <String>[];
    SharedPreferences.setMockInitialValues({});
    debugSetServerMediaWidgetLoader((uri, {required policy, maxBytes}) async {
      return Uint8List.fromList(_pngBytes);
    });

    await tester.pumpWidget(
      _TestShell(
        child: MessageComposer(
          onSubmit: sent.add,
          mediaPolicy: ServerMediaPolicy.fromOrigins(
            apiOrigin: officialApiOrigin,
          ),
          customStickers: const [
            ServerCustomSticker(
              id: 'sticker-1',
              name: 'smokoko',
              imageUrl: 'https://cdn.pryzmapp.com/stickers/sticker-1.webp',
              networkId: 'origin:https%3A%2F%2Fapi.verdant.chat',
              serverId: 'server-1',
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('composer-emoji-button')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('emoji-picker-tab-emoji')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('emoji-picker-tab-stickers')),
      findsOneWidget,
    );
    expect(find.text('Server stickers'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('emoji-picker-tab-stickers')));
    await tester.pumpAndSettle();

    expect(find.text('Server stickers'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('emoji-picker-custom-sticker-sticker-1')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('composer-send-button')));
    await tester.pump();

    expect(sent, [':smokoko:']);
  });

  testWidgets(
    'emoji picker limits custom emoji groups to active server route',
    (tester) async {
      final sent = <String>[];
      final requestedUris = <Uri>[];
      const homeNetworkId = 'origin:https%3A%2F%2Fapi.verdant.chat';
      const fedNetworkId = 'origin:https%3A%2F%2Fapi-test.pryzmapp.com';
      SharedPreferences.setMockInitialValues({});
      debugSetServerMediaWidgetLoader((uri, {required policy, maxBytes}) async {
        requestedUris.add(uri);
        return Uint8List.fromList(_pngBytes);
      });

      await tester.pumpWidget(
        _TestShell(
          child: MessageComposer(
            networkId: homeNetworkId,
            serverId: 'server-home',
            onSubmit: sent.add,
            mediaPolicy: ServerMediaPolicy.fromOrigins(
              apiOrigin: officialApiOrigin,
            ),
            customEmojiGroups: const [
              ServerCustomEmojiGroup(
                serverId: 'server-home',
                networkId: homeNetworkId,
                label: 'Verdant',
                emojis: [
                  ServerCustomEmoji(
                    id: 'emoji-home',
                    name: 'homewave',
                    imageUrl: 'https://cdn.pryzmapp.com/emojis/homewave.webp',
                    networkId: homeNetworkId,
                    serverId: 'server-home',
                  ),
                ],
              ),
              ServerCustomEmojiGroup(
                serverId: 'server-fed',
                networkId: fedNetworkId,
                label: 'Self Host',
                mediaPolicy: ServerMediaPolicy(
                  allowedOrigins: {'https://fed-cdn.example.com'},
                  allowLocalHttp: false,
                ),
                emojis: [
                  ServerCustomEmoji(
                    id: 'emoji-fed',
                    name: 'fedbonk',
                    imageUrl: 'https://fed-cdn.example.com/emojis/fedbonk.gif',
                    networkId: fedNetworkId,
                    serverId: 'server-fed',
                    animated: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('composer-emoji-button')));
      await tester.pumpAndSettle();

      expect(find.text('Verdant'), findsOneWidget);
      expect(find.text('Self Host'), findsNothing);
      expect(
        requestedUris.map((uri) => '${uri.scheme}://${uri.host}'),
        isNot(contains('https://fed-cdn.example.com')),
      );

      await tester.tap(
        find.byKey(const ValueKey('emoji-picker-custom-item-emoji-home')),
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('composer-send-button')));
      await tester.pump();

      expect(sent, [':homewave:']);
    },
  );

  testWidgets('emoji picker rail shows server icons for custom sections', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      final selected = <String>[];
      const homeNetworkId = 'origin:https%3A%2F%2Fapi.verdant.chat';
      const fedNetworkId = 'origin:https%3A%2F%2Fapi-test.pryzmapp.com';
      SharedPreferences.setMockInitialValues({});
      debugSetServerMediaWidgetLoader((uri, {required policy, maxBytes}) async {
        return Uint8List.fromList(_pngBytes);
      });

      await tester.pumpWidget(
        _TestShell(
          child: EmojiPickerPopover(
            onSelected: selected.add,
            mediaPolicy: ServerMediaPolicy.fromOrigins(
              apiOrigin: officialApiOrigin,
            ),
            customEmojiGroups: [
              ServerCustomEmojiGroup(
                serverId: 'server-home',
                networkId: homeNetworkId,
                label: 'Verdant',
                iconUrl: 'https://cdn.pryzmapp.com/server-icons/home.webp',
                emojis: [
                  for (var index = 0; index < 42; index += 1)
                    ServerCustomEmoji(
                      id: 'home-$index',
                      name: 'home_$index',
                      imageUrl:
                          'https://cdn.pryzmapp.com/emojis/home-$index.webp',
                      networkId: homeNetworkId,
                      serverId: 'server-home',
                    ),
                ],
              ),
              const ServerCustomEmojiGroup(
                serverId: 'server-fed',
                networkId: fedNetworkId,
                label: 'Self Host',
                iconUrl: 'https://cdn.pryzmapp.com/server-icons/fed.webp',
                emojis: [
                  ServerCustomEmoji(
                    id: 'fed-1',
                    name: 'fed_wave',
                    imageUrl: 'https://cdn.pryzmapp.com/emojis/fed-1.webp',
                    networkId: fedNetworkId,
                    serverId: 'server-fed',
                  ),
                ],
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      const homeRailKey = ValueKey(
        'emoji-picker-category-server-custom_origin_https_3A_2F_2Fapi_verdant_chat_server-home',
      );
      const fedRailKey = ValueKey(
        'emoji-picker-category-server-custom_origin_https_3A_2F_2Fapi-test_pryzmapp_com_server-fed',
      );
      expect(find.byKey(homeRailKey), findsOneWidget);
      expect(find.byKey(fedRailKey), findsOneWidget);
      expect(
        tester.getSemantics(find.byKey(homeRailKey)).flagsCollection.isSelected,
        Tristate.isTrue,
      );

      await tester.dragUntilVisible(
        find.text('Self Host'),
        find.byKey(const ValueKey('emoji-picker-grid-sections')),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();

      expect(
        tester.getSemantics(find.byKey(fedRailKey)).flagsCollection.isSelected,
        Tristate.isTrue,
      );
    } finally {
      semantics.dispose();
    }
  });

  testWidgets(
    'composer suggests active-network member mentions with usernames',
    (tester) async {
      const officialNetworkId = 'origin:https%3A%2F%2Fapi.verdant.chat';
      const selfHostNetworkId = 'origin:https%3A%2F%2Fapi-test.pryzmapp.com';
      final sent = <String>[];
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        _TestShell(
          child: MessageComposer(
            networkId: officialNetworkId,
            mentionMembers: const [
              MemberSeed(
                id: '$selfHostNetworkId/user-joshy',
                name: 'Self-host Josh',
                username: 'joshy',
                status: 'Online',
                initials: 'SJ',
              ),
              MemberSeed(
                id: '$officialNetworkId/user-joshy',
                name: 'Josh Display',
                username: 'joshy',
                status: 'Online',
                initials: 'JD',
              ),
            ],
            onSubmit: sent.add,
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const ValueKey('composer-message-field')),
        'ship @Josh',
      );
      await tester.pump();

      expect(
        find.byKey(const ValueKey('composer-mention-suggestions')),
        findsOneWidget,
      );
      expect(find.text('Josh Display'), findsOneWidget);
      expect(find.text('@joshy'), findsOneWidget);
      expect(find.text('Self-host Josh'), findsNothing);

      await tester.tap(
        find.byKey(const ValueKey('composer-mention-suggestion-user-joshy')),
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('composer-send-button')));
      await tester.pump();

      expect(sent, ['ship @user-joshy']);
    },
  );

  testWidgets('emoji picker rail follows clicked and scrolled sections', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        _TestShell(
          child: MessageComposer(
            mediaPolicy: ServerMediaPolicy.fromOrigins(
              apiOrigin: officialApiOrigin,
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('composer-emoji-button')));
      await tester.pumpAndSettle();

      expect(
        tester
            .getSemantics(
              find.byKey(const ValueKey('emoji-picker-category-smileys')),
            )
            .flagsCollection
            .isSelected,
        Tristate.isTrue,
      );
      expect(
        find.byKey(const ValueKey('emoji-picker-category-selected-Smileys')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('emoji-picker-category-objects')),
      );
      await tester.pump(const Duration(milliseconds: 160));
      expect(
        tester
            .getSemantics(
              find.byKey(const ValueKey('emoji-picker-category-objects')),
            )
            .flagsCollection
            .isSelected,
        Tristate.isTrue,
      );
      expect(
        find.byKey(const ValueKey('emoji-picker-category-selected-Objects')),
        findsOneWidget,
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('emoji-picker-category-animals')),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .getSemantics(
              find.byKey(const ValueKey('emoji-picker-category-animals')),
            )
            .flagsCollection
            .isSelected,
        Tristate.isTrue,
      );

      await tester.dragUntilVisible(
        find.byKey(const ValueKey('emoji-picker-item-activities-0')),
        find.byKey(const ValueKey('emoji-picker-grid-sections')),
        const Offset(0, -380),
      );
      await tester.pumpAndSettle();

      expect(
        tester
            .getSemantics(
              find.byKey(const ValueKey('emoji-picker-category-activities')),
            )
            .flagsCollection
            .isSelected,
        Tristate.isTrue,
      );
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('klipy picker sends the selected media URL', (tester) async {
    final sent = <String>[];
    SharedPreferences.setMockInitialValues({});
    debugSetServerMediaWidgetLoader((uri, {required policy, maxBytes}) async {
      return Uint8List.fromList(_pngBytes);
    });

    await tester.pumpWidget(
      _TestShell(
        child: MessageComposer(
          onSubmit: sent.add,
          klipyRepository: const SeededKlipyMediaRepository(),
          mediaPolicy: ServerMediaPolicy.fromOrigins(
            apiOrigin: officialApiOrigin,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('composer-klipy-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('klipy-picker-popover')), findsOneWidget);
    expect(find.byKey(const ValueKey('klipy-picker-tab-gif')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('klipy-picker-category-reactions')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('klipy-picker-category-reactions')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('klipy-picker-item-gif-verdant-spark')),
    );
    await tester.pumpAndSettle();

    expect(sent.single, startsWith('https://static.klipy.com/'));
    expect(find.byKey(const ValueKey('klipy-picker-popover')), findsNothing);
  });

  testWidgets('klipy picker can save favorites on the current media type', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    debugSetServerMediaWidgetLoader((uri, {required policy, maxBytes}) async {
      return Uint8List.fromList(_pngBytes);
    });

    await tester.pumpWidget(
      _TestShell(
        child: MessageComposer(
          klipyRepository: const SeededKlipyMediaRepository(),
          mediaPolicy: ServerMediaPolicy.fromOrigins(
            apiOrigin: officialApiOrigin,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('composer-klipy-button')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('klipy-picker-category-reactions')),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('klipy-picker-favorite-button')).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('klipy-picker-back-button')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('klipy-picker-favorites-gif')),
      findsOneWidget,
    );
  });

  testWidgets('klipy picker ignores stale home loads after type changes', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    debugSetServerMediaWidgetLoader((uri, {required policy, maxBytes}) async {
      return Uint8List.fromList(_pngBytes);
    });
    final repository = _ControlledKlipyMediaRepository();

    await tester.pumpWidget(
      _TestShell(
        child: KlipyMediaPicker(
          repository: repository,
          mediaPolicy: ServerMediaPolicy.fromOrigins(
            apiOrigin: officialApiOrigin,
          ),
          onSelected: (_) {},
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('klipy-picker-tab-sticker')));
    await tester.pump();

    repository.completeHome(KlipyMediaType.sticker, const [
      KlipyMediaCategory(
        name: 'Sticker Set',
        slug: 'sticker-set',
        imageUrl: null,
      ),
    ]);
    await tester.pump();
    await tester.pump();

    expect(
      find.byKey(const ValueKey('klipy-picker-category-sticker-set')),
      findsOneWidget,
    );

    repository.completeHome(KlipyMediaType.gif, const [
      KlipyMediaCategory(name: 'Old GIFs', slug: 'old-gifs', imageUrl: null),
    ]);
    await tester.pump();
    await tester.pump();

    expect(
      find.byKey(const ValueKey('klipy-picker-category-sticker-set')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('klipy-picker-category-old-gifs')),
      findsNothing,
    );
  });

  testWidgets('klipy picker surfaces sanitized backend errors', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      _TestShell(
        child: KlipyMediaPicker(
          repository: const _FailingKlipyMediaRepository(
            'Sign in again to use Klipy',
          ),
          mediaPolicy: ServerMediaPolicy.fromOrigins(
            apiOrigin: officialApiOrigin,
          ),
          onSelected: (_) {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const ValueKey('klipy-picker-error')), findsOneWidget);
    expect(find.text('Sign in again to use Klipy'), findsOneWidget);
    expect(find.text('Could not load Klipy media'), findsNothing);
  });
}

final class _ControlledKlipyMediaRepository implements KlipyMediaRepository {
  final _categoryRequests =
      <KlipyMediaType, List<Completer<List<KlipyMediaCategory>>>>{};
  final _previewRequests = <KlipyMediaType, List<Completer<String?>>>{};

  @override
  Future<KlipyMediaResult> load({
    required KlipyMediaType type,
    String query = '',
    int page = 1,
  }) async {
    return const KlipyMediaResult(items: []);
  }

  @override
  Future<List<KlipyMediaCategory>> loadCategories({
    required KlipyMediaType type,
  }) {
    final completer = Completer<List<KlipyMediaCategory>>();
    _categoryRequests.putIfAbsent(type, () => []).add(completer);
    return completer.future;
  }

  @override
  Future<String?> loadTrendingPreview({required KlipyMediaType type}) {
    final completer = Completer<String?>();
    _previewRequests.putIfAbsent(type, () => []).add(completer);
    return completer.future;
  }

  void completeHome(KlipyMediaType type, List<KlipyMediaCategory> categories) {
    final categoryCompleter = _categoryRequests[type]?.removeAt(0);
    final previewCompleter = _previewRequests[type]?.removeAt(0);
    categoryCompleter?.complete(categories);
    previewCompleter?.complete(null);
  }
}

final class _FailingKlipyMediaRepository implements KlipyMediaRepository {
  const _FailingKlipyMediaRepository(this.message);

  final String message;

  @override
  Future<KlipyMediaResult> load({
    required KlipyMediaType type,
    String query = '',
    int page = 1,
  }) async {
    throw KlipyMediaException(message);
  }

  @override
  Future<List<KlipyMediaCategory>> loadCategories({
    required KlipyMediaType type,
  }) async {
    throw KlipyMediaException(message);
  }

  @override
  Future<String?> loadTrendingPreview({required KlipyMediaType type}) async {
    throw KlipyMediaException(message);
  }
}

class _TestShell extends StatelessWidget {
  const _TestShell({
    required this.child,
    this.themeMode = VerdantThemeMode.dark,
  });

  final Widget child;
  final VerdantThemeMode themeMode;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: buildVerdantTheme(mode: themeMode),
      home: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(width: 720, child: child),
        ),
      ),
    );
  }
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
