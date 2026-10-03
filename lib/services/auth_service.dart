
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<String> login({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );

    final user = response.user;

    if (user == null) {
      throw Exception('Login failed. Please try again.');
    }

    final profile = await _supabase
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .maybeSingle();

    if (profile == null) {
      await _supabase.auth.signOut();
      throw Exception('User profile not found.');
    }

    final role = profile['role'] as String;

    if (role != 'manager' && role != 'owner') {
      await _supabase.auth.signOut();
      throw Exception('Invalid user role.');
    }

    return role;
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
  }
}