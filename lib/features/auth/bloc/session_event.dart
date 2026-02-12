import 'package:eyesos/features/auth/models/user_model.dart';

abstract class SessionEvent {}

class AuthLoggedIn extends SessionEvent {
  final UserModel user;

  AuthLoggedIn(this.user);
}

class AuthLoggedOut extends SessionEvent {}
