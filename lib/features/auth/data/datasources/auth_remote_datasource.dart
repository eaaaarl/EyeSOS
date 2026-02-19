import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/user_model.dart';

class AuthRemoteDatasource {
  final SupabaseClient _supabase = Supabase.instance.client;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  Future<UserModel> signup({
    required String name,
    required String email,
    required String password,
    required String phoneNumber,
  }) async {
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
      'user_type': 'bystander',
    });

    return getCurrentUser(response.user!.id);
  }

  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user == null) {
      throw Exception('Email and Password invalid');
    }
    return getCurrentUser(response.user!.id);
  }

  Future<UserModel> signInWithGoogle() async {
    await _googleSignIn.initialize(
      serverClientId: dotenv.env['GOOGLE_CLIENT_WEB_ID'],
    );

    final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

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
      'user_type': 'bystander',
      'avatarUrl': googleUser.photoUrl,
    });

    return await getCurrentUser(response.user!.id);
  }

  Future<UserModel> getCurrentUser(String userId) async {
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
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<void> signOutGoogle() async {
    await _googleSignIn.signOut();
  }
}
