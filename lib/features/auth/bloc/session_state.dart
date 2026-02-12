import 'package:eyesos/features/auth/models/user_model.dart';
import 'package:equatable/equatable.dart';

abstract class SessionState extends Equatable {
  @override
  List<Object?> get props => [];
}

class SessionInitial extends SessionState {}

class AuthAuthenticated extends SessionState {
  final UserModel user;

  AuthAuthenticated({required this.user});

  String get userId => user.id;
  String get email => user.email;
  String? get fullName => user.fullName;
  String? get phoneNumber => user.phoneNumber;

  Map<String, dynamic> toJson() => user.toJson();

  @override
  List<Object?> get props => [user];
}
