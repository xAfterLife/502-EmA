import 'package:equatable/equatable.dart';

/// Per-vault cloud sync status.
class VaultCloudStatus extends Equatable {
  const VaultCloudStatus({
    this.enabled = false,
    this.syncing = false,
    this.lastSyncedAt,
    this.error,
  });

  final bool enabled;
  final bool syncing;
  final DateTime? lastSyncedAt;
  final String? error;

  VaultCloudStatus copyWith({
    bool? enabled,
    bool? syncing,
    DateTime? lastSyncedAt,
    String? error,
  }) => VaultCloudStatus(
    enabled: enabled ?? this.enabled,
    syncing: syncing ?? this.syncing,
    lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    error: error,
  );

  @override
  List<Object?> get props => [enabled, syncing, lastSyncedAt, error];
}

sealed class CloudSyncState extends Equatable {
  const CloudSyncState();
}

final class CloudSyncInitial extends CloudSyncState {
  const CloudSyncInitial();
  @override
  List<Object?> get props => [];
}

final class CloudSyncLoaded extends CloudSyncState {
  const CloudSyncLoaded(this.statuses);
  final Map<String, VaultCloudStatus> statuses;

  /// Convenience: get status for a specific vault folderName.
  VaultCloudStatus forVault(String folderName) =>
      statuses[folderName] ?? const VaultCloudStatus();

  @override
  List<Object?> get props => [statuses];
}

final class CloudSyncError extends CloudSyncState {
  const CloudSyncError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
