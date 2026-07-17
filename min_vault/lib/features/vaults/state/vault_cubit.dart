import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:min_vault/features/vaults/data/vault_repository.dart';
import 'package:min_vault/features/vaults/state/vault_state.dart';

class VaultCubit extends Cubit<VaultState> {
  VaultCubit() : super(const VaultInitial());

  final _repo = VaultRepository.instance;

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
      await _repo.createVault(name);
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
