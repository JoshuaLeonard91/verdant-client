import 'package:flutter_test/flutter_test.dart';
import 'package:verdant_flutter/features/auth/auth_models.dart';
import 'package:verdant_flutter/features/workspace/chat_workspace/chat_invite_link.dart';

void main() {
  test('extracts official and current-network invite links safely', () {
    expect(
      extractChatInviteTargets(
        'Join https://verdant.chat/invite/ABC123',
      ).single,
      const ChatInviteTarget(code: 'ABC123', apiOrigin: officialApiOrigin),
    );
    expect(
      extractChatInviteTargets(
        'Join https://api.verdant.chat/invite/ABC123',
      ).single,
      const ChatInviteTarget(code: 'ABC123', apiOrigin: officialApiOrigin),
    );
    expect(
      extractChatInviteTargets('Join /invite/CURRENT1').single,
      const ChatInviteTarget(code: 'CURRENT1'),
    );
  });

  test('builds share links for official and self-host invites', () {
    expect(
      buildChatInviteShareLink('ABC123'),
      'https://verdant.chat/invite/ABC123',
    );
    expect(
      buildChatInviteShareLink(
        'SELF123',
        apiOrigin: 'https://api.community.example',
      ),
      'https://api.community.example/invite/SELF123',
    );
  });

  test('extracts self-host and deep-link invite targets with api origin', () {
    expect(
      extractChatInviteTargets(
        'Join https://api.community.example/invite/SELF123',
      ).single,
      const ChatInviteTarget(
        code: 'SELF123',
        apiOrigin: 'https://api.community.example',
      ),
    );
    expect(
      extractChatInviteTargets(
        'verdant://invite/SELF123?api=https%3A%2F%2Fapi.community.example',
      ).single,
      const ChatInviteTarget(
        code: 'SELF123',
        apiOrigin: 'https://api.community.example',
      ),
    );
  });

  test('rejects unsafe invite links', () {
    expect(
      extractChatInviteTargets(
        'https://user:pass@api.community.example/invite/SELF123',
      ),
      isEmpty,
    );
    expect(
      extractChatInviteTargets(
        'https://api.community.example/invite/SELF123#x',
      ),
      isEmpty,
    );
    expect(
      extractChatInviteTargets('https://api.community.example/path/invite/x'),
      isEmpty,
    );
    expect(extractChatInviteTargets('just ABC123 in normal text'), isEmpty);
  });
}
