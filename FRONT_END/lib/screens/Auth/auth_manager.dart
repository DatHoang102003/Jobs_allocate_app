import 'package:flutter/foundation.dart';
import '../../services/auth_service.dart';

class AuthManager extends ChangeNotifier {
  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _userId;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get userId => _userId;

  /// Khởi tạo và kiểm tra trạng thái đăng nhập hiện tại
  Future<void> init() async {
    await AuthService.init();
    final token = await AuthService.getToken();
    final uid = await AuthService.getUserId();

    _isAuthenticated = token.isNotEmpty && uid.isNotEmpty;
    _userId = uid.isNotEmpty ? uid : null;
    notifyListeners();
  }

  /// Đăng nhập người dùng
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    final success = await AuthService.loginUser(email, password);
    if (success) {
      _userId = await AuthService.getUserId();
      _isAuthenticated = true;
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  /// Đăng ký người dùng mới
  Future<bool> register(String name, String email, String password,
      String confirmPassword) async {
    _isLoading = true;
    notifyListeners();

    final success =
        await AuthService.registerUser(name, email, password, confirmPassword);

    _isLoading = false;
    notifyListeners();
    return success;
  }

  /// Đăng xuất người dùng
  Future<void> logout() async {
    await AuthService.logoutUser();
    _userId = null;
    _isAuthenticated = false;
    notifyListeners();
  }
}
