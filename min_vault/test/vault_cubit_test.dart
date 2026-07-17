import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:min_vault/features/vaults/data/vault_repository.dart';
import 'package:min_vault/features/vaults/domain/vault.dart';
import 'package:min_vault/features/vaults/state/vault_cubit.dart';
import 'package:min_vault/features/vaults/state/vault_state.dart';

class MockVaultRepository extends Mock implements VaultRepository {}

void main() {
  //Late binding instanziierung im setUp()
  late MockVaultRepository mockRepo;

  setUp(() {
    mockRepo = MockVaultRepository();
    registerFallbackValue(
      const Vault(name: 'Test', folderName: 'test', itemCount: 0),
    );
  });

  group('VaultCubit', () {
    test('initial state is VaultInitial', () {
      final cubit = VaultCubit(repository: mockRepo);
      expect(cubit.state, const VaultInitial());
      cubit.close();
    });

    blocTest<VaultCubit, VaultState>(
      'emits [VaultLoading, VaultLoaded] when loadVaults succeeds',
      build: () => VaultCubit(repository: mockRepo),
      act: (cubit) => cubit.loadVaults(),
      setUp: () {
        when(() => mockRepo.loadVaults()).thenAnswer(
          (_) async => [
            const Vault(
              name: 'Photos',
              folderName: 'enc',
              itemCount: 3,
            ),
          ],
        );
      },
      expect: () => [
        const VaultLoading(),
        const VaultLoaded([
          Vault(name: 'Photos', folderName: 'enc', itemCount: 3),
        ]),
      ],
    );

    blocTest<VaultCubit, VaultState>(
      'emits [VaultLoading, VaultError] when loadVaults fails',
      build: () => VaultCubit(repository: mockRepo),
      act: (cubit) => cubit.loadVaults(),
      setUp: () {
        when(() => mockRepo.loadVaults()).thenThrow(Exception('Disk error'));
      },
      expect: () => [
        const VaultLoading(),
        const VaultError('Exception: Disk error'),
      ],
    );

    blocTest<VaultCubit, VaultState>(
      'createVault delegates to repo then reloads',
      build: () => VaultCubit(repository: mockRepo),
      act: (cubit) => cubit.createVault('Notes'),
      setUp: () {
        when(
          () => mockRepo.createVault('Notes', id: any(named: 'id')),
        ).thenAnswer(
          (_) async => const Vault(
            name: 'Notes',
            folderName: 'enc',
            itemCount: 0,
          ),
        );
        when(() => mockRepo.loadVaults()).thenAnswer(
          (_) async => [
            const Vault(
              name: 'Notes',
              folderName: 'enc',
              itemCount: 0,
            ),
          ],
        );
      },
      expect: () => [
        const VaultLoading(),
        const VaultLoaded([
          Vault(name: 'Notes', folderName: 'enc', itemCount: 0),
        ]),
      ],
    );

    blocTest<VaultCubit, VaultState>(
      'deleteVault delegates to repo then reloads',
      build: () => VaultCubit(repository: mockRepo),
      act: (cubit) => cubit.deleteVault('enc_folder'),
      setUp: () {
        when(() => mockRepo.deleteVault('enc_folder')).thenAnswer((_) async {});
        when(
          () => mockRepo.loadVaults(),
        ).thenAnswer((_) async => const <Vault>[]);
      },
      expect: () => [const VaultLoading(), const VaultLoaded([])],
    );
  });
}
