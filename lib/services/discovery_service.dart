/// Discovery Service
/// ==================
/// Advanced search and discovery for dishes and chefs

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class DiscoveryService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Search dishes with filters
  static Future<List<DishResult>> searchDishes({
    String? query,
    String? category,
    String? location,
    double? maxPrice,
    double? minRating,
    bool? isSpicy,
    bool? isVegetarian,
    String? sortBy, // 'rating', 'price', 'orders', 'newest'
    int limit = 20,
  }) async {
    try {
      Query queryRef = _db.collection('dishes')
          .where('isAvailable', isEqualTo: true);

      // Apply filters
      if (category != null && category.isNotEmpty) {
        queryRef = queryRef.where('category', isEqualTo: category);
      }

      if (isSpicy != null) {
        queryRef = queryRef.where('isSpicy', isEqualTo: isSpicy);
      }

      if (isVegetarian != null) {
        queryRef = queryRef.where('isVegetarian', isEqualTo: isVegetarian);
      }

      // Apply sorting
      switch (sortBy) {
        case 'rating':
          queryRef = queryRef.orderBy('rating', descending: true);
          break;
        case 'price':
          queryRef = queryRef.orderBy('price', descending: false);
          break;
        case 'orders':
          queryRef = queryRef.orderBy('ordersCount', descending: true);
          break;
        case 'newest':
        default:
          queryRef = queryRef.orderBy('createdAt', descending: true);
      }

      queryRef = queryRef.limit(limit);

      final snapshot = await queryRef.get();
      
      var results = snapshot.docs
          .map((doc) => DishResult.fromFirestore(doc))
          .toList();

      // Client-side filtering for fields that can't be combined in Firestore
      if (query != null && query.isNotEmpty) {
        final queryLower = query.toLowerCase();
        results = results.where((dish) {
          return dish.name.toLowerCase().contains(queryLower) ||
              dish.description.toLowerCase().contains(queryLower) ||
              dish.cookerName.toLowerCase().contains(queryLower);
        }).toList();
      }

      if (maxPrice != null) {
        results = results.where((dish) => dish.price <= maxPrice).toList();
      }

      if (minRating != null) {
        results = results.where((dish) => dish.rating >= minRating).toList();
      }

      if (location != null && location.isNotEmpty) {
        final locationLower = location.toLowerCase();
        results = results.where((dish) => 
            dish.location.toLowerCase().contains(locationLower)).toList();
      }

      return results;
    } catch (e) {
      debugPrint('Error searching dishes: $e');
      return [];
    }
  }

  /// Search chefs with filters
  static Future<List<ChefResult>> searchChefs({
    String? query,
    String? location,
    double? minRating,
    String? specialty,
    String? sortBy, // 'rating', 'orders', 'dishes', 'newest'
    int limit = 20,
  }) async {
    try {
      Query queryRef = _db.collection('cookers')
          .where('isAvailable', isEqualTo: true);

      // Apply sorting
      switch (sortBy) {
        case 'rating':
          queryRef = queryRef.orderBy('rating', descending: true);
          break;
        case 'orders':
          queryRef = queryRef.orderBy('totalOrders', descending: true);
          break;
        case 'dishes':
          queryRef = queryRef.orderBy('totalDishes', descending: true);
          break;
        case 'newest':
        default:
          queryRef = queryRef.orderBy('createdAt', descending: true);
      }

      queryRef = queryRef.limit(limit);

      final snapshot = await queryRef.get();
      
      var results = snapshot.docs
          .map((doc) => ChefResult.fromFirestore(doc))
          .toList();

      // Client-side filtering
      if (query != null && query.isNotEmpty) {
        final queryLower = query.toLowerCase();
        results = results.where((chef) {
          return chef.name.toLowerCase().contains(queryLower) ||
              chef.location.toLowerCase().contains(queryLower) ||
              chef.specialties.any((s) => s.toLowerCase().contains(queryLower));
        }).toList();
      }

      if (location != null && location.isNotEmpty) {
        final locationLower = location.toLowerCase();
        results = results.where((chef) => 
            chef.location.toLowerCase().contains(locationLower)).toList();
      }

      if (minRating != null) {
        results = results.where((chef) => chef.rating >= minRating).toList();
      }

      if (specialty != null && specialty.isNotEmpty) {
        results = results.where((chef) => 
            chef.specialties.any((s) => s.contains(specialty))).toList();
      }

      return results;
    } catch (e) {
      debugPrint('Error searching chefs: $e');
      return [];
    }
  }

  /// Get trending dishes (most ordered in last 7 days)
  static Future<List<DishResult>> getTrendingDishes({int limit = 10}) async {
    try {
      final snapshot = await _db.collection('dishes')
          .where('isAvailable', isEqualTo: true)
          .orderBy('ordersCount', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => DishResult.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting trending dishes: $e');
      return [];
    }
  }

  /// Get top rated dishes
  static Future<List<DishResult>> getTopRatedDishes({int limit = 10}) async {
    try {
      final snapshot = await _db.collection('dishes')
          .where('isAvailable', isEqualTo: true)
          .orderBy('rating', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => DishResult.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting top rated dishes: $e');
      return [];
    }
  }

  /// Get nearby chefs
  static Future<List<ChefResult>> getNearbyChefs({
    required String location,
    int limit = 10,
  }) async {
    try {
      final locationLower = location.toLowerCase();
      
      final snapshot = await _db.collection('cookers')
          .where('isAvailable', isEqualTo: true)
          .orderBy('rating', descending: true)
          .limit(50)
          .get();

      final results = snapshot.docs
          .map((doc) => ChefResult.fromFirestore(doc))
          .where((chef) => chef.location.toLowerCase().contains(locationLower))
          .take(limit)
          .toList();

      return results;
    } catch (e) {
      debugPrint('Error getting nearby chefs: $e');
      return [];
    }
  }

  /// Get recommended dishes based on user history
  static Future<List<DishResult>> getRecommendedDishes({
    String? userId,
    int limit = 10,
  }) async {
    // TODO: Implement recommendation algorithm based on user's order history
    // For now, return top rated dishes
    return getTopRatedDishes(limit: limit);
  }

  /// Get categories with counts
  static Future<List<CategoryInfo>> getCategories() async {
    try {
      final snapshot = await _db.collection('dishes')
          .where('isAvailable', isEqualTo: true)
          .get();

      final categoryCounts = <String, int>{};
      for (final doc in snapshot.docs) {
        final category = doc.data()['category'] as String? ?? 'أخرى';
        categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
      }

      return categoryCounts.entries
          .map((e) => CategoryInfo(name: e.key, count: e.value))
          .toList()
        ..sort((a, b) => b.count.compareTo(a.count));
    } catch (e) {
      debugPrint('Error getting categories: $e');
      return [];
    }
  }
}

/// Dish search result
class DishResult {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final String image;
  final double rating;
  final int reviewCount;
  final int ordersCount;
  final String cookerId;
  final String cookerName;
  final String location;
  final bool isSpicy;
  final bool isVegetarian;

  DishResult({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.image,
    required this.rating,
    required this.reviewCount,
    required this.ordersCount,
    required this.cookerId,
    required this.cookerName,
    required this.location,
    required this.isSpicy,
    required this.isVegetarian,
  });

  factory DishResult.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DishResult(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      category: data['category'] ?? '',
      image: data['image'] ?? '',
      rating: (data['rating'] ?? 0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      ordersCount: data['ordersCount'] ?? 0,
      cookerId: data['cookerId'] ?? '',
      cookerName: data['cookerName'] ?? '',
      location: data['location'] ?? '',
      isSpicy: data['isSpicy'] ?? false,
      isVegetarian: data['isVegetarian'] ?? false,
    );
  }
}

/// Chef search result
class ChefResult {
  final String id;
  final String name;
  final String profileImage;
  final String location;
  final double rating;
  final int totalReviews;
  final int totalDishes;
  final int totalOrders;
  final List<String> specialties;
  final String bio;

  ChefResult({
    required this.id,
    required this.name,
    required this.profileImage,
    required this.location,
    required this.rating,
    required this.totalReviews,
    required this.totalDishes,
    required this.totalOrders,
    required this.specialties,
    required this.bio,
  });

  factory ChefResult.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChefResult(
      id: doc.id,
      name: data['name'] ?? '',
      profileImage: data['profileImage'] ?? '',
      location: data['location'] ?? '',
      rating: (data['rating'] ?? 0).toDouble(),
      totalReviews: data['totalReviews'] ?? 0,
      totalDishes: data['totalDishes'] ?? 0,
      totalOrders: data['totalOrders'] ?? 0,
      specialties: List<String>.from(data['specialties'] ?? []),
      bio: data['bio'] ?? '',
    );
  }
}

/// Category info
class CategoryInfo {
  final String name;
  final int count;

  CategoryInfo({required this.name, required this.count});
}
