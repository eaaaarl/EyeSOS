import '../entities/user_entity.dart';
import '../repositories/i_auth_repository.dart';

class UpdatePhoneNumberUsecase {
  final IAuthRepository repository;

  UpdatePhoneNumberUsecase(this.repository);

  Future<UserEntity> call(String userId, String phoneNumber) {
    return repository.updatePhoneNumber(userId, phoneNumber);
  }
}
