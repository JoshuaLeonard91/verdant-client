import 'package:flutter_test/flutter_test.dart';
import 'package:verdant_flutter/features/workspace/direct_messages_workspace/direct_messages_models.dart';
import 'package:verdant_flutter/features/workspace/direct_messages_workspace/direct_messages_store.dart';

void main() {
  test('relationship cache keeps same local user IDs isolated by network', () {
    final store = DirectMessagesStore();

    store.replaceSnapshot(
      DirectMessagesWorkspaceData.empty(
        networkId: 'official',
        currentUserName: 'Joshy',
        currentUserInitials: 'JO',
      ),
    );

    final officialFriend = _friend(
      id: 'official/42',
      networkId: 'official',
      localUserId: '42',
      displayName: 'Official Avery',
    );
    final selfHostedFriend = _friend(
      id: 'origin:https%3A%2F%2Fapi-test.pryzmapp.com/42',
      networkId: 'origin:https%3A%2F%2Fapi-test.pryzmapp.com',
      localUserId: '42',
      displayName: 'Self-host Avery',
    );

    store.upsertRelationship(officialFriend);
    final snapshot = store.upsertRelationship(selfHostedFriend);

    expect(snapshot.friends, hasLength(2));
    expect(
      snapshot.friends.map((friend) => friend.displayName),
      containsAll(<String>['Official Avery', 'Self-host Avery']),
    );
  });

  test('relationship cache updates same local user ID within one network', () {
    final store = DirectMessagesStore();

    store.replaceSnapshot(
      DirectMessagesWorkspaceData.empty(
        networkId: 'official',
        currentUserName: 'Joshy',
        currentUserInitials: 'JO',
      ),
    );

    store.upsertRelationship(
      _friend(
        id: 'official/42',
        networkId: 'official',
        localUserId: '42',
        displayName: 'Avery',
      ),
    );
    final snapshot = store.upsertRelationship(
      _friend(
        id: 'official/42-updated',
        networkId: 'official',
        localUserId: '42',
        displayName: 'Avery Updated',
      ),
    );

    expect(snapshot.friends, hasLength(1));
    expect(snapshot.friends.single.displayName, 'Avery Updated');
  });
}

FriendPreviewSeed _friend({
  required String id,
  required String networkId,
  required String localUserId,
  required String displayName,
}) {
  return FriendPreviewSeed(
    id: id,
    networkId: networkId,
    localUserId: localUserId,
    displayName: displayName,
    initials: 'AV',
    status: 'Online',
    detail: 'Friend',
    kind: FriendRelationshipKind.friend,
  );
}
