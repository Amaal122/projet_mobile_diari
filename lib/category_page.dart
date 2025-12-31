import 'package:flutter/material.dart';
import 'dish_details_page.dart';
import 'models/dish.dart';

class CategoryPage extends StatelessWidget {
  final String categoryName;
  final String categoryEmoji;

  const CategoryPage({
    super.key,
    required this.categoryName,
    required this.categoryEmoji,
  });

  @override
  Widget build(BuildContext context) {
    final dishes = _getDishesForCategory(categoryName);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F7F6),
        appBar: AppBar(
          backgroundColor: const Color(0xFFEE8C2B),
          elevation: 0,
          centerTitle: true,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(categoryEmoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Text(
                'أطباق $categoryName',
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
        body: dishes.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.restaurant_menu,
                      size: 80,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'لا توجد أطباق متاحة حالياً',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: dishes.length,
                itemBuilder: (context, index) {
                  return _DishListItem(dish: dishes[index]);
                },
              ),
      ),
    );
  }

  List<DishData> _getDishesForCategory(String category) {
    final Map<String, List<DishData>> dishesDatabase = {
      'بحري': [
        DishData(
          name: 'سمك مشوي',
          cookName: 'محمد الساحلي',
          cookImage: 'lib/assets/images/ali.jpg',
          rating: 4.9,
          price: '25.00',
          location: 'حلق الوادي',
          imageAsset: 'lib/assets/images/fish.jpg',
          description: 'سمك طازج مشوي على الفحم مع صلصة الهريسة',
          ingredients: ['سمك طازج', 'ليمون', 'هريسة', 'ثوم', 'كزبرة'],
          preparationTime: 'متوفر مع نصف النهار',
          tags: ['حار', 'صحي', 'بروتين عالي'],
        ),
        DishData(
          name: 'كمونية روبيان',
          cookName: 'ليلى البحراوي',
          cookImage: 'lib/assets/images/mariem.jpg',
          rating: 4.8,
          price: '28.00',
          location: 'قرطاج',
          imageAsset: 'lib/assets/images/shrimp.jpg',
          description: 'روبيان طازج بالكمون والهريسة على الطريقة التونسية',
          ingredients: ['روبيان', 'كمون', 'هريسة', 'طماطم', 'فلفل'],
          preparationTime: 'متوفر مع نصف النهار',
          tags: ['حار', 'بحري', 'حريف'],
        ),
        DishData(
          name: 'مقرونة بالفواكه البحرية',
          cookName: 'نادية الصيادي',
          cookImage: 'lib/assets/images/sarra.jpg',
          rating: 4.7,
          price: '22.00',
          location: 'المرسى',
          imageAsset: 'lib/assets/images/seafood_pasta.jpg',
          description: 'مقرونة بالروبيان والكلمار وبلح البحر',
          ingredients: ['مقرونة', 'روبيان', 'كلمار', 'بلح البحر', 'صلصة'],
          preparationTime: 'متوفر مع نصف النهار',
          tags: ['إيطالي', 'بحري'],
        ),
        DishData(
          name: 'سلطة تونسية بالتونة',
          cookName: 'فاطمة الزهراء',
          cookImage: 'lib/assets/images/mariem.jpg',
          rating: 4.6,
          price: '15.00',
          location: 'باردو',
          imageAsset: 'lib/assets/images/tuna_salad.jpg',
          description: 'سلطة تونسية مع التونة الطازجة والبيض والزيتون',
          ingredients: ['تونة', 'بيض', 'زيتون', 'طماطم', 'فلفل'],
          preparationTime: 'متوفر مع نصف النهار',
          tags: ['صحي', 'خفيف'],
        ),
      ],
      'كسكسي': [
        DishData(
          name: 'كسكسي بالخضار',
          cookName: 'سنية',
          cookImage: 'lib/assets/images/mariem.jpg',
          rating: 4.8,
          price: '15.00',
          location: 'العوينة',
          imageAsset: 'lib/assets/images/koski.jpg',
          description: 'كسكسي تقليدي بالخضار الطازجة',
          ingredients: ['كسكسي', 'جزر', 'كوسة', 'فلفل', 'بطاطا'],
          preparationTime: 'متوفر مع نصف النهار',
          tags: ['نباتي', 'صحي'],
        ),
        DishData(
          name: 'كسكسي باللحم',
          cookName: 'آمال',
          cookImage: 'lib/assets/images/sarra.jpg',
          rating: 4.9,
          price: '18.00',
          location: 'المنزه',
          imageAsset: 'lib/assets/images/koski.jpg',
          description: 'كسكسي باللحم الأحمر والخضار',
          ingredients: ['كسكسي', 'لحم غنمي', 'خضار', 'حمص', 'فلفل'],
          preparationTime: 'متوفر مع نصف النهار',
          tags: ['تقليدي', 'لحم'],
        ),
      ],
      'مقرونة': [
        DishData(
          name: 'مقرونة بالدجاج',
          cookName: 'عائشة',
          cookImage: 'lib/assets/images/mariem.jpg',
          rating: 4.7,
          price: '12.00',
          location: 'أريانة',
          imageAsset: 'lib/assets/images/ma9rouna.jpg',
          description: 'مقرونة بالدجاج والصلصة الحمراء',
          ingredients: ['مقرونة', 'دجاج', 'صلصة طماطم', 'بصل', 'ثوم'],
          preparationTime: 'متوفر مع نصف النهار',
          tags: ['دجاج', 'إيطالي'],
        ),
      ],
      'تقليدي': [
        DishData(
          name: 'ملوخية باللحم',
          cookName: 'أمينة',
          cookImage: 'lib/assets/images/sarra.jpg',
          rating: 4.9,
          price: '22.50',
          location: 'المرسى',
          imageAsset: 'lib/assets/images/mloukhia.jpg',
          description: 'ملوخية تونسية أصيلة باللحم',
          ingredients: ['ملوخية', 'لحم', 'ثوم', 'هريسة', 'بهارات'],
          preparationTime: 'متوفر مع نصف النهار',
          tags: ['تقليدي', 'تونسي'],
        ),
      ],
      'حلويات': [
        DishData(
          name: 'كعك الورقة',
          cookName: 'فاطمة',
          cookImage: 'lib/assets/images/mariem.jpg',
          rating: 4.6,
          price: '8.00',
          location: 'باردو',
          imageAsset: 'lib/assets/images/cake.jpg',
          description: 'كعك الورقة التونسي بالعسل واللوز',
          ingredients: ['عجين ورقة', 'لوز', 'عسل', 'ماء الزهر', 'سكر'],
          preparationTime: 'متوفر طوال اليوم',
          tags: ['حلويات', 'تقليدي'],
        ),
      ],
    };

    return dishesDatabase[category] ?? [];
  }
}

