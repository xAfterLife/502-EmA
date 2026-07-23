import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:min_vault/core/di/injection.dart';
import 'package:min_vault/core/theme/app_theme.dart';
import 'package:min_vault/core/theme/theme_cubit.dart';
import 'package:min_vault/features/auth/auth_cubit.dart';
import 'package:min_vault/features/cloud/cloud_auth_cubit.dart';
import 'package:min_vault/features/cloud/cloud_auth_sheet.dart';
import 'package:min_vault/features/cloud/cloud_auth_state.dart';
import 'package:min_vault/features/cloud_backup/backup_repository.dart';
import 'package:min_vault/features/cloud_backup/cloud_sync_cubit.dart';
import 'package:min_vault/features/cloud_backup/vault_backup_info.dart';
import 'package:min_vault/features/vaults/vault_cubit.dart' show VaultCubit;
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool? _biometricEnabled;
  bool _biometricBusy = false;

  static const _deleteOriginalKey = 'delete_original_always';
  bool? _deleteOriginalAlways;

  @override
  void initState() {
    super.initState();
    context.read<AuthCubit>().isBiometricEnabled().then((enabled) {
      if (mounted) setState(() => _biometricEnabled = enabled);
    });
    var prefs = getIt<SharedPreferences>();
    if (mounted) {
      setState(() {
        _deleteOriginalAlways = prefs.getBool(_deleteOriginalKey) ?? false;
      });
    }
  }

  Future<void> _onBiometricChanged(bool value) async {
    setState(() => _biometricBusy = true);
    try {
      await context.read<AuthCubit>().setBiometricEnabled(value);
      if (mounted) setState(() => _biometricEnabled = value);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not update biometric unlock: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _biometricBusy = false);
    }
  }

  Future<void> _onDeleteOriginalChanged(bool value) async {
    final prefs = getIt<SharedPreferences>();
    await prefs.setBool(_deleteOriginalKey, value);
    if (mounted) setState(() => _deleteOriginalAlways = value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColour,
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.spM),
          children: [
            _SectionHeader('Appearance'),
            BlocBuilder<ThemeCubit, bool>(
              builder: (context, isDark) => _SettingsTile(
                icon: Icons.dark_mode_outlined,
                title: 'Dark Mode',
                trailing: Switch(
                  value: isDark,
                  activeThumbColor: AppTheme.accentColor,
                  onChanged: (v) => context.read<ThemeCubit>().toggle(v),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spL),
            _SectionHeader('Security'),
            _SettingsTile(
              icon: Icons.fingerprint,
              title: 'Biometric Unlock',
              trailing: _biometricEnabled == null
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Switch(
                      value: _biometricEnabled!,
                      activeThumbColor: AppTheme.accentColor,
                      onChanged: _biometricBusy ? null : _onBiometricChanged,
                    ),
            ),
            const SizedBox(height: AppTheme.spL),
            _SectionHeader('Import'),
            _SettingsTile(
              icon: Icons.delete_sweep_outlined,
              title: 'Delete original after import',
              trailing: _deleteOriginalAlways == null
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Switch(
                      value: _deleteOriginalAlways!,
                      activeThumbColor: AppTheme.accentColor,
                      onChanged: _onDeleteOriginalChanged,
                    ),
            ),
            const SizedBox(height: AppTheme.spL),
            _SectionHeader('Cloud Account'),
            BlocBuilder<CloudAuthCubit, CloudAuthState>(
              builder: (context, state) {
                final signedIn = state is CloudAuthSignedIn;
                final busy = state is CloudAuthLoading;
                return _SettingsTile(
                  icon: signedIn
                      ? Icons.cloud_done_outlined
                      : Icons.cloud_outlined,
                  title: signedIn ? (state).email : 'Cloud Account',
                  trailing: busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Switch(
                          value: signedIn,
                          activeThumbColor: AppTheme.accentColor,
                          onChanged: (value) {
                            if (value) {
                              showCloudAuthSheet(context);
                            } else {
                              context.read<CloudAuthCubit>().signOut();
                            }
                          },
                        ),
                );
              },
            ),
            BlocBuilder<CloudAuthCubit, CloudAuthState>(
              builder: (context, state) {
                final signedIn = state is CloudAuthSignedIn;
                if (!signedIn) {
                  return _SettingsTile(
                    icon: Icons.cloud_download_outlined,
                    title: 'Restore from Cloud',
                    trailing: Text(
                      'Sign in first',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  );
                }
                return _ActionTile(
                  icon: Icons.cloud_download_outlined,
                  title: 'Restore from Cloud',
                  onTap: () => _restoreFromCloud(context),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _restoreFromCloud(BuildContext context) async {
    final backupRepo = getIt<BackupRepository>();

    try {
      final backups = await backupRepo.listBackups();

      if (backups.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No cloud backups found'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      if (!context.mounted) return;

      final selected = await showDialog<VaultBackupInfo>(
        context: context,
        builder: (dialogContext) => Dialog(
          backgroundColor: AppTheme.surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spM),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Restore Vault',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: AppTheme.spM),
                ...backups.map(
                  (vaultBackupInfo) => InkWell(
                    borderRadius: BorderRadius.circular(AppTheme.radiusL),
                    onTap: () {
                      Navigator.pop(dialogContext, vaultBackupInfo);
                    },
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: AppTheme.spS),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spM,
                        vertical: AppTheme.spS,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundColour,
                        borderRadius: BorderRadius.circular(AppTheme.radiusL),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.folder_outlined,
                            color: AppTheme.textSecondaryColor,
                          ),
                          const SizedBox(width: AppTheme.spM),
                          Expanded(
                            child: Text(
                              vaultBackupInfo.name,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textPrimaryColor,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      if (selected == null || !context.mounted) return;

      final vaultName = await context.read<CloudSyncCubit>().restoreFromCloud(
        selected,
      );

      if (context.mounted) {
        await context.read<VaultCubit>().loadVaults();
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vault "$vaultName" restored from cloud'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restore failed: $e'),
            backgroundColor: AppTheme.dangerColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spS),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppTheme.textSecondaryColor,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.trailing,
  });

  final IconData icon;
  final String title;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spS),
      constraints: const BoxConstraints(minHeight: AppTheme.tileHeight),
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spM),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textSecondaryColor),
          const SizedBox(width: AppTheme.spM),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusL),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spS),
        constraints: const BoxConstraints(minHeight: AppTheme.tileHeight),
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spM),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.textSecondaryColor),
            const SizedBox(width: AppTheme.spM),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textSecondaryColor,
            ),
          ],
        ),
      ),
    );
  }
}
