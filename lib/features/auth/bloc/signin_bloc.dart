import 'package:eyesos/features/auth/repository/auth_repository.dart';
import 'package:eyesos/features/auth/validation/email.dart';
import 'package:eyesos/features/auth/validation/password.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'signin_event.dart';
import 'signin_state.dart';

class SigninBloc extends Bloc<SigninEvent, SigninState> {
  final AuthRepository _authRepository;

  SigninBloc(this._authRepository) : super(const SigninState()) {
    on<SigninEmailChanged>(_onEmailChanged);
    on<SigninPasswordChanged>(_onPasswordChanged);
    on<SigninSubmitted>(_onSubmitted);
    on<SigninClearForms>(_onClearForms);
    on<GoogleSigninRequested>(_onGoogleSigninRequested);
    on<SigninResetState>(_onResetState);
  }

  void _onEmailChanged(SigninEmailChanged event, Emitter<SigninState> emit) {
    final email = Email.dirty(event.email);
    emit(
      state.copyWith(
        email: email,
        isValid: Formz.validate([email, state.password]),
      ),
    );
  }

  void _onPasswordChanged(
    SigninPasswordChanged event,
    Emitter<SigninState> emit,
  ) {
    final password = Password.dirty(event.password);
    emit(
      state.copyWith(
        password: password,
        isValid: Formz.validate([state.email, password]),
      ),
    );
  }

  Future<void> _onSubmitted(
    SigninSubmitted event,
    Emitter<SigninState> emit,
  ) async {
    if (!state.isValid) return;

    emit(state.copyWith(status: SigninStatus.loading));

    try {
      final user = await _authRepository.signIn(
        email: state.email.value,
        password: state.password.value,
      );
      emit(state.copyWith(status: SigninStatus.success, user: user));
    } catch (e) {
      emit(
        state.copyWith(
          status: SigninStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onGoogleSigninRequested(
    GoogleSigninRequested event,
    Emitter<SigninState> emit,
  ) async {
    emit(state.copyWith(googleSignInStatus: GoogleSignInStatus.loading));

    try {
      final user = await _authRepository.signInWithGoogle();
      final hasPhone = await _authRepository.hasPhoneNumber(user.id);
      emit(
        state.copyWith(
          googleSignInStatus: GoogleSignInStatus.success,
          user: user,
          hasPhoneNumber: hasPhone,
        ),
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        // User pressed back — silently reset, don't show error
        emit(state.copyWith(googleSignInStatus: GoogleSignInStatus.idle));
        return;
      }
      emit(
        state.copyWith(
          googleSignInStatus: GoogleSignInStatus.failure,
          googleSignInErrorMessage: e.description ?? 'Google sign-in failed',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          googleSignInStatus: GoogleSignInStatus.failure,
          googleSignInErrorMessage: e.toString(),
        ),
      );
    }
  }

  void _onClearForms(SigninClearForms event, Emitter<SigninState> emit) {
    emit(const SigninState());
  }

  void _onResetState(SigninResetState event, Emitter<SigninState> emit) {
    emit(
      const SigninState(
        status: SigninStatus.initial,
        googleSignInStatus: GoogleSignInStatus.initial,
      ),
    );
  }
}
