import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/user_model.dart';
import '../domain/usecases/sign_out_usecase.dart';
import '../domain/usecases/sign_out_google_usecase.dart';
import 'session_event.dart';
import 'session_state.dart';

class SessionBloc extends HydratedBloc<SessionEvent, SessionState> {
  final SignOutUsecase _signOutUsecase;
  final SignOutGoogleUsecase _signOutGoogleUsecase;

  SessionBloc({
    required SignOutUsecase signOutUsecase,
    required SignOutGoogleUsecase signOutGoogleUsecase,
  }) : _signOutUsecase = signOutUsecase,
       _signOutGoogleUsecase = signOutGoogleUsecase,
       super(SessionInitial()) {
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
      await _signOutUsecase();
      await _signOutGoogleUsecase();
      emit(SessionInitial());
      await HydratedBloc.storage.clear();
    } catch (e) {
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
      final json = {
        'type': 'authenticated',
        'user': (state.user as UserModel).toJson(),
      };
      return json;
    }
    return null;
  }
}
