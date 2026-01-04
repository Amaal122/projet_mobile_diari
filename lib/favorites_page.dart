import 'package:flutter/material.dart';
import 'theme.dart';
import 'services/user_service.dart';
import 'services/dish_service.dart' as dish_svc;
import 'dish_details_page.dart';
import 'models/dish.dart';

const Color _primary = AppColors.primary;

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  List<FavoriteItem> _favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);
    final response = await UserService.getFavorites();
    if (response.success && response.data != null) {
      final List<dynamic> favList = response.data!['favorites'] ?? [];
      setState(() {
        _favorites = favList.map((fav) => FavoriteItem.fromJson(fav)).toList();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _removeFavorite(String dishId) async {
    final response = await UserService.removeFavorite(dishId);
    if (response.success) {
      await _loadFavorites();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت الإزالة من المفضلة'), backgroundColor: _primary),
        );
      }
    }
  }

  void _navigateToDishDetails(FavoriteItem favorite) async {
    // Fetch full dish details
    final dishes = await dish_svc.DishService.getAllDishes();
    final dish = dishes.firstWhere(
      (d) => d.id == favorite.dishId,
      orElse: () => dish_svc.Dish(
        id: favorite.dishId,
        name: favorite.dishName,
        nameAr: favorite.dishName,
        price: 0.0,
        image: favorite.dishImage,
        category: '',
        cookerId: '',
        cookerName: '',
        rating: 0.0,
        reviewCount: 0,
        description: '',
        prepTime: 0,
        servings: 1,
        isAvailable: true,
        isPopular: false,
        tags: [],
      ),
    );

    final oldDish = Dish(
      name: dish.nameAr,
      price: '${dish.price.toStringAsFixed(2)} د.ت',
      cookName: dish.cookerName,
      cookerId: dish.cookerId,
      rating: dish.rating,
      location: 'تونس',
      imageAsset: dish.image,
    );

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DishDetailsPage(dish: oldDish, dishId: dish.id),
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
          title: const Text('المفضلة', style: TextStyle(fontWeight: FontWeight.bold)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _favorites.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.favorite_border, size: 100, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        const Text('لا توجد أطباق مفضلة', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text('أضف أطباقك المفضلة لتجدها هنا', style: TextStyle(fontSize: 16, color: Colors.grey)),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context); // Close favorites
                            Navigator.pushNamed(context, '/home'); // Go to home with dishes
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primary,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          ),
                          child: const Text('تصفح الأطباق', style: TextStyle(fontSize: 16)),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadFavorites,
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: _favorites.length,
                      itemBuilder: (context, index) {
                        final favorite = _favorites[index];
                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: InkWell(
                            onTap: () => _navigateToDishDetails(favorite),
                            borderRadius: BorderRadius.circular(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                        child: favorite.dishImage.startsWith('http')
                                            ? Image.network(
                                                favorite.dishImage,
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) => Container(
                                                  color: Colors.grey[300],
                                                  child: const Icon(Icons.restaurant, size: 40),
                                                ),
                                              )
                                            : Image.asset(
                                                favorite.dishImage,
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) => Container(
                                                  color: Colors.grey[300],
                                                  child: const Icon(Icons.restaurant, size: 40),
                                                ),
                                              ),
                                      ),
                                      Positioned(
                                        top: 8,
                                        left: 8,
                                        child: InkWell(
                                          onTap: () => _removeFavorite(favorite.dishId),
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.1),
                                                  blurRadius: 4,
                                                ),
                                              ],
                                            ),
                                            child: const Icon(Icons.favorite, color: Colors.red, size: 20),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          favorite.dishName,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.restaurant_menu, size: 12, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                'اضغط للتفاصيل',
                                                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
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
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}
