import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/dish.dart';
import 'api_service.dart';
import 'api_config.dart';

/// Service for chef dish management (CRUD)
class ChefDishService {
  static String get _baseUrl => ApiConfig.baseUrl;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Get all dishes for a chef
  static Future<ApiResponse> getMyDishes(String userId) async {
    return await ApiService.get('$_baseUrl/cookers/dishes?userId=$userId');
  }

  /// Get all available dishes (for customers)
  static Future<ApiResponse> getAllDishes({
    String? category,
    String? cookerId,
    String? search,
    int page = 1,
    int perPage = 20,
  }) async {
    String url = '$_baseUrl/dishes/?page=$page&perPage=$perPage';
    if (category != null) url += '&category=$category';
    if (cookerId != null) url += '&cookerId=$cookerId';
    if (search != null) url += '&search=$search';
    
    return await ApiService.get(url);
  }

  /// Get popular dishes
  static Future<ApiResponse> getPopularDishes({int limit = 10}) async {
    return await ApiService.get('$_baseUrl/dishes/popular?limit=$limit');
  }

  /// Get categories
  static Future<ApiResponse> getCategories() async {
    return await ApiService.get('$_baseUrl/dishes/categories');
  }

  /// Get a single dish
  static Future<ApiResponse> getDish(String dishId) async {
    return await ApiService.get('$_baseUrl/dishes/$dishId');
  }

