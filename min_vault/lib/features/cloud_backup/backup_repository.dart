import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:min_vault/features/cloud_backup/vault_backup_info.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Storage layout: `backups/{userId}/{folderName}.zip`
class BackupRepository {
  BackupRepository({required this._client});

  final SupabaseClient _client;
  static const _bucketName = 'backups';

  String? get _userId => _client.auth.currentUser?.id;

  Future<Uint8List> buildExportZip(String folderName) async {
    final appDir = await getApplicationDocumentsDirectory();
    final vaultDir = Directory('${appDir.path}/vaults/$folderName');

    if (!await vaultDir.exists()) {
      throw StateError('Vault directory not found.');
    }

    final archive = Archive();

    await for (final entity in vaultDir.list()) {
      if (entity is File) {
        final fileName = entity.uri.pathSegments.last;
        final bytes = await entity.readAsBytes();
        archive.addFile(ArchiveFile(fileName, bytes.length, bytes));
      }
    }

    return Uint8List.fromList(ZipEncoder().encode(archive));
  }

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

  Future<void> updateBackup(String folderName, Uint8List zipBytes) async {
    final userId = _userId;
    if (userId == null) throw StateError('Not signed in to cloud.');

    final path = '$userId/$folderName.zip';

    // Write to temp file — Supabase upload requires a File
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/cloud_upload_$folderName.zip');
    await tempFile.writeAsBytes(zipBytes);

    try {
      await _client.storage.from(_bucketName).update(path, tempFile);
    } finally {
      if (await tempFile.exists()) await tempFile.delete();
    }
  }

  Future<Uint8List> downloadBackup(String folderName) async {
    final userId = _userId;
    if (userId == null) throw StateError('Not signed in to cloud.');

    final path = '$userId/$folderName.zip';
    return _client.storage.from(_bucketName).download(path);
  }

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

  Future<void> registerBackup({
    required String vaultId,
    required String vaultName,
  }) async {
    final userId = _userId;

    if (userId == null) {
      throw StateError('Not signed in to cloud.');
    }

    await _client.from('vault_backups').upsert({
      'user_id': userId,
      'vault_id': vaultId,
      'vault_name': vaultName,
    });
  }

  Future<void> updateBackupMetadata({
    required String vaultId,
    required String vaultName,
  }) async {
    final userId = _userId;

    if (userId == null) {
      throw StateError('Not signed in to cloud.');
    }

    await _client
        .from('vault_backups')
        .update({
          'vault_name': vaultName,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('user_id', userId)
        .eq('vault_id', vaultId);
  }

  /// Deletes a per-vault backup from Supabase Storage.
  Future<void> deleteBackup(String vaultId) async {
    final userId = _userId;

    if (userId == null) {
      throw StateError('Not signed in to cloud.');
    }

    await _client.storage.from(_bucketName).remove(['$userId/$vaultId.zip']);

    await _client
        .from('vault_backups')
        .delete()
        .eq('user_id', userId)
        .eq('vault_id', vaultId);
  }

  Future<List<VaultBackupInfo>> listBackups() async {
    final userId = _userId;

    if (userId == null) {
      throw StateError('Not signed in to cloud.');
    }

    final result = await _client
        .from('vault_backups')
        .select()
        .eq('user_id', userId)
        .order('created_at');

    return (result as List)
        .map((json) => VaultBackupInfo.fromJson(json))
        .toList();
  }

  String? _extractVaultName(String json) {
    final regex = RegExp(r'"name"\s*:\s*"([^"]*)"');
    return regex.firstMatch(json)?.group(1);
  }
}
