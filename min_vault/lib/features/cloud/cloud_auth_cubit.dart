import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:min_vault/features/cloud/cloud_auth_state.dart';

class CloudAuthCubit extends Cubit<CloudAuthState> {
  CloudAuthCubit({required SupabaseClient client})
    : _client = client,
      super(_initialState(client)) {
    _sub = _client.auth.onAuthStateChange.listen((data) {
      final user = data.session?.user;
      emit(
        user == null
            ? const CloudAuthSignedOut()
            : CloudAuthSignedIn(user.email ?? user.id),
      );
    });
  }

  final SupabaseClient _client;
  late final StreamSubscription<AuthState> _sub;

  static CloudAuthState _initialState(SupabaseClient client) {
    final user = client.auth.currentUser;
    return user == null
        ? const CloudAuthSignedOut()
        : CloudAuthSignedIn(user.email ?? user.id);
  }

  Future<void> signIn(String email, String password) async {
    emit(const CloudAuthLoading());
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (e) {
      emit(CloudAuthError(e.message));
    } catch (e) {
      emit(CloudAuthError(e.toString()));
    }
  }

  Future<void> signUp(String email, String password) async {
    emit(const CloudAuthLoading());
    try {
      await _client.auth.signUp(email: email, password: password);
      if (_client.auth.currentSession == null) {
        // Only hits this if "Confirm email" is still ON.
        emit(const CloudAuthError('Check your inbox to confirm your email.'));
      }
    } on AuthException catch (e) {
      emit(CloudAuthError(e.message));
    } catch (e) {
      emit(CloudAuthError(e.toString()));
    }
  }

  Future<void> signOut() => _client.auth.signOut();

  @override
  Future<void> close() {
    _sub.cancel();
    return super.close();
  }
}
