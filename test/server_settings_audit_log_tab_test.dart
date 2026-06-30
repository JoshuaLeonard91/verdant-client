import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verdant_flutter/features/workspace/server_settings_workspace/server_settings_audit_log_tab.dart';
import 'package:verdant_flutter/features/workspace/server_settings_workspace/server_settings_models.dart';
import 'package:verdant_flutter/features/workspace/server_settings_workspace/server_settings_service.dart';
import 'package:verdant_flutter/theme/verdant_theme.dart';

void main() {
  testWidgets('audit log tab renders rich events and paginates', (
    tester,
  ) async {
    final repository = _FakeAuditRepository();
    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerdantTheme(),
        home: Scaffold(
          body: ServerSettingsAuditLogTab(
            serverId: 'server-1',
            entries: const [
              ServerSettingsListItemSeed(
                id: '900',
                title: 'Moderator banned a member',
                subtitle: 'user user-2 - spam',
                trailing: '2026-06-10',
                action: 'BAN_MEMBER',
                actorId: 'user-1',
                actorUsername: 'Moderator',
                targetType: 'user',
                targetId: 'user-2',
                reason: 'spam',
                createdAt: '2026-06-10T12:00:00Z',
              ),
            ],
            auditRepository: repository,
          ),
        ),
      ),
    );

    expect(find.text('Audit Log'), findsOneWidget);
    expect(find.text('Moderator'), findsOneWidget);
    expect(find.text('Banned member'), findsOneWidget);
    expect(find.text('spam'), findsOneWidget);
    expect(find.text('2026-06-10'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('server-audit-load-more-button')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('server-audit-load-more-button')),
    );
    await tester.pumpAndSettle();

    expect(repository.beforeIds, ['900']);
    expect(find.text('Admin'), findsOneWidget);
    expect(find.text('Removed ban'), findsOneWidget);
    expect(find.text('No more audit events'), findsOneWidget);
  });
}

final class _FakeAuditRepository implements ServerSettingsAuditRepository {
  final beforeIds = <String?>[];

  @override
  Future<ServerSettingsAuditPage> listAuditEvents({
    required String serverId,
    int limit = 50,
    String? beforeEventId,
  }) async {
    expect(serverId, 'server-1');
    expect(limit, 50);
    beforeIds.add(beforeEventId);
    return const ServerSettingsAuditPage(
      hasMore: false,
      entries: [
        ServerSettingsListItemSeed(
          id: '899',
          title: 'Admin removed a ban',
          subtitle: 'user user-2',
          trailing: '2026-06-09',
          action: 'UNBAN_MEMBER',
          actorId: 'user-3',
          actorUsername: 'Admin',
          targetType: 'user',
          targetId: 'user-2',
          createdAt: '2026-06-09T12:00:00Z',
        ),
      ],
    );
  }
}
