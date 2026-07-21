import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:min_vault/features/vaults/vault.dart';
import 'package:uuid/uuid.dart';

class VaultRepository {
  VaultRepository();

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

    final metaFile = File('${entry.path}/meta.json');
    if (await metaFile.exists()) {
      final content = await metaFile.readAsString();
      final meta = json.decode(content) as Map<String, dynamic>;
      final count = await entry
          .list()
          .where((e) => e is File && e.path.endsWith('.crypt'))
          .length;
      return Vault(
        name: meta['name'] as String? ?? folderName,
        folderName: folderName,
        itemCount: count,
      );
    } else {
      return null;
    }
  }

  Future<Vault> createVault(String name, {required String id}) async {
    final folderName = Uuid().v4();
    final dir = await _vaultsDir;
    final vaultDir = Directory('${dir.path}/$folderName');

    if (await vaultDir.exists()) {
      throw StateError('A vault with this name already exists.');
    }
    await vaultDir.create(recursive: true);

    final meta = {
      'name': name,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    };
    final metaFile = File('${vaultDir.path}/meta.json');
    await metaFile.writeAsString(json.encode(meta));

    return Vault(name: name, folderName: folderName, itemCount: 0);
  }

  Future<void> deleteVault(String folderName) async {
    final dir = await _vaultsDir;
    final vaultDir = Directory('${dir.path}/$folderName');
    if (await vaultDir.exists()) await vaultDir.delete(recursive: true);
  }
}
