import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:min_vault/core/theme/app_theme.dart';
import 'package:min_vault/core/ui/bottom_sheet_helper.dart';
import 'package:min_vault/features/vaults/vault.dart';
import 'package:min_vault/features/vaults/vault_cubit.dart';
import 'package:min_vault/features/vaults/vault_state.dart';

class VaultListScreen extends StatefulWidget {
  const VaultListScreen({super.key});

  @override
  State<VaultListScreen> createState() => _VaultListScreenState();
}

class _VaultListScreenState extends State<VaultListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<VaultCubit>().loadVaults();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColour,
      appBar: AppBar(
        title: const Text('My Vaults'),
        actions: [
          IconButton(
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: BlocBuilder<VaultCubit, VaultState>(
                builder: (context, state) => switch (state) {
                  VaultInitial() => const SizedBox.shrink(),
                  VaultLoading() => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  VaultError(:final message) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spM),
                      child: Text(
                        message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppTheme.dangerColor),
                      ),
                    ),
                  ),
                  VaultLoaded(:final vaults) =>
                    vaults.isEmpty ? _EmptyState() : _VaultList(vaults: vaults),
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppTheme.spM),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showNewVaultSheet(context),
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    minimumSize: const Size.fromHeight(56),
                    backgroundColor: AppTheme.accentColor,
                    foregroundColor: AppTheme.onAccentColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusL),
                    ),
                  ),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text(
                    'New Vault',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNewVaultSheet(BuildContext context) {
    final cubit = context.read<VaultCubit>();
    showSafeBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) =>
          _NewVaultSheet(onConfirm: (name) => cubit.createVault(name)),
    );
  }
}

class _VaultList extends StatelessWidget {
  const _VaultList({required this.vaults});
  final List<Vault> vaults;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppTheme.spM),
      itemCount: vaults.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _VaultCard(vault: vaults[index]),
    );
  }
}

class _VaultCard extends StatelessWidget {
  const _VaultCard({required this.vault});
  final Vault vault;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radiusL),
      onTap: () async {
        await context.push('/vault_detail', extra: vault);
        if (context.mounted) context.read<VaultCubit>().loadVaults();
      },
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spM),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.accentLightColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
              child: const Icon(
                Icons.folder_outlined,
                color: AppTheme.accentColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vault.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${vault.itemCount} Items',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _confirmDelete(context),
              icon: Icon(
                Icons.delete_forever_rounded,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Vault'),
        content: Text(
          'Delete "${vault.name}"?\nAll contents will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textPrimaryColor),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<VaultCubit>().deleteVault(vault.folderName);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppTheme.dangerColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.folder_open_outlined,
            size: 64,
            color: AppTheme.textSecondaryColor,
          ),
          SizedBox(height: 16),
          Text(
            'No vaults yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Tap "New Vault" to get started.',
            style: TextStyle(color: AppTheme.textSecondaryColor),
          ),
        ],
      ),
    );
  }
}

class _NewVaultSheet extends StatefulWidget {
  const _NewVaultSheet({required this.onConfirm});
  final Future<void> Function(String name) onConfirm;

  @override
  State<_NewVaultSheet> createState() => _NewVaultSheetState();
}

class _NewVaultSheetState extends State<_NewVaultSheet> {
  final _controller = TextEditingController();
  bool _isCreating = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Vault name cannot be empty.');
      return;
    }
    setState(() {
      _isCreating = true;
      _error = null;
    });
    try {
      await widget.onConfirm(name);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isCreating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppTheme.spM,
        AppTheme.spL,
        AppTheme.spM,
        AppTheme.spM + bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.borderColor,
              borderRadius: BorderRadius.circular(AppTheme.radiusXL),
            ),
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'New Vault',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            style: TextStyle(color: AppTheme.textPrimaryColor),
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              hintText: 'Vault Name',
              errorText: _error,
              prefixIcon: const Icon(Icons.folder_outlined),
              filled: true,
              fillColor: AppTheme.backgroundColour,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusL),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isCreating ? null : _submit,
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
              child: _isCreating
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.onAccentColor,
                      ),
                    )
                  : const Text(
                      'Create Vault',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
