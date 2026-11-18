import 'dart:io';

import 'package:image_picker/image_picker.dart';

import '../domain/attachment.dart';

/// Production gateway over the `image_picker` plugin.
class PluginImagePickerGateway implements ImagePickerGateway {
  PluginImagePickerGateway([ImagePicker? picker])
    : _picker = picker ?? ImagePicker();
  final ImagePicker _picker;

  Future<File?> _pick(ImageSource source) async {
    final x = await _picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1600,
    );
    return x == null ? null : File(x.path);
  }

  @override
  Future<File?> pickFromCamera() => _pick(ImageSource.camera);

  @override
  Future<File?> pickFromGallery() => _pick(ImageSource.gallery);
}
