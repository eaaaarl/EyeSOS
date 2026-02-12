import 'package:equatable/equatable.dart';

abstract class SigninEvent extends Equatable {
  const SigninEvent();

  @override
  List<Object> get props => [];
}

class SigninEmailChanged extends SigninEvent {
  const SigninEmailChanged(this.email);

  final String email;

  @override
  List<Object> get props => [email];
}

class SigninPasswordChanged extends SigninEvent {
  const SigninPasswordChanged(this.password);

  final String password;

  @override
  List<Object> get props => [password];
}

class SigninSubmitted extends SigninEvent {
  const SigninSubmitted();
}

class GoogleSigninRequested extends SigninEvent {
  const GoogleSigninRequested();
}

class SigninClearForms extends SigninEvent {
  const SigninClearForms();
}

class SigninResetState extends SigninEvent {
  const SigninResetState();
}
