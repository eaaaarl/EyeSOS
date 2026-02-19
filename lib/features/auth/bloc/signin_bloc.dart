import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../domain/usecases/signin_usecase.dart';
import '../domain/usecases/signin_with_google_usecase.dart';
import '../domain/usecases/has_phone_number_usecase.dart';
import '../presentation/validation/email.dart';
import '../presentation/validation/password.dart';
import 'signin_event.dart';
import 'signin_state.dart';

class SigninBloc extends Bloc<SigninEvent, SigninState> {
  final SignInUsecase _signInUsecase;
  final SignInWithGoogleUsecase _signInWithGoogleUsecase;
  final HasPhoneNumberUsecase _hasPhoneNumberUsecase;

  SigninBloc({
    required SignInUsecase signInUsecase,
    required SignInWithGoogleUsecase signInWithGoogleUsecase,
    required HasPhoneNumberUsecase hasPhoneNumberUsecase,
  }) : _signInUsecase = signInUsecase,
       _signInWithGoogleUsecase = signInWithGoogleUsecase,
       _hasPhoneNumberUsecase = hasPhoneNumberUsecase,
       super(const SigninState()) {
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
      final user = await _signInUsecase(
        email: state.email.value,
        password: state.password.value,
      );
      final hasPhone = await _hasPhoneNumberUsecase(user.id);
      emit(
        state.copyWith(
          status: SigninStatus.success,
          user: user,
          hasPhoneNumber: hasPhone,
        ),
      );
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
      final user = await _signInWithGoogleUsecase();
      final hasPhone = await _hasPhoneNumberUsecase(user.id);
      emit(
        state.copyWith(
          googleSignInStatus: GoogleSignInStatus.success,
          user: user,
          hasPhoneNumber: hasPhone,
        ),
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
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
