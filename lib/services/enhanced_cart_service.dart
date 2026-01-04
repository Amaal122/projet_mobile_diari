/// Enhanced CartService with Local Storage + API Fallback
/// ========================================================
/// Uses local storage for Flutter Web, with optional backend sync

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';
import 'auth_service.dart';

class CartService {
  // Cart state
  static final List<CartItem> _items = [];
  static double _deliveryFee = 3.0;
  static const String _cartKey = 'diari_cart';
  
  // Getters
  static List<CartItem> get items => List.unmodifiable(_items);
  static double get subtotal => _items.fold(0, (sum, item) => sum + (item.price * item.quantity));
  static double get deliveryFee => _deliveryFee;
  static double get total => subtotal + deliveryFee;
  static int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  static bool get isEmpty => _items.isEmpty;
  
  /// Load cart - tries API first, falls back to local storage
  static Future<List<CartItem>> loadCart() async {
    // Try to load from local storage first (faster)
    await _loadFromLocalStorage();
    
    // Try to sync with backend (might fail on web due to CORS)
    try {
      final user = AuthService.currentUser;
      if (user == null) return _items;
      
      final token = await user.getIdToken();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/cart'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _items.clear();
        
        for (var item in data['items'] ?? []) {
          _items.add(CartItem.fromJson(item));
        }
        await _saveToLocalStorage();
      }
    } catch (e) {
      print('API cart load failed (using local): $e');
      // Local storage already loaded, continue with that
    }
    
    return _items;
  }
  
  /// Add item to cart
  static Future<bool> addItem({
    required String dishId,
    required String dishName,
    required double price,
    required String image,
    required String cookerId,
    required String cookerName,
    int quantity = 1,
  }) async {
    // Check if item already exists
    final existingIndex = _items.indexWhere((item) => item.dishId == dishId);
    
    if (existingIndex >= 0) {
      // Update quantity
      final existing = _items[existingIndex];
      _items[existingIndex] = CartItem(
        dishId: existing.dishId,
        dishName: existing.dishName,
        price: existing.price,
        image: existing.image,
        cookerId: existing.cookerId,
        cookerName: existing.cookerName,
        quantity: existing.quantity + quantity,
      );
    } else {
      // Add new item
      _items.add(CartItem(
        dishId: dishId,
        dishName: dishName,
        price: price,
        image: image,
        cookerId: cookerId,
        cookerName: cookerName,
        quantity: quantity,
      ));
    }
    
    // Save locally
    await _saveToLocalStorage();
    
    // Try to sync with backend (don't block on failure)
    _syncWithBackend();
    
    return true;
  }
  
  /// Update item quantity
  static Future<bool> updateQuantity(String dishId, int quantity) async {
    if (quantity <= 0) {
      return await removeItem(dishId);
    }
    
    final index = _items.indexWhere((item) => item.dishId == dishId);
    if (index < 0) return false;
    
    final existing = _items[index];
    _items[index] = CartItem(
      dishId: existing.dishId,
      dishName: existing.dishName,
      price: existing.price,
      image: existing.image,
      cookerId: existing.cookerId,
      cookerName: existing.cookerName,
      quantity: quantity,
    );
    
    await _saveToLocalStorage();
    _syncWithBackend();
    
    return true;
  }
  
  /// Remove item from cart
  static Future<bool> removeItem(String dishId) async {
    _items.removeWhere((item) => item.dishId == dishId);
    await _saveToLocalStorage();
    _syncWithBackend();
    return true;
  }
  
  /// Clear entire cart
  static Future<bool> clearCart() async {
    _items.clear();
    await _saveToLocalStorage();
    _syncWithBackend();
    return true;
  }
  
  /// Increment quantity
  static Future<bool> incrementQuantity(String dishId) async {
    final item = _items.firstWhere((item) => item.dishId == dishId, orElse: () => CartItem.empty());
    if (item.dishId.isEmpty) return false;
    return await updateQuantity(dishId, item.quantity + 1);
  }
  
  /// Decrement quantity
  static Future<bool> decrementQuantity(String dishId) async {
    final item = _items.firstWhere((item) => item.dishId == dishId, orElse: () => CartItem.empty());
    if (item.dishId.isEmpty) return false;
    return await updateQuantity(dishId, item.quantity - 1);
  }
  
  // ===== LOCAL STORAGE METHODS =====
  
  static Future<void> _loadFromLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = prefs.getString(_cartKey);
      
      if (cartJson != null) {
        final List<dynamic> cartList = json.decode(cartJson);
        _items.clear();
        for (var item in cartList) {
          _items.add(CartItem.fromJson(item));
        }
      }
    } catch (e) {
      print('Error loading cart from local storage: $e');
    }
  }
  
  static Future<void> _saveToLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartList = _items.map((item) => item.toJson()).toList();
      await prefs.setString(_cartKey, json.encode(cartList));
    } catch (e) {
      print('Error saving cart to local storage: $e');
    }
  }
  
  // ===== BACKEND SYNC (OPTIONAL) =====
  
  static Future<void> _syncWithBackend() async {
    try {
      final user = AuthService.currentUser;
      if (user == null) return;
      
      final token = await user.getIdToken();
      
      // Clear and re-add all items
      await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/cart/clear'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 3));
      
      for (var item in _items) {
        await http.post(
          Uri.parse('${ApiConfig.baseUrl}/cart/add'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'dishId': item.dishId,
            'dishName': item.dishName,
            'price': item.price,
            'dishImage': item.image,
            'cookerId': item.cookerId,
            'cookerName': item.cookerName,
            'quantity': item.quantity,
          }),
        ).timeout(const Duration(seconds: 3));
      }
    } catch (e) {
      // Backend sync failed - that's OK, local storage is primary
      print('Backend cart sync failed (not critical): $e');
    }
  }
}

/// Cart Item Model
class CartItem {
  final String dishId;
  final String dishName;
  final double price;
  final String image;
  final String cookerId;
  final String cookerName;
  final int quantity;
  
  CartItem({
    required this.dishId,
    required this.dishName,
    required this.price,
    required this.image,
    required this.cookerId,
    required this.cookerName,
    required this.quantity,
  });
  
  factory CartItem.empty() => CartItem(
    dishId: '',
    dishName: '',
    price: 0,
    image: '',
    cookerId: '',
    cookerName: '',
    quantity: 0,
  );
  
  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      dishId: json['dishId'] ?? '',
      dishName: json['dishName'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      image: json['dishImage'] ?? json['image'] ?? '',
      cookerId: json['cookerId'] ?? '',
      cookerName: json['cookerName'] ?? '',
      quantity: json['quantity'] ?? 1,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'dishId': dishId,
      'dishName': dishName,
      'price': price,
      'dishImage': image,
      'image': image,
      'cookerId': cookerId,
      'cookerName': cookerName,
      'quantity': quantity,
    };
  }
}
