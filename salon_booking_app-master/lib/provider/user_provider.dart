import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserProvider extends ChangeNotifier {
  User? user;

  /// Dùng cho luồng Admin đăng nhập kiểu "admin/admin" hoặc user có role=admin
  bool isAdmin = false;

  void setUser(User? newUser) {
    user = newUser;
    notifyListeners();
  }

  User? getUser() => user;

  void setAdmin(bool value) {
    isAdmin = value;
    notifyListeners();
  }

  // ✅ Thêm hàm này để xóa user khi đăng xuất
  void clearUser() {
    user = null;
    isAdmin = false;
    notifyListeners();
  }
}
