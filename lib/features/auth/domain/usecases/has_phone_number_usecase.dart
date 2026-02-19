import '../repositories/i_auth_repository.dart';

class HasPhoneNumberUsecase {
  final IAuthRepository repository;

  HasPhoneNumberUsecase(this.repository);

  Future<bool> call(String userId) {
    return repository.hasPhoneNumber(userId);
  }
}
