import 'package:equatable/equatable.dart';
import '../../domain/entities/user_entity.dart';
import '../../data/models/user_model.dart';
import '../validation/email.dart';
import '../validation/password.dart';

enum SigninStatus { initial, loading, success, failure }

enum GoogleSignInStatus { idle, initial, loading, success, failure }

class SigninState extends Equatable {
  const SigninState({
    this.status = SigninStatus.initial,
    this.googleSignInStatus = GoogleSignInStatus.initial,
    this.email = const Email.pure(),
    this.password = const Password.pure(),
    this.isValid = false,
    this.errorMessage,
    this.user,
    this.googleSignInErrorMessage,
    this.hasPhoneNumber = false,
  });

  // GOOGLE SIGNIN
  final GoogleSignInStatus googleSignInStatus;
  final String? googleSignInErrorMessage;
  // EMAIL SIGNIN
  final SigninStatus status;
  final Email email;
  final Password password;
  final bool isValid;
  final String? errorMessage;
  final UserEntity? user;
  final bool hasPhoneNumber;

  SigninState copyWith({
    GoogleSignInStatus? googleSignInStatus,
    String? googleSignInErrorMessage,
    SigninStatus? status,
    Email? email,
    Password? password,
    bool? isValid,
    String? errorMessage,
    UserEntity? user,
    bool? hasPhoneNumber,
  }) {
    return SigninState(
      googleSignInStatus: googleSignInStatus ?? this.googleSignInStatus,
      googleSignInErrorMessage:
          googleSignInErrorMessage ?? this.googleSignInErrorMessage,
      status: status ?? this.status,
      email: email ?? this.email,
      password: password ?? this.password,
      isValid: isValid ?? this.isValid,
      errorMessage: errorMessage ?? this.errorMessage,
      user: user ?? this.user,
      hasPhoneNumber: hasPhoneNumber ?? this.hasPhoneNumber,
    );
  }

  Map<String, dynamic> toMap() {
    return {'status': status.index, 'user': (user as UserModel?)?.toJson()};
  }

  factory SigninState.fromMap(Map<String, dynamic> map) {
    return SigninState(
      status: SigninStatus.values[map['status'] ?? 0],
      user: map['user'] != null ? UserModel.fromJson(map['user']) : null,
      // We keep these pure because we don't need to save half-typed passwords!
      email: const Email.pure(),
      password: const Password.pure(),
      isValid: false,
    );
  }

  @override
  List<Object?> get props => [
    googleSignInStatus,
    googleSignInErrorMessage,
    status,
    email,
    password,
    isValid,
    errorMessage,
    user,
    hasPhoneNumber,
  ];
}
