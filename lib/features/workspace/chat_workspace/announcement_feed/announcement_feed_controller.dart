import 'package:flutter/foundation.dart';

import 'announcement_content_models.dart';
import 'announcement_feed_service.dart';

final class AnnouncementFeedController extends ChangeNotifier {
  AnnouncementFeedController({
    required AnnouncementFeedRepository repository,
    required String serverId,
    required String feedId,
  }) : this._(repository, serverId, feedId);

  AnnouncementFeedController._(this._repository, this._serverId, this._feedId);

  final AnnouncementFeedRepository _repository;
  String _serverId;
  String _feedId;
  List<FeedAnnouncementRecord> _records = const [];
  bool _isLoading = false;
  bool _isSaving = false;
  bool _hasLoaded = false;
  String? _errorMessage;

  List<FeedAnnouncementRecord> get records => _records;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get hasLoaded => _hasLoaded;
  String? get errorMessage => _errorMessage;

  void updateRoute({required String serverId, required String feedId}) {
    if (_serverId == serverId && _feedId == feedId) {
      return;
    }
    _serverId = serverId;
    _feedId = feedId;
    _records = const [];
    _hasLoaded = false;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final records = await _repository.listFeedAnnouncements(
        serverId: _serverId,
        feedId: _feedId,
      );
      _records = records.reversed.toList(growable: false);
      _hasLoaded = true;
    } catch (error) {
      _errorMessage = _messageFor(error);
      _hasLoaded = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> publish(FeedAnnouncementDraft draft) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final record = await _repository.createFeedAnnouncement(
        serverId: _serverId,
        feedId: _feedId,
        draft: draft,
      );
      _records = [..._records, record];
    } catch (error) {
      _errorMessage = _messageFor(error);
      rethrow;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> update({
    required String announcementId,
    required FeedAnnouncementDraft draft,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final record = await _repository.updateFeedAnnouncement(
        serverId: _serverId,
        feedId: _feedId,
        announcementId: announcementId,
        draft: draft,
      );
      _records = [
        for (final existing in _records)
          if (existing.id == announcementId) record else existing,
      ];
    } catch (error) {
      _errorMessage = _messageFor(error);
      rethrow;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> delete(String announcementId) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.deleteFeedAnnouncement(
        serverId: _serverId,
        feedId: _feedId,
        announcementId: announcementId,
      );
      _records = [
        for (final record in _records)
          if (record.id != announcementId) record,
      ];
    } catch (error) {
      _errorMessage = _messageFor(error);
      rethrow;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}

String _messageFor(Object error) {
  return switch (error) {
    AnnouncementFeedException(:final message) => message,
    _ => 'Could not load announcements',
  };
}
