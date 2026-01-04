import 'package:flutter/material.dart';
import 'dart:async';
import 'theme.dart';
import 'services/order_stream_service.dart';

const Color _primary = AppColors.primary;

class OrderTrackingPage extends StatefulWidget {
  final String orderId;
  final String? chefName;

  const OrderTrackingPage({
    super.key,
    required this.orderId,
    this.chefName,
  });

  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage> {
  StreamSubscription<CustomerOrderData?>? _orderSubscription;
  CustomerOrderData? _order;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _subscribeToOrder();
  }

  @override
  void dispose() {
    _orderSubscription?.cancel();
    super.dispose();
  }

  void _subscribeToOrder() {
    _orderSubscription = OrderStreamService()
        .streamOrderDetails(widget.orderId)
        .listen(
      (order) {
        if (mounted) {
          setState(() {
            _order = order;
            _isLoading = false;
            _error = order == null ? 'الطلب غير موجود' : null;
          });
        }
      },
      onError: (e) {
        if (mounted) {
          setState(() {
            _error = 'حدث خطأ في تحميل الطلب';
            _isLoading = false;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          backgroundColor: _primary,
          title: const Text('تتبع الطلب'),
          centerTitle: true,
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _primary),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(_error!, style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    if (_order == null) {
      return const Center(child: Text('الطلب غير موجود'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Order Status Card
          _buildStatusCard(),
          const SizedBox(height: 16),

          // Progress Timeline
          _buildProgressTimeline(),
          const SizedBox(height: 16),

          // Order Details Card
          _buildOrderDetailsCard(),
          const SizedBox(height: 16),

          // Items Card
          _buildItemsCard(),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final statusInfo = _getStatusInfo(_order!.status);
    
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [statusInfo['color'] as Color, (statusInfo['color'] as Color).withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Icon(
              statusInfo['icon'] as IconData,
              size: 64,
              color: Colors.white,
            ),
            const SizedBox(height: 16),
            Text(
              statusInfo['title'] as String,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              statusInfo['subtitle'] as String,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressTimeline() {
    final steps = [
      {'status': 'pending', 'label': 'تم الطلب', 'icon': Icons.receipt_long},
      {'status': 'accepted', 'label': 'تم القبول', 'icon': Icons.check_circle},
      {'status': 'preparing', 'label': 'جاري التحضير', 'icon': Icons.restaurant},
      {'status': 'ready', 'label': 'جاهز', 'icon': Icons.done_all},
      {'status': 'completed', 'label': 'تم التسليم', 'icon': Icons.verified},
    ];

    final currentIndex = steps.indexWhere((s) => s['status'] == _order!.status);
    final isRejected = _order!.status == 'rejected' || _order!.status == 'cancelled';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'مراحل الطلب',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (isRejected)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cancel, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _order!.status == 'cancelled' 
                            ? 'تم إلغاء الطلب'
                            : 'تم رفض الطلب',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...steps.asMap().entries.map((entry) {
                final index = entry.key;
                final step = entry.value;
                final isCompleted = index <= currentIndex;
                final isCurrent = index == currentIndex;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      // Timeline indicator
                      Column(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isCompleted ? _primary : Colors.grey[300],
                              border: isCurrent
                                  ? Border.all(color: _primary, width: 3)
                                  : null,
                            ),
                            child: Icon(
                              step['icon'] as IconData,
                              size: 16,
                              color: isCompleted ? Colors.white : Colors.grey[500],
                            ),
                          ),
                          if (index < steps.length - 1)
                            Container(
                              width: 2,
                              height: 24,
                              color: index < currentIndex ? _primary : Colors.grey[300],
                            ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          step['label'] as String,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                            color: isCompleted ? Colors.black : Colors.grey[500],
                          ),
                        ),
                      ),
                      if (isCompleted && _getTimestamp(step['status'] as String) != null)
                        Text(
                          _formatTime(_getTimestamp(step['status'] as String)!),
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  DateTime? _getTimestamp(String status) {
    switch (status) {
      case 'pending':
        return _order?.createdAt;
      case 'accepted':
        return _order?.acceptedAt;
      case 'preparing':
        return _order?.preparingAt;
      case 'ready':
        return _order?.readyAt;
      case 'completed':
        return _order?.completedAt;
      default:
        return null;
    }
  }

  Widget _buildOrderDetailsCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'تفاصيل الطلب',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(Icons.tag, 'رقم الطلب', '#${widget.orderId.substring(0, 8)}'),
            if (widget.chefName != null)
              _buildDetailRow(Icons.restaurant, 'الطباخ', widget.chefName!),
            _buildDetailRow(Icons.location_on, 'العنوان', _order!.deliveryAddress),
            _buildDetailRow(Icons.payment, 'طريقة الدفع', _getPaymentMethod(_order!.paymentMethod)),
            if (_order!.notes.isNotEmpty)
              _buildDetailRow(Icons.note, 'ملاحظات', _order!.notes),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                Text(value, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'الأصناف',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._order!.items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        '${item.quantity}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(item.dishName)),
                  Text(
                    '${(item.price * item.quantity).toStringAsFixed(2)} دت',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )),
            const Divider(),
            _buildPriceRow('المجموع الفرعي', _order!.subtotal),
            _buildPriceRow('رسوم التوصيل', _order!.deliveryFee),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  'الإجمالي',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '${_order!.total.toStringAsFixed(2)} دت',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          const Spacer(),
          Text('${amount.toStringAsFixed(2)} دت'),
        ],
      ),
    );
  }

  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status) {
      case 'pending':
        return {
          'title': 'في انتظار القبول',
          'subtitle': 'طلبك قيد المراجعة من قبل الطباخ',
          'icon': Icons.hourglass_empty,
          'color': Colors.orange,
        };
      case 'accepted':
        return {
          'title': 'تم قبول الطلب',
          'subtitle': 'الطباخ قبل طلبك وسيبدأ التحضير قريباً',
          'icon': Icons.check_circle,
          'color': Colors.blue,
        };
      case 'preparing':
        return {
          'title': 'جاري التحضير',
          'subtitle': 'الطباخ يقوم بتحضير طلبك الآن',
          'icon': Icons.restaurant,
          'color': _primary,
        };
      case 'ready':
        return {
          'title': 'طلبك جاهز!',
          'subtitle': 'طلبك جاهز للتسليم',
          'icon': Icons.done_all,
          'color': Colors.green,
        };
      case 'completed':
        return {
          'title': 'تم التسليم',
          'subtitle': 'شكراً لك! نتمنى أن تستمتع بوجبتك',
          'icon': Icons.verified,
          'color': Colors.teal,
        };
      case 'rejected':
        return {
          'title': 'تم رفض الطلب',
          'subtitle': 'للأسف، الطباخ غير قادر على تلبية طلبك حالياً',
          'icon': Icons.cancel,
          'color': Colors.red,
        };
      case 'cancelled':
        return {
          'title': 'تم إلغاء الطلب',
          'subtitle': 'تم إلغاء هذا الطلب',
          'icon': Icons.cancel_outlined,
          'color': Colors.grey,
        };
      default:
        return {
          'title': 'حالة غير معروفة',
          'subtitle': '',
          'icon': Icons.help_outline,
          'color': Colors.grey,
        };
    }
  }

  String _getPaymentMethod(String method) {
    switch (method) {
      case 'cash':
        return 'الدفع عند الاستلام';
      case 'card':
        return 'بطاقة ائتمان';
      case 'wallet':
        return 'المحفظة الإلكترونية';
      default:
        return method;
    }
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
