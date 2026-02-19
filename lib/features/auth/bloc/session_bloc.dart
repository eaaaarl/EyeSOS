import 'package:eyesos/features/auth/bloc/session_event.dart';
import 'package:eyesos/features/auth/bloc/session_state.dart';
import 'package:eyesos/features/auth/models/user_model.dart';
import 'package:eyesos/features/auth/repository/auth_repository.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SessionBloc extends HydratedBloc<SessionEvent, SessionState> {
  final AuthRepository _authRepository;
  SessionBloc(this._authRepository) : super(SessionInitial()) {
    on<AuthLoggedIn>(_onAuthLoggedIn);
    on<AuthLoggedOut>(_onAuthLoggedOut);

    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedOut &&
          state is AuthAuthenticated) {
        add(AuthLoggedOut());
      }
    });
  }

  void _onAuthLoggedIn(AuthLoggedIn event, Emitter<SessionState> emit) {
    emit(AuthAuthenticated(user: event.user));
  }

  void _onAuthLoggedOut(AuthLoggedOut event, Emitter<SessionState> emit) async {
    try {
      // 2. Tell Supabase to Sign Out
      await _authRepository.signOut();
      await _authRepository.signOutGoogle();

      // 3. Reset the UI state
      emit(SessionInitial());

      // 4. Clear the local hydrated cache
      await HydratedBloc.storage.clear();
    } catch (e) {
      // Even if Supabase fails (e.g. no internet), we still log out locally
      emit(SessionInitial());
    }
  }

  @override
  SessionState? fromJson(Map<String, dynamic> json) {
    try {
      if (json['type'] == 'authenticated') {
        final user = UserModel.fromJson(json['user'] as Map<String, dynamic>);

        return AuthAuthenticated(user: user);
      }
      return SessionInitial();
    } catch (e) {
      return null;
    }
  }

  @override
  Map<String, dynamic>? toJson(SessionState state) {
    if (state is AuthAuthenticated) {
      final json = {'type': 'authenticated', 'user': state.user.toJson()};
      return json;
    }
    return null;
  }
}
