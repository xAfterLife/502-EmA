import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:min_vault/features/cloud/cloud_auth_state.dart';
import 'package:min_vault/features/cloud_backup/backup_repository.dart';
import 'package:min_vault/features/cloud_backup/cloud_sync_state.dart';
import 'package:min_vault/features/cloud_backup/vault_backup_info.dart';
import 'package:min_vault/features/vaults/vault.dart';
import 'package:min_vault/features/vaults/vault_repository.dart';

class CloudSyncCubit extends Cubit<CloudSyncState> {
  CloudSyncCubit({required this._backupRepo, required this._vaultRepo})
    : super(const CloudSyncInitial());

  final BackupRepository _backupRepo;
  final VaultRepository _vaultRepo;

  Future<void> loadStatuses(List<Vault> vaults) async {
    final statuses = <String, VaultCloudStatus>{};
    for (final vault in vaults) {
      statuses[vault.folderName] = VaultCloudStatus(
        enabled: vault.cloudEnabled,
        lastSyncedAt: vault.lastSyncedAt,
      );
    }
    emit(CloudSyncLoaded(statuses));
  }

  Future<void> enableBackup(Vault vault, CloudAuthState authState) async {
    if (authState is! CloudAuthSignedIn) {
      _updateStatus(vault.folderName, error: 'Not signed in to cloud.');
      return;
    }

    _updateStatus(vault.folderName, syncing: true, error: null);

    try {
      final zipBytes = await _backupRepo.buildExportZip(vault.folderName);
      await _backupRepo.uploadBackup(vault.folderName, zipBytes);

      await _backupRepo.registerBackup(
        vaultId: vault.folderName,
        vaultName: vault.name,
      );

      final now = DateTime.now();
      await _vaultRepo.updateCloudMeta(
        vault.folderName,
        cloudEnabled: true,
        lastSyncedAt: now,
      );

      _updateStatus(
        vault.folderName,
        enabled: true,
        syncing: false,
        lastSyncedAt: now,
      );
    } catch (e) {
      _updateStatus(vault.folderName, syncing: false, error: e.toString());
    }
  }

  Future<void> syncNow(Vault vault, CloudAuthState authState) async {
    if (authState is! CloudAuthSignedIn) {
      _updateStatus(vault.folderName, error: 'Not signed in to cloud.');
      return;
    }

    _updateStatus(vault.folderName, syncing: true, error: null);

    try {
      final zipBytes = await _backupRepo.buildExportZip(vault.folderName);
      await _backupRepo.updateBackup(vault.folderName, zipBytes);

      await _backupRepo.updateBackupMetadata(
        vaultId: vault.folderName,
        vaultName: vault.name,
      );

      final now = DateTime.now();
      await _vaultRepo.updateCloudMeta(
        vault.folderName,
        cloudEnabled: true,
        lastSyncedAt: now,
      );

      _updateStatus(vault.folderName, syncing: false, lastSyncedAt: now);
    } catch (e) {
      _updateStatus(vault.folderName, syncing: false, error: e.toString());
    }
  }

  Future<void> disableBackup(String folderName) async {
    _updateStatus(folderName, syncing: true, error: null);

    try {
      await _backupRepo.deleteBackup(folderName);
      await _vaultRepo.updateCloudMeta(folderName, cloudEnabled: false);

      _updateStatus(
        folderName,
        enabled: false,
        syncing: false,
        lastSyncedAt: null,
      );
    } catch (e) {
      await _vaultRepo.updateCloudMeta(folderName, cloudEnabled: false);
      _updateStatus(
        folderName,
        enabled: false,
        syncing: false,
        lastSyncedAt: null,
        error: e.toString(),
      );
    }
  }

  Future<String> restoreFromCloud(VaultBackupInfo backup) async {
    try {
      final zipBytes = await _backupRepo.downloadBackup(backup.id);

      final vaultName = await _backupRepo.restoreBackup(zipBytes, backup.id);

      await _vaultRepo.updateCloudMeta(
        backup.id,
        cloudEnabled: true,
        lastSyncedAt: backup.updatedAt,
      );

      _updateStatus(
        backup.id,
        enabled: true,
        syncing: false,
        lastSyncedAt: backup.updatedAt,
      );

      return vaultName;
    } catch (e) {
      throw StateError('Cloud restore failed: $e');
    }
  }

  void _updateStatus(
    String folderName, {
    bool? enabled,
    bool? syncing,
    DateTime? lastSyncedAt,
    String? error,
  }) {
    final state = this.state;
    if (state is! CloudSyncLoaded) return;

    final current = state.forVault(folderName);
    final updated = current.copyWith(
      enabled: enabled,
      syncing: syncing,
      lastSyncedAt: lastSyncedAt,
      error: error,
    );

    emit(CloudSyncLoaded({...state.statuses, folderName: updated}));
  }
}
