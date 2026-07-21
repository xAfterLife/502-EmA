import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Thin wrapper around [FlutterSecureStorage].
class AuthStorageService {
  AuthStorageService._(this._storage);

  static Future<AuthStorageService> init() async {
    const androidOptions = AndroidOptions();
    const storage = FlutterSecureStorage(aOptions: androidOptions);
    return AuthStorageService._(storage);
  }

  final FlutterSecureStorage _storage;

  Future<String?> read({required String key}) => _storage.read(key: key);

  Future<void> write({required String key, required String value}) =>
      _storage.write(key: key, value: value);

  Future<void> writeBytes({required String key, required Uint8List value}) =>
      _storage.write(key: key, value: base64Encode(value));

  Future<Uint8List?> readBytes({required String key}) async {
    final s = await _storage.read(key: key);
    if (s == null) return null;
    return base64Decode(s);
  }

  Future<void> delete({required String key}) => _storage.delete(key: key);
}
