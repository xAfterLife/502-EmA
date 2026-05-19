import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:min_vault/features/vaults/presentation/vault_list_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/vault_list',
  routes: [
    GoRoute(path: '/vault_list', builder: (ctx, _) => const VaultListScreen()),
  ],
  debugLogDiagnostics: true, // prints navigation logs
  errorBuilder: (ctx, state) =>
      Scaffold(body: Center(child: Text('Error: ${state.error}'))),
);
