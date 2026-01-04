import 'package:flutter/material.dart';
import 'theme.dart';
import 'services/enhanced_cart_service.dart';

const Color _primary = AppColors.primary;

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List<CartItem> _cartItems = [];
  bool _isLoading = true;
  double _subtotal = 0.0;
  double _deliveryFee = 3.0;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    setState(() => _isLoading = true);
    final items = await CartService.loadCart();
    setState(() {
      _cartItems = items;
      _calculateSubtotal();
      _isLoading = false;
    });
  }

  void _calculateSubtotal() {
    _subtotal = _cartItems.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  Future<void> _updateQuantity(String dishId, int newQuantity) async {
    if (newQuantity < 1) return;
    
    final success = await CartService.updateQuantity(dishId, newQuantity);
    if (success) {
      await _loadCart();
    }
  }

  Future<void> _removeItem(String dishId) async {
    final success = await CartService.removeItem(dishId);
    if (success) {
      await _loadCart();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف الطبق من السلة'), backgroundColor: _primary),
        );
      }
    }
  }

  Future<void> _clearCart() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تفريغ السلة', textDirection: TextDirection.rtl),
        content: const Text('هل تريد حذف جميع الأطباق', textDirection: TextDirection.rtl),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('تأكيد', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await CartService.clearCart();
      if (success) {
        await _loadCart();
      }
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
          title: const Text('السلة', style: TextStyle(fontWeight: FontWeight.bold)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          actions: _cartItems.isNotEmpty
              ? [
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: _clearCart,
                    tooltip: 'تفريغ السلة',
                  ),
                ]
              : null,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _cartItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_outlined, size: 100, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        const Text('السلة فارغة', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
                          style: ElevatedButton.styleFrom(backgroundColor: _primary,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12)),
                          child: const Text('تصفح الأطباق', style: TextStyle(fontSize: 16)),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _cartItems.length,
                          itemBuilder: (context, index) {
                            final item = _cartItems[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: item.image.startsWith('http')
                                          ? Image.network(item.image, width: 70, height: 70, fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Container(
                                                width: 70, height: 70, color: Colors.grey[300],
                                                child: const Icon(Icons.restaurant),
                                              ))
                                          : Image.asset(item.image, width: 70, height: 70, fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Container(
                                                width: 70, height: 70, color: Colors.grey[300],
                                                child: const Icon(Icons.restaurant),
                                              )),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(item.dishName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                          Text('من اعداد ${item.cookerName}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                          const SizedBox(height: 4),
                                          Text('${item.price.toStringAsFixed(2)} دت', style: const TextStyle(fontSize: 14, color: _primary, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.grey.shade300),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.remove, size: 16),
                                                onPressed: () => _updateQuantity(item.dishId, item.quantity - 1),
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                              ),
                                              Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                              IconButton(
                                                icon: const Icon(Icons.add, size: 16),
                                                onPressed: () => _updateQuantity(item.dishId, item.quantity + 1),
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                          onPressed: () => _removeItem(item.dishId),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                          boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black26)],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('المجموع الفرعي', style: TextStyle(fontSize: 16)),
                                Text('${_subtotal.toStringAsFixed(2)} دت', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('رسوم التوصيل', style: TextStyle(fontSize: 16)),
                                Text('${_deliveryFee.toStringAsFixed(2)} دت', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('المجموع الكلي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                Text('${(_subtotal + _deliveryFee).toStringAsFixed(2)} دت', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _primary)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => Navigator.pushNamed(context, '/checkout'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _primary,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('المتابعة للدفع', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
