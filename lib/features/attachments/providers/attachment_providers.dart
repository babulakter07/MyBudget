import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/core_providers.dart';
import '../data/attachment_repository.dart';
import '../data/image_picker_gateway.dart';
import '../domain/attachment.dart';

final attachmentRepositoryProvider = Provider<AttachmentRepository>(
  (ref) => AttachmentRepository(ref.watch(appDatabaseProvider)),
);

/// Override in tests with a fake.
final imagePickerGatewayProvider = Provider<ImagePickerGateway>(
  (ref) => PluginImagePickerGateway(),
);

final attachmentsForTransactionProvider =
    StreamProvider.family<List<Attachment>, int>((ref, txnId) {
      final pid = ref.watch(activeProfileIdProvider);
      if (pid == null) return Stream.value(const []);
      return ref
          .watch(attachmentRepositoryProvider)
          .watchForTransaction(pid, txnId);
    });