class DishData {
  final String name;
  final String cookName;
  final String cookImage;
  final double rating;
  final String price;
  final String location;
  final String imageAsset;
  final String description;
  final List<String> ingredients;
  final String preparationTime;
  final List<String> tags;

  DishData({
    required this.name,
    required this.cookName,
    required this.cookImage,
    required this.rating,
    required this.price,
    required this.location,
    required this.imageAsset,
    required this.description,
    required this.ingredients,
    required this.preparationTime,
    required this.tags,
  });
}

class _DishListItem extends StatelessWidget {
  final DishData dish;

  const _DishListItem({required this.dish});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DishDetailsPage(
              dish: Dish(
                name: dish.name,
                price: dish.price,
                cookName: dish.cookName,
                rating: dish.rating,
                location: dish.location,
                imageAsset: dish.imageAsset,
              ),
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Image.asset(
                dish.imageAsset,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 180,
                    color: Colors.grey.shade200,
                    child: Icon(
                      Icons.restaurant,
                      size: 60,
                      color: Colors.grey.shade400,
                    ),
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dish.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    dish.description,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEE8C2B).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 20,
                          color: Color(0xFFEE8C2B),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dish.cookName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  dish.location,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              dish.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Text(
                        '${dish.price} د.ت',
                        style: const TextStyle(
                          color: Color(0xFFEE8C2B),
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
}
