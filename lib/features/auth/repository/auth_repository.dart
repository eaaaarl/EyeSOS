import 'package:eyesos/features/auth/models/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

enum UserType { bystander, blgu, lgu }

class AuthRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  Future<UserModel> signup({
    required String name,
    required String email,
    required String password,
    required String phoneNumber,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': name, 'phone': phoneNumber},
      );

      if (response.user == null) {
        throw Exception('Signup failed: No user returned');
      }

      await _supabase.from('profiles').insert({
        'id': response.user!.id,
        'name': name,
        'email': email,
        'mobileNo': phoneNumber,
        'user_type': UserType.bystander.name,
      });

      return getCurrentUser(response.user!.id);
    } on AuthException catch (e) {
      throw _getAuthErrorMessage(e);
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Email and Password invalid');
      }
      return getCurrentUser(response.user!.id);
    } on AuthException catch (e) {
      throw _getAuthErrorMessage(e);
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel> signInWithGoogle() async {
    try {
      await _googleSignIn.initialize(
        serverClientId: dotenv.env['GOOGLE_CLIENT_WEB_ID'],
      );

      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

      //await signOutGoogle();

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      final List<String> scopes = ['email', 'profile', 'openid'];

      final authClient = await googleUser.authorizationClient.authorizeScopes(
        scopes,
      );
      final String accessToken = authClient.accessToken;

      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken!,
        accessToken: accessToken,
      );

      if (response.user == null) {
        throw Exception('Google Sign In invalid');
      }

      await _supabase.from('profiles').upsert({
        'id': response.user!.id,
        'name': googleUser.displayName,
        'email': googleUser.email,
        'user_type': UserType.bystander.name,
        'avatarUrl': googleUser.photoUrl,
      });

      return await getCurrentUser(response.user!.id);
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel> getCurrentUser(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      final json = {
        'id': response['id'],
        'email': response['email'],
        'user_metadata': {
          'full_name': response['name'],
          'phone': response['mobileNo'],
          'avatar_url': response['avatarUrl'],
        },
      };

      return UserModel.fromJson(json);
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> hasPhoneNumber(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('mobileNo')
          .eq('id', userId)
          .single();

      final phoneNumber = response['mobileNo'] as String?;
      return phoneNumber != null && phoneNumber.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<UserModel> updatePhoneNumber(String userId, String phoneNumber) async {
    try {
      final updatedUser = await _supabase
          .from('profiles')
          .update({'mobileNo': phoneNumber})
          .eq('id', userId)
          .select()
          .single();

      final json = {
        'id': updatedUser['id'],
        'email': updatedUser['email'],
        'user_metadata': {
          'full_name': updatedUser['name'],
          'phone': updatedUser['mobileNo'],
          'avatar_url': updatedUser['avatarUrl'],
        },
      };

      return UserModel.fromJson(json);
    } catch (e) {
      throw Exception('Failed to update phone number: ${e.toString()}');
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<void> signOutGoogle() async {
    await _googleSignIn.signOut();
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