  /// Create a new dish
  static Future<ApiResponse> createDish({
    required String userId,
    required String name,
    required double price,
    String description = '',
    String category = 'عام',
    String image = '',
    List<String> images = const [],
    List<String> ingredients = const [],
    int preparationTime = 30,
    String servingSize = '1 شخص',
    bool isSpicy = false,
    bool isVegetarian = false,
  }) async {
    // First, create via API
    final response = await ApiService.post(
      '$_baseUrl/dishes/',
      body: {
        'userId': userId,
        'name': name,
        'price': price,
        'description': description,
        'category': category,
        'image': image,
        'images': images,
        'ingredients': ingredients,
        'preparationTime': preparationTime,
        'servingSize': servingSize,
        'isSpicy': isSpicy,
        'isVegetarian': isVegetarian,
      },
    );

    // If successful, also write to Firestore for customer visibility
    if (response.success && response.data != null && response.data['dish'] != null) {
      try {
        final dishData = response.data['dish'];
        final dishId = dishData['id'] ?? '';
        
        // Get cooker/chef name from the cookers collection
        String cookerName = 'طاهي';
        try {
          final cookerDoc = await _db.collection('cookers').doc(userId).get();
          if (cookerDoc.exists) {
            cookerName = cookerDoc.data()?['fullName'] ?? cookerDoc.data()?['name'] ?? 'طاهي';
          }
        } catch (e) {
          print('Error getting cooker name: $e');
        }

        await _db.collection('dishes').doc(dishId).set({
          'name': name,
          'nameAr': name, // Arabic name (same as name for now)
          'description': description,
          'price': price,
          'category': category,
          'image': image,
          'cookerId': userId,
          'cookerName': cookerName,
          'rating': 0.0,
          'reviewCount': 0,
          'prepTime': preparationTime,
          'servings': 1,
          'isAvailable': true,
          'isPopular': false,
          'tags': ingredients,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('Dish written to Firestore: $dishId');
      } catch (e) {
        print('Error writing dish to Firestore: $e');
        // Don't fail the whole operation if Firestore write fails
      }
    }

    return response;
  }

  /// Update a dish
  static Future<ApiResponse> updateDish({
    required String userId,
    required String dishId,
    String? name,
    double? price,
    String? description,
    String? category,
    String? image,
    List<String>? images,
    List<String>? ingredients,
    int? preparationTime,
    String? servingSize,
    bool? isSpicy,
    bool? isVegetarian,
  }) async {
    final data = <String, dynamic>{'userId': userId};
    
    if (name != null) data['name'] = name;
    if (price != null) data['price'] = price;
    if (description != null) data['description'] = description;
    if (category != null) data['category'] = category;
    if (image != null) data['image'] = image;
    if (images != null) data['images'] = images;
    if (ingredients != null) data['ingredients'] = ingredients;
    if (preparationTime != null) data['preparationTime'] = preparationTime;
    if (servingSize != null) data['servingSize'] = servingSize;
    if (isSpicy != null) data['isSpicy'] = isSpicy;
    if (isVegetarian != null) data['isVegetarian'] = isVegetarian;

    final response = await ApiService.put('$_baseUrl/dishes/$dishId', body: data);

    // If successful, also update in Firestore
    if (response.success) {
      try {
        final updateData = <String, dynamic>{
          'updatedAt': FieldValue.serverTimestamp(),
        };
        
        if (name != null) {
          updateData['name'] = name;
          updateData['nameAr'] = name;
        }
        if (price != null) updateData['price'] = price;
        if (description != null) updateData['description'] = description;
        if (category != null) updateData['category'] = category;
        if (image != null) updateData['image'] = image;
        if (ingredients != null) updateData['tags'] = ingredients;
        if (preparationTime != null) updateData['prepTime'] = preparationTime;

        await _db.collection('dishes').doc(dishId).update(updateData);
        print('Dish updated in Firestore: $dishId');
      } catch (e) {
        print('Error updating dish in Firestore: $e');
        // Don't fail the whole operation if Firestore update fails
      }
    }

    return response;
  }

  /// Delete a dish
  static Future<ApiResponse> deleteDish({
    required String userId,
    required String dishId,
  }) async {
    final response = await ApiService.delete('$_baseUrl/dishes/$dishId?userId=$userId');

    // If successful, also delete from Firestore
    if (response.success) {
      try {
        await _db.collection('dishes').doc(dishId).delete();
        print('Dish deleted from Firestore: $dishId');
      } catch (e) {
        print('Error deleting dish from Firestore: $e');
      }
    }

    return response;
  }

  /// Toggle dish availability
  static Future<ApiResponse> toggleAvailability({
    required String userId,
    required String dishId,
    required bool isAvailable,
  }) async {
    final response = await ApiService.put(
      '$_baseUrl/dishes/$dishId/availability',
      body: {'userId': userId, 'isAvailable': isAvailable},
    );

    // If successful, also update in Firestore
    if (response.success) {
      try {
        await _db.collection('dishes').doc(dishId).update({
          'isAvailable': isAvailable,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('Dish availability updated in Firestore: $dishId');
      } catch (e) {
        print('Error updating availability in Firestore: $e');
      }
    }

    return response;
  }

  /// Parse dishes list from response
  static List<Dish> parseDishes(ApiResponse response) {
    if (response.success && response.data != null && response.data['dishes'] != null) {
      final List<dynamic> dishesJson = response.data['dishes'];
      return dishesJson.map((json) => _dishFromApiJson(json)).toList();
    }
    return [];
  }

  /// Convert API dish JSON to Dish model
  static Dish _dishFromApiJson(Map<String, dynamic> json) {
    return Dish(
      name: json['name'] ?? '',
      imageAsset: json['image'] ?? '',
      price: '${(json['price'] ?? 0).toStringAsFixed(2)} دت',
      rating: (json['rating'] ?? 0).toDouble(),
      cookName: json['cookerName'] ?? json['cookerId'] ?? '',
      location: json['location'] ?? '',
    );
  }

  /// Parse categories from response
  static List<DishCategory> parseCategories(ApiResponse response) {
    if (response.success && response.data != null && response.data['categories'] != null) {
      final List<dynamic> categoriesJson = response.data['categories'];
      return categoriesJson.map((json) => DishCategory.fromJson(json)).toList();
    }
    return [];
  }
}

/// Dish category model
class DishCategory {
  final String id;
  final String name;
  final String icon;

  DishCategory({
    required this.id,
    required this.name,
    this.icon = '',
  });

  factory DishCategory.fromJson(Map<String, dynamic> json) {
    return DishCategory(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      icon: json['icon'] ?? '',
    );
  }
}

/// Extended dish model for chef management (includes API fields)
class ChefDish {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final String image;
  final List<String> images;
  final List<String> ingredients;
  final int preparationTime;
  final String servingSize;
  final bool isAvailable;
  final bool isSpicy;
  final bool isVegetarian;
  final String cookerId;
  final String cookerName;
  final double rating;
  final int reviewsCount;
  final int ordersCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ChefDish({
    required this.id,
    required this.name,
    this.description = '',
    required this.price,
    this.category = 'عام',
    this.image = '',
    this.images = const [],
    this.ingredients = const [],
    this.preparationTime = 30,
    this.servingSize = '1 شخص',
    this.isAvailable = true,
    this.isSpicy = false,
    this.isVegetarian = false,
    this.cookerId = '',
    this.cookerName = '',
    this.rating = 0.0,
    this.reviewsCount = 0,
    this.ordersCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory ChefDish.fromJson(Map<String, dynamic> json) {
    return ChefDish(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      category: json['category'] ?? 'عام',
      image: json['image'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      ingredients: List<String>.from(json['ingredients'] ?? []),
      preparationTime: json['preparationTime'] ?? 30,
      servingSize: json['servingSize'] ?? '1 شخص',
      isAvailable: json['isAvailable'] ?? true,
      isSpicy: json['isSpicy'] ?? false,
      isVegetarian: json['isVegetarian'] ?? false,
      cookerId: json['cookerId'] ?? '',
      cookerName: json['cookerName'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      reviewsCount: json['reviewsCount'] ?? 0,
      ordersCount: json['ordersCount'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'image': image,
      'images': images,
      'ingredients': ingredients,
      'preparationTime': preparationTime,
      'servingSize': servingSize,
      'isAvailable': isAvailable,
      'isSpicy': isSpicy,
      'isVegetarian': isVegetarian,
      'cookerId': cookerId,
      'cookerName': cookerName,
      'rating': rating,
      'reviewsCount': reviewsCount,
      'ordersCount': ordersCount,
    };
  }

  /// Convert to Dish model for compatibility
  Dish toDish() {
    return Dish(
      name: name,
      imageAsset: image,
      price: '${price.toStringAsFixed(2)} دت',
      rating: rating,
      cookName: cookerName,
      location: '',
    );
  }

  /// Parse list of ChefDish from API response
  static List<ChefDish> parseList(ApiResponse response) {
    if (response.success && response.data != null && response.data['dishes'] != null) {
      final List<dynamic> dishesJson = response.data['dishes'];
      return dishesJson.map((json) => ChefDish.fromJson(json)).toList();
    }
    return [];
  }
}
