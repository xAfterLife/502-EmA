import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:cryptography/cryptography.dart';

class EncryptionService {
  EncryptionService._();

  static Future<EncryptionService> init() async {
    return EncryptionService._();
  }

  static final _algorithm = Xchacha20.poly1305Aead();

  SecretKey? _dataEncryptionKey;

  bool get hasDataKey => _dataEncryptionKey != null;

  Future<SecretKey> generateNewKey() {
    return _algorithm.newSecretKey();
  }

  void setDataKey(SecretKey key) async {
    _dataEncryptionKey = key;
  }

  void clearDataKey() async {
    _dataEncryptionKey = null;
  }

  Future<Uint8List> exportDataKeyBytes() async =>
      Uint8List.fromList(await _requireDataKey().extractBytes());

  SecretKey _requireDataKey() {
    final key = _dataEncryptionKey;
    if (key == null) throw StateError('Vault locked: no data key set.');
    return key;
  }

  Future<Uint8List> encrypt(
    List<int> plaintext, {
    required SecretKey key,
    List<int> aad = const [],
  }) async {
    final nonce = _algorithm.newNonce();
    final box = await _algorithm.encrypt(
      plaintext,
      secretKey: key,
      nonce: nonce,
      aad: aad,
    );
    return Uint8List.fromList(box.concatenation());
  }

  Future<Uint8List> decrypt(
    Uint8List data, {
    required SecretKey key,
    List<int> aad = const [],
  }) async {
    final box = SecretBox.fromConcatenation(
      data,
      nonceLength: _algorithm.nonceLength,
      macLength: _algorithm.macAlgorithm.macLength,
    );
    return Uint8List.fromList(
      await _algorithm.decrypt(box, secretKey: key, aad: aad),
    );
  }

  /// This function takes a file path as an argument and encrypts the file with the Xchacha20-poly1305
  /// algorithm. After encryption you will have the original file and an encrypted file ending with .crypt .
  Future<void> encryptFile(String filePath) async {
    try {
      // Input setup
      final inputFile = File(filePath);
      if (!await inputFile.exists()) {
        throw Exception('File does not exist.');
      }

      final String fileName = basename(filePath);
      final String fileExtension = extension(filePath);

      Uint8List fileBytes = await inputFile.readAsBytes();

      final nonce = _algorithm.newNonce(); // Xchacha20 uses a 192-bit nonce
      final List<int> additionalData = utf8.encode(
        fileExtension,
      ); // Use file extension as AAD

      // Data encryption
      final secretBox = await _algorithm.encrypt(
        fileBytes,
        secretKey: _requireDataKey(),
        nonce: nonce,
        aad: additionalData,
      );

      final bytes = secretBox.concatenation();

      // Output setup
      final String outputFilePath = dirname(filePath);
      final outputFile = File('$outputFilePath/$fileName.crypt');

      await outputFile.writeAsBytes(bytes);

      //TODO: Remove original unencrypted file after encryption
    } catch (err) {
      if (kDebugMode) {
        print('Error in decryptFile(): $err');
      }
    }
  }

  /// This function takes a file path as an argument and decrypts the file with the Xchacha20-poly1305
  /// algorithm. After decryption you will have the encrypted file and an decrypted file ending with .crypt .
  Future<void> decryptFile(String filePath) async {
    try {
      // Input setup
      final inputFile = File(filePath);
      if (!await inputFile.exists()) {
        throw Exception("File does not exist.");
      }

      Uint8List fileBytes = await inputFile.readAsBytes();

      final secretBox = SecretBox.fromConcatenation(
        fileBytes,
        nonceLength: _algorithm.nonceLength,
        macLength: _algorithm.macAlgorithm.macLength,
      );

      // Output setup
      final String fileName = basename(filePath);

      int lastIndex = fileName.lastIndexOf('.');
      // If the character exists, take the substring after it including the character
      String outputFileName = lastIndex != -1
          ? fileName.substring(0, lastIndex)
          : fileName;

      final String outputFilePath = dirname(filePath);

      // Data decryption
      final String fileExtension = extension(outputFileName);
      final List<int> additionalData = utf8.encode(fileExtension);

      final decryptedBytes = await _algorithm.decrypt(
        secretBox,
        secretKey: _requireDataKey(),
        aad: additionalData,
      );

      // Write decrypted file
      final outputFile = File("$outputFilePath/$outputFileName");
      await outputFile.writeAsBytes(decryptedBytes);
    } catch (err) {
      if (kDebugMode) {
        print('Error in decryptFile(): $err');
      }
    }
  }
}
