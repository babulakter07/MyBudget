import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A folder the user granted the app lasting access to.
class PickedFolder {
  const PickedFolder({required this.uri, required this.name});
  final String uri;
  final String name;
}

/// Platform access needed by the folder backup: a user-chosen folder and a
/// secret store for the backup password. Faked in tests.
abstract interface class BackupFolderGateway {
  /// Opens the system folder picker; null when the user cancels.
  Future<PickedFolder?> pickFolder();

  /// File names directly inside [folderUri].
  Future<List<String>> listFiles(String folderUri);

  /// Copies the local file at [sourcePath] into [folderUri] as [name].
  Future<void> writeFile(String folderUri, String name, String sourcePath);

  Future<void> deleteFile(String folderUri, String name);

  /// Gives up the lasting permission for [folderUri].
  Future<void> releaseFolder(String folderUri);

  Future<void> saveSecret(String value);
  Future<String?> readSecret();
  Future<void> clearSecret();
}

/// Android implementation (see `BackupFolderChannel.kt`): Storage Access
/// Framework for the folder, Android Keystore for the password.
class ChannelBackupFolderGateway implements BackupFolderGateway {
  const ChannelBackupFolderGateway();

  static const _channel = MethodChannel('mybudget/backup_folder');

  @override
  Future<PickedFolder?> pickFolder() async {
    final r = await _channel.invokeMapMethod<String, String>('pickFolder');
    if (r == null) return null;
    return PickedFolder(uri: r['uri']!, name: r['name']!);
  }

  @override
  Future<List<String>> listFiles(String folderUri) async =>
      await _channel.invokeListMethod<String>('listFiles', {
        'folder': folderUri,
      }) ??
      const [];

  @override
  Future<void> writeFile(String folderUri, String name, String sourcePath) =>
      _channel.invokeMethod<void>('writeFile', {
        'folder': folderUri,
        'name': name,
        'source': sourcePath,
      });

  @override
  Future<void> deleteFile(String folderUri, String name) => _channel
      .invokeMethod<void>('deleteFile', {'folder': folderUri, 'name': name});

  @override
  Future<void> releaseFolder(String folderUri) =>
      _channel.invokeMethod<void>('releaseFolder', {'folder': folderUri});

  @override
  Future<void> saveSecret(String value) =>
      _channel.invokeMethod<void>('saveSecret', {'value': value});

  @override
  Future<String?> readSecret() => _channel.invokeMethod<String>('readSecret');

  @override
  Future<void> clearSecret() => _channel.invokeMethod<void>('clearSecret');
}

final backupFolderGatewayProvider = Provider<BackupFolderGateway>(
  (ref) => const ChannelBackupFolderGateway(),
);
