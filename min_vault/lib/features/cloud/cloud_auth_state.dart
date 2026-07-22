import 'package:equatable/equatable.dart';

sealed class CloudAuthState extends Equatable {
  const CloudAuthState();
}

final class CloudAuthLoading extends CloudAuthState {
  const CloudAuthLoading();
  @override
  List<Object?> get props => [];
}

final class CloudAuthSignedOut extends CloudAuthState {
  const CloudAuthSignedOut();
  @override
  List<Object?> get props => [];
}

final class CloudAuthSignedIn extends CloudAuthState {
  const CloudAuthSignedIn(this.email);
  final String email;
  @override
  List<Object?> get props => [email];
}

final class CloudAuthError extends CloudAuthState {
  const CloudAuthError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
