import '../entities/user_entity.dart';
import '../repositories/i_auth_repository.dart';

class GetCurrentUserUsecase {
  final IAuthRepository repository;

  GetCurrentUserUsecase(this.repository);

  Future<UserEntity> call(String userId) {
    return repository.getCurrentUser(userId);
  }
}
