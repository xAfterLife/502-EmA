import 'package:flutter/foundation.dart';
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
}
