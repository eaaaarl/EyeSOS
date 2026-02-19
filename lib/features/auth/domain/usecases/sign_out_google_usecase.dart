import '../repositories/i_auth_repository.dart';

class SignOutGoogleUsecase {
  final IAuthRepository repository;

  SignOutGoogleUsecase(this.repository);

  Future<void> call() {
    return repository.signOutGoogle();
  }
}
