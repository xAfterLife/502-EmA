import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:min_vault/core/theme/app_theme.dart';
import 'package:min_vault/features/cloud/cloud_auth_cubit.dart';
import 'package:min_vault/features/cloud/cloud_auth_sheet.dart';
import 'package:min_vault/features/cloud/cloud_auth_state.dart';
import 'package:min_vault/features/cloud_backup/cloud_sync_cubit.dart';
import 'package:min_vault/features/cloud_backup/cloud_sync_state.dart';
import 'package:min_vault/features/vaults/vault.dart';
import 'package:min_vault/features/vaults/vault_cubit.dart';

void showCloudSheet(BuildContext context, Vault vault) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.surfaceColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppTheme.radiusXL),
      ),
    ),
    builder: (_) => _CloudSheet(vault: vault),
  );
}

class _CloudSheet extends StatelessWidget {
  const _CloudSheet({required this.vault});
  final Vault vault;

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final authState = context.watch<CloudAuthCubit>().state;
    final syncState = context.watch<CloudSyncCubit>().state;

    final signedIn = authState is CloudAuthSignedIn;
    final status = syncState is CloudSyncLoaded
        ? syncState.forVault(vault.folderName)
        : const VaultCloudStatus();

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppTheme.spL,
        AppTheme.spL,
        AppTheme.spL,
        AppTheme.spL + safeBottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.borderColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusXL),
              ),
            ),
          ),
          const SizedBox(height: 24),

          if (!signedIn)
            _NotSignedInSection()
          else if (!status.enabled)
            _EnableSection(vault: vault, status: status)
          else
            _EnabledSection(vault: vault, status: status),
        ],
      ),
    );
  }
}

class _NotSignedInSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Sign in to enable per-vault cloud backup.\n'
          'Your master password never leaves this device.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textSecondaryColor),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              showCloudAuthSheet(context);
            },
            style: ElevatedButton.styleFrom(
              elevation: 0,
              minimumSize: const Size.fromHeight(54),
              backgroundColor: AppTheme.accentColor,
              foregroundColor: AppTheme.onAccentColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusL),
              ),
            ),
            icon: const Icon(Icons.cloud_outlined),
            label: const Text(
              'Sign In to Cloud',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}

class _EnableSection extends StatelessWidget {
  const _EnableSection({required this.vault, required this.status});
  final Vault vault;
  final VaultCloudStatus status;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (status.error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              status.error!,
              style: const TextStyle(color: AppTheme.dangerColor),
            ),
          ),
        SwitchListTile(
          value: false,
          onChanged: (_) {
            context.read<CloudSyncCubit>().enableBackup(
              vault,
              context.read<CloudAuthCubit>().state,
            );
          },
          title: const Text('Back up this vault'),
          subtitle: const Text(
            'Upload encrypted vault data to cloud.\n'
            'Zero-knowledge: server only sees ciphertext.',
          ),
          activeThumbColor: AppTheme.accentColor,
        ),
      ],
    );
  }
}

class _EnabledSection extends StatelessWidget {
  const _EnabledSection({required this.vault, required this.status});
  final Vault vault;
  final VaultCloudStatus status;

  @override
  Widget build(BuildContext context) {
    final lastSynced = status.lastSyncedAt;
    final syncing = status.syncing;

    return Column(
      children: [
        if (status.error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              status.error!,
              style: const TextStyle(color: AppTheme.dangerColor),
            ),
          ),
        Container(
          padding: const EdgeInsets.all(AppTheme.spM),
          decoration: BoxDecoration(
            color: AppTheme.accentLightColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
          ),
          child: Row(
            children: [
              Icon(Icons.cloud_done_rounded, color: AppTheme.accentColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cloud backup enabled',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.accentColor,
                      ),
                    ),
                    if (lastSynced != null)
                      Text(
                        'Last synced: ${_formatDate(lastSynced)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: syncing
                ? null
                : () {
                    context.read<CloudSyncCubit>().syncNow(
                      vault,
                      context.read<CloudAuthCubit>().state,
                    );
                  },
            style: ElevatedButton.styleFrom(
              elevation: 0,
              minimumSize: const Size.fromHeight(54),
              backgroundColor: AppTheme.accentColor,
              foregroundColor: AppTheme.onAccentColor,
              disabledBackgroundColor: AppTheme.accentColor.withValues(
                alpha: 0.6,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusL),
              ),
            ),
            icon: syncing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.sync_rounded),
            label: Text(
              syncing ? 'Syncing...' : 'Sync Now',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () {
            context.read<CloudSyncCubit>().disableBackup(vault.folderName);
            // Also refresh vault list to update the cloudEnabled flag
            context.read<VaultCubit>().loadVaults();
          },
          icon: Icon(Icons.cloud_off_outlined, color: AppTheme.dangerColor),
          label: const Text(
            'Remove from Cloud',
            style: TextStyle(color: AppTheme.dangerColor),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    return '${local.day}.${local.month}.${local.year} ${local.hour}:${local.minute.toString().padLeft(2, '0')}';
  }
}
