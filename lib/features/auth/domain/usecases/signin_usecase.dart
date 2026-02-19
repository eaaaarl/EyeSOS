import '../entities/user_entity.dart';
import '../repositories/i_auth_repository.dart';

class SignInUsecase {
  final IAuthRepository repository;

  SignInUsecase(this.repository);

  Future<UserEntity> call({required String email, required String password}) {
    return repository.signIn(email: email, password: password);
  }
}
