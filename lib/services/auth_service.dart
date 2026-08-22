import 'package:supabase_flutter/supabase_flutter.dart';

const String kAdminEmail = 'sameraoaad@gmail.com';

class AuthService {
  AuthService._internal();
  static final AuthService instance = AuthService._internal();

  final SupabaseClient _client = Supabase.instance.client;

  bool get isLoggedIn => _client.auth.currentSession != null;
  User? get currentUser => _client.auth.currentUser;

  bool get isCurrentUserAdmin {
    final email = _client.auth.currentUser?.email;
    return email != null && email.toLowerCase() == kAdminEmail.toLowerCase();
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        if (phone != null) 'phone': phone,
      },
    );
    return response;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}