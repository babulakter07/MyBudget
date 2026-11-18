import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exception.dart';

class Attachment {
  const Attachment({
    required this.id,
    required this.profileId,
    required this.transactionId,
    required this.relativePath,
    required this.mimeType,
    required this.sizeBytes,
    required this.createdAt,
  });
  final int id;
  final int profileId;
  final int transactionId;

  /// Relative to `attachmentsDirectory()`.
  final String relativePath;
  final String mimeType;
  final int sizeBytes;
  final DateTime createdAt;
}

class AttachmentLimits {
  AttachmentLimits._();
  static const maxPerTransaction = 5;
  static const maxBytes = 10 * 1024 * 1024;
  static const countMessage = 'A transaction can have at most 5 attachments.';
  static const sizeMessage = 'Each attachment must be 10 MB or smaller.';
}

/// Picks images from camera or gallery. Wrapped so tests can inject a fake.
abstract class ImagePickerGateway {
  Future<File?> pickFromCamera();
  Future<File?> pickFromGallery();
}

/// Photos picked for a transaction that is not saved yet. The transaction
/// form passes this to `AttachmentRepository.commitPending` after saving.
class PendingAttachments extends ChangeNotifier {
  final List<File> _files = [];

  List<File> get files => List.unmodifiable(_files);
  int get length => _files.length;
  bool get isEmpty => _files.isEmpty;

  /// Validates count and size, then holds the file.
  Future<void> add(File file) async {
    if (_files.length >= AttachmentLimits.maxPerTransaction) {
      throw ValidationException(AttachmentLimits.countMessage);
    }
    if (await file.length() > AttachmentLimits.maxBytes) {
      throw ValidationException(AttachmentLimits.sizeMessage);
    }
    _files.add(file);
    notifyListeners();
  }

  void removeAt(int index) {
    _files.removeAt(index);
    notifyListeners();
  }

  void clear() {
    _files.clear();
    notifyListeners();
  }
}
