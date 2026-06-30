import '../../../shared/verdant_input_sanitizer.dart';
import '../../auth/auth_models.dart';

const officialInvitePublicOrigin = 'https://verdant.chat';

final class ChatInviteTarget {
  const ChatInviteTarget({required this.code, this.apiOrigin});

  final String code;
  final String? apiOrigin;

  @override
  bool operator ==(Object other) {
    return other is ChatInviteTarget &&
        other.code == code &&
        other.apiOrigin == apiOrigin;
  }

  @override
  int get hashCode => Object.hash(code, apiOrigin);

  @override
  String toString() {
    return 'ChatInviteTarget(code: $code, apiOrigin: $apiOrigin)';
  }
}

String buildChatInviteShareLink(String code, {String? apiOrigin}) {
  final safeCode = _validInviteCode(code);
  if (safeCode == null) {
    throw const FormatException('Invalid invite code');
  }
  final normalizedOrigin = apiOrigin == null || apiOrigin.trim().isEmpty
      ? officialInvitePublicOrigin
      : normalizeBackendApiOrigin(apiOrigin);
  final publicOrigin = normalizedOrigin == officialApiOrigin
      ? officialInvitePublicOrigin
      : normalizedOrigin;
  return '$publicOrigin/invite/${Uri.encodeComponent(safeCode)}';
}

final _absoluteInviteLinkPattern = RegExp(
  r'''(?:https?://|verdant://)[^\s<>"']+''',
  caseSensitive: false,
);
final _relativeInviteLinkPattern = RegExp(
  r'''(?:^|[\s(])(/(?:invite|invites)/[A-Za-z0-9]{1,64})(?![A-Za-z0-9/])''',
  caseSensitive: false,
);

List<ChatInviteTarget> extractChatInviteTargets(String body, {int max = 5}) {
  if (body.isEmpty || max <= 0) {
    return const [];
  }
  final targets = <ChatInviteTarget>[];
  final seen = <String>{};
  void addTarget(ChatInviteTarget target) {
    final key = '${target.apiOrigin ?? ''}/${target.code}';
    if (seen.add(key)) {
      targets.add(target);
    }
  }

  for (final match in _absoluteInviteLinkPattern.allMatches(body)) {
    if (targets.length >= max) {
      break;
    }
    final target = _targetFromAbsoluteLink(_trimTrailingPunctuation(match[0]!));
    if (target != null) {
      addTarget(target);
    }
  }
  for (final match in _relativeInviteLinkPattern.allMatches(body)) {
    if (targets.length >= max) {
      break;
    }
    final target = _targetFromRelativeLink(match[1]!);
    if (target != null) {
      addTarget(target);
    }
  }
  return List.unmodifiable(targets);
}

String removeChatInviteLinksFromBody(String body) {
  if (body.isEmpty) {
    return body;
  }
  var next = body.replaceAllMapped(_absoluteInviteLinkPattern, (match) {
    final raw = _trimTrailingPunctuation(match[0]!);
    return _targetFromAbsoluteLink(raw) == null ? match[0]! : '';
  });
  next = next.replaceAllMapped(_relativeInviteLinkPattern, (match) {
    final matched = match[0]!;
    final relative = match[1]!;
    if (_targetFromRelativeLink(relative) == null) {
      return matched;
    }
    if (matched.startsWith(relative)) {
      return '';
    }
    return matched.substring(0, matched.length - relative.length);
  });
  return next.replaceAll(RegExp(r'[ \t]{2,}'), ' ').trim();
}

ChatInviteTarget? _targetFromAbsoluteLink(String raw) {
  final sanitized = sanitizeUrlInput(raw);
  final uri = Uri.tryParse(sanitized);
  if (uri == null || uri.hasFragment || uri.userInfo.isNotEmpty) {
    return null;
  }
  if (uri.scheme == 'verdant') {
    return _targetFromVerdantDeepLink(uri);
  }
  if (uri.scheme != 'https' && uri.scheme != 'http') {
    return null;
  }
  if (uri.host.isEmpty || uri.pathSegments.length != 2) {
    return null;
  }
  final first = uri.pathSegments[0].toLowerCase();
  if (first != 'invite' && first != 'invites') {
    return null;
  }
  final code = _validInviteCode(uri.pathSegments[1]);
  if (code == null) {
    return null;
  }
  final apiOrigin = _originForInviteHost(uri);
  return apiOrigin == null
      ? null
      : ChatInviteTarget(code: code, apiOrigin: apiOrigin);
}

ChatInviteTarget? _targetFromVerdantDeepLink(Uri uri) {
  if (uri.host.toLowerCase() != 'invite' || uri.pathSegments.length != 1) {
    return null;
  }
  final code = _validInviteCode(uri.pathSegments.single);
  if (code == null) {
    return null;
  }
  final api = uri.queryParameters['api'];
  if (api == null || api.trim().isEmpty) {
    return ChatInviteTarget(code: code);
  }
  try {
    return ChatInviteTarget(
      code: code,
      apiOrigin: normalizeBackendApiOrigin(api),
    );
  } on AuthException {
    return null;
  }
}

ChatInviteTarget? _targetFromRelativeLink(String raw) {
  final uri = Uri.tryParse(raw);
  if (uri == null || uri.pathSegments.length != 2) {
    return null;
  }
  final first = uri.pathSegments[0].toLowerCase();
  if (first != 'invite' && first != 'invites') {
    return null;
  }
  final code = _validInviteCode(uri.pathSegments[1]);
  return code == null ? null : ChatInviteTarget(code: code);
}

String? _originForInviteHost(Uri uri) {
  final host = uri.host.toLowerCase();
  if (host == 'verdant.chat' ||
      host == 'www.verdant.chat' ||
      host == 'api.verdant.chat') {
    return officialApiOrigin;
  }

  final scheme = uri.scheme.toLowerCase();
  if (scheme != 'https' &&
      !(scheme == 'http' &&
          (host == 'localhost' || host == '127.0.0.1' || host == '::1'))) {
    return null;
  }
  final wrappedHost = host.contains(':') && !host.startsWith('[')
      ? '[$host]'
      : host;
  final port = uri.hasPort ? ':${uri.port}' : '';
  return '$scheme://$wrappedHost$port';
}

String? _validInviteCode(String raw) {
  final code = sanitizeInviteCodeInput(raw);
  if (code.isEmpty || code.length > 64) {
    return null;
  }
  return RegExp(r'^[A-Za-z0-9]+$').hasMatch(code) ? code : null;
}

String _trimTrailingPunctuation(String raw) {
  var next = raw;
  while (next.isNotEmpty && '.,);]'.contains(next[next.length - 1])) {
    next = next.substring(0, next.length - 1);
  }
  return next;
}
