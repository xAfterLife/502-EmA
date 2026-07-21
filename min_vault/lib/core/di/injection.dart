import 'package:get_it/get_it.dart';
import 'package:min_vault/core/crypto/encryption_service.dart';
import 'package:min_vault/features/auth/auth_storage_service.dart';
import 'package:min_vault/features/auth/master_key_service.dart';
import 'package:min_vault/features/vaults/vault_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  await getIt.allReady();

  getIt.registerSingleton<MasterKeyService>(
    MasterKeyService(
      storage: getIt<AuthStorageService>(),
      encryptionService: getIt<EncryptionService>(),
    ),
  );

  getIt.registerSingleton<VaultRepository>(VaultRepository());
}
