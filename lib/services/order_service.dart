/// Order Service
/// ==============
/// Handles order operations with Flask backend

import 'api_service.dart';
import 'api_config.dart';

class OrderService {
  /// Create a new order
  static Future<ApiResponse> createOrder({
    required List<Map<String, dynamic>> items,
    required String deliveryAddress,
    String? deliveryNotes,
    String paymentMethod = 'cash',
  }) async {
    return await ApiService.post(
      ApiConfig.orders,
      body: {
        'items': items,
        'deliveryAddress': deliveryAddress,
        'deliveryNotes': deliveryNotes ?? '',
        'paymentMethod': paymentMethod,
      },
    );
  }
  
  /// Get all orders for current user
  static Future<ApiResponse> getOrders() async {
    return await ApiService.get(ApiConfig.orders);
  }
  
  /// Get single order by ID
  static Future<ApiResponse> getOrder(String orderId) async {
    return await ApiService.get(ApiConfig.orderById(orderId));
  }
  
  /// Cancel an order
  static Future<ApiResponse> cancelOrder(String orderId) async {
    return await ApiService.post(ApiConfig.cancelOrder(orderId));
  }
}


/// Order model
class Order {
  final String id;
  final String userId;
  final List<OrderItem> items;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final String deliveryAddress;
  final String deliveryNotes;
  final String paymentMethod;
  final String status;
  final DateTime createdAt;
  
  Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.deliveryAddress,
    required this.deliveryNotes,
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
  });
  
  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      items: (json['items'] as List?)
          ?.map((item) => OrderItem.fromJson(item))
          .toList() ?? [],
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      deliveryFee: (json['deliveryFee'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
      deliveryAddress: json['deliveryAddress'] ?? '',
      deliveryNotes: json['deliveryNotes'] ?? '',
      paymentMethod: json['paymentMethod'] ?? 'cash',
      status: json['status'] ?? 'pending',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
  
  String get statusText {
    switch (status) {
      case 'pending': return 'قيد الانتظار';
      case 'confirmed': return 'مؤكد';
      case 'preparing': return 'قيد التحضير';
      case 'on_the_way': return 'في الطريق';
      case 'delivered': return 'تم التوصيل';
      case 'cancelled': return 'ملغي';
      default: return status;
    }
  }
}


class OrderItem {
  final String dishId;
  final String dishName;
  final int quantity;
  final double price;
  final String cookerId;
  final String cookerName;
  
  OrderItem({
    required this.dishId,
    required this.dishName,
    required this.quantity,
    required this.price,
    required this.cookerId,
    required this.cookerName,
  });
  
  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      dishId: json['dishId'] ?? '',
      dishName: json['dishName'] ?? '',
      quantity: json['quantity'] ?? 1,
      price: (json['price'] ?? 0).toDouble(),
      cookerId: json['cookerId'] ?? '',
      cookerName: json['cookerName'] ?? '',
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'dishId': dishId,
      'dishName': dishName,
      'quantity': quantity,
      'price': price,
      'cookerId': cookerId,
      'cookerName': cookerName,
    };
  }
}
