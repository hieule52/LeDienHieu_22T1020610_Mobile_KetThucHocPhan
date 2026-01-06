import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthController extends ChangeNotifier {
  String? _token;
  bool _isLoading = false;

  String? get token => _token;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;
  bool get isLoading => _isLoading;

  AuthController() {
    _loadToken();
  }

  Future<void> _loadToken() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token');
    } catch (e) {
      if (kDebugMode) {
        print('Error loading token: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Import http at top if needed, or use ApiService
      final response = await _performLogin(username, password);

      if (response['success'] == true && response['token'] != null) {
        _token = response['token'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      if (kDebugMode) {
        print('Login error: $e');
      }
      return false;
    }
  }

  Future<Map<String, dynamic>> _performLogin(
      String username, String password) async {
    // This will be handled in LoginScreen directly
    // Return empty for now, actual login happens in LoginScreen
    return {'success': false};
  }

  Future<void> logout() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    notifyListeners();
  }

  Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    notifyListeners();
  }

  Future<void> checkAuth() async {
    await _loadToken();
  }
}

