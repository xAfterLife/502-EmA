import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:min_vault/features/vaults/data/vault_folder_service.dart';
import 'package:min_vault/features/vaults/domain/vault.dart';

class VaultRepository {
  VaultRepository._();
  static final VaultRepository instance = VaultRepository._();

  Future<Directory> get _vaultsDir async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/vaults');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<List<Vault>> loadVaults() async {
    final dir = await _vaultsDir;

    final futures = <Future<Vault?>>[];

    await for (final entry in dir.list()) {
      if (entry is Directory) {
        futures.add(_loadVault(entry));
      }
    }

    final result = await Future.wait(futures);
    return result.whereType<Vault>().toList();
  }

  Future<Vault?> _loadVault(Directory entry) async {
    final folderName = entry.uri.pathSegments.lastWhere((s) => s.isNotEmpty);

    try {
      final nameFuture = VaultFolderService.folderToVaultName(folderName);

      final countFuture = entry.list().length;

      final results = await Future.wait([nameFuture, countFuture]);

      return Vault(
        name: results[0] as String,
        folderName: folderName,
        itemCount: results[1] as int,
      );
    } catch (_) {
      return null;
    }
  }

  Future<Vault> createVault(String name) async {
    final folderName = await VaultFolderService.vaultNameToFolder(name);
    final dir = await _vaultsDir;
    final vaultDir = Directory('${dir.path}/$folderName');
    if (await vaultDir.exists()) {
      throw StateError('A vault with this name already exists.');
    }
    await vaultDir.create(recursive: true);
    return Vault(name: name, folderName: folderName, itemCount: 0);
  }

  Future<void> deleteVault(String folderName) async {
    final dir = await _vaultsDir;
    final vaultDir = Directory('${dir.path}/$folderName');
    if (await vaultDir.exists()) await vaultDir.delete(recursive: true);
  }
}
