/// App State Manager
/// ==================
/// Simple state management using ChangeNotifier

import 'package:flutter/foundation.dart';

/// Global app state
class AppState extends ChangeNotifier {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal();

  // User state
  String? _userId;
  String? _userName;
  String? _userEmail;
  String _userRole = 'customer'; // 'customer' or 'chef'
  bool _isAuthenticated = false;

  // Cart state
  int _cartItemCount = 0;

  // Loading states
  bool _isLoading = false;

  // Getters
  String? get userId => _userId;
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  String get userRole => _userRole;
  bool get isAuthenticated => _isAuthenticated;
  bool get isChef => _userRole == 'chef';
  bool get isCustomer => _userRole == 'customer';
  int get cartItemCount => _cartItemCount;
  bool get isLoading => _isLoading;

  // Setters with notification
  void setUser(String? id, String? name, String? email, {String role = 'customer'}) {
    _userId = id;
    _userName = name;
    _userEmail = email;
    _userRole = role;
    _isAuthenticated = id != null;
    notifyListeners();
  }

  void setUserRole(String role) {
    _userRole = role;
    notifyListeners();
  }

  void clearUser() {
    _userId = null;
    _userName = null;
    _userEmail = null;
    _userRole = 'customer';
    _isAuthenticated = false;
    _cartItemCount = 0;
    notifyListeners();
  }

  void setCartItemCount(int count) {
    _cartItemCount = count;
    notifyListeners();
  }

  void incrementCartCount() {
    _cartItemCount++;
    notifyListeners();
  }

  void decrementCartCount() {
    if (_cartItemCount > 0) {
      _cartItemCount--;
      notifyListeners();
    }
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
