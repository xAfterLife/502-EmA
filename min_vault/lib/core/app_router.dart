import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:min_vault/features/auth/auth_cubit.dart';
import 'package:min_vault/features/auth/auth_state.dart';
import 'package:min_vault/features/vault_items/vault_detail_screen.dart';
import 'package:min_vault/features/vaults/vault.dart';
import 'package:min_vault/features/vaults/vault_list_screen.dart';
import 'package:min_vault/features/auth/setup_screen.dart';
import 'package:min_vault/features/auth/unlock_screen.dart';

late final GoRouter appRouter;

class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier(AuthCubit authCubit) {
    _sub = authCubit.stream.listen((_) => notifyListeners());
  }
  late final StreamSubscription _sub;
  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

GoRouter _createRouter(AuthCubit authCubit) {
  return GoRouter(
    refreshListenable: _AuthChangeNotifier(authCubit),
    initialLocation: '/auth',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final authState = authCubit.state;
      final isAuthRoute =
          state.matchedLocation == '/auth' || state.matchedLocation == '/setup';

      if (authState is AuthAuthenticated && isAuthRoute) {
        return '/vault_list';
      }
      if (authState is AuthSetupRequired && state.matchedLocation != '/setup') {
        return '/setup';
      }
      if (authState is! AuthAuthenticated && !isAuthRoute) {
        return '/auth';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/vault_list',
        builder: (ctx, _) => const VaultListScreen(),
      ),
      GoRoute(
        path: '/vault_detail',
        builder: (ctx, s) => VaultDetailScreenWrapper(vault: s.extra as Vault),
      ),
      GoRoute(path: '/setup', builder: (ctx, _) => const SetupScreen()),
      GoRoute(path: '/auth', builder: (ctx, _) => const UnlockScreen()),
    ],
    errorBuilder: (ctx, state) =>
        Scaffold(body: Center(child: Text('Error: ${state.error}'))),
  );
}

/// Must be called after [AuthCubit.checkAuthStatus] resolves so the
/// initial redirect knows whether to show setup, unlock, or vault list.
void initRouter(AuthCubit authCubit) {
  appRouter = _createRouter(authCubit);
}
