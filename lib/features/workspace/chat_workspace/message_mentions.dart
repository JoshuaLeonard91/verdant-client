import 'package:flutter/material.dart';

import '../shared/custom_expressive_asset.dart';
import '../workspace_local_id.dart';
import '../workspace_seed.dart';

final _messageMentionPattern = RegExp(
  r'@\{([^{}\r\n]+)\}|@(?:[A-Za-z0-9_:%.+-]+/[A-Za-z0-9%._~-]+|[A-Za-z0-9_:%.+-]+%2[Ff][A-Za-z0-9%._~-]+|everyone|here|[A-Za-z0-9_][A-Za-z0-9_-]{0,63})',
  caseSensitive: false,
);

typedef MessageMentionSpanBuilder =
    InlineSpan Function(MessageMentionResolution mention, TextStyle? style);

typedef MessageCustomEmojiSpanBuilder =
    InlineSpan Function(ServerCustomEmoji emoji, TextStyle? style);

typedef MessageCustomStickerSpanBuilder =
    InlineSpan Function(ServerCustomSticker sticker, TextStyle? style);

const int maxInlineStickerSpansPerMessage = 8;

List<InlineSpan> messageBodyMentionSpans({
  required String body,
  required String? networkId,
  required List<MemberSeed> members,
  required TextStyle? mentionStyle,
  MessageMentionSpanBuilder? mentionBuilder,
}) {
  return messageBodyExpressionSpans(
    body: body,
    networkId: networkId,
    members: members,
    mentionStyle: mentionStyle,
    mentionBuilder: mentionBuilder,
  );
}

List<InlineSpan> messageBodyExpressionSpans({
  required String body,
  required String? networkId,
  required List<MemberSeed> members,
  required TextStyle? mentionStyle,
  List<ServerCustomEmoji> customEmojis = const [],
  List<ServerCustomSticker> customStickers = const [],
  TextStyle? customEmojiFallbackStyle,
  TextStyle? customStickerFallbackStyle,
  MessageMentionSpanBuilder? mentionBuilder,
  MessageCustomEmojiSpanBuilder? customEmojiBuilder,
  MessageCustomStickerSpanBuilder? customStickerBuilder,
  int maxCustomStickerSpans = maxInlineStickerSpansPerMessage,
}) {
  if (body.isEmpty ||
      (!body.contains('@') &&
          ((customEmojis.isEmpty && customStickers.isEmpty) ||
              !body.contains(':')))) {
    return [TextSpan(text: body)];
  }
  final mentionMembers = normalizedMentionMembers(
    members: members,
    networkId: networkId,
  );

  final matches = <({int start, int end, InlineSpan span})>[];
  for (final match in _messageMentionPattern.allMatches(body)) {
    final token = _mentionTokenFromMatch(match);
    if (token == null) {
      continue;
    }
    final mention = resolveMessageMention(
      token: token,
      networkId: networkId,
      members: mentionMembers,
    );
    if (mention == null) {
      continue;
    }
    matches.add((
      start: match.start,
      end: match.end,
      span:
          mentionBuilder?.call(mention, mentionStyle) ??
          TextSpan(text: mention.renderText, style: mentionStyle),
    ));
  }

  final customEmojiNames = <String>{};
  if (customEmojis.isNotEmpty && body.contains(':')) {
    final customByName = <String, ServerCustomEmoji>{
      for (final emoji in customEmojis) emoji.name.toLowerCase(): emoji,
    };
    customEmojiNames.addAll(customByName.keys);
    for (final match in _customEmojiPattern.allMatches(body)) {
      final name = match.group(1)?.toLowerCase();
      final emoji = name == null ? null : customByName[name];
      if (emoji == null) {
        continue;
      }
      matches.add((
        start: match.start,
        end: match.end,
        span:
            customEmojiBuilder?.call(emoji, customEmojiFallbackStyle) ??
            TextSpan(text: emoji.shortcode, style: customEmojiFallbackStyle),
      ));
    }
  }
  if (customStickers.isNotEmpty && body.contains(':')) {
    final customByName = <String, ServerCustomSticker>{
      for (final sticker in customStickers) sticker.name.toLowerCase(): sticker,
    };
    var renderedStickerSpans = 0;
    for (final match in _customEmojiPattern.allMatches(body)) {
      final name = match.group(1)?.toLowerCase();
      if (name == null || customEmojiNames.contains(name)) {
        continue;
      }
      final sticker = customByName[name];
      if (sticker == null) {
        continue;
      }
      if (renderedStickerSpans >= maxCustomStickerSpans) {
        continue;
      }
      renderedStickerSpans += 1;
      matches.add((
        start: match.start,
        end: match.end,
        span:
            customStickerBuilder?.call(sticker, customStickerFallbackStyle) ??
            TextSpan(
              text: sticker.shortcode,
              style: customStickerFallbackStyle,
            ),
      ));
    }
  }

  if (matches.isEmpty) {
    return [TextSpan(text: body)];
  }
  matches.sort((left, right) {
    final start = left.start.compareTo(right.start);
    if (start != 0) {
      return start;
    }
    return (right.end - right.start).compareTo(left.end - left.start);
  });

  final spans = <InlineSpan>[];
  var cursor = 0;
  for (final match in matches) {
    if (match.start < cursor) {
      continue;
    }
    if (match.start > cursor) {
      spans.add(TextSpan(text: body.substring(cursor, match.start)));
    }
    spans.add(match.span);
    cursor = match.end;
  }
  if (cursor < body.length) {
    spans.add(TextSpan(text: body.substring(cursor)));
  }
  return spans;
}

