import 'package:flutter/material.dart';
import 'theme.dart';
import 'services/auth_service.dart';
import 'services/user_service.dart';
import 'services/enhanced_order_service.dart';

class UserInterfacePage extends StatefulWidget {
  final bool showOrders;
  final bool showNavBar;
  const UserInterfacePage({super.key, this.showOrders = false, this.showNavBar = true});

  @override
  State<UserInterfacePage> createState() => _UserInterfacePageState();
}

class _UserInterfacePageState extends State<UserInterfacePage> {
  Color get primaryColor => AppColors.primary; // Orange Diari
  Color get backgroundColor => AppColors.backgroundLight; // Couleur Background

  // بيانات المستخدم
  String fullName = 'سارة منصور';
  String email = 'sara@example.com';
  String phone = '+216 20 123 456';
  List<Order> _orders = [];
  bool _isLoadingOrders = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadOrders();
  }
  
  Future<void> _loadOrders() async {
    if (!mounted) return;
    setState(() => _isLoadingOrders = true);
    final orders = await OrderService.getOrderHistory();
    if (mounted) {
      setState(() {
        _orders = orders;
        _isLoadingOrders = false;
      });
    }
  }
  
  void _loadUserData() async {
    // Get user from Firebase Auth
    final user = AuthService.currentUser;
    if (user != null) {
      setState(() {
        email = user.email ?? 'sara@example.com';
        fullName = user.displayName ?? 'سارة منصور';
      });
      
      // Load profile from backend
      final response = await UserService.getProfile();
      if (response.success && response.data != null) {
        final profile = UserProfile.fromJson(response.data!);
        setState(() {
          fullName = profile.name;
          phone = profile.phone;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: _buildOrdersList(),
            ),
          ],
        ),
      ),
    );
  }

  // --- HEADER ---
  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 40, bottom: 20, left: 20, right: 20),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'طلباتي',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- LISTE COMMANDES ---
  Widget _buildOrdersList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'سجل الطلبات',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/order-history').then((_) => _loadOrders());
                },
                child: const Text('عرض الكل'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoadingOrders
              ? const Center(child: CircularProgressIndicator())
              : _orders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          const Text('لا توجد طلبات', style: TextStyle(fontSize: 18, color: Colors.grey)),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => Navigator.pushNamed(context, '/home'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                            ),
                            child: const Text('تصفح الأطباق'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadOrders,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _orders.length > 5 ? 5 : _orders.length,
                        itemBuilder: (context, index) {
                          final order = _orders[index];
                          return _buildOrderCard(order);
                        },
                      ),
                    ),
        ),
      ],
    );
  }
  
  Widget _buildOrderCard(Order order) {
    Color statusColor;
    switch (order.status) {
      case 'pending': statusColor = Colors.orange; break;
      case 'confirmed': statusColor = Colors.blue; break;
      case 'preparing': statusColor = Colors.purple; break;
      case 'on_the_way': statusColor = Colors.teal; break;
      case 'delivered': statusColor = Colors.green; break;
      case 'cancelled': statusColor = Colors.red; break;
      default: statusColor = Colors.grey;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, '/order-details', arguments: order.id).then((_) => _loadOrders());
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('طلب #${order.id.substring(0, 8)}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('${order.items.length} طبق',
                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(_formatOrderDate(order.createdAt),
                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      order.statusArabic,
                      style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('${order.total.toStringAsFixed(2)} دت',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryColor)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  String _formatOrderDate(DateTime date) {
    final now = DateTime.now();
    if (date.day == now.day && date.month == now.month && date.year == now.year) {
      return 'اليوم ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    return '${date.day}/${date.month}/${date.year}';
  }
}

/* =======================================================================
   ====================  LES PAGES SECONDAIRES  ==========================
   ======================================================================= */

// 1. PAGE MODIFIER LE PROFIL
class EditProfilePage extends StatefulWidget {
  final String currentName;
  final String currentEmail;
  final String currentPhone;

  const EditProfilePage({
    super.key,
    required this.currentName,
    required this.currentEmail,
    required this.currentPhone,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.currentName);
    emailController = TextEditingController(text: widget.currentEmail);
    phoneController = TextEditingController(text: widget.currentPhone);
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F9F9),
        appBar: AppBar(
          title: const Text(
            'تعديل الملف الشخصي',
            style: TextStyle(color: Colors.black),
          ),
          centerTitle: true,
          backgroundColor: const Color(0xFFF9F9F9),
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 50,
                  backgroundImage: AssetImage('assets/sarra.jpg'),
                ),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('يرجى اختيار صورة من المعرض أو الكاميرا'),
                        backgroundColor: Color(0xFFEE8C2B),
                      ),
                    );
                  },
                  child: const Text(
                    "تغيير الصورة",
                    style: TextStyle(color: Color(0xFFEE8C2B)),
                  ),
                ),
                const SizedBox(height: 20),
                _buildTextField("الاسم الكامل", nameController),
                const SizedBox(height: 15),
                _buildTextField("البريد الإلكتروني", emailController),
                const SizedBox(height: 15),
                _buildTextField("رقم الهاتف", phoneController),
                const SizedBox(height: 50),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, {
                        'name': nameController.text,
                        'email': emailController.text,
                        'phone': phoneController.text,
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEE8C2B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "حفظ التغييرات",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            fillColor: Colors.white,
            filled: true,
          ),
        ),
      ],
    );
  }
}

