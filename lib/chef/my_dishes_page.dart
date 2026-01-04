import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme.dart';
import '../services/chef_dish_service.dart';
import 'add_dish_page.dart';

const Color _primary = AppColors.primary;

class MyDishesPage extends StatefulWidget {
  const MyDishesPage({super.key});

  @override
  State<MyDishesPage> createState() => _MyDishesPageState();
}

class _MyDishesPageState extends State<MyDishesPage> {
  List<ChefDish> _dishes = [];
  bool _isLoading = true;
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    _loadDishes();
  }

  Future<void> _loadDishes() async {
    setState(() => _isLoading = true);
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final response = await ChefDishService.getMyDishes(user.uid);
      if (response.success && mounted) {
        setState(() {
          _dishes = ChefDish.parseList(response);
        });
      }
    } catch (e) {
      debugPrint('Error loading dishes: $e');
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _toggleAvailability(ChefDish dish) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final response = await ChefDishService.toggleAvailability(
        userId: user.uid,
        dishId: dish.id,
        isAvailable: !dish.isAvailable,
      );

      if (response.success && mounted) {
        await _loadDishes();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(dish.isAvailable ? 'الطبق غير متاح الآن' : 'الطبق متاح الآن'),
            backgroundColor: dish.isAvailable ? Colors.grey : Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error toggling availability: $e');
    }
  }

  Future<void> _deleteDish(ChefDish dish) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الطبق', textDirection: TextDirection.rtl),
        content: Text(
          'هل أنت متأكد من حذف "${dish.name}"؟',
          textDirection: TextDirection.rtl,
        ),
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

    if (confirmed != true) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final response = await ChefDishService.deleteDish(
        userId: user.uid,
        dishId: dish.id,
      );

      if (response.success && mounted) {
        await _loadDishes();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حذف الطبق'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error deleting dish: $e');
    }
  }

  void _editDish(ChefDish dish) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddDishPage(dish: dish),
      ),
    );

    if (result == true) {
      _loadDishes();
    }
  }

  void _addDish() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddDishPage(),
      ),
    );

    if (result == true) {
      _loadDishes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: _primary,
        title: const Text('أطباقي'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacementNamed(context, '/chef'),
          tooltip: 'العودة للرئيسية',
        ),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
            onPressed: () => setState(() => _isGridView = !_isGridView),
            tooltip: _isGridView ? 'عرض قائمة' : 'عرض شبكة',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : RefreshIndicator(
              onRefresh: _loadDishes,
              color: _primary,
              child: _dishes.isEmpty
                  ? _buildEmptyState()
                  : _isGridView
                      ? _buildGridView()
                      : _buildListView(),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addDish,
        backgroundColor: _primary,
        icon: const Icon(Icons.add),
        label: const Text('إضافة طبق'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant_menu, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'لا توجد أطباق حالياً',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'أضف أول طبق لك',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _addDish,
            icon: const Icon(Icons.add),
            label: const Text('إضافة طبق'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: _dishes.length,
      itemBuilder: (context, index) {
        final dish = _dishes[index];
        return _buildDishCard(dish);
      },
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _dishes.length,
      itemBuilder: (context, index) {
        final dish = _dishes[index];
        return _buildDishListItem(dish);
      },
    );
  }

  Widget _buildDishCard(ChefDish dish) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image
              Expanded(
                flex: 3,
                child: dish.image.isNotEmpty
                    ? Image.network(
                        dish.image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.restaurant, size: 40),
                        ),
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.restaurant, size: 40),
                      ),
              ),
              // Info
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dish.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${dish.price.toStringAsFixed(2)} دت',
                        style: const TextStyle(
                          color: _primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 14,
                            color: Colors.amber[700],
                          ),
                          Text(
                            ' ${dish.rating.toStringAsFixed(1)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          const Spacer(),
                          Text(
                            '${dish.ordersCount} طلب',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Availability badge
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: dish.isAvailable ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                dish.isAvailable ? 'متاح' : 'غير متاح',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // Menu button
          Positioned(
            top: 8,
            left: 8,
            child: PopupMenuButton<String>(
              icon: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.more_vert, color: Colors.white, size: 18),
              ),
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _editDish(dish);
                    break;
                  case 'toggle':
                    _toggleAvailability(dish);
                    break;
                  case 'delete':
                    _deleteDish(dish);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 18),
                      SizedBox(width: 8),
                      Text('تعديل'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'toggle',
                  child: Row(
                    children: [
                      Icon(
                        dish.isAvailable ? Icons.visibility_off : Icons.visibility,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(dish.isAvailable ? 'إخفاء' : 'إظهار'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('حذف', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDishListItem(ChefDish dish) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: dish.image.isNotEmpty
              ? Image.network(
                  dish.image,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[300],
                    child: const Icon(Icons.restaurant),
                  ),
                )
              : Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey[300],
                  child: const Icon(Icons.restaurant),
                ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                dish.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: dish.isAvailable 
                    ? Colors.green.withOpacity(0.1) 
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                dish.isAvailable ? 'متاح' : 'غير متاح',
                style: TextStyle(
                  fontSize: 10,
                  color: dish.isAvailable ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${dish.price.toStringAsFixed(2)} دت',
              style: const TextStyle(
                color: _primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.star, size: 14, color: Colors.amber[700]),
                Text(' ${dish.rating.toStringAsFixed(1)}'),
                const SizedBox(width: 12),
                Text('${dish.ordersCount} طلب'),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _editDish(dish);
                break;
              case 'toggle':
                _toggleAvailability(dish);
                break;
              case 'delete':
                _deleteDish(dish);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 18),
                  SizedBox(width: 8),
                  Text('تعديل'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'toggle',
              child: Row(
                children: [
                  Icon(
                    dish.isAvailable ? Icons.visibility_off : Icons.visibility,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(dish.isAvailable ? 'إخفاء' : 'إظهار'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 18, color: Colors.red),
                  SizedBox(width: 8),
                  Text('حذف', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
