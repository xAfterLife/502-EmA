import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart';
import 'package:cryptography/cryptography.dart';

class EncryptionService {
  EncryptionService._();

  static Future<void> encryptFile(String filePath) async {
    try {
      // Input setup
      final inputFile = File(filePath);
      if (!await inputFile.exists()) { throw Exception("File does not exist."); }
      final String fileName = basenameWithoutExtension(inputFile.path);

      Uint8List fileBytes = await inputFile.readAsBytes();

      // Encryption setup, might not want to init algorithm in this function
      final algorithm = Xchacha20.poly1305Aead();
      final nonce = algorithm.newNonce(); // Xchacha20 uses a 192-bit nonce
      final List<int> additionalData = utf8.encode(fileName); // Use file name as AAD

      //TODO: Derive Data Encryption Key with master password hash from Key Store via an Key Service/Manager
      final dataEncryptionKey = await algorithm.newSecretKey();

      // Data encryption
      final secretBox = await algorithm.encrypt(
        fileBytes,
        secretKey: dataEncryptionKey,
        nonce: nonce,
        aad: additionalData
      );

      final bytes = secretBox.concatenation();

      // Output setup
      String outputFilePath = dirname(filePath);
      final outputFile = File("$outputFilePath/$fileName.crypt");

      await outputFile.writeAsBytes(bytes);

      //TODO: Remove original unencrypted file after encryption

    } catch (err) {
      print('Error in encryptFile(): $err');
    }
  }

  static Future<void> decryptFile(String filePath) async {

  }
}