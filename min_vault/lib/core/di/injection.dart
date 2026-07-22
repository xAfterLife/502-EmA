import 'package:get_it/get_it.dart';
import 'package:local_auth/local_auth.dart';
import 'package:min_vault/core/crypto/encryption_service.dart';
import 'package:min_vault/features/auth/auth_storage_service.dart';
import 'package:min_vault/features/auth/key_service.dart';
import 'package:min_vault/features/vaults/vault_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  getIt.registerSingletonAsync<AuthStorageService>(
    () => AuthStorageService.init(),
  );

  getIt.registerSingletonAsync<EncryptionService>(
    () => EncryptionService.init(),
  );

  getIt.registerSingletonAsync<SharedPreferences>(
    () => SharedPreferences.getInstance(),
  );

  getIt.registerLazySingleton<LocalAuthentication>(() => LocalAuthentication());
  getIt.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);

  await getIt.allReady();

  getIt.registerSingleton<KeyService>(
    KeyService(
      storage: getIt<AuthStorageService>(),
      encryptionService: getIt<EncryptionService>(),
      localAuth: getIt<LocalAuthentication>(),
    ),
  );

  getIt.registerSingleton<VaultRepository>(VaultRepository());
}
