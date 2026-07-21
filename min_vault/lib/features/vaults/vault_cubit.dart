import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:min_vault/features/vaults/vault_repository.dart';
import 'package:min_vault/features/vaults/vault_state.dart';
import 'package:uuid/uuid.dart';

class VaultCubit extends Cubit<VaultState> {
  VaultCubit({required VaultRepository repository})
    : _repo = repository,
      super(const VaultInitial());

  final VaultRepository _repo;
  static const _uuid = Uuid();

  Future<void> loadVaults() async {
    emit(const VaultLoading());
    try {
      final vaults = await _repo.loadVaults();
      emit(VaultLoaded(vaults));
    } catch (e) {
      emit(VaultError(e.toString()));
    }
  }

  Future<void> createVault(String name) async {
    try {
      final id = _uuid.v4();
      await _repo.createVault(name, id: id);
      await loadVaults();
    } catch (e) {
      emit(VaultError(e.toString()));
    }
  }

  Future<void> deleteVault(String folderName) async {
    try {
      await _repo.deleteVault(folderName);
      await loadVaults();
    } catch (e) {
      emit(VaultError(e.toString()));
    }
  }
}