final _customEmojiPattern = RegExp(r':([A-Za-z0-9_]{2,32}):');

String normalizeOutgoingMessageMentions({
  required String body,
  required String? networkId,
  required List<MemberSeed> members,
}) {
  if (body.isEmpty || !body.contains('@')) {
    return body;
  }
  final mentionMembers = normalizedMentionMembers(
    members: members,
    networkId: networkId,
  );
  return body.replaceAllMapped(_messageMentionPattern, (match) {
    final token = _mentionTokenFromMatch(match);
    if (token == null) {
      return match.group(0) ?? '';
    }
    final mention = resolveMessageMention(
      token: token,
      networkId: networkId,
      members: mentionMembers,
    );
    final localId = mention?.localUserId;
    if (localId == null || localId.isEmpty) {
      return match.group(0) ?? '';
    }
    return '@$localId';
  });
}

String? messageMentionLocalUserId(MemberSeed member, String? networkId) {
  if (!_memberBelongsToMessageNetwork(member, networkId)) {
    return null;
  }
  return _memberLocalId(member, networkId);
}

List<MemberSeed> normalizedMentionMembers({
  required List<MemberSeed> members,
  required String? networkId,
}) {
  if (members.isEmpty) {
    return const [];
  }
  final byLocalId = <String, MemberSeed>{};
  final order = <String>[];
  for (final member in members) {
    if (!_memberBelongsToMessageNetwork(member, networkId)) {
      continue;
    }
    final localId = _memberLocalId(member, networkId);
    if (localId == null) {
      continue;
    }
    final existing = byLocalId[localId];
    if (existing == null) {
      byLocalId[localId] = member;
      order.add(localId);
      continue;
    }
    byLocalId[localId] = _mergeMentionMember(existing, member, networkId);
  }

  final localIdByUsername = <String, String>{};
  for (final localId in List<String>.of(order)) {
    final member = byLocalId[localId];
    if (member == null) {
      continue;
    }
    final usernameKey = _normalizedMentionToken(member.username ?? '');
    if (usernameKey.isEmpty) {
      continue;
    }
    final existingLocalId = localIdByUsername[usernameKey];
    if (existingLocalId == null) {
      localIdByUsername[usernameKey] = localId;
      continue;
    }
    final existing = byLocalId[existingLocalId];
    if (existing == null) {
      localIdByUsername[usernameKey] = localId;
      continue;
    }
    final candidateWins = _preferMentionMember(member, existing, networkId);
    final merged = _mergeMentionMember(existing, member, networkId);
    if (candidateWins) {
      byLocalId.remove(existingLocalId);
      final oldIndex = order.indexOf(existingLocalId);
      if (oldIndex >= 0) {
        order[oldIndex] = localId;
      } else if (!order.contains(localId)) {
        order.add(localId);
      }
      localIdByUsername[usernameKey] = localId;
      byLocalId[localId] = merged;
    } else {
      byLocalId.remove(localId);
      order.remove(localId);
      byLocalId[existingLocalId] = merged;
    }
  }

  final emitted = <String>{};
  return [
    for (final localId in order)
      if (emitted.add(localId) && byLocalId[localId] != null)
        byLocalId[localId]!,
  ];
}

