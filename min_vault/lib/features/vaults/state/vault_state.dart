import 'package:equatable/equatable.dart';
import 'package:min_vault/features/vaults/domain/vault.dart';

sealed class VaultState extends Equatable {
  const VaultState();
}

final class VaultInitial extends VaultState {
  const VaultInitial();
  @override List<Object?> get props => [];
}

final class VaultLoading extends VaultState {
  const VaultLoading();
  @override List<Object?> get props => [];
}

final class VaultLoaded extends VaultState {
  const VaultLoaded(this.vaults);
  final List<Vault> vaults;
  @override List<Object?> get props => [vaults];
}

final class VaultError extends VaultState {
  const VaultError(this.message);
  final String message;
  @override List<Object?> get props => [message];
}