import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:min_vault/core/app_router.dart';
import 'package:min_vault/core/di/injection.dart';
import 'package:min_vault/core/theme/app_theme.dart';
import 'package:min_vault/core/theme/theme_cubit.dart';
import 'package:min_vault/features/auth/key_service.dart';
import 'package:min_vault/features/auth/auth_cubit.dart';
import 'package:min_vault/features/auth/auth_state.dart';
import 'package:min_vault/features/cloud/cloud_auth_cubit.dart';
import 'package:min_vault/features/cloud_backup/backup_repository.dart';
import 'package:min_vault/features/cloud_backup/cloud_sync_cubit.dart';
import 'package:min_vault/features/vaults/vault_repository.dart';
import 'package:min_vault/features/vaults/vault_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://fvqfvzdjfsaebxnjcbey.supabase.co',
    publishableKey: 'sb_publishable_9FNE0TPC66y7wGFleGlx2g_1IXZ0F1a',
  );

  await configureDependencies();

  final authCubit = AuthCubit(keyService: getIt<KeyService>());
  final vaultCubit = VaultCubit(repository: getIt<VaultRepository>());
  final themeCubit = ThemeCubit(prefs: getIt<SharedPreferences>());
  final cloudAuthCubit = CloudAuthCubit(client: getIt<SupabaseClient>());
  final cloudSyncCubit = CloudSyncCubit(
    backupRepo: getIt<BackupRepository>(),
    vaultRepo: getIt<VaultRepository>(),
  );

  await authCubit.checkAuthStatus();
  initRouter(authCubit);

  runApp(
    MinVaultApp(
      authCubit: authCubit,
      vaultCubit: vaultCubit,
      themeCubit: themeCubit,
      cloudAuthCubit: cloudAuthCubit,
      cloudSyncCubit: cloudSyncCubit,
    ),
  );
}

class MinVaultApp extends StatelessWidget {
  const MinVaultApp({
    required this.authCubit,
    required this.vaultCubit,
    required this.themeCubit,
    required this.cloudAuthCubit,
    required this.cloudSyncCubit,
    super.key,
  });

  final AuthCubit authCubit;
  final VaultCubit vaultCubit;
  final ThemeCubit themeCubit;
  final CloudAuthCubit cloudAuthCubit;
  final CloudSyncCubit cloudSyncCubit;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: authCubit),
        BlocProvider.value(value: vaultCubit),
        BlocProvider.value(value: themeCubit),
        BlocProvider.value(value: cloudAuthCubit),
        BlocProvider.value(value: cloudSyncCubit),
      ],

      child: BlocBuilder<ThemeCubit, bool>(
        builder: (context, isDark) {
          return BlocBuilder<AuthCubit, AuthState>(
            builder: (context, authState) {
              return MaterialApp.router(
                key: ValueKey(isDark),
                title: 'MinVault',
                debugShowCheckedModeBanner: false,
                theme: isDark ? AppTheme.dark : AppTheme.light,
                routerConfig: appRouter,
                builder: (context, child) => BlocListener<AuthCubit, AuthState>(
                  listener: (context, state) {},
                  child: child ?? const SizedBox.shrink(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
