import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  bool _isLoggedIn = false;
  String? _username;
  String? _email;

  bool get isLoggedIn => _isLoggedIn;
  String? get username => _username;
  String? get email => _email;

  Future<void> checkAuthStatus() async {
    _isLoggedIn = await _authService.isLoggedIn();
    if (_isLoggedIn) {
      _username = await _authService.getUsername();
      _email = await _authService.getEmail();
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    final success = await _authService.login(email, password);
    if (success) {
      _isLoggedIn = true;
      _email = email;
      _username = await _authService.getUsername();
      notifyListeners();
    }
    return success;
  }

  Future<bool> signUp(String username, String email, String password) async {
    final success = await _authService.signUp(username, email, password);
    if (success) {
      _isLoggedIn = true;
      _username = username;
      _email = email;
      notifyListeners();
    }
    return success;
  }

  Future<void> logout() async {
    await _authService.logout();
    _isLoggedIn = false;
    _username = null;
    _email = null;
    notifyListeners();
  }
}

