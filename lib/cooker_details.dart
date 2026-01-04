import 'package:flutter/material.dart';
import 'models/cooker.dart';
import 'models/dish.dart';
import 'theme.dart';
import 'services/cooker_service.dart' as cooker_svc;
import 'services/dish_service.dart' as dish_svc;
import 'dish_details_page.dart';

class CookerDetailsPage extends StatefulWidget {
  final Cooker cooker;

  const CookerDetailsPage({super.key, required this.cooker});

  @override
  State<CookerDetailsPage> createState() => _CookerDetailsPageState();
}

class _CookerDetailsPageState extends State<CookerDetailsPage> {
  cooker_svc.Cooker? _cookerDetails;
  List<dish_svc.Dish> _cookerDishes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCookerData();
  }

  Future<void> _loadCookerData() async {
    setState(() => _isLoading = true);
    
    final cookerDetails = await cooker_svc.CookerService.getCookerById(widget.cooker.id);
    final dishes = await dish_svc.DishService.getDishesByCooker(widget.cooker.id);
    
    setState(() {
      _cookerDetails = cookerDetails;
      _cookerDishes = dishes;
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
          backgroundColor: AppColors.primary,
          title: Text(_cookerDetails?.name ?? widget.cooker.name),
          centerTitle: true,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _cookerDetails == null
                ? const Center(child: Text('لم يتم العثور على معلومات الطباخ'))
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildCookerHeader(),
                        const SizedBox(height: 16),
                        _buildCookerInfo(),
                        const SizedBox(height: 24),
                        _buildDishesList(),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildCookerHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.white,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(60),
            child: _cookerDetails!.image.startsWith('http')
                ? Image.network(_cookerDetails!.image, width: 120, height: 120, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildAvatarPlaceholder())
                : Image.asset(_cookerDetails!.image, width: 120, height: 120, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildAvatarPlaceholder()),
          ),
          const SizedBox(height: 16),
          Text(_cookerDetails!.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(_cookerDetails!.specialty, style: const TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 20),
              const SizedBox(width: 4),
              Text('${_cookerDetails!.rating.toStringAsFixed(1)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              Text(' (${_cookerDetails!.reviewCount} تقييم)', style: const TextStyle(fontSize: 14, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCookerInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('عن الطباخ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(_cookerDetails!.bio, style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.location_on, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Text(_cookerDetails!.location, style: const TextStyle(fontSize: 14)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.restaurant_menu, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Text('${_cookerDishes.length} طبق', style: const TextStyle(fontSize: 14)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDishesList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('الأطباق', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _cookerDishes.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(32),
                  child: const Center(child: Text('لا توجد أطباق متاحة حاليا', style: TextStyle(color: Colors.grey))),
                )
              : Column(
                  children: _cookerDishes.map((dish) => _buildDishCard(dish)).toList(),
                ),
        ],
      ),
    );
  }

  Widget _buildDishCard(dish_svc.Dish dish) {
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
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DishDetailsPage(dish: oldDish, dishId: dish.id))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black12)],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: dish.image.startsWith('http')
                  ? Image.network(dish.image, width: 80, height: 80, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildDishPlaceholder())
                  : Image.asset(dish.image, width: 80, height: 80, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildDishPlaceholder()),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dish.nameAr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('${dish.price.toStringAsFixed(2)} د.ت', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(dish.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 12)),
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

  Widget _buildAvatarPlaceholder() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(color: Colors.grey[300], shape: BoxShape.circle),
      child: const Icon(Icons.person, size: 60, color: Colors.grey),
    );
  }

  Widget _buildDishPlaceholder() {
    return Container(
      width: 80,
      height: 80,
      color: Colors.grey[300],
      child: const Icon(Icons.restaurant, size: 40, color: Colors.grey),
    );
  }
}
