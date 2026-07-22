import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:min_vault/features/vault_items/vault_item.dart';
import 'package:min_vault/features/vault_items/vault_item_repository.dart';
import 'package:min_vault/features/vault_items/vault_items_state.dart';

class VaultItemsCubit extends Cubit<VaultItemsState> {
  VaultItemsCubit({required VaultItemRepository repository})
    : _repo = repository,
      super(const ItemsInitial());

  final VaultItemRepository _repo;

  Future<void> loadItems() async {
    emit(const ItemsLoading());
    try {
      final items = await _repo.loadItems();

      final entries = await Future.wait(
        items
            .where((item) => item.hasThumbnail)
            .map(
              (item) => _repo
                  .loadThumbnail(item.id)
                  .then((bytes) => MapEntry(item.id, bytes)),
            ),
      );

      final thumbnails = <String, Uint8List>{};
      for (final entry in entries) {
        if (entry.value != null) thumbnails[entry.key] = entry.value!;
      }

      emit(ItemsLoaded(items, thumbnails));
    } catch (e) {
      emit(ItemsError(e.toString()));
    }
  }

  Future<void> addItem({
    required String title,
    required ItemType type,
    required Object value,
  }) async {
    try {
      await _repo.addItem(title: title, type: type, value: value);
      await loadItems();
    } catch (e) {
      emit(ItemsError(e.toString()));
    }
  }

  Future<void> deleteItem(String id) async {
    try {
      await _repo.deleteItem(id);
      await loadItems();
    } catch (e) {
      emit(ItemsError(e.toString()));
    }
  }

  Future<String> revealText(String id) => _repo.revealText(id);

  Future<Uint8List> revealImageBytes(String id) => _repo.revealImageBytes(id);

  Future<void> updateText(String id, String newValue) =>
      _repo.updateText(id, newValue);

  Future<File> revealFile(String id) => _repo.revealFile(id);
}
