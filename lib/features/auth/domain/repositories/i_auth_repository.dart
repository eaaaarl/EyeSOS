import '../entities/user_entity.dart';

abstract class IAuthRepository {
  Future<UserEntity> signup({
    required String name,
    required String email,
    required String password,
    required String phoneNumber,
  });

  Future<UserEntity> signIn({required String email, required String password});

  Future<UserEntity> signInWithGoogle();

  Future<UserEntity> getCurrentUser(String userId);

  Future<bool> hasPhoneNumber(String userId);

  Future<UserEntity> updatePhoneNumber(String userId, String phoneNumber);

  Future<void> signOut();

  Future<void> signOutGoogle();
}
