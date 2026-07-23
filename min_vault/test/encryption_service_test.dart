import 'package:flutter_test/flutter_test.dart';
import 'package:min_vault/core/crypto/encryption_service.dart';

void main() {
  group('EncryptionService', () {
    late EncryptionService service;

    setUp(() async {
      service = await EncryptionService.init();
    });

    test('encrypt then decrypt returns original plaintext', () async {
      final key = await service.generateNewKey();
      final plaintext = 'hello vault'.codeUnits;

      final cipher = await service.encrypt(plaintext, key: key);
      final decrypted = await service.decrypt(cipher, key: key);

      expect(decrypted, plaintext);
    });

    test('decrypting with the wrong key throws', () async {
      final key = await service.generateNewKey();
      final wrongKey = await service.generateNewKey();
      final cipher = await service.encrypt('secret'.codeUnits, key: key);

      expect(
        () => service.decrypt(cipher, key: wrongKey),
        throwsA(anything),
      );
    });

    test('ciphertext differs between two encryptions of the same plaintext', () async {
      final key = await service.generateNewKey();
      final plaintext = 'repeat me'.codeUnits;

      final cipher1 = await service.encrypt(plaintext, key: key);
      final cipher2 = await service.encrypt(plaintext, key: key);

      expect(cipher1, isNot(equals(cipher2))); // proves nonce is actually random per call
    });
  });
}