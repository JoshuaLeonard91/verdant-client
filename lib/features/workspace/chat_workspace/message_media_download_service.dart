import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';

class MessageMediaDownloadService {
  const MessageMediaDownloadService();

  Future<void> saveBytes({
    required Uint8List bytes,
    required String suggestedName,
  }) async {
    final location = await getSaveLocation(suggestedName: suggestedName);
    if (location == null) {
      return;
    }
    await File(location.path).writeAsBytes(bytes, flush: true);
  }
}

const messageMediaDownloadService = MessageMediaDownloadService();
