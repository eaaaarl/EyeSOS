import '../repositories/i_auth_repository.dart';

class SignOutUsecase {
  final IAuthRepository repository;

  SignOutUsecase(this.repository);

  Future<void> call() {
    return repository.signOut();
  }
}
