import 'package:flutter/material.dart';
import 'theme.dart';
import 'services/user_service.dart';

const Color _primary = AppColors.primary;

class AddressesPage extends StatefulWidget {
  const AddressesPage({super.key});

  @override
  State<AddressesPage> createState() => _AddressesPageState();
}

class _AddressesPageState extends State<AddressesPage> {
  List<Address> _addresses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() => _isLoading = true);
    final response = await UserService.getAddresses();
    if (response.success && response.data != null) {
      final List<dynamic> addressList = response.data!['addresses'] ?? [];
      setState(() {
        _addresses = addressList.map((addr) => Address.fromJson(addr)).toList();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAddress(String addressId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف العنوان', textDirection: TextDirection.rtl),
        content: const Text('هل أنت متأكد من حذف هذا العنوان؟', textDirection: TextDirection.rtl),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final response = await UserService.deleteAddress(addressId);
      if (response.success) {
        await _loadAddresses();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم حذف العنوان'), backgroundColor: _primary),
          );
        }
      }
    }
  }

  Future<void> _setDefault(String addressId) async {
    // For now, just show a message - backend needs to implement this endpoint
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ميزة قيد التطوير'), backgroundColor: Colors.orange),
    );
  }

  void _showAddEditDialog({Address? address}) {
    final isEdit = address != null;
    final labelController = TextEditingController(text: address?.label ?? '');
    final addressController = TextEditingController(text: address?.address ?? '');
    final cityController = TextEditingController(text: address?.city ?? '');
    bool isDefault = address?.isDefault ?? false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'تعديل العنوان' : 'عنوان جديد', textDirection: TextDirection.rtl),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: labelController,
                  decoration: const InputDecoration(
                    labelText: 'التسمية',
                    hintText: 'منزل، عمل، الخ',
                    border: OutlineInputBorder(),
                  ),
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'العنوان الكامل',
                    border: OutlineInputBorder(),
                  ),
                  textDirection: TextDirection.rtl,
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: cityController,
                  decoration: const InputDecoration(
                    labelText: 'المدينة',
                    border: OutlineInputBorder(),
                  ),
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  title: const Text('تعيين كعنوان افتراضي', textDirection: TextDirection.rtl),
                  value: isDefault,
                  onChanged: (value) {
                    setDialogState(() => isDefault = value ?? false);
                  },
                  activeColor: _primary,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (labelController.text.isEmpty ||
                    addressController.text.isEmpty ||
                    cityController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('يرجى ملء جميع الحقول المطلوبة')),
                  );
                  return;
                }

                // If editing, delete old then add new (since backend doesn't have update endpoint yet)
                if (isEdit) {
                  await UserService.deleteAddress(address.id);
                }

                final response = await UserService.addAddress(
                  address: addressController.text,
                  label: labelController.text,
                  city: cityController.text,
                  isDefault: isDefault,
                );

                if (response.success) {
                  Navigator.pop(context);
                  await _loadAddresses();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isEdit ? 'تم تحديث العنوان' : 'تم إضافة العنوان'),
                        backgroundColor: _primary,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: _primary),
              child: Text(isEdit ? 'تحديث' : 'إضافة'),
            ),
          ],
        ),
      ),
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
          centerTitle: true,
          title: const Text('عناويني', style: TextStyle(fontWeight: FontWeight.bold)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _addresses.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_off_outlined, size: 100, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        const Text('لا توجد عناوين محفوظة', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text('أضف عنوانك الأول', style: TextStyle(fontSize: 16, color: Colors.grey)),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => _showAddEditDialog(),
                          icon: const Icon(Icons.add),
                          label: const Text('إضافة عنوان'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primary,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _addresses.length,
                          itemBuilder: (context, index) {
                            final address = _addresses[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: address.isDefault ? _primary.withOpacity(0.1) : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    address.isDefault ? Icons.location_on : Icons.location_on_outlined,
                                    color: address.isDefault ? _primary : Colors.grey,
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Text(address.label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    if (address.isDefault) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _primary,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Text('افتراضي', style: TextStyle(color: Colors.white, fontSize: 10)),
                                      ),
                                    ],
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text('${address.address}, ${address.city}', style: const TextStyle(fontSize: 14)),
                                  ],
                                ),
                                trailing: PopupMenuButton(
                                  icon: const Icon(Icons.more_vert),
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      child: const Row(
                                        children: [
                                          Icon(Icons.edit, size: 20),
                                          SizedBox(width: 8),
                                          Text('تعديل'),
                                        ],
                                      ),
                                      onTap: () {
                                        Future.delayed(Duration.zero, () => _showAddEditDialog(address: address));
                                      },
                                    ),
                                    if (!address.isDefault)
                                      PopupMenuItem(
                                        child: const Row(
                                          children: [
                                            Icon(Icons.check_circle, size: 20),
                                            SizedBox(width: 8),
                                            Text('تعيين افتراضي'),
                                          ],
                                        ),
                                        onTap: () => _setDefault(address.id),
                                      ),
                                    PopupMenuItem(
                                      child: const Row(
                                        children: [
                                          Icon(Icons.delete, size: 20, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('حذف', style: TextStyle(color: Colors.red)),
                                        ],
                                      ),
                                      onTap: () => _deleteAddress(address.id),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _showAddEditDialog(),
                            icon: const Icon(Icons.add),
                            label: const Text('إضافة عنوان جديد'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
