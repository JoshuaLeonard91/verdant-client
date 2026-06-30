import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verdant_flutter/features/workspace/server_settings_workspace/server_settings_models.dart';
import 'package:verdant_flutter/features/workspace/server_settings_workspace/server_settings_roles_tab.dart';
import 'package:verdant_flutter/features/workspace/server_settings_workspace/server_settings_service.dart';
import 'package:verdant_flutter/shared/smooth_single_child_scroll_view.dart';
import 'package:verdant_flutter/theme/verdant_theme.dart';

void main() {
  testWidgets(
    'roles tab focuses role lists and slides editor after selection',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildVerdantTheme(),
          home: const Scaffold(
            body: ServerSettingsRolesTab(
              roles: [
                ServerSettingsListItemSeed(
                  id: 'everyone',
                  title: '@everyone',
                  subtitle: 'Default access',
                  permissions: 12291,
                  position: 0,
                ),
                ServerSettingsListItemSeed(
                  id: 'admin',
                  title: 'Member',
                  subtitle: 'Access role',
                  trailing: '#2196f3',
                  accent: Color(0xFF2196F3),
                  permissions: 12291,
                  position: 2,
                  showAsSection: true,
                  colorPriority: 7,
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
                  colorPriority: 12,
                ),
              ],
              canManageRoles: true,
            ),
          ),
        ),
      );

      expect(find.text('Roles'), findsNothing);
      expect(find.text('Access Roles'), findsOneWidget);
      expect(find.text('Name Colors'), findsOneWidget);
      expect(
        find.text('Permissions and member-list grouping.'),
        findsOneWidget,
      );
      expect(
        find.text('Member-selectable display colors only.'),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('server-permission-roles-scroll')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('server-color-roles-scroll')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('server-role-editor-scroll')),
        findsNothing,
      );
      expect(find.byType(SmoothSingleChildScrollView), findsNWidgets(2));
      expect(
        find.byKey(const ValueKey('server-role-mini-scroll-indicator')),
        findsNWidgets(2),
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('server-role-editor-scroll')),
          matching: find.byType(Scrollbar),
        ),
        findsNothing,
      );
      expect(find.text('Create Access Role'), findsOneWidget);
      expect(find.text('Create Name Color'), findsOneWidget);
      expect(find.text('@everyone'), findsWidgets);
      expect(find.text('Member'), findsWidgets);
      expect(find.text('Purple'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('server-role-row-admin')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('server-role-editor-route')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('server-role-editor-back-button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('server-role-editor-scroll')),
        findsOneWidget,
      );
      expect(find.text('Role Name'), findsOneWidget);
      expect(find.text('Show as member-list section'), findsOneWidget);
      expect(
        find.text('Groups online members under this role in member panels.'),
        findsNothing,
      );
      expect(find.text('Role Color'), findsOneWidget);
      expect(find.text('#2196f3'), findsOneWidget);
      expect(find.text('Color Priority'), findsNothing);
      expect(find.text('Permissions'), findsOneWidget);
      expect(find.text('General'), findsOneWidget);
      expect(find.text('Text'), findsOneWidget);
      expect(find.text('Voice'), findsOneWidget);
      expect(find.text('Administrator'), findsWidgets);

      await tester.tap(
        find.byKey(const ValueKey('server-role-editor-back-button')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('server-role-list-route')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('server-role-row-purple')));
      await tester.pumpAndSettle();
      expect(find.text('Role Name'), findsOneWidget);
      expect(find.text('Role Color'), findsOneWidget);
      expect(find.text('#673ab7'), findsOneWidget);
      expect(find.text('Color Priority'), findsNothing);
      expect(find.text('Permissions'), findsNothing);
      expect(find.text('Show as member-list section'), findsNothing);
    },
  );

  testWidgets(
    'role editor uses live pill and color picker with explicit save',
    (tester) async {
      final repository = _FakeRoleRepository(initialRoles: _roleSeeds);
      await _pumpRolesTab(tester, repository: repository);

      await tester.tap(find.byKey(const ValueKey('server-role-row-admin')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('server-role-member-list-switch')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('server-role-member-list-help')),
        findsOneWidget,
      );
      expect(find.byType(Checkbox), findsNothing);
      expect(
        find.byKey(const ValueKey('server-role-color-saturation-value')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('server-role-color-hue-slider')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('server-role-color-swatch-#2196f3')),
        findsNothing,
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('server-role-member-list-switch')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('server-role-member-list-switch')),
      );
      await tester.pumpAndSettle();
      expect(repository.updatePayloads, isEmpty);

      await tester.enterText(
        find.byKey(const ValueKey('server-role-name-field')),
        'Moderators',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(repository.updatePayloads, isEmpty);

      await tester.ensureVisible(
        find.byKey(const ValueKey('server-role-save-button')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('server-role-save-button')));
      await tester.pumpAndSettle();

      expect(repository.updatePayloads, hasLength(1));
      expect(
        repository.updatePayloads.single,
        containsPair('name', 'Moderators'),
      );
      expect(
        repository.updatePayloads.single,
        containsPair('showAsSection', false),
      );
    },
  );

  testWidgets('permission rows use separators instead of boxed cards', (
    tester,
  ) async {
    final repository = _FakeRoleRepository(initialRoles: _roleSeeds);
    await _pumpRolesTab(tester, repository: repository);

    await tester.tap(find.byKey(const ValueKey('server-role-row-admin')));
    await tester.pumpAndSettle();

    final row = tester.widget<Container>(
      find.byKey(const ValueKey('server-role-permission-row-VIEW_CHANNEL')),
    );
    final decoration = row.decoration as BoxDecoration?;

    expect(decoration?.color, isNull);
    expect(decoration?.borderRadius, isNull);
    expect(decoration?.border?.bottom.width, greaterThan(0));
  });

  testWidgets('role color picker stages drag release until save', (
    tester,
  ) async {
    final repository = _FakeRoleRepository(initialRoles: _roleSeeds);
    await _pumpRolesTab(tester, repository: repository);

    await tester.tap(find.byKey(const ValueKey('server-role-row-admin')));
    await tester.pumpAndSettle();

    final colorPad = find.byKey(
      const ValueKey('server-role-color-saturation-value'),
    );
    final gesture = await tester.startGesture(tester.getCenter(colorPad));
    await gesture.moveBy(const Offset(48, -16));
    await tester.pump();

    expect(repository.updatePayloads, isEmpty);

    await gesture.up();
    await tester.pumpAndSettle();

    expect(repository.updatePayloads, isEmpty);

    await tester.ensureVisible(
      find.byKey(const ValueKey('server-role-save-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('server-role-save-button')));
    await tester.pumpAndSettle();

    expect(repository.updatePayloads, hasLength(1));
    expect(repository.updatePayloads.single, contains('color'));
  });

  testWidgets('create role buttons create and select real editable roles', (
    tester,
  ) async {
    final repository = _FakeRoleRepository(initialRoles: _roleSeeds);
    var changedRoles = const <ServerSettingsListItemSeed>[];
    await _pumpRolesTab(
      tester,
      repository: repository,
      onRolesChanged: (roles) => changedRoles = roles,
    );

    await tester.tap(
      find.byKey(const ValueKey('server-create-permission-role-button')),
    );
    await tester.pumpAndSettle();

    expect(repository.createPayloads.single, containsPair('colorOnly', false));
    expect(
      find.byKey(const ValueKey('server-role-editor-route')),
      findsOneWidget,
    );
    expect(find.text('New Access Role'), findsWidgets);

    await tester.tap(
      find.byKey(const ValueKey('server-role-editor-back-button')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('server-role-row-created-permission')),
      findsOneWidget,
    );
    expect(changedRoles.any((role) => role.id == 'created-permission'), isTrue);

    await tester.tap(
      find.byKey(const ValueKey('server-create-color-role-button')),
    );
    await tester.pumpAndSettle();

    expect(repository.createPayloads.last, containsPair('colorOnly', true));
    expect(repository.createPayloads.last, containsPair('permissions', '0'));
    expect(
      find.byKey(const ValueKey('server-role-editor-route')),
      findsOneWidget,
    );
    expect(find.text('New Name Color'), findsWidgets);

    await tester.tap(
      find.byKey(const ValueKey('server-role-editor-back-button')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('server-role-row-created-color')),
      findsOneWidget,
    );
    expect(changedRoles.any((role) => role.id == 'created-color'), isTrue);
  });
}

Future<void> _pumpRolesTab(
  WidgetTester tester, {
  required ServerSettingsRoleRepository repository,
  ValueChanged<List<ServerSettingsListItemSeed>>? onRolesChanged,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: buildVerdantTheme(),
      home: Scaffold(
        body: ServerSettingsRolesTab(
          serverId: 'server-1',
          roles: _roleSeeds,
          canManageRoles: true,
          roleRepository: repository,
          onRolesChanged: onRolesChanged,
        ),
      ),
    ),
  );
}

const _roleSeeds = [
  ServerSettingsListItemSeed(
    id: 'everyone',
    title: '@everyone',
    subtitle: 'Default access',
    permissions: 12291,
    position: 0,
  ),
  ServerSettingsListItemSeed(
    id: 'admin',
    title: 'Member',
    subtitle: 'Access role',
    trailing: '#2196f3',
    accent: Color(0xFF2196F3),
    permissions: 12291,
    position: 2,
    showAsSection: true,
    colorPriority: 7,
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
    colorPriority: 12,
  ),
];

final class _FakeRoleRepository implements ServerSettingsRoleRepository {
  _FakeRoleRepository({required List<ServerSettingsListItemSeed> initialRoles})
    : _roles = [...initialRoles];

  List<ServerSettingsListItemSeed> _roles;
  final createPayloads = <Map<String, Object?>>[];
  final updatePayloads = <Map<String, Object?>>[];

  @override
  Future<ServerSettingsListItemSeed> createRole({
    required String serverId,
    required ServerRolePatch patch,
  }) async {
    expect(serverId, 'server-1');
    final payload = patch.toJson();
    createPayloads.add(payload);
    final colorOnly = payload['colorOnly'] == true;
    final role = ServerSettingsListItemSeed(
      id: colorOnly ? 'created-color' : 'created-permission',
      title:
          payload['name'] as String? ??
          (colorOnly ? 'New Name Color' : 'New Access Role'),
      subtitle: colorOnly ? 'Name Color' : 'Access role',
      trailing: payload['color'] as String? ?? 'default',
      accent: _colorFromHex(payload['color'] as String?),
      permissions: int.tryParse(payload['permissions']?.toString() ?? '0') ?? 0,
      position: colorOnly ? 11 : 3,
      colorOnly: colorOnly,
      showAsSection: payload['showAsSection'] == true,
      colorPriority: colorOnly ? 13 : 8,
    );
    _roles = [role, ..._roles];
    return role;
  }

  @override
  Future<ServerSettingsListItemSeed> updateRole({
    required String serverId,
    required String roleId,
    required ServerRolePatch patch,
  }) async {
    expect(serverId, 'server-1');
    final payload = patch.toJson();
    updatePayloads.add(payload);
    final current = _roles.firstWhere((role) => role.id == roleId);
    final updated = _copyRole(current, payload);
    _roles = [
      for (final role in _roles)
        if (role.id == roleId) updated else role,
    ];
    return updated;
  }

  @override
  Future<void> deleteRole({
    required String serverId,
    required String roleId,
  }) async {}
}

ServerSettingsListItemSeed _copyRole(
  ServerSettingsListItemSeed role,
  Map<String, Object?> payload,
) {
  final nextColor = payload.containsKey('color')
      ? payload['color'] as String?
      : role.trailing;
  final nextColorOnly = payload['colorOnly'] as bool? ?? role.colorOnly;
  final nextPermissions = payload.containsKey('permissions')
      ? int.tryParse(payload['permissions'].toString()) ?? role.permissions
      : role.permissions;
  return ServerSettingsListItemSeed(
    id: role.id,
    title: payload['name'] as String? ?? role.title,
    subtitle: role.subtitle,
    trailing: nextColor ?? 'default',
    accent: _colorFromHex(nextColor) ?? role.accent,
    permissions: nextPermissions,
    position: payload['position'] as int? ?? role.position,
    colorOnly: nextColorOnly,
    showAsSection: payload['showAsSection'] as bool? ?? role.showAsSection,
    colorPriority: payload['colorPriority'] as int? ?? role.colorPriority,
  );
}

Color? _colorFromHex(String? value) {
  if (value == null || !RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(value)) {
    return null;
  }
  return Color(int.parse(value.substring(1), radix: 16) | 0xFF000000);
}
