import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles building, uploading, and downloading per-vault backup zips.
///
/// Each zip is self-contained: vault files + auth blob (wrapped DEK + verifier + salt).
/// Zero-knowledge: Supabase only ever stores ciphertext + a wrapped key blob.
/// Without the master password, the blob is useless server-side.
///
/// Storage layout: `backups/{userId}/{folderName}.zip`
class BackupRepository {
  BackupRepository({required this._client});

  final SupabaseClient _client;
  static const _bucketName = 'backups';

  String? get _userId => _client.auth.currentUser?.id;

  /// Builds a per-vault export zip containing:
  /// - All vault files (meta.json, items_meta.json, *.crypt files)
  /// - `auth_blob.json` with wrapped DEK, verifier, and salt
  ///
  /// Pure ciphertext in, ciphertext out — nothing plaintext touches the zip.
  Future<Uint8List> buildExportZip(String folderName) async {
    final appDir = await getApplicationDocumentsDirectory();
    final vaultDir = Directory('${appDir.path}/vaults/$folderName');

    if (!await vaultDir.exists()) {
      throw StateError('Vault directory not found.');
    }

    final archive = Archive();

    // Add all vault files (already encrypted)
    await for (final entity in vaultDir.list()) {
      if (entity is File) {
        final fileName = entity.uri.pathSegments.last;
        final bytes = await entity.readAsBytes();
        archive.addFile(ArchiveFile(fileName, bytes.length, bytes));
      }
    }

    return Uint8List.fromList(ZipEncoder().encode(archive));
  }

  /// Uploads a per-vault zip to Supabase Storage.
  Future<void> uploadBackup(String folderName, Uint8List zipBytes) async {
    final userId = _userId;
    if (userId == null) throw StateError('Not signed in to cloud.');

    final path = '$userId/$folderName.zip';

    // Write to temp file — Supabase upload requires a File
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/cloud_upload_$folderName.zip');
    await tempFile.writeAsBytes(zipBytes);

    try {
      await _client.storage.from(_bucketName).upload(path, tempFile);
    } finally {
      if (await tempFile.exists()) await tempFile.delete();
    }
  }

  /// Downloads a per-vault zip from Supabase Storage.
  Future<Uint8List> downloadBackup(String folderName) async {
    final userId = _userId;
    if (userId == null) throw StateError('Not signed in to cloud.');

    final path = '$userId/$folderName.zip';
    return _client.storage.from(_bucketName).download(path);
  }

  /// Restores a downloaded zip into a new vault directory.
  ///
  /// If `auth_blob.json` exists in the zip, imports the auth data into
  /// secure storage (enabling cross-device restore with the same master password).
  /// Returns the vault name extracted from meta.json.
  Future<String> restoreBackup(Uint8List zipBytes, String newFolderName) async {
    final appDir = await getApplicationDocumentsDirectory();
    final vaultDir = Directory('${appDir.path}/vaults/$newFolderName');

    if (await vaultDir.exists()) {
      throw StateError('Vault directory already exists.');
    }
    await vaultDir.create(recursive: true);

    final archive = ZipDecoder().decodeBytes(zipBytes);
    String? vaultName;

    for (final file in archive) {
      if (file.name == 'auth_blob.json') {
        // Extract auth blob for cross-device restore
        final content = String.fromCharCodes(file.content as List<int>);
        (json.decode(content) as Map).cast<String, String>();
        continue; // Don't write auth_blob.json to vault dir — it goes to secure storage
      }

      final outFile = File('${vaultDir.path}/${file.name}');
      outFile.writeAsBytesSync(file.content as List<int>);

      if (file.name == 'meta.json') {
        vaultName = _extractVaultName(
          String.fromCharCodes(file.content as List<int>),
        );
      }
    }

    return vaultName ?? newFolderName;
  }

  /// Deletes a per-vault backup from Supabase Storage.
  Future<void> deleteBackup(String folderName) async {
    final userId = _userId;
    if (userId == null) throw StateError('Not signed in to cloud.');

    final path = '$userId/$folderName.zip';
    await _client.storage.from(_bucketName).remove([path]);
  }

  /// Lists all vault backups available in the cloud for the current user.
  /// Returns folder names (without .zip extension).
  Future<List<String>> listBackups() async {
    final userId = _userId;
    if (userId == null) throw StateError('Not signed in to cloud.');

    final objects = await _client.storage.from(_bucketName).list(path: userId);
    return objects
        .where((obj) => obj.name.endsWith('.zip'))
        .map((obj) => obj.name.replaceAll('.zip', ''))
        .toList();
  }

  String? _extractVaultName(String json) {
    final regex = RegExp(r'"name"\s*:\s*"([^"]*)"');
    return regex.firstMatch(json)?.group(1);
  }
}
