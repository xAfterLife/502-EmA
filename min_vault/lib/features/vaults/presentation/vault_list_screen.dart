import 'package:flutter/material.dart';
import 'package:min_vault/core/theme/app_theme.dart';
import 'package:min_vault/features/vaults/domain/vault.dart';

class VaultListScreen extends StatelessWidget {
  const VaultListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vaults = [
      Vault(id: '1', name: 'Privat', itemCount: 12),
      Vault(id: '2', name: 'Arbeit', itemCount: 31),
      Vault(id: '3', name: 'Finanzen', itemCount: 7),
    ];

    return Scaffold(
      backgroundColor: AppTheme.backgroundColour,

      appBar: AppBar(
        title: const Text(
          'Meine Vaults',
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.settings_outlined,
            ),
          ),
        ],
      ),

      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(AppTheme.spM),
              itemCount: vaults.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final vault = vaults[index];

                return Container(
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
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimaryColor,
                              ),
                            ),

                            const SizedBox(height: 4),

                            Text(
                              '${vault.itemCount} Items',
                              style: const TextStyle(
                                fontSize: 13,
                                //color: AppTheme.textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),

                      IconButton(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.delete_forever_rounded,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(AppTheme.spM),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  _showNewVaultSheet(context);
                },
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  minimumSize: const Size.fromHeight(56),
                  backgroundColor: AppTheme.accentColor,
                  foregroundColor: AppTheme.surfaceColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusL),
                  ),
                ),
                icon: const Icon(Icons.add_rounded),
                label: const Text(
                  'Neues Vault',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showNewVaultSheet(BuildContext context) {
    final controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXL),
        ),
      ),
      builder: (context) {
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

              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Neues Vault',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Vault-Name',
                  prefixIcon: const Icon(Icons.folder_outlined),
                  filled: true,
                  fillColor: AppTheme.surfaceColor,
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
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    minimumSize: const Size.fromHeight(54),
                    backgroundColor: AppTheme.accentColor,
                    foregroundColor: AppTheme.surfaceColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusL),
                    ),
                  ),
                  child: const Text('Erstellen'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
