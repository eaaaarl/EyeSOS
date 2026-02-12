import 'package:equatable/equatable.dart';
import 'package:eyesos/features/auth/models/user_model.dart';
import 'package:eyesos/features/auth/validation/confirm_password.dart';
import 'package:eyesos/features/auth/validation/email.dart';
import 'package:eyesos/features/auth/validation/name.dart';
import 'package:eyesos/features/auth/validation/password.dart';
import 'package:eyesos/features/auth/validation/phone_number.dart';

enum SignupStatus { initial, loading, success, failure }

class SignupState extends Equatable {
  const SignupState({
    this.status = SignupStatus.initial,
    this.name = const Name.pure(),
    this.email = const Email.pure(),
    this.password = const Password.pure(),
    this.confirmedPassword = const ConfirmedPassword.pure(),
    this.phoneNumber = const PhoneNumber.pure(),
    this.isValid = false,
    this.errorMessage,
    this.user,
  });

  final SignupStatus status;
  final Name name;
  final Email email;
  final Password password;
  final ConfirmedPassword confirmedPassword;
  final PhoneNumber phoneNumber;
  final bool isValid;
  final String? errorMessage;
  final UserModel? user;

  SignupState copyWith({
    SignupStatus? status,
    Name? name,
    Email? email,
    Password? password,
    ConfirmedPassword? confirmedPassword,
    PhoneNumber? phoneNumber,
    bool? isValid,
    String? errorMessage,
    UserModel? user,
  }) {
    return SignupState(
      status: status ?? this.status,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      confirmedPassword: confirmedPassword ?? this.confirmedPassword,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isValid: isValid ?? this.isValid,
      errorMessage: errorMessage ?? this.errorMessage,
      user: user ?? this.user,
    );
  }

  @override
  List<Object?> get props => [
    status,
    name,
    email,
    password,
    confirmedPassword,
    phoneNumber,
    isValid,
    errorMessage,
    user,
  ];
}
