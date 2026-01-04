/// Order Stream Service
/// =====================
/// Real-time order updates using Firestore streams
/// For both chef and customer order tracking

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class OrderStreamService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Stream chef's orders (real-time)
  Stream<List<ChefOrderData>> streamChefOrders(
    String chefId, {
    String? status,
  }) {
    print('OrderStreamService: Querying orders for chefId: $chefId, status: $status');
    
    // Use simpler query to avoid composite index issues
    // First, get all orders for this chef
    Stream<QuerySnapshot> stream = _db.collection('orders')
        .where('chefId', isEqualTo: chefId)
        .snapshots();
    
    return stream.map((snapshot) {
      print('OrderStreamService: Found ${snapshot.docs.length} orders for chef $chefId');
      
      var orders = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        print('Order ${doc.id}: status=${data['status']}, chefId=${data['chefId']}');
        return ChefOrderData.fromFirestore(doc);
      }).toList();
      
      // Filter by status locally to avoid compound index
      if (status != null && status.isNotEmpty) {
        orders = orders.where((o) => o.status == status).toList();
        print('After status filter: ${orders.length} orders');
      }
      
      // Sort by createdAt locally
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return orders;
    });
  }

  /// Stream pending orders for chef (new orders)
  Stream<List<ChefOrderData>> streamPendingOrders(String chefId) {
    return _db.collection('orders')
        .where('chefId', isEqualTo: chefId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChefOrderData.fromFirestore(doc))
            .toList());
  }

  /// Stream active orders for chef (accepted, preparing, ready)
  Stream<List<ChefOrderData>> streamActiveOrders(String chefId) {
    return _db.collection('orders')
        .where('chefId', isEqualTo: chefId)
        .where('status', whereIn: ['accepted', 'preparing', 'ready'])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChefOrderData.fromFirestore(doc))
            .toList());
  }

  /// Stream customer's orders (real-time tracking)
  Stream<List<CustomerOrderData>> streamCustomerOrders(String customerId) {
    return _db.collection('orders')
        .where('userId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CustomerOrderData.fromFirestore(doc))
            .toList());
  }

  /// Stream single order for tracking
  Stream<CustomerOrderData?> streamOrderDetails(String orderId) {
    return _db.collection('orders')
        .doc(orderId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return null;
          return CustomerOrderData.fromFirestore(doc);
        });
  }

  /// Get chef's order count by status
  Stream<Map<String, int>> streamOrderCounts(String chefId) {
    return _db.collection('orders')
        .where('chefId', isEqualTo: chefId)
        .snapshots()
        .map((snapshot) {
          final counts = <String, int>{
            'pending': 0,
            'accepted': 0,
            'preparing': 0,
            'ready': 0,
            'completed': 0,
            'cancelled': 0,
          };
          
          for (final doc in snapshot.docs) {
            final status = doc.data()['status'] as String? ?? 'pending';
            counts[status] = (counts[status] ?? 0) + 1;
          }
          
          return counts;
        });
  }

  /// Update order status
  Future<bool> updateOrderStatus(
    String orderId,
    String status, {
    String? note,
  }) async {
    try {
      final updates = <String, dynamic>{
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      // Add timestamp for specific status changes
      switch (status) {
        case 'accepted':
          updates['acceptedAt'] = FieldValue.serverTimestamp();
          break;
        case 'preparing':
          updates['preparingAt'] = FieldValue.serverTimestamp();
          break;
        case 'ready':
          updates['readyAt'] = FieldValue.serverTimestamp();
          break;
        case 'completed':
          updates['completedAt'] = FieldValue.serverTimestamp();
          break;
        case 'cancelled':
          updates['cancelledAt'] = FieldValue.serverTimestamp();
          if (note != null) updates['cancellationReason'] = note;
          break;
      }
      
      await _db.collection('orders').doc(orderId).update(updates);
      return true;
    } catch (e) {
      debugPrint('Error updating order status: $e');
      return false;
    }
  }

  /// Accept order
  Future<bool> acceptOrder(String orderId) async {
    return updateOrderStatus(orderId, 'accepted');
  }

  /// Reject order
  Future<bool> rejectOrder(String orderId, [String? reason]) async {
    return updateOrderStatus(
      orderId, 
      'cancelled',
      note: reason ?? 'رفض من قبل الطباخ',
    );
  }

  /// Start preparing
  Future<bool> startPreparing(String orderId) async {
    return updateOrderStatus(orderId, 'preparing');
  }

  /// Mark ready
  Future<bool> markReady(String orderId) async {
    return updateOrderStatus(orderId, 'ready');
  }

  /// Complete order
  Future<bool> completeOrder(String orderId) async {
    return updateOrderStatus(orderId, 'completed');
  }
}

/// Order data model for chef view
class ChefOrderData {
  final String id;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final List<OrderItemData> items;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final String status;
  final String? notes;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? preparingAt;
  final DateTime? readyAt;
  final DateTime? completedAt;

  ChefOrderData({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.customerAddress,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.status,
    this.notes,
    required this.createdAt,
    this.acceptedAt,
    this.preparingAt,
    this.readyAt,
    this.completedAt,
  });

