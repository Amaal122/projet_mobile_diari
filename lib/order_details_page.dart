import 'package:flutter/material.dart';
import 'theme.dart';
import 'services/enhanced_order_service.dart';

const Color _primary = AppColors.primary;

class OrderDetailsPage extends StatefulWidget {
  final String orderId;
  
  const OrderDetailsPage({super.key, required this.orderId});

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  Order? _order;
  bool _isLoading = true;
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    setState(() => _isLoading = true);
    final order = await OrderService.getOrderById(widget.orderId);
    setState(() {
      _order = order;
      _isLoading = false;
    });
  }

  Future<void> _cancelOrder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إلغاء الطلب', textDirection: TextDirection.rtl),
        content: const Text('هل أنت متأكد من إلغاء هذا الطلب؟', textDirection: TextDirection.rtl),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('رجوع'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('إلغاء الطلب', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isCancelling = true);
      
      final success = await OrderService.cancelOrder(widget.orderId);
      
      setState(() => _isCancelling = false);
      
      if (success) {
        await _loadOrder();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إلغاء الطلب'), backgroundColor: Colors.red),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل إلغاء الطلب'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'preparing':
        return Colors.purple;
      case 'on_the_way':
        return Colors.teal;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          backgroundColor: _primary,
          centerTitle: true,
          title: const Text('تفاصيل الطلب', style: TextStyle(fontWeight: FontWeight.bold)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _order == null
                ? const Center(child: Text('لم يتم العثور على الطلب'))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Order Status Card
                        Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Text('طلب #${_order!.id.substring(0, 8)}',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(_order!.status).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _order!.statusArabic,
                                    style: TextStyle(
                                      color: _getStatusColor(_order!.status),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _formatDate(_order!.createdAt),
                                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Items Card
                        Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('الأطباق', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                const Divider(height: 20),
                                ..._order!.items.map((item) => Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: Row(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: item.dishImage.startsWith('http')
                                                ? Image.network(item.dishImage, width: 60, height: 60, fit: BoxFit.cover,
                                                    errorBuilder: (_, __, ___) => Container(
                                                      width: 60, height: 60, color: Colors.grey[300],
                                                      child: const Icon(Icons.restaurant),
                                                    ))
                                                : Image.asset(item.dishImage, width: 60, height: 60, fit: BoxFit.cover,
                                                    errorBuilder: (_, __, ___) => Container(
                                                      width: 60, height: 60, color: Colors.grey[300],
                                                      child: const Icon(Icons.restaurant),
                                                    )),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(item.dishName,
                                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                                Text('من اعداد ${item.cookerName}',
                                                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                                Text('الكمية: ${item.quantity}',
                                                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                              ],
                                            ),
                                          ),
                                          Text('${(item.price * item.quantity).toStringAsFixed(2)} دت',
                                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    )),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Delivery Info Card
                        Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('معلومات التوصيل', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                const Divider(height: 20),
                                _buildInfoRow(Icons.location_on, 'العنوان', _order!.deliveryAddress),
                                const SizedBox(height: 8),
                                _buildInfoRow(Icons.phone, 'الهاتف', _order!.phone),
                                if (_order!.notes != null && _order!.notes!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  _buildInfoRow(Icons.note, 'ملاحظات', _order!.notes!),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Payment Summary Card
                        Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('ملخص الدفع', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                const Divider(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('المجموع الفرعي', style: TextStyle(fontSize: 14)),
                                    Text('${_order!.subtotal.toStringAsFixed(2)} دت',
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('رسوم التوصيل', style: TextStyle(fontSize: 14)),
                                    Text('${_order!.deliveryFee.toStringAsFixed(2)} دت',
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const Divider(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('المجموع الكلي', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    Text('${_order!.total.toStringAsFixed(2)} دت',
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _primary)),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text('طريقة الدفع: ${_order!.paymentMethod == "cash" ? "نقداً" : "بطاقة بنكية"}',
                                    style: const TextStyle(fontSize: 14, color: Colors.grey)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Track Order Button (for non-cancelled/non-delivered orders)
                        if (_order!.status != 'cancelled' && _order!.status != 'delivered')
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pushNamed(context, '/order-tracking', arguments: {
                                  'orderId': _order!.id,
                                  'chefName': null,
                                });
                              },
                              icon: const Icon(Icons.location_on),
                              label: const Text('تتبع الطلب', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),
                        
                        // Cancel Button (only for pending/confirmed orders)
                        if (_order!.status == 'pending' || _order!.status == 'confirmed')
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: _isCancelling ? null : _cancelOrder,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: _isCancelling
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(color: Colors.red, strokeWidth: 2),
                                    )
                                  : const Text('إلغاء الطلب', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(value, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
