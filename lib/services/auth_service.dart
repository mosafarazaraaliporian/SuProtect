import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyUsername = 'username';
  static const String _keyEmail = 'email';

  Future<bool> login(String email, String password) async {
    // TODO: Implement actual authentication logic
    // For now, simple validation
    if (email.isNotEmpty && password.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsLoggedIn, true);
      await prefs.setString(_keyEmail, email);
      return true;
    }
    return false;
  }

  Future<bool> signUp(String username, String email, String password) async {
    // TODO: Implement actual sign up logic
    // For now, simple validation
    if (username.isNotEmpty && email.isNotEmpty && password.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsLoggedIn, true);
      await prefs.setString(_keyUsername, username);
      await prefs.setString(_keyEmail, email);
      return true;
    }
    return false;
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUsername);
  }

  Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyEmail);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyUsername);
    await prefs.remove(_keyEmail);
  }
}


