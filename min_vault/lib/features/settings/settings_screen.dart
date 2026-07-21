import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:min_vault/core/theme/app_theme.dart';
import 'package:min_vault/core/theme/theme_cubit.dart';
import 'package:min_vault/features/auth/auth_cubit.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool? _biometricEnabled;
  bool _biometricBusy = false;

  @override
  void initState() {
    super.initState();
    context.read<AuthCubit>().isBiometricEnabled().then((enabled) {
      if (mounted) setState(() => _biometricEnabled = enabled);
    });
  }

  Future<void> _onBiometricChanged(bool value) async {
    setState(() => _biometricBusy = true);
    try {
      await context.read<AuthCubit>().setBiometricEnabled(value);
      if (mounted) setState(() => _biometricEnabled = value);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update biometric unlock: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _biometricBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColour,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
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
          // Cloud Account section slots in here later.
        ],
      ),
    );
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spM,
        vertical: AppTheme.spS,
      ),
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
