import 'announcement_content_models.dart';

final class AnnouncementFeedException implements Exception {
  const AnnouncementFeedException(this.message);

  final String message;

  @override
  String toString() => message;
}

final class FeedAnnouncementRecord {
  const FeedAnnouncementRecord({
    required this.id,
    required this.feedId,
    required this.serverId,
    required this.draft,
    this.postedBy,
    this.botId,
    this.createdAt,
    this.updatedAt,
  });

  factory FeedAnnouncementRecord.fromJson(Map<String, Object?> json) {
    final id = _stringValue(json['id']).trim();
    final feedId = _stringValue(json['feedId']).trim();
    final serverId = _stringValue(json['serverId']).trim();
    final content = _mapValue(json['content']);
    if (id.isEmpty || feedId.isEmpty || serverId.isEmpty || content == null) {
      throw const FormatException('Announcement response was incomplete');
    }
    return FeedAnnouncementRecord(
      id: id,
      feedId: feedId,
      serverId: serverId,
      draft: FeedAnnouncementDraft.fromJson(content),
      postedBy: _nullableString(json['postedBy']),
      botId: _nullableString(json['botId']),
      createdAt: _nullableString(json['createdAt']),
      updatedAt: _nullableString(json['updatedAt']),
    );
  }

  final String id;
  final String feedId;
  final String serverId;
  final FeedAnnouncementDraft draft;
  final String? postedBy;
  final String? botId;
  final String? createdAt;
  final String? updatedAt;

  FeedAnnouncementRecord copyWith({
    String? id,
    String? feedId,
    String? serverId,
    FeedAnnouncementDraft? draft,
    Object? postedBy = _sentinel,
    Object? botId = _sentinel,
    Object? createdAt = _sentinel,
    Object? updatedAt = _sentinel,
  }) {
    return FeedAnnouncementRecord(
      id: id ?? this.id,
      feedId: feedId ?? this.feedId,
      serverId: serverId ?? this.serverId,
      draft: draft ?? this.draft,
      postedBy: identical(postedBy, _sentinel)
          ? this.postedBy
          : postedBy as String?,
      botId: identical(botId, _sentinel) ? this.botId : botId as String?,
      createdAt: identical(createdAt, _sentinel)
          ? this.createdAt
          : createdAt as String?,
      updatedAt: identical(updatedAt, _sentinel)
          ? this.updatedAt
          : updatedAt as String?,
    );
  }
}

abstract interface class AnnouncementFeedRepository {
  Future<List<FeedAnnouncementRecord>> listFeedAnnouncements({
    required String serverId,
    required String feedId,
    int limit = 25,
    String? beforeAnnouncementId,
  });

  Future<FeedAnnouncementRecord> createFeedAnnouncement({
    required String serverId,
    required String feedId,
    required FeedAnnouncementDraft draft,
  });

  Future<FeedAnnouncementRecord> updateFeedAnnouncement({
    required String serverId,
    required String feedId,
    required String announcementId,
    required FeedAnnouncementDraft draft,
  });

  Future<void> deleteFeedAnnouncement({
    required String serverId,
    required String feedId,
    required String announcementId,
  });
}

Map<String, Object?>? _mapValue(Object? value) {
  if (value is Map<String, Object?>) {
    return value;
  }
  if (value is Map) {
    final mapped = <String, Object?>{};
    for (final entry in value.entries) {
      final key = entry.key;
      if (key is String) {
        mapped[key] = entry.value;
      }
    }
    return mapped;
  }
  return null;
}

String _stringValue(Object? value) => value is String ? value : '';

String? _nullableString(Object? value) {
  if (value is! String) {
    return null;
  }
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

const Object _sentinel = Object();
