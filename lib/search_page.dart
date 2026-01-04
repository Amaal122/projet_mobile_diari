import 'package:flutter/material.dart';
import 'models/dish.dart';
import 'dish_details_page.dart';
import 'theme.dart';
import 'services/dish_service.dart' as dish_svc;

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<dish_svc.Dish> _filteredDishes = [];
  List<dish_svc.Dish> _allDishes = [];
  bool _isSearching = false;
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
      _filteredDishes = dishes;
      _isLoading = false;
    });
  }

  Future<void> _filterDishes(String query) async {
    setState(() {
      _isSearching = query.isNotEmpty;
    });

    if (query.isEmpty) {
      setState(() {
        _filteredDishes = _allDishes;
      });
    } else {
      // Use Firestore search
      final results = await dish_svc.DishService.searchDishes(query);
      setState(() {
        _filteredDishes = results;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          title: const Text('البحث عن طبق'),
          centerTitle: true,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _searchController,
                      textAlign: TextAlign.right,
                      onChanged: _filterDishes,
                      decoration: InputDecoration(
                        hintText: 'ابحث عن طبق بيتي...',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.circular(16),
                        ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 16,
                  ),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                ),
              ),
            ),
            Expanded(
              child: _filteredDishes.isEmpty && _isSearching
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 80, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'لا توجد نتائج',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredDishes.length,
                      itemBuilder: (context, index) {
                        final dish = _filteredDishes[index];
                        return _DishCard(dish: dish);
                      },
                    ),
            ),
          ],
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
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              blurRadius: 6,
              color: Colors.black12,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(16),
              ),
              child: dish.image.startsWith('http')
                  ? Image.network(
                      dish.image,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildImagePlaceholder();
                      },
                    )
                  : Image.asset(
                      dish.image,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildImagePlaceholder();
                      },
                    ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dish.nameAr,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${dish.price.toStringAsFixed(2)} د.ت',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          dish.rating.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.access_time, size: 16),
                        const SizedBox(width: 2),
                        Text(
                          '${dish.prepTime} دقيقة',
                          style: const TextStyle(fontSize: 12),
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
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: 100,
      height: 100,
      color: Colors.grey[300],
      child: const Icon(Icons.restaurant, size: 40, color: Colors.grey),
    );
  }
}
