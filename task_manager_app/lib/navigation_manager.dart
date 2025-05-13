import 'package:flutter/material.dart';

class NavigationManager with ChangeNotifier {
  int _selectedIndex = 0;

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  int get selectedIndex => _selectedIndex;

  void setSelectedIndex(int index) {
    _selectedIndex = index;
    notifyListeners();
  }

  /// Hàm push dùng để chuyển trang mà không cần context
  static Future<dynamic> push(Widget page) {
    return navigatorKey.currentState!.push(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  /// Optional: thêm hàm pop nếu bạn cần quay lại
  static void pop() {
    navigatorKey.currentState!.pop();
  }
}
