import 'package:flutter/material.dart';
import 'theme.dart';
import 'category_page.dart';
import 'cooker_details.dart';
import 'dish_details_page.dart';
import 'search_page.dart';
import 'models/cooker.dart';
import 'models/dish.dart';
import 'all_dishes_page.dart';
import 'services/dish_service.dart' as dish_svc;
import 'services/cooker_service.dart' as cooker_svc;

class HomePage extends StatefulWidget {
  final bool showNavBar;
  const HomePage({super.key, this.showNavBar = true});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const Color backgroundLight = AppColors.backgroundLight;

  List<dish_svc.Dish> _popularDishes = [];
  List<cooker_svc.Cooker> _topCookers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final dishes = await dish_svc.DishService.getPopularDishes(limit: 10);
    final cookers = await cooker_svc.CookerService.getTopCookers(limit: 5);
    
    setState(() {
      _popularDishes = dishes;
      _topCookers = cookers;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: backgroundLight,
        body: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      const _HeaderWithSearch(),
                      const SizedBox(height: 32),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: _CategoriesSection(),
                      ),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _FeaturedDishesSection(dishes: _popularDishes),
                      ),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _BestCooksSection(cookers: _topCookers),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

/* --------------------------- HEADER + SEARCH --------------------------- */
class _HeaderWithSearch extends StatelessWidget {
  const _HeaderWithSearch();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 230,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 180,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'مرحباً!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'تونس، تونس',
                        style: TextStyle(
                          color: Colors.white.withAlpha((0.8 * 255).round()),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 28),
                  onPressed: () {
                    Navigator.pushNamed(context, '/cart');
                  },
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha((0.3 * 255).round()),
                    shape: BoxShape.circle,
                  ),
                  child: const Text('👋', style: TextStyle(fontSize: 24)),
                ),
              ],
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: -24,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SearchPage()),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 16,
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.search, color: Colors.grey),
                      SizedBox(width: 12),
                      Text(
                        'ابحث عن طبق بيتي...',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ------------------------------ CATEGORIES ----------------------------- */
class _CategoriesSection extends StatelessWidget {
  const _CategoriesSection();

  @override
  Widget build(BuildContext context) {
    final categories = [
      _CategoryChip(
        label: 'بحري',
        emoji: '🐟',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const CategoryPage(categoryName: 'بحري', categoryEmoji: '🐟'),
            ),
          );
        },
      ),
      _CategoryChip(
        label: 'كسكسي',
        emoji: '🍝',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CategoryPage(
                categoryName: 'كسكسي',
                categoryEmoji: '🍝',
              ),
            ),
          );
        },
      ),
      _CategoryChip(
        label: 'مقرونة',
        emoji: '🍜',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CategoryPage(
                categoryName: 'مقرونة',
                categoryEmoji: '🍜',
              ),
            ),
          );
        },
      ),
      _CategoryChip(
        label: 'تقليدي',
        emoji: '🍲',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CategoryPage(
                categoryName: 'تقليدي',
                categoryEmoji: '🍲',
              ),
            ),
          );
        },
      ),
      _CategoryChip(
        label: 'حلويات',
        emoji: '🍰',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CategoryPage(
                categoryName: 'حلويات',
                categoryEmoji: '🍰',
              ),
            ),
          );
        },
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'التصنيفات',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 60,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) => categories[index],
          ),
        ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final String emoji;
  final VoidCallback? onTap;

  const _CategoryChip({required this.label, required this.emoji, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFE5E5E5),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          children: [
            Text(emoji),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF374151),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* --------------------------- FEATURED DISHES --------------------------- */
class _FeaturedDishesSection extends StatelessWidget {
  final List<dish_svc.Dish> dishes;
  const _FeaturedDishesSection({required this.dishes});

  @override
  Widget build(BuildContext context) {
    if (dishes.isEmpty) {
      return Column(
        children: [
          const Text(
            'الأطباق المميزة',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(32),
            child: const Text(
              'لا توجد أطباق متاحة حالياً',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'الأطباق المميزة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AllDishesPage()),
                );
              },
              child: const Text(
                'عرض الكل',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 300,
          child: Center(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < dishes.length; i++) ...[
                    _DishCard(dish: dishes[i]),
                    if (i != dishes.length - 1) const SizedBox(width: 12),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DishCard extends StatelessWidget {
  final dish_svc.Dish dish;

  const _DishCard({required this.dish});

  @override
  Widget build(BuildContext context) {
    // Convert Firestore Dish to old Dish model for navigation
    final oldDish = Dish(
      name: dish.nameAr,
      price: '${dish.price.toStringAsFixed(2)} د.ت',
      cookName: dish.cookerName,
      cookerId: dish.cookerId, // Pass cookerId for order tracking
      rating: dish.rating,
      location: 'تونس', // Default location
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
      child: SizedBox(
        width: 220,
        child: Container(
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: dish.image.startsWith('http')
                    ? Image.network(
                        dish.image,
                        height: 130,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildImagePlaceholder();
                        },
                      )
                    : Image.asset(
                        dish.image,
                        height: 130,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildImagePlaceholder();
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dish.nameAr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
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
                    Text(
                      'من عند ${dish.cookerName}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 16,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              dish.rating.toStringAsFixed(1),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        Row(
                          children: [
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
                  ],
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
      height: 130,
      width: double.infinity,
      color: Colors.grey[300],
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant, size: 40, color: Colors.grey),
          SizedBox(height: 8),
          Text('صورة غير متوفرة', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

/* ----------------------------- BEST COOKS ------------------------------ */
class _BestCooksSection extends StatelessWidget {
  final List<cooker_svc.Cooker> cookers;
  const _BestCooksSection({required this.cookers});

  @override
  Widget build(BuildContext context) {
    if (cookers.isEmpty) {
      return Column(
        children: [
          const Text(
            'أفضل الطباخين بالقرب منك',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(32),
            child: const Text(
              'لا يوجد طباخين متاحين حالياً',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'أفضل الطباخين بالقرب منك',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Column(
          children: cookers
              .map(
                (cooker) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: _CookCard(cooker: cooker),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _CookCard extends StatelessWidget {
  final cooker_svc.Cooker cooker;

  const _CookCard({required this.cooker});

  @override
  Widget build(BuildContext context) {
    // Convert Firestore Cooker to old Cooker model for navigation
    final oldCooker = Cooker(
      id: cooker.id,
      name: cooker.name,
      avatarUrl: cooker.image,
      location: cooker.location,
      rating: cooker.rating,
      bio: cooker.bio,
    );

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CookerDetailsPage(cooker: oldCooker)),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: cooker.image.startsWith('http')
                  ? Image.network(
                      cooker.image,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildAvatarPlaceholder();
                      },
                    )
                  : Image.asset(
                      cooker.image,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildAvatarPlaceholder();
                      },
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          cooker.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text(
                            cooker.rating.toStringAsFixed(1),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          cooker.location,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: cooker.tags.take(3)
                        .map(
                          (t) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(
                                (0.12 * 255).round(),
                              ),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              t,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.person, size: 32, color: Colors.grey),
    );
  }
}


