import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:min_vault/core/crypto/encryption_service.dart';
import 'package:min_vault/features/auth/auth_storage_service.dart';

/// Derives an AES-256 key from a master password and provides
/// a verifier so the password can be checked without storing it.
class MasterKeyService {
  MasterKeyService({required this._storage, required this._encryptionService});

  final AuthStorageService _storage;
  final EncryptionService _encryptionService;

  static const String _verifierKey = 'auth_verifier';
  static const String _biometricKey = 'auth_biometric_key';
  static const String _biometricEnabledKey = 'auth_biometric_enabled';
  static const String _verifierPlaintext = 'MINVAULT_KEY_VERIFIER';

  static final Uint8List _salt = Uint8List.fromList(
    utf8.encode('min_vault_master_key_salt_v1'),
  );
  static const int _pbkdf2Iterations = 600000;

  SecretKey? _cachedKey;

  Future<bool> hasMasterPassword() async {
    final verifier = await _storage.read(key: _verifierKey);
    return verifier != null && verifier.trim().isNotEmpty && verifier != "null";
  }

  Future<SecretKey> setupMasterPassword(String password) async {
    final key = await _deriveKey(password);
    final blob = await _encryptionService.encrypt(
      utf8.encode(_verifierPlaintext),
      key: key,
    );
    await _storage.write(key: _verifierKey, value: base64Encode(blob));
    _cachedKey = key;
    return key;
  }

  Future<SecretKey> verifyMasterPassword(String password) async {
    final stored = await _storage.read(key: _verifierKey);
    if (stored == null) throw StateError('No master password has been set.');

    final key = await _deriveKey(password);
    try {
      await _encryptionService.decrypt(base64Decode(stored), key: key);
    } catch (_) {
      throw StateError('Incorrect master password.');
    }
    _cachedKey = key;
    return key;
  }

  SecretKey? get cachedKey => _cachedKey;

  void lock() {
    _cachedKey = null;
  }

  Future<bool> isBiometricEnabled() async {
    return await _storage.read(key: _biometricEnabledKey) == 'true';
  }

  Future<void> enableBiometric() async {
    if (_cachedKey == null) {
      throw StateError('No unlocked key to cache for biometric.');
    }
    // Export the key bytes and store them.
    final keyBytes = Uint8List.fromList(await _cachedKey!.extractBytes());
    await _storage.writeBytes(key: _biometricKey, value: keyBytes);
    await _storage.write(key: _biometricEnabledKey, value: 'true');
  }

  Future<void> disableBiometric() async {
    await _storage.delete(key: _biometricKey);
    await _storage.write(key: _biometricEnabledKey, value: 'false');
  }

  /// Restore the AES key from biometric-secured storage.
  Future<SecretKey> unlockWithBiometric() async {
    final keyBytes = await _storage.readBytes(key: _biometricKey);
    if (keyBytes == null) {
      throw StateError('No biometric key stored.');
    }
    final key = SecretKey(keyBytes);
    _cachedKey = key;
    return key;
  }

  Future<SecretKey> _deriveKey(String password) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: _pbkdf2Iterations,
      bits: 256,
    );
    return pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: _salt,
    );
  }
}
