import '../shared/local_storage_namespace.dart';

final class VerdantAppProfile {
  const VerdantAppProfile._({
    required this.id,
    required this.windowTitle,
    required this.credentialKeyPrefix,
    required this.storageNamespace,
    this.titleBarBadgeLabel,
  });

  static const primary = VerdantAppProfile._(
    id: 'primary',
    windowTitle: 'Verdant',
    credentialKeyPrefix: 'verdant.flutter.auth.v1',
    storageNamespace: '',
  );

  static const secondary = VerdantAppProfile._(
    id: 'secondary',
    windowTitle: 'Verdant - Secondary Test Client',
    credentialKeyPrefix: 'verdant.flutter.auth.v1.profile.secondary',
    storageNamespace: 'secondary',
    titleBarBadgeLabel: 'Secondary Test Client',
  );

  final String id;
  final String windowTitle;
  final String credentialKeyPrefix;
  final String storageNamespace;
  final String? titleBarBadgeLabel;

  bool get isPrimary => id == primary.id;

  static VerdantAppProfile fromArgs(List<String> args) {
    final rawProfile = _profileArgValue(args);
    if (rawProfile == null || rawProfile.trim().isEmpty) {
      return primary;
    }
    final normalized = normalizeLocalStorageNamespace(rawProfile);
    return switch (normalized) {
      '' || 'primary' => primary,
      'secondary' || 'test' || 'isolated' => secondary,
      _ => throw ArgumentError.value(
        rawProfile,
        'profile',
        'Supported Verdant Flutter profiles are primary and secondary.',
      ),
    };
  }

  static String? _profileArgValue(List<String> args) {
    for (var index = 0; index < args.length; index += 1) {
      final arg = args[index].trim();
      if (arg == '--secondary') {
        return 'secondary';
      }
      if (arg.startsWith('--verdant-profile=')) {
        return arg.substring('--verdant-profile='.length);
      }
      if (arg == '--verdant-profile' && index + 1 < args.length) {
        return args[index + 1];
      }
    }
    return const String.fromEnvironment('VERDANT_FLUTTER_PROFILE');
  }
}
