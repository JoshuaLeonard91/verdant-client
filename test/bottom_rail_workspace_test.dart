import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verdant_flutter/features/auth/auth_models.dart';
import 'package:verdant_flutter/features/workspace/bottom_rail_workspace/bottom_rail_models.dart';
import 'package:verdant_flutter/features/workspace/bottom_rail_workspace/bottom_rail_workspace.dart';
import 'package:verdant_flutter/features/workspace/bottom_rail_workspace/join_server_modal.dart';
import 'package:verdant_flutter/features/workspace/bottom_rail_workspace/server_drawer.dart';
import 'package:verdant_flutter/features/workspace/chat_workspace/chat_invite_link.dart';
import 'package:verdant_flutter/features/workspace/server_settings_workspace/server_media_image.dart';
import 'package:verdant_flutter/features/workspace/server_settings_workspace/server_media_url_policy.dart';
import 'package:verdant_flutter/features/workspace/server_settings_workspace/server_settings_models.dart';
import 'package:verdant_flutter/theme/verdant_theme.dart';

void main() {
  tearDown(() {
    debugSetServerMediaWidgetLoader(null);
  });

  test('groups scoped rail servers with saved network metadata', () {
    final groups = buildRailNetworkGroups(
      activeNetworkId: 'official',
      networkOrder: const ['official', 'pryzm-test'],
      networkRecords: const [
        RailNetworkRecord(
          networkId: 'official',
          networkName: 'Official',
          mode: RailNetworkMode.official,
          availability: RailNetworkAvailability.available,
          authStatus: RailNetworkAuthStatus.authenticated,
        ),
        RailNetworkRecord(
          networkId: 'pryzm-test',
          networkName: 'Pryzm Test Self-Host',
          mode: RailNetworkMode.standalone,
          availability: RailNetworkAvailability.available,
          authStatus: RailNetworkAuthStatus.signedOut,
        ),
      ],
      servers: [
        const RailServerItem(
          networkId: 'official',
          localServerId: '123',
          name: 'Verdant',
          mediaPolicy: _mediaPolicy,
        ),
        const RailServerItem(
          networkId: 'pryzm-test',
          localServerId: 'selfhost-1',
          name: 'Pryzm Community',
          mediaPolicy: _selfHostMediaPolicy,
        ),
      ],
    );

    expect(groups.map((group) => group.networkId), ['official', 'pryzm-test']);
    expect(groups.first.networkName, 'Official');
    expect(groups.first.modeLabel, 'Network');
    expect(groups.first.statusLabel, 'Signed in');
    expect(groups.first.statusTone, RailNetworkStatusTone.success);

    final selfHostGroup = groups[1];
    expect(selfHostGroup.networkName, 'Pryzm Test Self-Host');
    expect(selfHostGroup.modeLabel, 'Federated');
    expect(selfHostGroup.statusLabel, 'Sign in required');
    expect(selfHostGroup.statusTone, RailNetworkStatusTone.warning);
    expect(selfHostGroup.servers.single.isUnavailable, isTrue);
  });

  test('labels federated mode records as federation access', () {
    const record = RailNetworkRecord(
      networkId: 'origin:https%3A%2F%2Fapi-test.pryzmapp.com',
      networkName: 'Pryzm Test',
      mode: RailNetworkMode.federated,
      availability: RailNetworkAvailability.available,
      authStatus: RailNetworkAuthStatus.authenticated,
      currentUserId:
          'origin:https%3A%2F%2Fapi-test.pryzmapp.com/fed_129fa6f4b31ac2c4a38906be',
      currentUsername: 'fed_129fa6f4b31ac2c4a38906be',
      credentialKind: AuthCredentialKind.userSession,
    );

    expect(record.usesFederatedAccess, isTrue);
    expect(
      railNetworkSignedInLabel(record, 'Connected'),
      'Connected as @fed_129fa6f4b31ac2c4a38906be',
    );
  });

  test(
    'keeps saved network rail order stable when the active network changes',
    () {
      final groups = buildRailNetworkGroups(
        activeNetworkId: 'pryzm-test',
        networkOrder: const ['official', 'pryzm-test'],
        networkRecords: const [
          RailNetworkRecord(
            networkId: 'official',
            networkName: 'Official',
            mode: RailNetworkMode.official,
            availability: RailNetworkAvailability.available,
            authStatus: RailNetworkAuthStatus.authenticated,
          ),
          RailNetworkRecord(
            networkId: 'pryzm-test',
            networkName: 'Pryzm Test Self-Host',
            mode: RailNetworkMode.standalone,
            availability: RailNetworkAvailability.available,
            authStatus: RailNetworkAuthStatus.authenticated,
          ),
        ],
        servers: const [
          RailServerItem(
            networkId: 'official',
            localServerId: '123',
            name: 'Verdant',
            mediaPolicy: _mediaPolicy,
          ),
          RailServerItem(
            networkId: 'pryzm-test',
            localServerId: 'selfhost-1',
            name: 'Pryzm Community',
            mediaPolicy: _selfHostMediaPolicy,
          ),
        ],
      );

      expect(groups.map((group) => group.networkId), [
        'official',
        'pryzm-test',
      ]);
    },
  );

  testWidgets('renders merged rail in server snapshot order', (tester) async {
    await tester.pumpWidget(
      _railApp(
        BottomRailWorkspace(
          networkId: 'official',
          activeServerId: '123',
          mediaPolicy: _mediaPolicy,
          networkOrder: const ['official', 'pryzm-test'],
          networkRecords: const [
            RailNetworkRecord(
              networkId: 'official',
              networkName: 'Official',
              mode: RailNetworkMode.official,
              availability: RailNetworkAvailability.available,
              authStatus: RailNetworkAuthStatus.authenticated,
            ),
            RailNetworkRecord(
              networkId: 'pryzm-test',
              networkName: 'Pryzm Test Self-Host',
              mode: RailNetworkMode.federated,
              availability: RailNetworkAvailability.available,
              authStatus: RailNetworkAuthStatus.authenticated,
            ),
          ],
          railServers: const [
            RailServerItem(
              networkId: 'pryzm-test',
              localServerId: 'selfhost-1',
              name: 'Pryzm Community',
              mediaPolicy: _selfHostMediaPolicy,
            ),
            RailServerItem(
              networkId: 'official',
              localServerId: '123',
              name: 'Actual Verdant',
              mediaPolicy: _mediaPolicy,
            ),
          ],
          servers: const [_officialServer],
          onSelectServer: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final selfHostLeft = tester
        .getTopLeft(
          find.byKey(const ValueKey('server-rail-item-pryzm-test/selfhost-1')),
        )
        .dx;
    final officialLeft = tester
        .getTopLeft(find.byKey(const ValueKey('server-rail-item-official/123')))
        .dx;

    expect(selfHostLeft, lessThan(officialLeft));
    expect(
      find.byKey(const ValueKey('server-rail-icon-pryzm-test/selfhost-1')),
      findsOneWidget,
    );
  });

  test(
    'groups legacy official rail rows under the active origin-derived network',
    () {
      final officialNetworkId = networkIdFromApiOrigin(officialApiOrigin);
      final groups = buildRailNetworkGroups(
        activeNetworkId: officialNetworkId,
        networkOrder: [officialNetworkId],
        networkRecords: [
          RailNetworkRecord(
            networkId: officialNetworkId,
            networkName: 'Official',
            mode: RailNetworkMode.official,
            availability: RailNetworkAvailability.available,
            authStatus: RailNetworkAuthStatus.authenticated,
          ),
        ],
        servers: const [
          RailServerItem(
            networkId: legacyOfficialNetworkId,
            localServerId: '123',
            name: 'Verdant',
            mediaPolicy: _mediaPolicy,
          ),
        ],
      );

      expect(groups, hasLength(1));
      expect(groups.single.networkId, officialNetworkId);
      expect(groups.single.networkName, 'Official');
      expect(groups.single.statusLabel, 'Signed in');
      expect(groups.single.servers.single.scopedServerId, 'official/123');
    },
  );

  testWidgets('renders scoped server rail modules with backend icon media', (
    tester,
  ) async {
    final requestedPaths = <String>[];
    debugSetServerMediaWidgetLoader((uri, {required policy, maxBytes}) async {
      requestedPaths.add(uri.path);
      return _pngBytes;
    });

    final selected = <ServerSettingsServer>[];
    await tester.pumpWidget(
      _railApp(
        BottomRailWorkspace(
          networkId: 'official',
          activeServerId: '123',
          mediaPolicy: _mediaPolicy,
          servers: const [
            ServerSettingsServer(
              id: '123',
              name: 'Actual Verdant',
              ownerId: '42',
              iconUrl: 'https://media.verdant.chat/server-icons/123/icon.png',
              voiceBitrate: 64000,
              bannerOffsetY: 50,
              memberCount: 42,
              large: false,
              createdAt: '2026-06-01T10:00:00Z',
              updatedAt: '2026-06-01T10:00:00Z',
            ),
            ServerSettingsServer(
              id: '456',
              name: 'Second Verdant',
              ownerId: '42',
              voiceBitrate: 64000,
              bannerOffsetY: 50,
              memberCount: 3,
              large: false,
              createdAt: '2026-06-01T10:00:00Z',
              updatedAt: '2026-06-01T10:00:00Z',
            ),
          ],
          onSelectServer: selected.add,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('bottom-rail-workspace')), findsOneWidget);
    expect(find.byKey(const ValueKey('bottom-rail-dm-button')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('bottom-rail-server-grid-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('bottom-rail-create-server-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('server-rail-network-official')),
      findsNothing,
    );
    expect(find.text('Saved Network'), findsNothing);
    expect(
      find.byKey(const ValueKey('server-rail-item-official/123')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('server-rail-icon-media-official/123')),
      findsOneWidget,
    );
    expect(requestedPaths, contains('/server-icons/123/icon.png'));

    await tester.tap(
      find.byKey(const ValueKey('server-rail-item-official/456')),
    );
    await tester.pump();

    expect(selected.map((server) => server.id), ['456']);
  });

  testWidgets(
    'server rail tooltip uses the network label instead of scoped id',
    (tester) async {
      await tester.pumpWidget(
        _railApp(
          BottomRailWorkspace(
            networkId: 'official',
            activeServerId: '123',
            mediaPolicy: _mediaPolicy,
            networkOrder: const ['official'],
            networkRecords: const [
              RailNetworkRecord(
                networkId: 'official',
                networkName: 'Official',
                mode: RailNetworkMode.official,
                availability: RailNetworkAvailability.available,
                authStatus: RailNetworkAuthStatus.authenticated,
              ),
            ],
            servers: const [
              ServerSettingsServer(
                id: '123',
                name: 'Actual Verdant',
                ownerId: '42',
                voiceBitrate: 64000,
                bannerOffsetY: 50,
                memberCount: 42,
                large: false,
                createdAt: '2026-06-01T10:00:00Z',
                updatedAt: '2026-06-01T10:00:00Z',
              ),
            ],
            onSelectServer: (_) {},
          ),
        ),
      );

      final tooltip = tester.widget<Tooltip>(
        find
            .ancestor(
              of: find.byKey(const ValueKey('server-rail-item-official/123')),
              matching: find.byType(Tooltip),
            )
            .first,
      );

      expect(tooltip.message, 'Actual Verdant - Official');
      expect(tooltip.message, isNot(contains('origin:')));
      expect(tooltip.message, isNot(contains('%')));
      final tooltipDecoration =
          Theme.of(
                tester.element(
                  find.byKey(const ValueKey('server-rail-item-official/123')),
                ),
              ).tooltipTheme.decoration
              as BoxDecoration;
      expect(tooltipDecoration.color, VerdantThemeColors.dark.panelRaised);
    },
  );

  testWidgets(
    'server drawer uses the network label instead of a generic tooltip',
    (tester) async {
      await tester.pumpWidget(
        _railApp(
          ServerDrawerModule(
            networkId: 'origin:https%3A%2F%2Fapi-test.pryzmapp.com',
            networkName: 'Pryzm Test Self-Host',
            activeServerId: 'selfhost-1',
            mediaPolicy: _selfHostMediaPolicy,
            servers: const [
              ServerSettingsServer(
                id: 'selfhost-1',
                name: 'Self-host Verdant',
                ownerId: '42',
                voiceBitrate: 64000,
                bannerOffsetY: 50,
                memberCount: 42,
                large: false,
                createdAt: '2026-06-01T10:00:00Z',
                updatedAt: '2026-06-01T10:00:00Z',
              ),
            ],
            onSelectServer: (_) {},
            onClose: () {},
          ),
        ),
      );

      final itemKey = const ValueKey(
        'server-drawer-item-origin:https%3A%2F%2Fapi-test.pryzmapp.com/selfhost-1',
      );
      expect(find.text('Pryzm Test Self-Host'), findsOneWidget);
      expect(find.text('Network'), findsNothing);

      final tooltip = tester.widget<Tooltip>(
        find.descendant(
          of: find.byKey(itemKey),
          matching: find.byType(Tooltip),
        ),
      );

      expect(tooltip.message, 'Self-host Verdant - Pryzm Test Self-Host');
      expect(tooltip.message, isNot(contains('origin:')));
      expect(tooltip.message, isNot(contains('%')));
    },
  );

  testWidgets(
    'renders saved self-host rail item without routing signed-out selection',
    (tester) async {
      final selectedLegacyServers = <ServerSettingsServer>[];
      final selectedRailServers = <RailServerItem>[];

      await tester.pumpWidget(
        _railApp(
          BottomRailWorkspace(
            networkId: 'official',
            activeServerId: '123',
            mediaPolicy: _mediaPolicy,
            networkOrder: const ['official', 'pryzm-test'],
            networkRecords: const [
              RailNetworkRecord(
                networkId: 'official',
                networkName: 'Official',
                mode: RailNetworkMode.official,
                availability: RailNetworkAvailability.available,
                authStatus: RailNetworkAuthStatus.authenticated,
              ),
              RailNetworkRecord(
                networkId: 'pryzm-test',
                networkName: 'Pryzm Test Self-Host',
                mode: RailNetworkMode.standalone,
                availability: RailNetworkAvailability.available,
                authStatus: RailNetworkAuthStatus.signedOut,
              ),
            ],
            railServers: [
              RailServerItem.fromServer(
                networkId: 'official',
                server: _officialServer,
                mediaPolicy: _mediaPolicy,
              ),
              const RailServerItem(
                networkId: 'pryzm-test',
                localServerId: 'selfhost-1',
                name: 'Pryzm Community',
                mediaPolicy: _selfHostMediaPolicy,
              ),
            ],
            servers: const [_officialServer],
            onSelectRailServer: selectedRailServers.add,
            onSelectServer: selectedLegacyServers.add,
          ),
        ),
      );

      expect(find.text('Pryzm Test Self-Host'), findsNothing);
      expect(
        find.byKey(const ValueKey('server-rail-item-pryzm-test/selfhost-1')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('server-rail-network-badge-pryzm-test/selfhost-1'),
        ),
        findsOneWidget,
      );

      final tooltip = tester.widget<Tooltip>(
        find
            .ancestor(
              of: find.byKey(
                const ValueKey('server-rail-item-pryzm-test/selfhost-1'),
              ),
              matching: find.byType(Tooltip),
            )
            .first,
      );
      expect(
        tooltip.message,
        'Pryzm Community - Federated via Pryzm Test Self-Host (Sign in required)',
      );

      await tester.tap(
        find.byKey(const ValueKey('server-rail-item-pryzm-test/selfhost-1')),
      );
      await tester.pump();

      expect(selectedRailServers, isEmpty);
      expect(selectedLegacyServers, isEmpty);
    },
  );

  testWidgets('unavailable federated rail servers show a red blocked badge', (
    tester,
  ) async {
    final selectedRailServers = <RailServerItem>[];

    await tester.pumpWidget(
      _railApp(
        BottomRailWorkspace(
          networkId: 'official',
          activeServerId: '123',
          mediaPolicy: _mediaPolicy,
          networkOrder: const ['official', 'pryzm-test'],
          networkRecords: const [
            RailNetworkRecord(
              networkId: 'official',
              networkName: 'Official',
              mode: RailNetworkMode.official,
              availability: RailNetworkAvailability.available,
              authStatus: RailNetworkAuthStatus.authenticated,
            ),
            RailNetworkRecord(
              networkId: 'pryzm-test',
              networkName: 'Pryzm Test Self-Host',
              mode: RailNetworkMode.federated,
              availability: RailNetworkAvailability.unavailable,
              authStatus: RailNetworkAuthStatus.authenticated,
            ),
          ],
          railServers: const [
            RailServerItem(
              networkId: 'pryzm-test',
              localServerId: 'selfhost-1',
              name: 'Pryzm Community',
              mediaPolicy: _selfHostMediaPolicy,
            ),
          ],
          servers: const [_officialServer],
          onSelectRailServer: selectedRailServers.add,
          onSelectServer: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(
        const ValueKey('server-rail-unavailable-overlay-pryzm-test/selfhost-1'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('server-rail-unavailable-blur-pryzm-test/selfhost-1'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('server-rail-unavailable-badge-pryzm-test/selfhost-1'),
      ),
      findsOneWidget,
    );
    expect(find.text('!'), findsOneWidget);

    final badge = tester.widget<Container>(
      find.byKey(
        const ValueKey('server-rail-unavailable-badge-pryzm-test/selfhost-1'),
      ),
    );
    final decoration = badge.decoration! as BoxDecoration;
    expect(decoration.color, const Color(0xFFDC3F4D));

    final tooltip = tester.widget<Tooltip>(
      find
          .ancestor(
            of: find.byKey(
              const ValueKey('server-rail-item-pryzm-test/selfhost-1'),
            ),
            matching: find.byType(Tooltip),
          )
          .first,
    );
    expect(
      tooltip.message,
      'Pryzm Community - Federated via Pryzm Test Self-Host (Unavailable)',
    );

    await tester.tap(
      find.byKey(const ValueKey('server-rail-item-pryzm-test/selfhost-1')),
    );
    await tester.pump();

    expect(selectedRailServers, isEmpty);
  });

  testWidgets(
    'routes legacy official rail items as active origin-derived network servers',
    (tester) async {
      final officialNetworkId = networkIdFromApiOrigin(officialApiOrigin);
      final selectedLegacyServers = <ServerSettingsServer>[];
      const secondaryServer = ServerSettingsServer(
        id: '456',
        name: 'Second Verdant',
        ownerId: '42',
        voiceBitrate: 64000,
        bannerOffsetY: 50,
        memberCount: 3,
        large: false,
        createdAt: '2026-06-01T10:00:00Z',
        updatedAt: '2026-06-01T10:00:00Z',
      );

      await tester.pumpWidget(
        _railApp(
          BottomRailWorkspace(
            networkId: officialNetworkId,
            activeServerId: '123',
            mediaPolicy: _mediaPolicy,
            railServers: const [
              RailServerItem(
                networkId: legacyOfficialNetworkId,
                localServerId: '456',
                name: 'Second Verdant',
                mediaPolicy: _mediaPolicy,
              ),
            ],
            servers: const [_officialServer, secondaryServer],
            onSelectServer: selectedLegacyServers.add,
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('server-rail-item-official/456')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('server-rail-item-official/456')),
      );
      await tester.pump();

      expect(selectedLegacyServers.map((server) => server.id), ['456']);
    },
  );

  testWidgets('rail action buttons use the active theme surface', (
    tester,
  ) async {
    await tester.pumpWidget(
      _railApp(
        BottomRailWorkspace(
          networkId: 'official',
          activeServerId: '123',
          mediaPolicy: _mediaPolicy,
          servers: const [
            ServerSettingsServer(
              id: '123',
              name: 'Actual Verdant',
              ownerId: '42',
              voiceBitrate: 64000,
              bannerOffsetY: 50,
              memberCount: 42,
              large: false,
              createdAt: '2026-06-01T10:00:00Z',
              updatedAt: '2026-06-01T10:00:00Z',
            ),
          ],
          onSelectServer: (_) {},
        ),
        theme: buildVerdantTheme(mode: VerdantThemeMode.light),
      ),
    );

    final createButtonMaterial = tester.widget<Material>(
      find
          .descendant(
            of: find.byKey(const ValueKey('bottom-rail-create-server-button')),
            matching: find.byType(Material),
          )
          .first,
    );

    expect(createButtonMaterial.color, VerdantThemeColors.light.panelRaised);
  });

  testWidgets('server rail right-click exposes invite and leave actions', (
    tester,
  ) async {
    RailServerItem? inviteServer;
    ServerSettingsServer? leaveServer;

    await tester.pumpWidget(
      _railApp(
        BottomRailWorkspace(
          networkId: 'official',
          activeServerId: '123',
          mediaPolicy: _mediaPolicy,
          servers: const [
            ServerSettingsServer(
              id: '123',
              name: 'Actual Verdant',
              ownerId: '42',
              voiceBitrate: 64000,
              bannerOffsetY: 50,
              memberCount: 42,
              large: false,
              createdAt: '2026-06-01T10:00:00Z',
              updatedAt: '2026-06-01T10:00:00Z',
            ),
          ],
          onSelectServer: (_) {},
          onCreateInviteForServer: (server) => inviteServer = server,
          onLeaveServer: (server) => leaveServer = server,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final item = find.byKey(const ValueKey('server-rail-item-official/123'));
    await tester.tapAt(tester.getCenter(item), buttons: kSecondaryMouseButton);
    await tester.pumpAndSettle();

    expect(
      find.byKey(
        const ValueKey('user-context-menu-item-server-rail-create-invite'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('user-context-menu-item-server-rail-leave-server'),
      ),
      findsOneWidget,
    );
    final createInviteSurface = find.byKey(
      const ValueKey(
        'user-context-menu-item-surface-server-rail-create-invite',
      ),
    );
    expect(createInviteSurface, findsOneWidget);
    final beforeHover = tester.widget<AnimatedContainer>(createInviteSurface);
    expect(
      (beforeHover.decoration! as BoxDecoration).color,
      Colors.transparent,
    );

    final hoverGesture = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
    );
    await hoverGesture.addPointer();
    addTearDown(hoverGesture.removePointer);
    await hoverGesture.moveTo(tester.getCenter(createInviteSurface));
    await tester.pump(const Duration(milliseconds: 140));

    final afterHover = tester.widget<AnimatedContainer>(createInviteSurface);
    expect(
      (afterHover.decoration! as BoxDecoration).color,
      VerdantColors.panelHover,
    );

    await tester.tap(
      find.byKey(
        const ValueKey('user-context-menu-item-server-rail-create-invite'),
      ),
    );
    await tester.pumpAndSettle();
    expect(inviteServer?.localServerId, '123');
    expect(inviteServer?.networkId, 'official');

    await tester.tapAt(tester.getCenter(item), buttons: kSecondaryMouseButton);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const ValueKey('user-context-menu-item-server-rail-leave-server'),
      ),
    );
    await tester.pumpAndSettle();
    expect(leaveServer?.id, '123');
  });

  testWidgets(
    'server rail right-click invite preserves the scoped self-host route',
    (tester) async {
      RailServerItem? inviteServer;
      final selectedLegacyServers = <ServerSettingsServer>[];
      final selectedRailServers = <RailServerItem>[];

      await tester.pumpWidget(
        _railApp(
          BottomRailWorkspace(
            networkId: 'official',
            activeServerId: '123',
            mediaPolicy: _mediaPolicy,
            networkOrder: const ['official', 'pryzm-test'],
            networkRecords: const [
              RailNetworkRecord(
                networkId: 'official',
                networkName: 'Official',
                mode: RailNetworkMode.official,
                availability: RailNetworkAvailability.available,
                authStatus: RailNetworkAuthStatus.authenticated,
              ),
              RailNetworkRecord(
                networkId: 'pryzm-test',
                networkName: 'Pryzm Test Self-Host',
                mode: RailNetworkMode.federated,
                availability: RailNetworkAvailability.available,
                authStatus: RailNetworkAuthStatus.authenticated,
                apiOrigin: 'https://api-test.pryzmapp.com',
              ),
            ],
            railServers: [
              RailServerItem.fromServer(
                networkId: 'official',
                server: _officialServer,
                mediaPolicy: _mediaPolicy,
              ),
              const RailServerItem(
                networkId: 'pryzm-test',
                localServerId: 'selfhost-1',
                name: 'Pryzm Community',
                mediaPolicy: _selfHostMediaPolicy,
              ),
            ],
            servers: const [_officialServer],
            onSelectRailServer: selectedRailServers.add,
            onSelectServer: selectedLegacyServers.add,
            onCreateInviteForServer: (server) => inviteServer = server,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final item = find.byKey(
        const ValueKey('server-rail-item-pryzm-test/selfhost-1'),
      );
      await tester.tapAt(
        tester.getCenter(item),
        buttons: kSecondaryMouseButton,
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const ValueKey('user-context-menu-item-server-rail-create-invite'),
        ),
      );
      await tester.pumpAndSettle();

      expect(inviteServer?.networkId, 'pryzm-test');
      expect(inviteServer?.localServerId, 'selfhost-1');
      expect(selectedLegacyServers, isEmpty);
      expect(selectedRailServers, isEmpty);
    },
  );

  testWidgets('join server modal preserves self-host invite origins', (
    tester,
  ) async {
    ChatInviteTarget? previewTarget;
    ChatInviteTarget? joinTarget;

    await tester.pumpWidget(
      _railApp(
        JoinServerRailModal(
          apiOrigin: officialApiOrigin,
          networkLabel: 'Official',
          onPreview: (target) async {
            previewTarget = target;
            return const ServerInvitePreview(
              code: 'ABC123',
              server: _selfHostServer,
              inviterUsername: 'operator',
              isMember: false,
            );
          },
          onJoin: (target, _) async {
            joinTarget = target;
            return _selfHostServer;
          },
          onOpenExisting: (_, _) async {},
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('join-server-invite-field')),
      'https://api-test.pryzmapp.com/invite/ABC123',
    );
    await tester.tap(find.byKey(const ValueKey('join-server-preview-button')));
    await tester.pumpAndSettle();

    expect(previewTarget, isNotNull);
    expect(previewTarget?.code, 'ABC123');
    expect(previewTarget?.apiOrigin, 'https://api-test.pryzmapp.com');
    expect(
      find.byKey(const ValueKey('join-server-preview-card')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('join-server-submit-button')));
    await tester.pumpAndSettle();

    expect(joinTarget, previewTarget);
  });
}

Widget _railApp(Widget child, {ThemeData? theme}) {
  return MaterialApp(
    theme: theme ?? buildVerdantTheme(),
    home: Scaffold(
      body: Align(alignment: Alignment.bottomCenter, child: child),
    ),
  );
}

const _mediaPolicy = ServerMediaPolicy(
  allowedOrigins: {'https://media.verdant.chat'},
  allowLocalHttp: false,
);

const _selfHostMediaPolicy = ServerMediaPolicy(
  allowedOrigins: {'https://api-test.pryzmapp.com'},
  allowLocalHttp: false,
  apiOrigin: 'https://api-test.pryzmapp.com',
);

const _officialServer = ServerSettingsServer(
  id: '123',
  name: 'Actual Verdant',
  ownerId: '42',
  voiceBitrate: 64000,
  bannerOffsetY: 50,
  memberCount: 42,
  large: false,
  createdAt: '2026-06-01T10:00:00Z',
  updatedAt: '2026-06-01T10:00:00Z',
);

const _selfHostServer = ServerSettingsServer(
  id: 'selfhost-1',
  name: 'Pryzm Community',
  ownerId: '7',
  voiceBitrate: 64000,
  bannerOffsetY: 50,
  memberCount: 12,
  large: false,
  createdAt: '2026-06-01T10:00:00Z',
  updatedAt: '2026-06-01T10:00:00Z',
);

final _pngBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMB/6Xk2kAAAAAASUVORK5CYII=',
);
