import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:min_vault/core/crypto/encryption_service.dart';
import 'package:min_vault/features/auth/data/auth_storage_service.dart';

/// Derives an AES-256 key from a master password and provides
/// a verifier so the password can be checked without storing it.
class KeyService {
  KeyService({required this._storage, required this._encryptionService});

  final AuthStorageService _storage;
  final EncryptionService _encryptionService;

  static const String _verifierKey = 'auth_verifier';
  static const String _biometricKey = 'auth_biometric_key';
  static const String _biometricEnabledKey = 'auth_biometric_enabled';
  static const String _verifierPlaintext = 'MINVAULT_KEY_VERIFIER';
  static const String _wrappedDekKey = 'vault_wrapped_dek';

  static final Uint8List _salt = Uint8List.fromList(
    utf8.encode('min_vault_master_key_salt_v1'),
  );
  static const int _pbkdf2Iterations = 600000;

  SecretKey? _cachedMasterKey;

  Future<bool> hasMasterPassword() async {
    final verifier = await _storage.read(key: _verifierKey);
    return verifier != null && verifier.trim().isNotEmpty && verifier != "null";
  }

  Future<void> setupMasterPassword(String password) async {
    final kek = await _deriveKey(password);

    final verifierBlob = await _encryptionService.encrypt(
      utf8.encode(_verifierPlaintext),
      key: kek,
    );
    await _storage.write(key: _verifierKey, value: base64Encode(verifierBlob));

    final dek = await _encryptionService.generateNewKey();
    final wrappedDek = await _encryptionService.encrypt(
      await dek.extractBytes(),
      key: kek,
    );
    await _storage.write(key: _wrappedDekKey, value: base64Encode(wrappedDek));

    _encryptionService.setDataKey(dek);
    _cachedMasterKey = kek;
  }

  Future<void> verifyMasterPassword(String password) async {
    final storedVerifier = await _storage.read(key: _verifierKey);
    final storedWrappedDek = await _storage.read(key: _wrappedDekKey);
    if (storedVerifier == null || storedWrappedDek == null) {
      throw StateError('No master password has been set.');
    }

    final kek = await _deriveKey(password);
    final SecretKey dek;
    try {
      await _encryptionService.decrypt(base64Decode(storedVerifier), key: kek);
      final dekBytes = await _encryptionService.decrypt(
        base64Decode(storedWrappedDek),
        key: kek,
      );
      dek = SecretKey(dekBytes);
    } catch (_) {
      throw StateError('Incorrect master password.');
    }

    _encryptionService.setDataKey(dek);
    _cachedMasterKey = kek;
  }

  SecretKey? get cachedKey => _cachedMasterKey;

  void lock() {
    _cachedMasterKey = null;
    _encryptionService.clearDataKey();
  }

  Future<bool> isBiometricEnabled() async {
    return await _storage.read(key: _biometricEnabledKey) == 'true';
  }

  Future<void> enableBiometric() async {
    if (!_encryptionService.hasDataKey) {
      throw StateError('No unlocked key to cache for biometric.');
    }
    // Export the key bytes and store them.
    final dekBytes = await _encryptionService.exportDataKeyBytes();
    await _storage.writeBytes(key: _biometricKey, value: dekBytes);
    await _storage.write(key: _biometricEnabledKey, value: 'true');
  }

  Future<void> disableBiometric() async {
    await _storage.delete(key: _biometricKey);
    await _storage.write(key: _biometricEnabledKey, value: 'false');
  }

  /// Restore the AES key from biometric-secured storage.
  Future<void> unlockWithBiometric() async {
    final dekBytes = await _storage.readBytes(key: _biometricKey);
    if (dekBytes == null) {
      throw StateError('No biometric key stored.');
    }
    _encryptionService.setDataKey(SecretKey(dekBytes));
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
