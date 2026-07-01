import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart';
import 'package:cryptography/cryptography.dart';

class EncryptionService {
  EncryptionService._();

  static final _algorithm = Xchacha20.poly1305Aead();

  //TODO: Derive Data Encryption Key with master password hash from Key Store via a Key Service/Manager
  static SecretKey _dataEncryptionKey = SecretKey([]);

  //TODO: Remove/change for release
  /// This function is used only for testing purposes to get a placeholder key and should be removed/change for release.
  static void setKey() async {
    _dataEncryptionKey = await _algorithm.newSecretKey();
  }

  /// This function takes a file path as an argument and encrypts the file with the Xchacha20-poly1305
  /// algorithm. After encryption you will have the original file and an encrypted file ending with .crypt .
  static Future<void> encryptFile(String filePath) async {
    try {
      // Input setup
      final inputFile = File(filePath);
      if (!await inputFile.exists()) { throw Exception("File does not exist."); }
      
      final String fileName = basename(filePath);
      final String fileExtension = extension(filePath);

      Uint8List fileBytes = await inputFile.readAsBytes();

      final nonce = _algorithm.newNonce(); // Xchacha20 uses a 192-bit nonce
      final List<int> additionalData = utf8.encode(fileExtension); // Use file extension as AAD

      // Data encryption
      final secretBox = await _algorithm.encrypt(
        fileBytes,
        secretKey: _dataEncryptionKey,
        nonce: nonce,
        aad: additionalData
      );

      final bytes = secretBox.concatenation();

      // Output setup
      final String outputFilePath = dirname(filePath);
      final outputFile = File("$outputFilePath/$fileName.crypt");

      await outputFile.writeAsBytes(bytes);

      //TODO: Remove original unencrypted file after encryption

    } catch (err) {
      print('Error in decryptFile(): $err');
    }
  }

  /// This function takes a file path as an argument and decrypts the file with the Xchacha20-poly1305
  /// algorithm. After decryption you will have the encrypted file and an decrypted file ending with .crypt .
  static Future<void> decryptFile(String filePath) async {
    // Input setup
    final inputFile = File(filePath);
    if (!await inputFile.exists()) { throw Exception("File does not exist."); }

    Uint8List fileBytes = await inputFile.readAsBytes();

    final secretBox = SecretBox.fromConcatenation(
      fileBytes,
      nonceLength: _algorithm.nonceLength,
      macLength: _algorithm.macAlgorithm.macLength
    );

    // Output setup
    final String fileName = basename(filePath);

    int lastIndex = fileName.lastIndexOf('.');
    // If the character exists, take the substring after it including the character
    String outputFileName = lastIndex != -1 ? fileName.substring(0, lastIndex) : fileName;

    final String outputFilePath = dirname(filePath);

    // Data decryption
    final String fileExtension = extension(outputFileName);
    final List<int> additionalData = utf8.encode(fileExtension);

    final decryptedBytes = await _algorithm.decrypt(
      secretBox, 
      secretKey: _dataEncryptionKey,
      aad: additionalData
    );

    // Write decrypted file
    final outputFile = File("$outputFilePath/$outputFileName");
    await outputFile.writeAsBytes(decryptedBytes);
  }
}