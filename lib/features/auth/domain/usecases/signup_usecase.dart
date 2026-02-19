import '../entities/user_entity.dart';
import '../repositories/i_auth_repository.dart';

class SignupUsecase {
  final IAuthRepository repository;

  SignupUsecase(this.repository);

  Future<UserEntity> call({
    required String name,
    required String email,
    required String password,
    required String phoneNumber,
  }) {
    return repository.signup(
      name: name,
      email: email,
      password: password,
      phoneNumber: phoneNumber,
    );
  }
}
