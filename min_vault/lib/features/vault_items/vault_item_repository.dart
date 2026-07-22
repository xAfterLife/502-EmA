import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:min_vault/core/crypto/encryption_service.dart';
import 'package:min_vault/features/vault_items/vault_item.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:image/image.dart' as img;

Uint8List? _generateThumbnailIsolate(List<dynamic> params) {
  final imageBytes = params[0] as Uint8List;
  final targetWidth = params[1] as int;
  final jpegQuality = params[2] as int;

  final decoded = img.decodeImage(imageBytes);
  if (decoded == null) return null;
  final resized = img.copyResize(decoded, width: targetWidth);
  return Uint8List.fromList(img.encodeJpg(resized, quality: jpegQuality));
}

Future<Uint8List> _decryptInIsolate(List<dynamic> params) async {
  final encryptedBytes = params[0] as Uint8List;
  final keyBytes = params[1] as Uint8List;

  final algorithm = Xchacha20.poly1305Aead();
  final box = SecretBox.fromConcatenation(
    encryptedBytes,
    nonceLength: algorithm.nonceLength,
    macLength: algorithm.macAlgorithm.macLength,
  );
  final key = SecretKey(keyBytes);
  final decrypted = await algorithm.decrypt(box, secretKey: key);
  return Uint8List.fromList(decrypted);
}

class VaultItemRepository {
  VaultItemRepository({
    required this.folderName,
    required this._encryptionService,
  });

  final String folderName;
  final EncryptionService _encryptionService;

  static const _uuid = Uuid();
  static const _thumbnailWidth = 200;
  static const _thumbnailQuality = 70;

  Future<Directory> get _vaultDir async {
    final appDir = await getApplicationDocumentsDirectory();
    return Directory('${appDir.path}/vaults/$folderName');
  }

  Future<File> get _metaFile async {
    final dir = await _vaultDir;
    return File('${dir.path}/items_meta.json');
  }

  Future<SecretKey> get _dek async =>
      SecretKey(await _encryptionService.exportDataKeyBytes());

  Future<List<VaultItem>> loadItems() async {
    final metaFile = await _metaFile;
    if (!await metaFile.exists()) return [];

    final raw = json.decode(await metaFile.readAsString()) as List<dynamic>;
    final key = await _dek;

    final items = <VaultItem>[];
    for (final entry in raw) {
      final map = entry as Map<String, dynamic>;
      final titleBytes = await _encryptionService.decrypt(
        base64Decode(map['title'] as String),
        key: key,
      );
      items.add(
        VaultItem(
          id: map['id'] as String,
          title: utf8.decode(titleBytes),
          type: ItemType.values.byName(map['type'] as String),
          hasThumbnail: map['hasThumbnail'] as bool? ?? false,
          createdAt: DateTime.parse(map['createdAt'] as String),
        ),
      );
    }

    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  Future<Uint8List?> loadThumbnail(String id) async {
    final dir = await _vaultDir;
    final thumbFile = File('${dir.path}/$id.thumb.crypt');
    if (!await thumbFile.exists()) return null;

    final encryptedBytes = await thumbFile.readAsBytes();
    final keyBytes = await _encryptionService.exportDataKeyBytes();
    return compute(_decryptInIsolate, <dynamic>[encryptedBytes, keyBytes]);
  }

  Future<void> addItem({
    required String title,
    required ItemType type,
    required Object value,
  }) async {
    final dir = await _vaultDir;
    if (!await dir.exists()) await dir.create(recursive: true);

    final key = await _dek;
    final id = _uuid.v4();
    final valueBytes = await _valueBytes(type, value);

    final valueFile = File('${dir.path}/$id.value.crypt');
    await valueFile.writeAsBytes(
      await _encryptionService.encrypt(valueBytes, key: key),
    );

    var hasThumbnail = false;
    if (type == ItemType.image) {
      final thumbBytes = await compute(_generateThumbnailIsolate, <dynamic>[
        valueBytes,
        _thumbnailWidth,
        _thumbnailQuality,
      ]);
      if (thumbBytes != null) {
        final thumbFile = File('${dir.path}/$id.thumb.crypt');
        await thumbFile.writeAsBytes(
          await _encryptionService.encrypt(thumbBytes, key: key),
        );
        hasThumbnail = true;
      }
    }

    final titleCipher = await _encryptionService.encrypt(
      utf8.encode(title),
      key: key,
    );

    final metaFile = await _metaFile;
    final existing = await metaFile.exists()
        ? json.decode(await metaFile.readAsString()) as List<dynamic>
        : <dynamic>[];

    existing.add({
      'id': id,
      'title': base64Encode(titleCipher),
      'type': type.name,
      'hasThumbnail': hasThumbnail,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    });

    await metaFile.writeAsString(json.encode(existing));
  }

  Future<void> deleteItem(String id) async {
    final dir = await _vaultDir;

    final valueFile = File('${dir.path}/$id.value.crypt');
    if (await valueFile.exists()) await valueFile.delete();

    final thumbFile = File('${dir.path}/$id.thumb.crypt');
    if (await thumbFile.exists()) await thumbFile.delete();

    final metaFile = await _metaFile;
    if (!await metaFile.exists()) return;

    final raw = json.decode(await metaFile.readAsString()) as List<dynamic>;
    raw.removeWhere((entry) => (entry as Map<String, dynamic>)['id'] == id);
    await metaFile.writeAsString(json.encode(raw));
  }

  Future<String> revealText(String id) async {
    return utf8.decode(await _readValueBytes(id));
  }

  Future<Uint8List> revealImageBytes(String id) => _readValueBytes(id);

  Future<void> updateText(String id, String newValue) async {
    final dir = await _vaultDir;
    final valueFile = File('${dir.path}/$id.value.crypt');
    if (!await valueFile.exists()) {
      throw StateError('Item not found.');
    }

    final key = await _dek;
    await valueFile.writeAsBytes(
      await _encryptionService.encrypt(utf8.encode(newValue), key: key),
    );
  }

  Future<File> revealFile(String id) async {
    final bytes = await _readValueBytes(id);
    final tempDir = await getTemporaryDirectory();
    final tempFile = File(
      '${tempDir.path}/${id}_${DateTime.now().millisecondsSinceEpoch}',
    );
    return tempFile.writeAsBytes(bytes);
  }

  Future<Uint8List> _readValueBytes(String id) async {
    final dir = await _vaultDir;
    final valueFile = File('${dir.path}/$id.value.crypt');
    if (!await valueFile.exists()) {
      throw StateError('Item not found.');
    }

    final key = await _dek;
    return _encryptionService.decrypt(await valueFile.readAsBytes(), key: key);
  }

  Future<Uint8List> _valueBytes(ItemType type, Object value) async {
    switch (type) {
      case ItemType.password:
      case ItemType.note:
        if (value is! String) {
          throw ArgumentError('Expected a String value for $type.');
        }
        return Uint8List.fromList(utf8.encode(value));
      case ItemType.image:
      case ItemType.file:
        if (value is File) return value.readAsBytes();
        if (value is Uint8List) return value;
        throw ArgumentError('Expected a File or bytes for $type.');
    }
  }
}
