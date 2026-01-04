import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../theme.dart';
import '../services/chef_service.dart';
import '../services/order_stream_service.dart';

const Color _primary = AppColors.primary;

class ChefOrdersPage extends StatefulWidget {
  const ChefOrdersPage({super.key});

  @override
  State<ChefOrdersPage> createState() => _ChefOrdersPageState();
}

class _ChefOrdersPageState extends State<ChefOrdersPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ChefOrder> _orders = [];
  bool _isLoading = true;
  String _currentStatus = 'pending';
  StreamSubscription<List<ChefOrderData>>? _ordersSubscription;
  bool _useRealtime = true; // Toggle for real-time mode

  final List<Map<String, dynamic>> _tabs = [
    {'status': 'pending', 'label': 'جديد', 'icon': Icons.new_releases},
    {'status': 'accepted', 'label': 'مقبول', 'icon': Icons.check_circle},
    {'status': 'preparing', 'label': 'يُحضّر', 'icon': Icons.restaurant},
    {'status': 'ready', 'label': 'جاهز', 'icon': Icons.done_all},
    {'status': 'completed', 'label': 'مكتمل', 'icon': Icons.verified},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _currentStatus = _tabs[_tabController.index]['status'];
        });
        _subscribeToOrders();
      }
    });
    _subscribeToOrders();
  }

  @override
  void dispose() {
    _ordersSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _subscribeToOrders() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _ordersSubscription?.cancel();
    setState(() => _isLoading = true);

    if (_useRealtime) {
      // Use Firestore real-time streams
      _ordersSubscription = OrderStreamService()
          .streamChefOrders(user.uid, status: _currentStatus)
          .listen(
        (orders) {
          if (mounted) {
            setState(() {
              _orders = orders.map((o) => ChefOrder(
                id: o.id,
                customerId: o.customerId,
                customerName: o.customerName,
                deliveryAddress: o.customerAddress,
                items: o.items.map((item) => {
                  'dishId': item.dishId,
                  'dishName': item.dishName,
                  'quantity': item.quantity,
                  'price': item.price,
                }).toList(),
                subtotal: o.subtotal,
                deliveryFee: o.deliveryFee,
                total: o.total,
                status: o.status,
                chefStatus: o.status,
                paymentMethod: 'cash',
                createdAt: o.createdAt,
                notes: o.notes ?? '',
              )).toList();
              _isLoading = false;
            });
          }
        },
        onError: (e) {
          debugPrint('Stream error: $e');
          // Fallback to API
          _loadOrders();
        },
      );
    } else {
      _loadOrders();
    }
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final response = await ChefService.getOrders(
        userId: user.uid,
        status: _currentStatus,
      );

      if (response.success && mounted) {
        final ordersJson = response.data['orders'] as List<dynamic>? ?? [];
        setState(() {
          _orders = ordersJson.map((o) => ChefOrder.fromJson(o)).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading orders: $e');
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _acceptOrder(ChefOrder order) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      if (_useRealtime) {
        // Use Firestore direct update
        await OrderStreamService().acceptOrder(order.id);
        _showSuccess('تم قبول الطلب');
      } else {
        final response = await ChefService.acceptOrder(
          userId: user.uid,
          orderId: order.id,
        );
        if (response.success && mounted) {
          _showSuccess('تم قبول الطلب');
          _loadOrders();
        }
      }
    } catch (e) {
      _showError('حدث خطأ: $e');
    }
  }

  Future<void> _rejectOrder(ChefOrder order) async {
    final reasonController = TextEditingController();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('رفض الطلب', textDirection: TextDirection.rtl),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'هل أنت متأكد من رفض هذا الطلب؟',
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'سبب الرفض (اختياري)',
                hintTextDirection: TextDirection.rtl,
                border: OutlineInputBorder(),
              ),
              textDirection: TextDirection.rtl,
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('رفض', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      if (_useRealtime) {
        await OrderStreamService().rejectOrder(order.id, reasonController.text);
        _showSuccess('تم رفض الطلب');
      } else {
        final response = await ChefService.rejectOrder(
          userId: user.uid,
          orderId: order.id,
          reason: reasonController.text,
        );
        if (response.success && mounted) {
          _showSuccess('تم رفض الطلب');
          _loadOrders();
        }
      }
    } catch (e) {
      _showError('حدث خطأ: $e');
    }
  }

  Future<void> _updateStatus(ChefOrder order, String newStatus) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final messages = {
      'preparing': 'جاري تحضير الطلب',
      'ready': 'الطلب جاهز',
      'completed': 'تم إكمال الطلب',
    };

    try {
      if (_useRealtime) {
        switch (newStatus) {
          case 'preparing':
            await OrderStreamService().startPreparing(order.id);
            break;
          case 'ready':
            await OrderStreamService().markReady(order.id);
            break;
          case 'completed':
            await OrderStreamService().completeOrder(order.id);
            break;
          default:
            await OrderStreamService().updateOrderStatus(order.id, newStatus);
        }
        _showSuccess(messages[newStatus] ?? 'تم التحديث');
      } else {
        final response = await ChefService.updateOrderStatus(
          userId: user.uid,
          orderId: order.id,
          status: newStatus,
        );
        if (response.success && mounted) {
          _showSuccess(messages[newStatus] ?? 'تم التحديث');
          _loadOrders();
        }
      }
    } catch (e) {
      _showError('حدث خطأ: $e');
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: _primary,
        title: const Text('الطلبات', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        automaticallyImplyLeading: false,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            height: 48,
            alignment: Alignment.centerRight,
            child: TabBar(
              controller: _tabController,
              isScrollable: false,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              unselectedLabelStyle: const TextStyle(fontSize: 11),
              tabs: _tabs.map((tab) => Tab(
                icon: Icon(tab['icon'], size: 16),
                text: tab['label'],
                iconMargin: const EdgeInsets.only(bottom: 2),
              )).toList(),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs.map((_) => _buildOrdersList()).toList(),
      ),
    );
  }

  Widget _buildOrdersList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _primary));
    }

    if (_orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'لا توجد طلبات',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      color: _primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _orders.length,
        itemBuilder: (context, index) {
          return _buildOrderCard(_orders[index]);
        },
      ),
    );
  }

  Widget _buildOrderCard(ChefOrder order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '#${order.id.substring(0, 8)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _primary,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(order.createdAt),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            const Divider(height: 24),

            // Customer Info
            Row(
              children: [
                const Icon(Icons.person_outline, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Text(order.customerName),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order.deliveryAddress,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Items
            ...order.items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text(
                        '${item['quantity']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _primary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(item['dishName'] ?? '')),
                  Text(
                    '${item['price']?.toStringAsFixed(2) ?? 0} دت',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )),
            const Divider(height: 24),

            // Total
            Row(
              children: [
                const Text(
                  'الإجمالي',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '${order.total.toStringAsFixed(2)} دت',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Actions based on status
            _buildActions(order),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(ChefOrder order) {
    switch (order.chefStatus) {
      case 'pending':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _rejectOrder(order),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
                child: const Text('رفض'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _acceptOrder(order),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('قبول'),
              ),
            ),
          ],
        );

      case 'accepted':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _updateStatus(order, 'preparing'),
            style: ElevatedButton.styleFrom(backgroundColor: _primary),
            icon: const Icon(Icons.restaurant),
            label: const Text('بدء التحضير'),
          ),
        );

      case 'preparing':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _updateStatus(order, 'ready'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            icon: const Icon(Icons.done_all),
            label: const Text('الطلب جاهز'),
          ),
        );

      case 'ready':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _updateStatus(order, 'completed'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            icon: const Icon(Icons.verified),
            label: const Text('تم التسليم'),
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    return '${date.day}/${date.month}/${date.year}';
  }
}

/// Chef Order model
class ChefOrder {
  final String id;
  final String customerId;
  final String customerName;
  final String deliveryAddress;
  final List<Map<String, dynamic>> items;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final String status;
  final String chefStatus;
  final String paymentMethod;
  final DateTime? createdAt;
  final String notes;

  ChefOrder({
    required this.id,
    this.customerId = '',
    this.customerName = '',
    this.deliveryAddress = '',
    this.items = const [],
    this.subtotal = 0,
    this.deliveryFee = 0,
    this.total = 0,
    this.status = 'pending',
    this.chefStatus = 'pending',
    this.paymentMethod = 'cash',
    this.createdAt,
    this.notes = '',
  });

  factory ChefOrder.fromJson(Map<String, dynamic> json) {
    return ChefOrder(
      id: json['id'] ?? '',
      customerId: json['userId'] ?? '',
      customerName: json['customerName'] ?? json['userName'] ?? 'زبون',
      deliveryAddress: json['deliveryAddress'] ?? json['address'] ?? '',
      items: List<Map<String, dynamic>>.from(json['items'] ?? []),
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      deliveryFee: (json['deliveryFee'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      chefStatus: json['chefStatus'] ?? json['status'] ?? 'pending',
      paymentMethod: json['paymentMethod'] ?? 'cash',
      createdAt: json['createdAt'] != null 
          ? DateTime.tryParse(json['createdAt']) 
          : null,
      notes: json['notes'] ?? '',
    );
  }
}
