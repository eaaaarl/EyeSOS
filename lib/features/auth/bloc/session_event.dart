import '../domain/entities/user_entity.dart';

abstract class SessionEvent {}

class AuthLoggedIn extends SessionEvent {
  final UserEntity user;

  AuthLoggedIn(this.user);
}

class AuthLoggedOut extends SessionEvent {}
