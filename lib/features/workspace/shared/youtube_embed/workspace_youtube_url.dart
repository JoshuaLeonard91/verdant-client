final RegExp workspaceYouTubeVideoIdPattern = RegExp(r'^[a-zA-Z0-9_-]{6,32}$');

String? extractWorkspaceYouTubeVideoId(String value) {
  final normalized = _normalizeWorkspaceYouTubeUrl(value);
  if (normalized == null) {
    return null;
  }
  final uri = Uri.tryParse(normalized);
  if (uri == null) {
    return null;
  }
  final host = uri.host.toLowerCase();
  if (host == 'youtu.be') {
    return cleanWorkspaceYouTubeVideoId(
      uri.pathSegments.isEmpty ? '' : uri.pathSegments[0],
    );
  }
  final isYouTubeHost =
      host == 'youtube.com' ||
      host == 'www.youtube.com' ||
      host == 'youtube-nocookie.com' ||
      host == 'www.youtube-nocookie.com';
  if (!isYouTubeHost) {
    return null;
  }
  if (uri.path == '/watch') {
    return cleanWorkspaceYouTubeVideoId(uri.queryParameters['v'] ?? '');
  }
  if (uri.pathSegments.length < 2) {
    return null;
  }
  final route = uri.pathSegments[0].toLowerCase();
  if (route == 'embed' || route == 'shorts' || route == 'live') {
    return cleanWorkspaceYouTubeVideoId(uri.pathSegments[1]);
  }
  return null;
}

String? cleanWorkspaceYouTubeVideoId(String value) {
  final trimmed = value.trim();
  if (workspaceYouTubeVideoIdPattern.hasMatch(trimmed)) {
    return trimmed;
  }
  return null;
}

String? _normalizeWorkspaceYouTubeUrl(String value) {
  final trimmed = value.trim();
  final uri = Uri.tryParse(trimmed);
  if (uri == null ||
      uri.scheme.toLowerCase() != 'https' ||
      uri.host.trim().isEmpty ||
      uri.userInfo.isNotEmpty ||
      uri.hasFragment ||
      value.contains('\u0000') ||
      value.contains('\\')) {
    return null;
  }
  return uri.toString();
}
