import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';
import '../domain/usecases/signup_usecase.dart';
import '../presentation/validation/confirm_password.dart';
import '../presentation/validation/email.dart';
import '../presentation/validation/name.dart';
import '../presentation/validation/password.dart';
import '../presentation/validation/phone_number.dart';
import 'signup_event.dart';
import 'signup_state.dart';

class SignupBloc extends Bloc<SignupEvent, SignupState> {
  final SignupUsecase _signupUsecase;

  SignupBloc({required SignupUsecase signupUsecase})
    : _signupUsecase = signupUsecase,
      super(const SignupState()) {
    on<SignupNameChanged>(_onNameChanged);
    on<SignupEmailChanged>(_onEmailChanged);
    on<SignupPasswordChanged>(_onPasswordChanged);
    on<SignupConfirmPasswordChanged>(_onConfirmPasswordChanged);
    on<SignupPhoneNumberChanged>(_onPhoneNumberChanged);
    on<SignupSubmitted>(_onSubmitted);
    on<SignupClearForms>(_onClearForms);
  }

  void _onNameChanged(SignupNameChanged event, Emitter<SignupState> emit) {
    final name = Name.dirty(event.name);
    emit(
      state.copyWith(
        name: name,
        isValid: Formz.validate([
          name,
          state.email,
          state.password,
          state.confirmedPassword,
          state.phoneNumber,
        ]),
      ),
    );
  }

  void _onEmailChanged(SignupEmailChanged event, Emitter<SignupState> emit) {
    final email = Email.dirty(event.email);
    emit(
      state.copyWith(
        email: email,
        isValid: Formz.validate([
          state.name,
          email,
          state.password,
          state.confirmedPassword,
          state.phoneNumber,
        ]),
      ),
    );
  }

  void _onPasswordChanged(
    SignupPasswordChanged event,
    Emitter<SignupState> emit,
  ) {
    final password = Password.dirty(event.password);
    final confirmedPassword = ConfirmedPassword.dirty(
      password: event.password,
      value: state.confirmedPassword.value,
    );

    emit(
      state.copyWith(
        password: password,
        confirmedPassword: confirmedPassword,
        isValid: Formz.validate([
          state.name,
          state.email,
          password,
          confirmedPassword,
          state.phoneNumber,
        ]),
      ),
    );
  }

  void _onConfirmPasswordChanged(
    SignupConfirmPasswordChanged event,
    Emitter<SignupState> emit,
  ) {
    final confirmedPassword = ConfirmedPassword.dirty(
      password: state.password.value,
      value: event.confirmPassword,
    );

    emit(
      state.copyWith(
        confirmedPassword: confirmedPassword,
        isValid: Formz.validate([
          state.name,
          state.email,
          state.password,
          confirmedPassword,
          state.phoneNumber,
        ]),
      ),
    );
  }

  void _onPhoneNumberChanged(
    SignupPhoneNumberChanged event,
    Emitter<SignupState> emit,
  ) {
    final phoneNumber = PhoneNumber.dirty(event.phoneNumber);
    emit(
      state.copyWith(
        phoneNumber: phoneNumber,
        isValid: Formz.validate([
          state.name,
          state.email,
          state.password,
          state.confirmedPassword,
          phoneNumber,
        ]),
      ),
    );
  }

  Future<void> _onSubmitted(
    SignupSubmitted event,
    Emitter<SignupState> emit,
  ) async {
    if (!state.isValid) return;

    emit(state.copyWith(status: SignupStatus.loading));

    try {
      final user = await _signupUsecase(
        name: state.name.value,
        email: state.email.value,
        password: state.password.value,
        phoneNumber: state.phoneNumber.value,
      );

      emit(state.copyWith(status: SignupStatus.success, user: user));
    } catch (e) {
      emit(
        state.copyWith(
          status: SignupStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void _onClearForms(SignupClearForms event, Emitter<SignupState> emit) {
    emit(const SignupState());
  }
}
