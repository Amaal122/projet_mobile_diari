/// Cart Service
/// =============
/// Handles shopping cart operations with Flask backend

import 'api_service.dart';
import 'api_config.dart';

class CartService {
  /// Get current cart
  static Future<ApiResponse> getCart() async {
    return await ApiService.get(ApiConfig.cart);
  }
  
  /// Add item to cart
  static Future<ApiResponse> addToCart({
    required String dishId,
    required String dishName,
    required double price,
    required int quantity,
    String? dishImage,
    String? cookerId,
    String? cookerName,
  }) async {
    return await ApiService.post(
      ApiConfig.cartAdd,
      body: {
        'dishId': dishId,
        'dishName': dishName,
        'dishImage': dishImage ?? '',
        'price': price,
        'quantity': quantity,
        'cookerId': cookerId ?? '',
        'cookerName': cookerName ?? '',
      },
    );
  }
  
  /// Update item quantity
  static Future<ApiResponse> updateQuantity({
    required String dishId,
    required int quantity,
  }) async {
    return await ApiService.put(
      ApiConfig.cartUpdate,
      body: {
        'dishId': dishId,
        'quantity': quantity,
      },
    );
  }
  
  /// Remove item from cart
  static Future<ApiResponse> removeFromCart(String dishId) async {
    return await ApiService.delete(ApiConfig.cartRemove(dishId));
  }
  
  /// Clear entire cart
  static Future<ApiResponse> clearCart() async {
    return await ApiService.delete(ApiConfig.cartClear);
  }
}


/// Cart model
class Cart {
  final List<CartItemModel> items;
  final double total;
  
  Cart({required this.items, required this.total});
  
  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      items: (json['items'] as List?)
          ?.map((item) => CartItemModel.fromJson(item))
          .toList() ?? [],
      total: (json['total'] ?? 0).toDouble(),
    );
  }
  
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
  
  bool get isEmpty => items.isEmpty;
}


class CartItemModel {
  final String dishId;
  final String dishName;
  final String dishImage;
  final double price;
  int quantity;
  final String cookerId;
  final String cookerName;
  
  CartItemModel({
    required this.dishId,
    required this.dishName,
    required this.dishImage,
    required this.price,
    required this.quantity,
    required this.cookerId,
    required this.cookerName,
  });
  
  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      dishId: json['dishId'] ?? '',
      dishName: json['dishName'] ?? '',
      dishImage: json['dishImage'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 1,
      cookerId: json['cookerId'] ?? '',
      cookerName: json['cookerName'] ?? '',
    );
  }
  
  double get totalPrice => price * quantity;
}
