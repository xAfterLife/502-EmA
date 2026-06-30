import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:min_vault/core/app_router.dart';
import 'package:min_vault/core/theme/app_theme.dart';
import 'package:min_vault/features/vaults/state/vault_cubit.dart';

void main() {
  runApp(const MinVaultApp());
}

class MinVaultApp extends StatelessWidget {
  const MinVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => VaultCubit(),
      child: MaterialApp.router(
        title: 'MinVault',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: appRouter,
      ),
    );
  }
}
