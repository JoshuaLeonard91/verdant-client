String namespacedLocalStorageKey(String baseKey, String namespace) {
  final normalized = normalizeLocalStorageNamespace(namespace);
  if (normalized.isEmpty) {
    return baseKey;
  }
  return '$baseKey.profile.$normalized';
}

String normalizeLocalStorageNamespace(String namespace) {
  final trimmed = namespace.trim().toLowerCase();
  if (trimmed.isEmpty || trimmed == 'primary') {
    return '';
  }
  final normalized = trimmed.replaceAll(RegExp(r'[^a-z0-9_-]+'), '-');
  return normalized.replaceAll(RegExp(r'^-+|-+$'), '');
}
