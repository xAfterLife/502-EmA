import 'package:equatable/equatable.dart';

sealed class AuthState extends Equatable {
  const AuthState();
}

final class AuthChecking extends AuthState {
  const AuthChecking();
  @override
  List<Object?> get props => [];
}

final class AuthSetupRequired extends AuthState {
  const AuthSetupRequired();
  @override
  List<Object?> get props => [];
}

final class AuthUnlockRequired extends AuthState {
  const AuthUnlockRequired({this.biometricAvailable = false});
  final bool biometricAvailable;
  @override
  List<Object?> get props => [biometricAvailable];
}

final class AuthLoading extends AuthState {
  const AuthLoading();
  @override
  List<Object?> get props => [];
}

final class AuthAuthenticated extends AuthState {
  const AuthAuthenticated();
  @override
  List<Object?> get props => [];
}

final class AuthError extends AuthState {
  const AuthError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
