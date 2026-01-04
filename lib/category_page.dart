import 'package:flutter/material.dart';
import 'dish_details_page.dart';
import 'theme.dart';
import 'models/dish.dart';
import 'services/dish_service.dart' as dish_svc;

class CategoryPage extends StatefulWidget {
  final String categoryName;
  final String categoryEmoji;

  const CategoryPage({
    super.key,
    required this.categoryName,
    required this.categoryEmoji,
  });

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  List<dish_svc.Dish> _dishes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDishes();
  }

  Future<void> _loadDishes() async {
    setState(() => _isLoading = true);
    
    String categoryId = _mapCategoryToId(widget.categoryName);
    
    final dishes = await dish_svc.DishService.getDishesByCategory(categoryId);
    setState(() {
      _dishes = dishes;
      _isLoading = false;
    });
  }

  String _mapCategoryToId(String displayCategory) {
    // Map display category names to chef's actual category IDs
    final mapping = {
      'بحري': 'seafood',
      'كسكسي': 'couscous',
      'مقرونة': 'pasta',
      'تقليدي': 'traditional',
      'حلويات': 'desserts',
      'سلطات': 'salads',
      'مقبلات': 'appetizers',
      'مشوي': 'grilled',
    };
    return mapping[displayCategory] ?? displayCategory;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          elevation: 0,
          centerTitle: true,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.categoryEmoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Text(
                'أطباق ${widget.categoryName}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _dishes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.restaurant_menu, size: 80, color: Colors.grey.shade400),
                        const SizedBox(height: 20),
                        Text('لا توجد أطباق متاحة حاليا', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _dishes.length,
                    itemBuilder: (context, index) {
                      return _DishListItem(dish: _dishes[index]);
                    },
                  ),
      ),
    );
  }
}

class _DishListItem extends StatelessWidget {
  final dish_svc.Dish dish;
  const _DishListItem({required this.dish});

  @override
  Widget build(BuildContext context) {
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
        Navigator.push(context, MaterialPageRoute(builder: (_) => DishDetailsPage(dish: oldDish, dishId: dish.id)));
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(blurRadius: 8, offset: Offset(0, 4), color: Colors.black12)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: dish.image.startsWith('http')
                  ? Image.network(dish.image, height: 200, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildImagePlaceholder())
                  : Image.asset(dish.image, height: 200, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildImagePlaceholder()),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(dish.nameAr, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      Text('${dish.price.toStringAsFixed(2)} د.ت', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('من عند ${dish.cookerName}', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text(dish.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      Text(' (${dish.reviewCount})', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(width: 16),
                      const Icon(Icons.access_time, size: 18, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('${dish.prepTime} دقيقة', style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(height: 200, color: Colors.grey[300], child: const Center(child: Icon(Icons.restaurant, size: 60, color: Colors.grey)));
  }
}
