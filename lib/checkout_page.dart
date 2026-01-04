import 'package:flutter/material.dart';
import 'theme.dart';
import 'services/enhanced_cart_service.dart';
import 'services/enhanced_order_service.dart';

const Color _primary = AppColors.primary;

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _paymentMethod = 'cash';
  bool _isSubmitting = false;
  List<CartItem> _cartItems = [];
  double _subtotal = 0.0;
  double _deliveryFee = 3.0;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadCart() async {
    final items = await CartService.loadCart();
    setState(() {
      _cartItems = items;
      _subtotal = items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
    });
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final order = await OrderService.createOrder(
      deliveryAddress: _addressController.text,
      phone: _phoneController.text,
      notes: _notesController.text,
      paymentMethod: _paymentMethod,
    );

    setState(() => _isSubmitting = false);

    if (order != null && mounted) {
      // Clear cart after successful order
      await CartService.clearCart();
      
      // Navigate to order confirmation
      Navigator.pushNamedAndRemoveUntil(
        context, 
        '/order-success',
        (route) => route.settings.name == '/home',
        arguments: order.id,
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('فشل إنشاء الطلب. حاول مرة أخرى.'),
          backgroundColor: Colors.red,
        ),
      );
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
          title: const Text('إتمام الطلب', style: TextStyle(fontWeight: FontWeight.bold)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: _cartItems.isEmpty
            ? const Center(child: Text('السلة فارغة'))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Order Summary Card
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('ملخص الطلب', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const Divider(height: 20),
                              ..._cartItems.map((item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text('${item.dishName} × ${item.quantity}',
                                              style: const TextStyle(fontSize: 14)),
                                        ),
                                        Text('${(item.price * item.quantity).toStringAsFixed(2)} دت',
                                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  )),
                              const Divider(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('المجموع الفرعي', style: TextStyle(fontSize: 14)),
                                  Text('${_subtotal.toStringAsFixed(2)} دت',
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('رسوم التوصيل', style: TextStyle(fontSize: 14)),
                                  Text('${_deliveryFee.toStringAsFixed(2)} دت',
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const Divider(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('المجموع الكلي', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  Text('${(_subtotal + _deliveryFee).toStringAsFixed(2)} دت',
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _primary)),
                                ],
                              ),
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
                              const SizedBox(height: 16),
                              
                              TextFormField(
                                controller: _addressController,
                                decoration: const InputDecoration(
                                  labelText: 'العنوان',
                                  hintText: 'أدخل عنوان التوصيل',
                                  prefixIcon: Icon(Icons.location_on),
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'يرجى إدخال العنوان';
                                  }
                                  return null;
                                },
                                maxLines: 2,
                              ),
                              const SizedBox(height: 16),
                              
                              TextFormField(
                                controller: _phoneController,
                                decoration: const InputDecoration(
                                  labelText: 'رقم الهاتف',
                                  hintText: 'أدخل رقم هاتفك',
                                  prefixIcon: Icon(Icons.phone),
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.phone,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'يرجى إدخال رقم الهاتف';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              
                              TextFormField(
                                controller: _notesController,
                                decoration: const InputDecoration(
                                  labelText: 'ملاحظات (اختياري)',
                                  hintText: 'أي تعليمات خاصة للتوصيل',
                                  prefixIcon: Icon(Icons.note),
                                  border: OutlineInputBorder(),
                                ),
                                maxLines: 3,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Payment Method Card
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('طريقة الدفع', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              
                              RadioListTile<String>(
                                title: const Text('الدفع عند الاستلام'),
                                subtitle: const Text('ادفع نقداً عند استلام الطلب'),
                                value: 'cash',
                                groupValue: _paymentMethod,
                                onChanged: (value) {
                                  setState(() => _paymentMethod = value!);
                                },
                                activeColor: _primary,
                              ),
                              
                              RadioListTile<String>(
                                title: const Text('بطاقة بنكية'),
                                subtitle: const Text('الدفع الإلكتروني'),
                                value: 'card',
                                groupValue: _paymentMethod,
                                onChanged: (value) {
                                  setState(() => _paymentMethod = value!);
                                },
                                activeColor: _primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitOrder,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Text('تأكيد الطلب', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
