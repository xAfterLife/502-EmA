import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:min_vault/features/auth/data/key_service.dart';
import 'package:min_vault/features/auth/state/auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({required this._keyService}) : super(const AuthChecking());

  final KeyService _keyService;

  /// Check whether a master password exists. Emits [AuthSetupRequired] or
  /// [AuthUnlockRequired] accordingly.
  Future<void> checkAuthStatus() async {
    try {
      final hasPassword = await _keyService.hasMasterPassword();
      if (!hasPassword) {
        emit(const AuthSetupRequired());
        return;
      }
      final bioEnabled = await _keyService.isBiometricEnabled();
      emit(AuthUnlockRequired(biometricAvailable: bioEnabled));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  /// First launch: set the master password.
  Future<void> setupMasterPassword(String password) async {
    emit(const AuthLoading());
    try {
      await _keyService.setupMasterPassword(password);
      emit(const AuthAuthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  /// Unlock with master password.
  Future<void> unlockWithPassword(String password) async {
    emit(const AuthLoading());
    try {
      await _keyService.verifyMasterPassword(password);
      emit(const AuthAuthenticated());
    } on StateError catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  /// Attempt biometric unlock.
  Future<void> unlockWithBiometric() async {
    emit(const AuthLoading());
    try {
      await _keyService.unlockWithBiometric();
      emit(const AuthAuthenticated());
    } catch (e) {
      // Biometric failed — fall back to password screen.
      emit(const AuthUnlockRequired(biometricAvailable: false));
    }
  }

  /// Lock the app (clear cached key, return to unlock screen).
  Future<void> lock() async {
    _keyService.lock();
    final bioEnabled = await _keyService.isBiometricEnabled();
    emit(AuthUnlockRequired(biometricAvailable: bioEnabled));
  }
}
