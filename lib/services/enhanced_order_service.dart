/// Enhanced OrderService with Firestore Direct Access
/// ===================================================
/// Creates orders directly in Firestore (no Flask API needed for web)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';
import 'enhanced_cart_service.dart';

class OrderService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final CollectionReference _ordersRef = _db.collection('orders');
  
  /// Create new order from cart - directly to Firestore
  static Future<Order?> createOrder({
    required String deliveryAddress,
    required String phone,
    String? notes,
    String paymentMethod = 'cash',
  }) async {
    try {
      final user = AuthService.currentUser;
      if (user == null) {
        print('Order error: User not logged in');
        return null;
      }
      
      // Get cart items
      final cartItems = await CartService.loadCart();
      if (cartItems.isEmpty) {
        print('Order error: Cart is empty');
        return null;
      }
      
      // Calculate totals
      final double subtotal = cartItems.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
      const double deliveryFee = 3.0;
      final double total = subtotal + deliveryFee;
      
      // Prepare order items
      final orderItems = cartItems.map((item) => {
        'dishId': item.dishId,
        'dishName': item.dishName,
        'dishImage': item.image,
        'price': item.price,
        'quantity': item.quantity,
        'cookerId': item.cookerId,
        'cookerName': item.cookerName,
      }).toList();
      
      // Get chef ID from first item (all items should be from same chef)
      final String? chefId = cartItems.isNotEmpty ? cartItems.first.cookerId : null;
      
      print('OrderService: Creating order with chefId: $chefId');
      print('OrderService: Cart items: ${cartItems.length}');
      for (var item in cartItems) {
        print('  - ${item.dishName}: cookerId=${item.cookerId}');
      }
      
      // Create order document
      final orderData = {
        'userId': user.uid,
        'userEmail': user.email,
        'userName': user.displayName ?? 'زبون',
        'chefId': chefId, // Add chef ID for filtering
        'cookerId': chefId, // Also add as cookerId for backward compatibility
        'items': orderItems,
        'subtotal': subtotal,
        'deliveryFee': deliveryFee,
        'total': total,
        'status': 'pending',
        'deliveryAddress': deliveryAddress,
        'phone': phone,
        'notes': notes ?? '',
        'paymentMethod': paymentMethod,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      // Add to Firestore
      final docRef = await _ordersRef.add(orderData);
      
      print('Order created successfully with ID: ${docRef.id}');
      
      // Return the created order
      return Order(
        id: docRef.id,
        userId: user.uid,
        items: cartItems.map((item) => OrderItem(
          dishId: item.dishId,
          dishName: item.dishName,
          dishImage: item.image,
          price: item.price,
          quantity: item.quantity,
          cookerId: item.cookerId,
          cookerName: item.cookerName,
        )).toList(),
        subtotal: subtotal,
        deliveryFee: deliveryFee,
        total: total,
        status: 'pending',
        deliveryAddress: deliveryAddress,
        phone: phone,
        notes: notes,
        paymentMethod: paymentMethod,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      print('Error creating order: $e');
      return null;
    }
  }
  
  /// Get order history for current user
  static Future<List<Order>> getOrderHistory() async {
    try {
      final user = AuthService.currentUser;
      if (user == null) return [];
      
      // Use simple query without orderBy to avoid index requirement
      final snapshot = await _ordersRef
          .where('userId', isEqualTo: user.uid)
          .get();
      
      final orders = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Order.fromFirestore(doc.id, data);
      }).toList();
      
      // Sort locally by createdAt descending
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    } catch (e) {
      print('Error fetching order history: $e');
      return [];
    }
  }
  
  /// Get specific order details
  static Future<Order?> getOrderById(String orderId) async {
    try {
      final doc = await _ordersRef.doc(orderId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return Order.fromFirestore(doc.id, data);
      }
      return null;
    } catch (e) {
      print('Error fetching order: $e');
      return null;
    }
  }
  
  /// Cancel an order
  static Future<bool> cancelOrder(String orderId) async {
    try {
      await _ordersRef.doc(orderId).update({
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error canceling order: $e');
      return false;
    }
  }
  
  /// Track order status
  static Future<String?> getOrderStatus(String orderId) async {
    final order = await getOrderById(orderId);
    return order?.status;
  }
  
  /// Stream order updates in real-time
  static Stream<Order?> watchOrder(String orderId) {
    return _ordersRef.doc(orderId).snapshots().map((doc) {
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return Order.fromFirestore(doc.id, data);
      }
      return null;
    });
  }
}

/// Order Model
class Order {
  final String id;
  final String userId;
  final List<OrderItem> items;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final String status;
  final String deliveryAddress;
  final String phone;
  final String? notes;
  final String paymentMethod;
  final DateTime createdAt;
  final DateTime? deliveredAt;
  
  Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.status,
    required this.deliveryAddress,
    required this.phone,
    this.notes,
    required this.paymentMethod,
    required this.createdAt,
    this.deliveredAt,
  });
  
  factory Order.fromFirestore(String id, Map<String, dynamic> data) {
    // Handle Firestore Timestamp
    DateTime createdAt;
    if (data['createdAt'] is Timestamp) {
      createdAt = (data['createdAt'] as Timestamp).toDate();
    } else if (data['createdAt'] is String) {
      createdAt = DateTime.parse(data['createdAt']);
    } else {
      createdAt = DateTime.now();
    }
    
    DateTime? deliveredAt;
    if (data['deliveredAt'] != null) {
      if (data['deliveredAt'] is Timestamp) {
        deliveredAt = (data['deliveredAt'] as Timestamp).toDate();
      } else if (data['deliveredAt'] is String) {
        deliveredAt = DateTime.parse(data['deliveredAt']);
      }
    }
    
    return Order(
      id: id,
      userId: data['userId'] ?? '',
      items: (data['items'] as List? ?? [])
          .map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      subtotal: (data['subtotal'] ?? 0).toDouble(),
      deliveryFee: (data['deliveryFee'] ?? 0).toDouble(),
      total: (data['total'] ?? 0).toDouble(),
      status: data['status'] ?? 'pending',
      deliveryAddress: data['deliveryAddress'] ?? '',
      phone: data['phone'] ?? '',
      notes: data['notes'],
      paymentMethod: data['paymentMethod'] ?? 'cash',
      createdAt: createdAt,
      deliveredAt: deliveredAt,
    );
  }
  
  factory Order.fromJson(Map<String, dynamic> json) {
    return Order.fromFirestore(json['id'] ?? '', json);
  }
  
  String get statusArabic {
    switch (status) {
      case 'pending':
        return 'قيد الانتظار';
      case 'confirmed':
        return 'تم التأكيد';
      case 'preparing':
        return 'قيد التحضير';
      case 'on_the_way':
        return 'في الطريق';
      case 'delivered':
        return 'تم التوصيل';
      case 'cancelled':
        return 'ملغى';
      default:
        return status;
    }
  }
}

/// Order Item Model
class OrderItem {
  final String dishId;
  final String dishName;
  final String dishImage;
  final double price;
  final int quantity;
  final String cookerId;
  final String cookerName;
  
  OrderItem({
    required this.dishId,
    required this.dishName,
    required this.dishImage,
    required this.price,
    required this.quantity,
    required this.cookerId,
    required this.cookerName,
  });
  
  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      dishId: json['dishId'] ?? '',
      dishName: json['dishName'] ?? '',
      dishImage: json['dishImage'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 1,
      cookerId: json['cookerId'] ?? '',
      cookerName: json['cookerName'] ?? '',
    );
  }
  
  double get subtotal => price * quantity;
}
