import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:min_vault/features/vault_items/vault_item.dart';

sealed class VaultItemsState extends Equatable {
  const VaultItemsState();
}

final class ItemsInitial extends VaultItemsState {
  const ItemsInitial();
  @override
  List<Object?> get props => [];
}

final class ItemsLoading extends VaultItemsState {
  const ItemsLoading();
  @override
  List<Object?> get props => [];
}

final class ItemsLoaded extends VaultItemsState {
  const ItemsLoaded(this.items, this.thumbnails);
  final List<VaultItem> items;
  final Map<String, Uint8List> thumbnails;
  @override
  List<Object?> get props => [items, thumbnails];
}

final class ItemsError extends VaultItemsState {
  const ItemsError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