// 2. PAGE MES ADRESSES (نسخة تفاعلية وجديدة)
class AddressesPage extends StatefulWidget {
  const AddressesPage({super.key});

  @override
  State<AddressesPage> createState() => _AddressesPageState();
}

class _AddressesPageState extends State<AddressesPage> {
  // قائمة العناوين
  List<Map<String, dynamic>> myAddresses = [
    {
      "title": "المنزل",
      "details": "شارع الحبيب بورقيبة، تونس",
      "icon": Icons.home,
    },
    {
      "title": "العمل",
      "details": "القطب التكنولوجي الغزالة، أريانة",
      "icon": Icons.work,
    },
  ];

  int selectedIndex = 0;
  final TextEditingController titleController = TextEditingController();
  final TextEditingController detailsController = TextEditingController();

  @override
  void dispose() {
    titleController.dispose();
    detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F9F9),
        appBar: AppBar(
          title: const Text('عناويني', style: TextStyle(color: Colors.black)),
          centerTitle: true,
          backgroundColor: const Color(0xFFF9F9F9),
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: myAddresses.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedIndex = index;
                        });
                      },
                      child: _buildAddressCard(
                        myAddresses[index]["title"],
                        myAddresses[index]["details"],
                        myAddresses[index]["icon"],
                        selectedIndex == index,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _showAddAddressDialog,
                  icon: const Icon(Icons.add, color: Color(0xFFEE8C2B)),
                  label: const Text(
                    "إضافة عنوان جديد",
                    style: TextStyle(color: Color(0xFFEE8C2B), fontSize: 16),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    side: const BorderSide(color: Color(0xFFEE8C2B)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddressCard(
    String title,
    String details,
    IconData icon,
    bool isSelected,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected ? Colors.orange.shade50 : Colors.white,
        border: isSelected
            ? Border.all(color: const Color(0xFFEE8C2B), width: 2)
            : Border.all(color: Colors.transparent, width: 2),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.05 * 255).round()),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFEE8C2B), size: 30),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  details,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
          if (isSelected)
            const Icon(Icons.check_circle, color: Color(0xFFEE8C2B)),
        ],
      ),
    );
  }

  void _showAddAddressDialog() {
    titleController.clear();
    detailsController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          top: 20,
          left: 20,
          right: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "عنوان جديد",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: titleController,
              textAlign: TextAlign.right,
              decoration: const InputDecoration(
                labelText: "اسم المكان (مثال: منزل صديقي)",
                prefixIcon: Icon(Icons.label_outline),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: detailsController,
              textAlign: TextAlign.right,
              decoration: const InputDecoration(
                labelText: "العنوان بالتفصيل",
                prefixIcon: Icon(Icons.location_on_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty &&
                    detailsController.text.isNotEmpty) {
                  setState(() {
                    myAddresses.add({
                      "title": titleController.text,
                      "details": detailsController.text,
                      "icon": Icons.location_on,
                    });
                    selectedIndex = myAddresses.length - 1;
                  });
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEE8C2B),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "حفظ العنوان",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 3. PAGE FAVORIS (كيما هي)
class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F9F9),
        appBar: AppBar(
          title: const Text('المفضلة', style: TextStyle(color: Colors.black)),
          centerTitle: true,
          backgroundColor: const Color(0xFFF9F9F9),
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildFavItem(
              "كسكسي بالخضار",
              "15.00 د.ت",
              "assets/koski.jpg",
            ),
            _buildFavItem(
              "ملوخية تونسية",
              "22.00 د.ت",
              "assets/mloukhia.jpg",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavItem(String name, String price, String img) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.05 * 255).round()),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              img,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(
                width: 80,
                height: 80,
                color: Colors.grey.shade200,
                child: const Icon(Icons.broken_image),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  price,
                  style: const TextStyle(
                    color: Color(0xFFEE8C2B),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.favorite, color: Colors.red),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

// 4. PAGE PAIEMENT (نسخة تفاعلية وجديدة)
class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  // قائمة طرق الدفع
  List<Map<String, dynamic>> paymentMethods = [
    {"title": "الدفع نقداً عند الاستلام", "icon": Icons.money},
    {"title": "بطاقة بنكية (**** 1234)", "icon": Icons.credit_card},
  ];

  int selectedIndex = 0;
  final TextEditingController cardNumberController = TextEditingController();

  @override
  void dispose() {
    cardNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F9F9),
        appBar: AppBar(
          title: const Text('طرق الدفع', style: TextStyle(color: Colors.black)),
          centerTitle: true,
          backgroundColor: const Color(0xFFF9F9F9),
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // --- البطاقة البصرية ---
              Container(
                height: 180,
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEE8C2B), Color(0xFFE08E79)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withAlpha((0.3 * 255).round()),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(
                      Icons.credit_card,
                      color: Colors.white,
                      size: 30,
                    ),
                    const Text(
                      "**** **** **** 1234",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        letterSpacing: 2,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          "SARRA BENNANI",
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        Text(
                          "09/26",
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // --- قائمة الاختيارات ---
              Expanded(
                child: ListView.builder(
                  itemCount: paymentMethods.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedIndex = index;
                        });
                      },
                      child: _buildPaymentOption(
                        paymentMethods[index]["title"],
                        paymentMethods[index]["icon"],
                        selectedIndex == index,
                      ),
                    );
                  },
                ),
              ),

              // --- زر إضافة بطاقة ---
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _showAddCardDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEE8C2B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "إضافة بطاقة جديدة",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOption(String title, IconData icon, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected ? Colors.orange.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isSelected
            ? Border.all(color: const Color(0xFFEE8C2B), width: 2)
            : Border.all(color: Colors.transparent, width: 2),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isSelected ? const Color(0xFFEE8C2B) : Colors.grey[700],
          ),
          const SizedBox(width: 15),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isSelected ? const Color(0xFFEE8C2B) : Colors.black,
            ),
          ),
          const Spacer(),
          if (isSelected)
            const Icon(Icons.check_circle, color: Color(0xFFEE8C2B)),
        ],
      ),
    );
  }

  void _showAddCardDialog() {
    cardNumberController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          top: 20,
          left: 20,
          right: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "إضافة بطاقة بنكية",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: cardNumberController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.right,
              decoration: const InputDecoration(
                labelText: "رقم البطاقة",
                hintText: "0000 0000 0000 0000",
                prefixIcon: Icon(Icons.credit_card),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            Row(
              children: const [
                Expanded(
                  child: TextField(
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      labelText: "تاريخ الانتهاء",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      labelText: "CVC",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (cardNumberController.text.length >= 4) {
                  String last4 = cardNumberController.text.substring(
                    cardNumberController.text.length - 4,
                  );
                  setState(() {
                    paymentMethods.add({
                      "title": "بطاقة بنكية (**** $last4)",
                      "icon": Icons.credit_card,
                    });
                    selectedIndex = paymentMethods.length - 1;
                  });
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEE8C2B),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "حفظ البطاقة",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