MessageMentionResolution? resolveMessageMention({
  required String token,
  required String? networkId,
  required List<MemberSeed> members,
}) {
  final normalizedToken = _normalizedMentionToken(token);
  if (normalizedToken.isEmpty) {
    return null;
  }
  if (normalizedToken == 'everyone' || normalizedToken == 'here') {
    return MessageMentionResolution.everyone('@$normalizedToken');
  }
  final mentionMembers = normalizedMentionMembers(
    members: members,
    networkId: networkId,
  );

  for (final member in mentionMembers) {
    if (!_memberBelongsToMessageNetwork(member, networkId)) {
      continue;
    }
    final localId = _memberLocalId(member, networkId);
    if (localId == null) {
      continue;
    }
    if (_mentionTokenMatchesMemberId(
      normalizedToken,
      member,
      localId,
      networkId,
    )) {
      return MessageMentionResolution.member(
        renderText: '@${member.name}',
        localUserId: localId,
        member: member,
      );
    }
  }

  final namedMatchesByLocalId =
      <String, ({MemberSeed member, String localId})>{};
  for (final member in mentionMembers) {
    if (!_memberBelongsToMessageNetwork(member, networkId)) {
      continue;
    }
    if (!_mentionTokenMatchesMemberName(normalizedToken, member)) {
      continue;
    }
    final localId = _memberLocalId(member, networkId);
    if (localId != null) {
      final key = _normalizedMentionToken(localId);
      final existing = namedMatchesByLocalId[key];
      if (existing == null ||
          _preferMentionMember(member, existing.member, networkId)) {
        namedMatchesByLocalId[key] = (member: member, localId: localId);
      }
    }
  }
  if (namedMatchesByLocalId.length != 1) {
    return null;
  }
  final match = namedMatchesByLocalId.values.single;
  return MessageMentionResolution.member(
    renderText: '@${match.member.name}',
    localUserId: match.localId,
    member: match.member,
  );
}

bool _preferMentionMember(
  MemberSeed candidate,
  MemberSeed existing,
  String? networkId,
) {
  final candidateScore = _mentionMemberSpecificity(candidate, networkId);
  final existingScore = _mentionMemberSpecificity(existing, networkId);
  if (candidateScore != existingScore) {
    return candidateScore > existingScore;
  }
  if (_statusLooksOffline(existing.status) &&
      !_statusLooksOffline(candidate.status)) {
    return true;
  }
  if ((existing.username == null || existing.username!.trim().isEmpty) &&
      candidate.username != null &&
      candidate.username!.trim().isNotEmpty) {
    return true;
  }
  if (existing.avatarUrl == null && candidate.avatarUrl != null) {
    return true;
  }
  if (existing.bannerUrl == null && candidate.bannerUrl != null) {
    return true;
  }
  if (existing.memberListBannerUrl == null &&
      candidate.memberListBannerUrl != null) {
    return true;
  }
  return false;
}

MemberSeed _mergeMentionMember(
  MemberSeed existing,
  MemberSeed candidate,
  String? networkId,
) {
  final preferred = _preferMentionMember(candidate, existing, networkId)
      ? candidate
      : existing;
  final fallback = identical(preferred, candidate) ? existing : candidate;
  final username =
      _nonEmptyString(preferred.username) ?? _nonEmptyString(fallback.username);
  final status = _preferredMentionStatus(preferred.status, fallback.status);
  return preferred.copyWith(
    id: preferred.id ?? fallback.id,
    name: _preferredMentionName(preferred, fallback),
    username: username,
    status: status,
    initials: _nonEmptyString(preferred.initials) ?? fallback.initials,
    role: _nonEmptyString(preferred.role) ?? fallback.role,
    roleIds: preferred.roleIds.isNotEmpty
        ? preferred.roleIds
        : fallback.roleIds,
    displayColor: preferred.displayColor ?? fallback.displayColor,
    avatarUrl: preferred.avatarUrl ?? fallback.avatarUrl,
    bannerUrl: preferred.bannerUrl ?? fallback.bannerUrl,
    bannerCrop: preferred.bannerCrop ?? fallback.bannerCrop,
    memberListBannerUrl:
        preferred.memberListBannerUrl ?? fallback.memberListBannerUrl,
    memberListBannerCrop:
        preferred.memberListBannerCrop ?? fallback.memberListBannerCrop,
    lastMessageAt: preferred.lastMessageAt ?? fallback.lastMessageAt,
    isActive: preferred.isActive || fallback.isActive,
  );
}

String _preferredMentionName(MemberSeed preferred, MemberSeed fallback) {
  final preferredName = _nonEmptyString(preferred.name);
  if (preferredName != null && !_looksLikeBackendId(preferredName)) {
    return preferredName;
  }
  final fallbackName = _nonEmptyString(fallback.name);
  if (fallbackName != null && !_looksLikeBackendId(fallbackName)) {
    return fallbackName;
  }
  return preferredName ?? fallbackName ?? preferred.name;
}

String _preferredMentionStatus(String preferred, String fallback) {
  if (_statusLooksOffline(preferred) && !_statusLooksOffline(fallback)) {
    return fallback;
  }
  return preferred;
}

String? _nonEmptyString(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}

bool _statusLooksOffline(String status) {
  return status.toLowerCase().contains('offline');
}