  factory ChefOrderData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    final itemsList = (data['items'] as List<dynamic>? ?? [])
        .map((item) => OrderItemData.fromMap(item as Map<String, dynamic>))
        .toList();

    return ChefOrderData(
      id: doc.id,
      customerId: data['userId'] ?? '',
      customerName: data['customerName'] ?? data['userName'] ?? 'عميل',
      customerPhone: data['customerPhone'] ?? data['phone'] ?? '',
      customerAddress: data['deliveryAddress'] ?? data['address'] ?? '',
      items: itemsList,
      subtotal: (data['subtotal'] ?? 0).toDouble(),
      deliveryFee: (data['deliveryFee'] ?? 0).toDouble(),
      total: (data['total'] ?? 0).toDouble(),
      status: data['status'] ?? 'pending',
      notes: data['notes'],
      createdAt: _parseTimestamp(data['createdAt']),
      acceptedAt: _parseNullableTimestamp(data['acceptedAt']),
      preparingAt: _parseNullableTimestamp(data['preparingAt']),
      readyAt: _parseNullableTimestamp(data['readyAt']),
      completedAt: _parseNullableTimestamp(data['completedAt']),
    );
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  static DateTime? _parseNullableTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  String get statusArabic {
    switch (status) {
      case 'pending': return 'في الانتظار';
      case 'accepted': return 'مقبول';
      case 'preparing': return 'قيد التحضير';
      case 'ready': return 'جاهز';
      case 'out_for_delivery': return 'في الطريق';
      case 'completed': return 'مكتمل';
      case 'cancelled': return 'ملغي';
      default: return status;
    }
  }

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
}

/// Order data model for customer view
class CustomerOrderData {
  final String id;
  final String chefId;
  final String chefName;
  final String chefPhone;
  final List<OrderItemData> items;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final String status;
  final String deliveryAddress;
  final String paymentMethod;
  final String notes;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? preparingAt;
  final DateTime? readyAt;
  final DateTime? completedAt;
  final DateTime? estimatedDelivery;
  final bool isRated;

  CustomerOrderData({
    required this.id,
    required this.chefId,
    required this.chefName,
    required this.chefPhone,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.status,
    required this.deliveryAddress,
    this.paymentMethod = 'cash',
    this.notes = '',
    required this.createdAt,
    this.acceptedAt,
    this.preparingAt,
    this.readyAt,
    this.completedAt,
    this.estimatedDelivery,
    this.isRated = false,
  });

  factory CustomerOrderData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    final itemsList = (data['items'] as List<dynamic>? ?? [])
        .map((item) => OrderItemData.fromMap(item as Map<String, dynamic>))
        .toList();

    return CustomerOrderData(
      id: doc.id,
      chefId: data['cookerId'] ?? '',
      chefName: data['cookerName'] ?? 'طباخ',
      chefPhone: data['cookerPhone'] ?? '',
      items: itemsList,
      subtotal: (data['subtotal'] ?? 0).toDouble(),
      deliveryFee: (data['deliveryFee'] ?? 0).toDouble(),
      total: (data['total'] ?? 0).toDouble(),
      status: data['status'] ?? 'pending',
      deliveryAddress: data['deliveryAddress'] ?? '',
      paymentMethod: data['paymentMethod'] ?? 'cash',
      notes: data['notes'] ?? '',
      createdAt: ChefOrderData._parseTimestamp(data['createdAt']),
      acceptedAt: ChefOrderData._parseNullableTimestamp(data['acceptedAt']),
      preparingAt: ChefOrderData._parseNullableTimestamp(data['preparingAt']),
      readyAt: ChefOrderData._parseNullableTimestamp(data['readyAt']),
      completedAt: ChefOrderData._parseNullableTimestamp(data['completedAt']),
      estimatedDelivery: ChefOrderData._parseNullableTimestamp(data['estimatedDelivery']),
      isRated: data['isRated'] ?? false,
    );
  }

  String get statusArabic {
    switch (status) {
      case 'pending': return 'في الانتظار';
      case 'accepted': return 'تم القبول';
      case 'preparing': return 'قيد التحضير';
      case 'ready': return 'جاهز للتوصيل';
      case 'out_for_delivery': return 'في الطريق إليك';
      case 'completed': return 'تم التوصيل';
      case 'cancelled': return 'ملغي';
      default: return status;
    }
  }

  bool get canRate => status == 'completed' && !isRated;
}

/// Order item data
class OrderItemData {
  final String dishId;
  final String name;
  final int quantity;
  final double price;
  final String? image;
  final String? notes;

  OrderItemData({
    required this.dishId,
    required this.name,
    required this.quantity,
    required this.price,
    this.image,
    this.notes,
  });

  factory OrderItemData.fromMap(Map<String, dynamic> map) {
    return OrderItemData(
      dishId: map['dishId'] ?? '',
      name: map['name'] ?? map['dishName'] ?? '',
      quantity: map['quantity'] ?? 1,
      price: (map['price'] ?? 0).toDouble(),
      image: map['image'],
      notes: map['notes'],
    );
  }

  /// Alias for name to maintain compatibility
  String get dishName => name;

  double get total => price * quantity;
}
