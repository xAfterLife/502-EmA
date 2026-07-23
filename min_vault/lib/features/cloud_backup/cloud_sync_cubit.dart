import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:min_vault/features/cloud/cloud_auth_state.dart';
import 'package:min_vault/features/cloud_backup/backup_repository.dart';
import 'package:min_vault/features/cloud_backup/cloud_sync_state.dart';
import 'package:min_vault/features/vaults/vault.dart';
import 'package:min_vault/features/vaults/vault_repository.dart';
import 'package:uuid/uuid.dart';

/// Manages per-vault cloud sync status as a map-shaped state.
///
/// Reads cloud sign-in status from the existing CloudAuthCubit.
/// Each vault's sync state (enabled, syncing, lastSyncedAt, error)
/// is tracked independently in `CloudSyncLoaded.statuses`.
class CloudSyncCubit extends Cubit<CloudSyncState> {
  CloudSyncCubit({required this._backupRepo, required this._vaultRepo})
    : super(const CloudSyncInitial());

  final BackupRepository _backupRepo;
  final VaultRepository _vaultRepo;

  /// Initializes sync status from vault metadata (cloudEnabled, lastSyncedAt).
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

  /// Enables cloud backup for a vault: builds zip, uploads, updates meta.
  Future<void> enableBackup(String folderName, CloudAuthState authState) async {
    if (authState is! CloudAuthSignedIn) {
      _updateStatus(folderName, error: 'Not signed in to cloud.');
      return;
    }

    _updateStatus(folderName, syncing: true, error: null);

    try {
      final zipBytes = await _backupRepo.buildExportZip(folderName);
      await _backupRepo.uploadBackup(folderName, zipBytes);

      final now = DateTime.now();
      await _vaultRepo.updateCloudMeta(
        folderName,
        cloudEnabled: true,
        lastSyncedAt: now,
      );

      _updateStatus(
        folderName,
        enabled: true,
        syncing: false,
        lastSyncedAt: now,
      );
    } catch (e) {
      _updateStatus(folderName, syncing: false, error: e.toString());
    }
  }

  /// Syncs (re-uploads) a vault that's already enabled.
  Future<void> syncNow(String folderName, CloudAuthState authState) async {
    if (authState is! CloudAuthSignedIn) {
      _updateStatus(folderName, error: 'Not signed in to cloud.');
      return;
    }

    _updateStatus(folderName, syncing: true, error: null);

    try {
      final zipBytes = await _backupRepo.buildExportZip(folderName);
      await _backupRepo.uploadBackup(folderName, zipBytes);

      final now = DateTime.now();
      await _vaultRepo.updateCloudMeta(
        folderName,
        cloudEnabled: true,
        lastSyncedAt: now,
      );

      _updateStatus(folderName, syncing: false, lastSyncedAt: now);
    } catch (e) {
      _updateStatus(folderName, syncing: false, error: e.toString());
    }
  }

  /// Disables cloud backup: deletes remote zip, flips flag off.
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
      // Remote delete might fail if backup doesn't exist — still flip the flag
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

  /// Restores a vault from cloud backup.
  /// Returns the new vault name.
  Future<String> restoreFromCloud(String folderName) async {
    final zipBytes = await _backupRepo.downloadBackup(folderName);
    // Use same folderName for restore (overwrite) or generate new UUID for merge
    // For safety, we generate a new folderName to avoid collision
    final newFolderName = const Uuid().v4();
    final vaultName = await _backupRepo.restoreBackup(zipBytes, newFolderName);
    return vaultName;
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