bool _looksLikeBackendId(String value) {
  final trimmed = value.trim();
  return RegExp(r'^[0-9]{6,}$').hasMatch(trimmed) ||
      RegExp(r'^[A-Za-z0-9_-]{12,}$').hasMatch(trimmed);
}

int _mentionMemberSpecificity(MemberSeed member, String? networkId) {
  final memberId = member.id?.trim();
  if (memberId == null || memberId.isEmpty) {
    return 0;
  }
  final target = networkId?.trim();
  final slash = memberId.indexOf('/');
  if (target != null &&
      target.isNotEmpty &&
      slash > 0 &&
      slash < memberId.length - 1 &&
      memberId.indexOf('/', slash + 1) < 0 &&
      sameWorkspaceNetworkId(memberId.substring(0, slash), target)) {
    return 2;
  }
  return 1;
}

String? _mentionTokenFromMatch(Match match) {
  final braced = match.group(1);
  if (braced != null) {
    return braced.trim();
  }
  final raw = match.group(0);
  if (raw == null || raw.length <= 1) {
    return null;
  }
  return raw.substring(1).trim();
}

bool _mentionTokenMatchesMemberId(
  String normalizedToken,
  MemberSeed member,
  String localId,
  String? networkId,
) {
  final memberId = member.id?.trim();
  if (memberId != null && memberId.isNotEmpty) {
    if (_normalizedMentionToken(memberId) == normalizedToken) {
      return true;
    }
    final scopedToken = _splitMentionScopedToken(normalizedToken);
    if (scopedToken != null) {
      if (networkId != null &&
          sameWorkspaceNetworkId(scopedToken.networkId, networkId) &&
          _normalizedMentionToken(scopedToken.localId) ==
              _normalizedMentionToken(localId)) {
        return true;
      }
    }
  }
  return normalizedToken == _normalizedMentionToken(localId);
}

({String networkId, String localId})? _splitMentionScopedToken(String token) {
  final slash = token.indexOf('/');
  if (slash > 0 && slash < token.length - 1) {
    return (
      networkId: token.substring(0, slash),
      localId: token.substring(slash + 1),
    );
  }
  final encodedSlash = token.lastIndexOf('%2f');
  if (encodedSlash > 0 && encodedSlash < token.length - 3) {
    return (
      networkId: token.substring(0, encodedSlash),
      localId: token.substring(encodedSlash + 3),
    );
  }
  return null;
}

bool _mentionTokenMatchesMemberName(String normalizedToken, MemberSeed member) {
  if (_normalizedMentionToken(member.name) == normalizedToken) {
    return true;
  }
  final username = member.username;
  return username != null &&
      _normalizedMentionToken(username) == normalizedToken;
}

bool _memberBelongsToMessageNetwork(MemberSeed member, String? networkId) {
  final target = networkId?.trim();
  if (target == null || target.isEmpty) {
    return true;
  }
  final memberId = member.id?.trim();
  if (memberId == null || memberId.isEmpty || !memberId.contains('/')) {
    return true;
  }
  final slash = memberId.indexOf('/');
  if (slash <= 0 ||
      slash == memberId.length - 1 ||
      memberId.indexOf('/', slash + 1) >= 0) {
    return false;
  }
  return sameWorkspaceNetworkId(memberId.substring(0, slash), target);
}

String? _memberLocalId(MemberSeed member, String? networkId) {
  final memberId = member.id?.trim();
  if (memberId == null || memberId.isEmpty) {
    return null;
  }
  try {
    final slash = memberId.indexOf('/');
    if (slash > 0 && slash < memberId.length - 1) {
      if (networkId != null &&
          !sameWorkspaceNetworkId(memberId.substring(0, slash), networkId)) {
        return null;
      }
      return safeWorkspaceLocalId(memberId.substring(slash + 1));
    }
    return safeWorkspaceLocalId(memberId);
  } on FormatException {
    return null;
  }
}

String _normalizedMentionToken(String value) {
  return value.trim().toLowerCase();
}

final class MessageMentionResolution {
  const MessageMentionResolution._({
    required this.renderText,
    this.localUserId,
    this.member,
  });

  factory MessageMentionResolution.member({
    required String renderText,
    required String localUserId,
    required MemberSeed member,
  }) {
    return MessageMentionResolution._(
      renderText: renderText,
      localUserId: localUserId,
      member: member,
    );
  }

  factory MessageMentionResolution.everyone(String renderText) {
    return MessageMentionResolution._(renderText: renderText);
  }

  final String renderText;
  final String? localUserId;
  final MemberSeed? member;

  String get clipboardUserId {
    final id = member?.id?.trim();
    if (id != null && id.isNotEmpty) {
      return id;
    }
    return localUserId ?? renderText;
  }
}
