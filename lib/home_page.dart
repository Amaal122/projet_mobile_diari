import 'package:flutter/material.dart';
import 'dish_details_page.dart';
import 'userinterface.dart'; // <--- J'ai ajouté l'import ici !

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const Color primary = Color(0xFFEE8C2B);
  static const Color backgroundLight = Color(0xFFF8F7F6);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: backgroundLight,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: const [
                _HeaderWithSearch(),
                SizedBox(height: 32),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: _CategoriesSection(),
                ),
                SizedBox(height: 24),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: _FeaturedDishesSection(),
                ),
                SizedBox(height: 24),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: _BestCooksSection(),
                ),
                SizedBox(height: 24),
              ],
            ),
          ),
        ),
        bottomNavigationBar: const _BottomNavBar(),
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
              color: HomePage.primary,
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
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
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
              child: TextField(
                textAlign: TextAlign.right,
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
    final categories = const [
      _CategoryChip(label: 'تقليدي', emoji: '🍲', selected: true),
      _CategoryChip(label: 'كسكسي', emoji: '🍝'),
      _CategoryChip(label: 'مقرونة', emoji: '🍜'),
      _CategoryChip(label: 'بحري', emoji: '🐟'),
      _CategoryChip(label: 'حلويات', emoji: '🍰'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'الأصناف',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 48,
          child: ListView.separated(
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
  final bool selected;

  const _CategoryChip({
    required this.label,
    required this.emoji,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? HomePage.primary.withOpacity(0.2)
        : const Color(0xFFE5E5E5);
    final textColor = selected ? HomePage.primary : const Color(0xFF374151);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Text(emoji),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/* --------------------------- FEATURED DISHES --------------------------- */

class _FeaturedDishesSection extends StatelessWidget {
  const _FeaturedDishesSection();

  @override
  Widget build(BuildContext context) {
    final dishes = [
      Dish(
        name: 'كسكسي بالخضار',
        price: '15.00 د.ت',
        cookName: 'سنية',
        rating: 4.8,
        location: 'العوينة',
        imageAsset: 'lib/assets/images/koski.jpg',
      ),
      Dish(
        name: 'ملوخية باللحم',
        price: '22.50 د.ت',
        cookName: 'أمينة',
        rating: 4.9,
        location: 'المرسى',
        imageAsset: 'lib/assets/images/mloukhia.jpg',
      ),
      Dish(
        name: 'مقرونة بالدجاج',
        price: '12.00 د.ت',
        cookName: 'عائشة',
        rating: 4.7,
        location: 'أريانة',
        imageAsset: 'lib/assets/images/ma9rouna.jpg',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'الأطباق المميزة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'عرض الكل',
              style: TextStyle(
                color: HomePage.primary,
                fontWeight: FontWeight.w600,
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

class Dish {
  final String name;
  final String price;
  final String cookName;
  final double rating;
  final String location;
  final String imageAsset;

  Dish({
    required this.name,
    required this.price,
    required this.cookName,
    required this.rating,
    required this.location,
    required this.imageAsset,
  });
}

class _DishCard extends StatelessWidget {
  final Dish dish;

  const _DishCard({required this.dish});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DishDetailsPage()),
        );
      },
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
                child: Image.asset(
                  dish.imageAsset,
                  height: 130,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dish.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dish.price,
                      style: const TextStyle(
                        color: HomePage.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'من عند ${dish.cookName}',
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
                            const Icon(Icons.location_on, size: 16),
                            const SizedBox(width: 2),
                            Text(
                              dish.location,
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
}

/* ----------------------------- BEST COOKS ------------------------------ */

class _BestCooksSection extends StatelessWidget {
  const _BestCooksSection();

  @override
  Widget build(BuildContext context) {
    final cooks = [
      Cook(
        name: 'مريم بن علي',
        location: 'عوينة',
        rating: 4.9,
        tags: const ['حار', 'نباتي'],
        imageAsset: 'lib/assets/images/mariem.jpg',
      ),
      Cook(
        name: 'علي الغربي',
        location: 'البحيرة، تونس',
        rating: 4.8,
        tags: const ['أطباق بحرية', 'مشويات'],
        imageAsset: 'lib/assets/images/ali.jpg',
      ),
      Cook(
        name: 'سارة منصور',
        location: 'المنزه، تونس',
        rating: 4.7,
        tags: const ['حلويات', 'معجنات'],
        imageAsset: 'lib/assets/images/sarra.jpg',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'أفضل الطباخين بالقرب منك',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Column(
          children: cooks
              .map(
                (cook) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: _CookCard(cook: cook),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class Cook {
  final String name;
  final String location;
  final double rating;
  final List<String> tags;
  final String imageAsset;

  Cook({
    required this.name,
    required this.location,
    required this.rating,
    required this.tags,
    required this.imageAsset,
  });
}

class _CookCard extends StatelessWidget {
  final Cook cook;

  const _CookCard({required this.cook});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(blurRadius: 6, color: Colors.black12, offset: Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Image.asset(
              cook.imageAsset,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
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
                    Text(
                      cook.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                        const SizedBox(width: 2),
                        Text(
                          cook.rating.toStringAsFixed(1),
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
                    Text(
                      cook.location,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: cook.tags
                      .map(
                        (t) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: HomePage.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            t,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: HomePage.primary,
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
    );
  }
}

/* -------------------------- BOTTOM NAVIGATION -------------------------- */

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 0,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: HomePage.primary,
      unselectedItemColor: Colors.grey,
      onTap: (index) {
        // Si on clique sur l'icône "Profile" (index 3)
        if (index == 3) {
           Navigator.push(
             context,
             // CORRECTION ICI : On appelle UserInterfacePage
             MaterialPageRoute(builder: (context) => const UserInterfacePage()),
           );
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'الرئيسية'),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long),
          label: 'الطلبات',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat_bubble_outline),
          label: 'الرسائل',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'الحساب',
        ),
      ],
    );
  }
}