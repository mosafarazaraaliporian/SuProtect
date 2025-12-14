import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'firebase_service.dart';
import 'logger_service.dart';

class AuthService {
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyAccessToken = 'access_token';
  static const String _keyUserId = 'user_id';
  static const String _keyUsername = 'username';
  static const String _keyEmail = 'email';

  Future<bool> login(String email, String password) async {
    try {
      // Get FCM token for notifications
      String? fcmToken = FirebaseService().fcmToken;
      
      final response = await ApiService.login(
        email: email,
        password: password,
        fcmToken: fcmToken,
      );
      
      if (response['access_token'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_keyIsLoggedIn, true);
        await prefs.setString(_keyAccessToken, response['access_token']);
        await prefs.setString(_keyUserId, response['user_id']);
        await prefs.setString(_keyUsername, response['username'] ?? '');
        await prefs.setString(_keyEmail, response['email'] ?? email);
        
        // Set token in API service
        ApiService.setAccessToken(response['access_token']);
        
        LoggerService.i('AuthService', 'Login successful: ${response['email']}');
        return true;
      }
      return false;
    } catch (e) {
      LoggerService.e('AuthService', 'Login error', e);
      return false;
    }
  }

  Future<bool> signUp(String username, String email, String password) async {
    try {
      // Get FCM token for notifications
      String? fcmToken = FirebaseService().fcmToken;
      
      final response = await ApiService.register(
        username: username,
        email: email,
        password: password,
        fcmToken: fcmToken,
      );
      
      if (response['access_token'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_keyIsLoggedIn, true);
        await prefs.setString(_keyAccessToken, response['access_token']);
        await prefs.setString(_keyUserId, response['user_id']);
        await prefs.setString(_keyUsername, response['username'] ?? username);
        await prefs.setString(_keyEmail, response['email'] ?? email);
        
        // Set token in API service
        ApiService.setAccessToken(response['access_token']);
        
        LoggerService.i('AuthService', 'Signup successful: ${response['email']}');
        return true;
      }
      return false;
    } catch (e) {
      LoggerService.e('AuthService', 'Signup error', e);
      return false;
    }
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
    
    if (isLoggedIn) {
      // Restore token
      final token = prefs.getString(_keyAccessToken);
      if (token != null) {
        ApiService.setAccessToken(token);
      }
    }
    
    return isLoggedIn;
  }

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAccessToken);
  }

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserId);
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
    await prefs.remove(_keyAccessToken);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUsername);
    await prefs.remove(_keyEmail);
    
    ApiService.clearAuth();
    
    LoggerService.i('AuthService', 'Logged out');
  }
}
