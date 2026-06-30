import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verdant_flutter/features/workspace/server_settings_workspace/server_settings_feeds_tab.dart';
import 'package:verdant_flutter/features/workspace/server_settings_workspace/server_settings_models.dart';
import 'package:verdant_flutter/features/workspace/server_settings_workspace/server_settings_service.dart';
import 'package:verdant_flutter/theme/verdant_theme.dart';

void main() {
  testWidgets('feeds tab manages feed drafts with explicit save', (
    tester,
  ) async {
    final repository = _FakeFeedRepository(initialFeeds: _feedSeeds);
    var changedFeeds = const <ServerSettingsListItemSeed>[];

    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerdantTheme(),
        home: Scaffold(
          body: ServerSettingsFeedsTab(
            serverId: 'server-1',
            feeds: _feedSeeds,
            roles: _roleSeeds,
            canManageServer: true,
            feedRepository: repository,
            onFeedsChanged: (feeds) => changedFeeds = feeds,
          ),
        ),
      ),
    );

    expect(find.text('Announcement Feeds'), findsOneWidget);
    expect(find.text('Patch Notes'), findsOneWidget);
    expect(find.text('Publish: Member'), findsOneWidget);
    expect(find.text('Visible: Everyone'), findsOneWidget);
    expect(find.text('Purple'), findsNothing);
    expect(
      find.byKey(const ValueKey('server-feed-editor-route')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('server-feed-list-route')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('server-feed-create-button')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('server-feed-editor-route')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('server-feed-list-route')), findsNothing);
    expect(
      find.byKey(const ValueKey('server-feed-editor-back-button')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('server-feed-editor-title')))
          .data,
      'Create Feed',
    );
    expect(find.text('EDIT FEED'), findsNothing);
    expect(find.text('NEW FEED'), findsNothing);
    expect(find.text('Announcement Feed'), findsNothing);
    expect(find.byKey(const ValueKey('server-feed-icon-field')), findsNothing);
    await tester.enterText(
      find.byKey(const ValueKey('server-feed-name-field')),
      'Deploy Notes',
    );
    await tester.pump();
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('server-feed-editor-title')))
          .data,
      'Deploy Notes',
    );
    await tester.enterText(
      find.byKey(const ValueKey('server-feed-description-field')),
      'Short release notes',
    );
    await tester.tap(
      find.byKey(const ValueKey('server-feed-publish-role-menu')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('server-feed-publish-role-popover')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('server-feed-publish-role-option-member')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('server-feed-publish-role-popover')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('server-feed-publish-role-selected-member')),
      findsOneWidget,
    );

    expect(repository.createPayloads, isEmpty);

    await tester.ensureVisible(
      find.byKey(const ValueKey('server-feed-save-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('server-feed-save-button')));
    await tester.pumpAndSettle();

    expect(repository.createPayloads, hasLength(1));
    expect(
      repository.createPayloads.single,
      containsPair('name', 'Deploy Notes'),
    );
    expect(
      repository.createPayloads.single,
      containsPair('description', 'Short release notes'),
    );
    expect(repository.createPayloads.single.containsKey('icon'), isFalse);
    expect(
      repository.createPayloads.single,
      containsPair('publishRoleIds', ['member']),
    );
    expect(
      repository.createPayloads.single,
      containsPair('visibleRoleIds', null),
    );
    expect(changedFeeds.any((feed) => feed.id == 'created-feed'), isTrue);
    expect(find.text('Deploy Notes'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('server-feed-edit-feed-1')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('server-feed-editor-route')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('server-feed-editor-title')))
          .data,
      'Patch Notes',
    );
    await tester.enterText(
      find.byKey(const ValueKey('server-feed-description-field')),
      'Member-only release notes',
    );
    await tester.tap(
      find.byKey(const ValueKey('server-feed-visible-role-menu')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('server-feed-visible-role-popover')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('server-feed-visible-role-option-member')),
    );
    await tester.pumpAndSettle();

    expect(repository.updatePayloads, isEmpty);

    await tester.ensureVisible(
      find.byKey(const ValueKey('server-feed-save-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('server-feed-save-button')));
    await tester.pumpAndSettle();

    expect(repository.updatedFeedIds, ['feed-1']);
    expect(repository.updatePayloads, hasLength(1));
    expect(
      repository.updatePayloads.single,
      containsPair('description', 'Member-only release notes'),
    );
    expect(
      repository.updatePayloads.single,
      containsPair('visibleRoleIds', ['member']),
    );
    expect(repository.updatePayloads.single.containsKey('icon'), isFalse);

    await tester.tap(find.byKey(const ValueKey('server-feed-delete-feed-1')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('server-feed-delete-confirm-feed-1')),
    );
    await tester.pumpAndSettle();

    expect(repository.deletedFeedIds, ['feed-1']);
  });
}

const _roleSeeds = [
  ServerSettingsListItemSeed(
    id: 'everyone',
    title: '@everyone',
    subtitle: 'Default access',
    permissions: 0,
    position: 0,
  ),
  ServerSettingsListItemSeed(
    id: 'member',
    title: 'Member',
    subtitle: 'Access role',
    trailing: '#2196f3',
    accent: Color(0xFF2196F3),
    permissions: 12291,
    position: 2,
  ),
  ServerSettingsListItemSeed(
    id: 'publisher',
    title: 'Publisher',
    subtitle: 'Access role',
    trailing: '#22c55e',
    accent: Color(0xFF22C55E),
    permissions: 64,
    position: 3,
  ),
  ServerSettingsListItemSeed(
    id: 'purple',
    title: 'Purple',
    subtitle: 'Name Color',
    trailing: '#673ab7',
    accent: Color(0xFF673AB7),
    permissions: 0,
    position: 10,
    colorOnly: true,
  ),
];

const _feedSeeds = [
  ServerSettingsListItemSeed(
    id: 'feed-1',
    title: 'Patch Notes',
    subtitle: 'Release notes and maintenance windows',
    trailing: '#0',
    feedIcon: 'PN',
    publishRoleIds: ['member'],
    visibleRoleIds: [],
  ),
];

final class _FakeFeedRepository implements ServerSettingsFeedRepository {
  _FakeFeedRepository({required List<ServerSettingsListItemSeed> initialFeeds})
    : _feeds = [...initialFeeds];

  List<ServerSettingsListItemSeed> _feeds;
  final createPayloads = <Map<String, Object?>>[];
  final updatePayloads = <Map<String, Object?>>[];
  final updatedFeedIds = <String>[];
  final deletedFeedIds = <String>[];

  @override
  Future<ServerSettingsListItemSeed> createFeed({
    required String serverId,
    required ServerFeedPatch patch,
  }) async {
    expect(serverId, 'server-1');
    final payload = patch.toJson();
    createPayloads.add(payload);
    final feed = ServerSettingsListItemSeed(
      id: 'created-feed',
      title: payload['name'] as String? ?? 'Created Feed',
      subtitle: payload['description'] as String? ?? 'No description',
      trailing: '#1',
      feedIcon: payload['icon'] as String?,
      publishRoleIds:
          (payload['publishRoleIds'] as List?)?.cast<String>() ??
          const <String>[],
      visibleRoleIds:
          (payload['visibleRoleIds'] as List?)?.cast<String>() ??
          const <String>[],
    );
    _feeds = [feed, ..._feeds];
    return feed;
  }

  @override
  Future<ServerSettingsListItemSeed> updateFeed({
    required String serverId,
    required String feedId,
    required ServerFeedPatch patch,
  }) async {
    expect(serverId, 'server-1');
    updatedFeedIds.add(feedId);
    final payload = patch.toJson();
    updatePayloads.add(payload);
    final current = _feeds.firstWhere((feed) => feed.id == feedId);
    final updated = ServerSettingsListItemSeed(
      id: current.id,
      title: payload['name'] as String? ?? current.title,
      subtitle: payload.containsKey('description')
          ? payload['description'] as String? ?? 'No description'
          : current.subtitle,
      trailing: current.trailing,
      feedIcon: payload.containsKey('icon')
          ? payload['icon'] as String?
          : current.feedIcon,
      publishRoleIds: payload.containsKey('publishRoleIds')
          ? (payload['publishRoleIds'] as List?)?.cast<String>() ??
                const <String>[]
          : current.publishRoleIds,
      visibleRoleIds: payload.containsKey('visibleRoleIds')
          ? (payload['visibleRoleIds'] as List?)?.cast<String>() ??
                const <String>[]
          : current.visibleRoleIds,
    );
    _feeds = [
      for (final feed in _feeds)
        if (feed.id == feedId) updated else feed,
    ];
    return updated;
  }

  @override
  Future<void> deleteFeed({
    required String serverId,
    required String feedId,
  }) async {
    expect(serverId, 'server-1');
    deletedFeedIds.add(feedId);
    _feeds = [
      for (final feed in _feeds)
        if (feed.id != feedId) feed,
    ];
  }
}
