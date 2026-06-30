import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verdant_flutter/features/workspace/server_settings_workspace/server_settings_bots_tab.dart';
import 'package:verdant_flutter/features/workspace/server_settings_workspace/server_settings_models.dart';
import 'package:verdant_flutter/features/workspace/server_settings_workspace/server_settings_service.dart';
import 'package:verdant_flutter/theme/verdant_theme.dart';

void main() {
  testWidgets('bots tab creates bots, shows one-time token, and deletes', (
    tester,
  ) async {
    final repository = _FakeBotRepository();
    var changedBots = const <ServerSettingsListItemSeed>[];

    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerdantTheme(),
        home: Scaffold(
          body: ServerSettingsBotsTab(
            serverId: 'server-1',
            bots: const [
              ServerSettingsListItemSeed(
                id: 'bot-1',
                title: 'Verdant Bot',
                subtitle: 'Feeds helper',
                trailing: 'offline',
              ),
            ],
            canManageServer: true,
            botRepository: repository,
            onBotsChanged: (bots) => changedBots = bots,
          ),
        ),
      ),
    );

    expect(find.text('Bots'), findsOneWidget);
    expect(find.text('Verdant Bot'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('server-bot-create-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('server-bot-name-field')),
      'Deploy Bot',
    );
    await tester.enterText(
      find.byKey(const ValueKey('server-bot-description-field')),
      'release helper',
    );
    await tester.tap(find.byKey(const ValueKey('server-bot-save-button')));
    await tester.pumpAndSettle();

    expect(
      repository.createPayloads.single,
      containsPair('name', 'Deploy Bot'),
    );
    expect(
      repository.createPayloads.single,
      containsPair('description', 'release helper'),
    );
    expect(changedBots.any((bot) => bot.id == 'bot-2'), isTrue);
    expect(find.text('Deploy Bot'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('server-bot-token-bot-2')));
    await tester.pumpAndSettle();

    expect(repository.tokenBotIds, ['bot-2']);
    expect(find.text('bot-token-visible-once'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('server-bot-delete-bot-2')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('server-bot-delete-confirm-bot-2')),
    );
    await tester.pumpAndSettle();

    expect(repository.deletedBotIds, ['bot-2']);
    expect(find.text('Deploy Bot'), findsNothing);
  });
}

final class _FakeBotRepository implements ServerSettingsBotRepository {
  final createPayloads = <Map<String, Object?>>[];
  final tokenBotIds = <String>[];
  final deletedBotIds = <String>[];

  @override
  Future<ServerSettingsListItemSeed> createBot({
    required String serverId,
    required ServerBotPatch patch,
  }) async {
    expect(serverId, 'server-1');
    final payload = patch.toJson();
    createPayloads.add(payload);
    return ServerSettingsListItemSeed(
      id: 'bot-2',
      title: payload['name'] as String,
      subtitle: payload['description'] as String? ?? 'No description',
      trailing: 'offline',
    );
  }

  @override
  Future<ServerSettingsListItemSeed> updateBot({
    required String serverId,
    required String botId,
    required ServerBotPatch patch,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteBot({
    required String serverId,
    required String botId,
  }) async {
    expect(serverId, 'server-1');
    deletedBotIds.add(botId);
  }

  @override
  Future<BotTokenResult> generateBotToken({
    required String serverId,
    required String botId,
    required BotTokenPatch patch,
  }) async {
    expect(serverId, 'server-1');
    tokenBotIds.add(botId);
    return const BotTokenResult(
      tokenId: 'token-1',
      token: 'bot-token-visible-once',
      name: 'default',
      scopes: [],
      allowedFeedIds: [],
      allowedChannelIds: [],
    );
  }
}
