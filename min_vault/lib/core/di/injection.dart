import 'package:get_it/get_it.dart';
import 'package:min_vault/core/crypto/encryption_service.dart';
import 'package:min_vault/features/auth/data/auth_storage_service.dart';
import 'package:min_vault/features/auth/data/master_key_service.dart';
import 'package:min_vault/features/vaults/data/vault_repository.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  getIt.registerSingletonAsync<AuthStorageService>(
    () => AuthStorageService.init(),
  );

  getIt.registerSingletonAsync<EncryptionService>(
    () => EncryptionService.init(),
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
