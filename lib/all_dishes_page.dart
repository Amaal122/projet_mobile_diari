import 'package:flutter/material.dart';
import 'models/dish.dart';
import 'dish_details_page.dart';
import 'theme.dart';
import 'services/dish_service.dart' as dish_svc;

class AllDishesPage extends StatefulWidget {
  const AllDishesPage({super.key});

  @override
  State<AllDishesPage> createState() => _AllDishesPageState();
}

class _AllDishesPageState extends State<AllDishesPage> {
  List<dish_svc.Dish> _allDishes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDishes();
  }

  Future<void> _loadDishes() async {
    setState(() => _isLoading = true);
    final dishes = await dish_svc.DishService.getAllDishes();
    setState(() {
      _allDishes = dishes;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          title: const Text('جميع الأطباق'),
          backgroundColor: AppColors.primary,
          centerTitle: true,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _allDishes.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.restaurant_menu, size: 80, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'لا توجد أطباق متاحة',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _allDishes.length,
                itemBuilder: (context, index) {
                  final dish = _allDishes[index];
                  return _DishCard(dish: dish);
                },
              ),
      ),
    );
  }
}

class _DishCard extends StatelessWidget {
  final dish_svc.Dish dish;

  const _DishCard({required this.dish});

  @override
  Widget build(BuildContext context) {
    // Convert to old Dish model
    final oldDish = Dish(
      name: dish.nameAr,
      price: '${dish.price.toStringAsFixed(2)} د.ت',
      cookName: dish.cookerName,
      cookerId: dish.cookerId,
      rating: dish.rating,
      location: 'تونس',
      imageAsset: dish.image,
    );

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DishDetailsPage(dish: oldDish, dishId: dish.id)),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: dish.image.startsWith('http')
                    ? Image.network(
                        dish.image,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildImagePlaceholder();
                        },
                      )
                    : Image.asset(
                        dish.image,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildImagePlaceholder();
                        },
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dish.nameAr,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'من عند ${dish.cookerName} • تونس',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          dish.rating.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                '${dish.price.toStringAsFixed(2)} د.ت',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: 80,
      height: 80,
      color: Colors.grey[300],
      child: const Icon(Icons.restaurant, size: 30, color: Colors.grey),
    );
  }
}
