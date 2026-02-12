import 'package:equatable/equatable.dart';

abstract class SignupEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class SignupNameChanged extends SignupEvent {
  final String name;
  SignupNameChanged(this.name);
  @override
  List<Object> get props => [name];
}

class SignupEmailChanged extends SignupEvent {
  final String email;
  SignupEmailChanged(this.email);
  @override
  List<Object> get props => [email];
}

class SignupPasswordChanged extends SignupEvent {
  final String password;
  SignupPasswordChanged(this.password);
  @override
  List<Object> get props => [password];
}

class SignupConfirmPasswordChanged extends SignupEvent {
  final String confirmPassword;
  SignupConfirmPasswordChanged(this.confirmPassword);
  @override
  List<Object> get props => [confirmPassword];
}

class SignupPhoneNumberChanged extends SignupEvent {
  final String phoneNumber;
  SignupPhoneNumberChanged(this.phoneNumber);
  @override
  List<Object> get props => [phoneNumber];
}

class SignupSubmitted extends SignupEvent {}

class SignupClearForms extends SignupEvent {}

class SignupResetState extends SignupEvent {}
