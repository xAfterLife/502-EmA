import 'package:flutter/material.dart';
import 'package:min_vault/core/app_router.dart';
import 'package:min_vault/core/theme/app_theme.dart';

void main() {
  runApp(const MinVaultApp());
}

class MinVaultApp extends StatelessWidget {
  const MinVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MinVault',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouter,
    );
  }
}
