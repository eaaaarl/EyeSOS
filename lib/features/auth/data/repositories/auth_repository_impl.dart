import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements IAuthRepository {
  final AuthRemoteDatasource remoteDatasource;

  AuthRepositoryImpl(this.remoteDatasource);

  @override
  Future<UserEntity> signup({
    required String name,
    required String email,
    required String password,
    required String phoneNumber,
  }) async {
    try {
      return await remoteDatasource.signup(
        name: name,
        email: email,
        password: password,
        phoneNumber: phoneNumber,
      );
    } on AuthException catch (e) {
      throw _getAuthErrorMessage(e);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<UserEntity> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await remoteDatasource.signIn(email: email, password: password);
    } on AuthException catch (e) {
      throw _getAuthErrorMessage(e);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<UserEntity> signInWithGoogle() async {
    try {
      return await remoteDatasource.signInWithGoogle();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<UserEntity> getCurrentUser(String userId) async {
    try {
      return await remoteDatasource.getCurrentUser(userId);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<bool> hasPhoneNumber(String userId) async {
    return await remoteDatasource.hasPhoneNumber(userId);
  }

  @override
  Future<UserEntity> updatePhoneNumber(
    String userId,
    String phoneNumber,
  ) async {
    try {
      return await remoteDatasource.updatePhoneNumber(userId, phoneNumber);
    } catch (e) {
      throw Exception('Failed to update phone number: ${e.toString()}');
    }
  }

  @override
  Future<void> signOut() async {
    await remoteDatasource.signOut();
  }

  @override
  Future<void> signOutGoogle() async {
    await remoteDatasource.signOutGoogle();
  }

  String _getAuthErrorMessage(AuthException e) {
    final message = e.message.toLowerCase();

    if (message.contains('already') ||
        message.contains('exists') ||
        message.contains('registered') ||
        message.contains('duplicate')) {
      return 'This email is already registered';
    }

    if (message.contains('invalid') || message.contains('format')) {
      return 'Invalid email or password format';
    }

    if (message.contains('weak')) {
      return 'Password is too weak';
    }

    if (e.statusCode == '429') {
      return 'Too many requests. Please try again later';
    }

    return e.message;
  }
}
