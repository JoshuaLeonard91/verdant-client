import 'package:flutter_test/flutter_test.dart';
import 'package:verdant_flutter/features/workspace/workspace_state.dart';

void main() {
  test('copyWith preserves nullable fields unless explicitly cleared', () {
    const initial = WorkspaceState(
      error: 'failed',
      activeChannelId: 'official/channel-1',
      activeFeedId: 'official/feed-1',
      serverMessagesError: 'message failed',
      dmMessagesError: 'dm failed',
    );

    final unchanged = initial.copyWith(isLoading: false);

    expect(unchanged.error, 'failed');
    expect(unchanged.activeChannelId, 'official/channel-1');
    expect(unchanged.activeFeedId, 'official/feed-1');
    expect(unchanged.serverMessagesError, 'message failed');
    expect(unchanged.dmMessagesError, 'dm failed');

    final cleared = unchanged.copyWith(
      error: null,
      activeChannelId: null,
      activeFeedId: null,
      serverMessagesError: null,
      dmMessagesError: null,
    );

    expect(cleared.error, isNull);
    expect(cleared.activeChannelId, isNull);
    expect(cleared.activeFeedId, isNull);
    expect(cleared.serverMessagesError, isNull);
    expect(cleared.dmMessagesError, isNull);
  });
}
