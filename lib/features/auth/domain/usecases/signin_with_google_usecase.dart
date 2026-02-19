import '../entities/user_entity.dart';
import '../repositories/i_auth_repository.dart';

class SignInWithGoogleUsecase {
  final IAuthRepository repository;

  SignInWithGoogleUsecase(this.repository);

  Future<UserEntity> call() {
    return repository.signInWithGoogle();
  }
}
