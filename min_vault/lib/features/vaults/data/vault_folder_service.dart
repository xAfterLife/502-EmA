import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

class VaultFolderService {
  VaultFolderService._();

  static const String _masterPassword =
      "THIS NEEDS TO COME FROM SECURE STORAGE IN PRODUCTION";

  static final Uint8List _salt = Uint8List.fromList(
    utf8.encode("vault_folder_naming_salt"),
  );

  static const int _pbkdf2Iterations = 600000;

  static SecretKey? _cachedKey;
  static final AesGcm _aesGcm = AesGcm.with256bits();
  static final Sha256 _sha256 = Sha256();

  static Future<SecretKey> _getKey() async {
    if (_cachedKey != null) return _cachedKey!;
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: _pbkdf2Iterations,
      bits: 256,
    );
    _cachedKey = await pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(_masterPassword)),
      nonce: _salt,
    );
    return _cachedKey!;
  }

  static Future<String> vaultNameToFolder(String vaultName) async {
    if (vaultName.isEmpty) throw ArgumentError('Vault name cannot be empty');
    final key = await _getKey();
    final nonceHash = await _sha256.hash(utf8.encode(vaultName));
    final nonce = Uint8List.fromList(nonceHash.bytes.sublist(0, 12));

    final secretBox = await _aesGcm.encrypt(
      utf8.encode(vaultName),
      secretKey: key,
      nonce: nonce,
    );

    final combined = Uint8List.fromList([
      ...nonce,
      ...secretBox.cipherText,
      ...secretBox.mac.bytes,
    ]);
    String folderName = base64Url.encode(combined);

    // Strip padding — safe for file systems
    while (folderName.endsWith('=')) {
      folderName = folderName.substring(0, folderName.length - 1);
    }
    return folderName;
  }

  static Future<String> folderToVaultName(String folderName) async {
    if (folderName.isEmpty) throw ArgumentError('Folder name cannot be empty');
    try {
      final padding = (4 - (folderName.length % 4)) % 4;
      final padded = folderName + ('=' * padding);
      final combined = base64Url.decode(padded);

      if (combined.length < 28) {
        throw const FormatException('Invalid data length');
      }

      final nonce = combined.sublist(0, 12);
      final cipherText = combined.sublist(12, combined.length - 16);
      final macBytes = combined.sublist(combined.length - 16);
      final key = await _getKey();

      final secretBox = SecretBox(cipherText, nonce: nonce, mac: Mac(macBytes));
      final decryptedBytes = await _aesGcm.decrypt(secretBox, secretKey: key);

      return utf8.decode(decryptedBytes);
    } catch (_) {
      throw const FormatException('Invalid folder name or master password');
    }
  }

  static void clearCache() => _cachedKey = null;
}
