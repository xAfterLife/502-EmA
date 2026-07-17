import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:min_vault/core/app_router.dart';
import 'package:min_vault/core/di/injection.dart';
import 'package:min_vault/core/theme/app_theme.dart';
import 'package:min_vault/features/auth/data/master_key_service.dart';
import 'package:min_vault/features/auth/state/auth_cubit.dart';
import 'package:min_vault/features/auth/state/auth_state.dart';
import 'package:min_vault/features/vaults/data/vault_repository.dart';
import 'package:min_vault/features/vaults/state/vault_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();

  final authCubit = AuthCubit(masterKeyService: getIt<MasterKeyService>());
  final vaultCubit = VaultCubit(repository: getIt<VaultRepository>());

  await authCubit.checkAuthStatus();
  initRouter(authCubit);

  runApp(MinVaultApp(authCubit: authCubit, vaultCubit: vaultCubit));
}

class MinVaultApp extends StatelessWidget {
  const MinVaultApp({
    required this.authCubit,
    required this.vaultCubit,
    super.key,
  });

  final AuthCubit authCubit;
  final VaultCubit vaultCubit;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: authCubit),
        BlocProvider.value(value: vaultCubit),
      ],
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          return MaterialApp.router(
            title: 'MinVault',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            routerConfig: appRouter,
            builder: (context, child) {
              return BlocListener<AuthCubit, AuthState>(
                listener: (context, state) {
                  // GoRouter's redirect will handle navigation.
                },
                child: child ?? const SizedBox.shrink(),
              );
            },
          );
        },
      ),
    );
  }
}
