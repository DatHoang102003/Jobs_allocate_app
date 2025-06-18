import 'package:flutter/foundation.dart';
import '../../services/auth_service.dart';

class AuthManager extends ChangeNotifier {
  bool _isLoading        = false;
  bool _isAuthenticated  = false;
  String? _userId;
  String? _lastError;               // optional: expose recent error

  bool get isLoading       => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get userId       => _userId;
  String? get lastError    => _lastError;

  /* ───────── init from SharedPreferences ───────── */
  Future<void> init() async {
    await AuthService.init();
    final token = await AuthService.getToken();
    final uid   = await AuthService.getUserId();

    _isAuthenticated = token.isNotEmpty && uid.isNotEmpty;
    _userId          = uid.isNotEmpty ? uid : null;
    notifyListeners();
  }

  /* ───────── login ───────── */
  Future<bool> login(String email, String password) async {
    _isLoading  = true;
    _lastError  = null;
    notifyListeners();

    bool success = false;
    try {
      await AuthService.loginUser(email, password);   // throws on failure
      _userId          = await AuthService.getUserId();
      _isAuthenticated = true;
      success = true;
    } catch (e) {
      _lastError = e.toString();
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  /* ───────── register ───────── */
  Future<bool> register(
    String name,
    String email,
    String password,
    String confirmPassword,
  ) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    bool success = false;
    try {
      await AuthService.registerUser(name, email, password, confirmPassword);
      success = true;                          // registration OK
    } catch (e) {
      _lastError = e.toString();
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  /* ───────── logout ───────── */
  Future<void> logout() async {
    await AuthService.logoutUser();
    _userId          = null;
    _isAuthenticated = false;
    notifyListeners();
  }
}
