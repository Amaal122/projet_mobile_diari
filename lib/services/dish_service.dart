/// Dish Service
/// =============
/// Handles Firestore operations for dishes
/// Read dishes, search, filter by category

import 'package:cloud_firestore/cloud_firestore.dart';

class DishService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final CollectionReference _dishesRef = _db.collection('dishes');
  
  /// Get all dishes
  static Future<List<Dish>> getAllDishes() async {
    try {
      final snapshot = await _dishesRef
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => Dish.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting dishes: $e');
      return [];
    }
  }
  
  /// Get popular dishes (highest rated)
  static Future<List<Dish>> getPopularDishes({int limit = 10}) async {
    try {
      // Simple query - just get by rating (no composite index needed)
      final snapshot = await _dishesRef
          .orderBy('rating', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) => Dish.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting popular dishes: $e');
      // Fallback: get all dishes and sort locally
      try {
        final allSnapshot = await _dishesRef.limit(limit * 2).get();
        final dishes = allSnapshot.docs
            .map((doc) => Dish.fromFirestore(doc))
            .toList();
        dishes.sort((a, b) => b.rating.compareTo(a.rating));
        return dishes.take(limit).toList();
      } catch (e2) {
        print('Fallback also failed: $e2');
        return [];
      }
    }
  }
  
  /// Get dish by ID
  static Future<Dish?> getDishById(String id) async {
    try {
      final doc = await _dishesRef.doc(id).get();
      if (doc.exists) {
        return Dish.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting dish: $e');
      return null;
    }
  }
  
  /// Get dishes by category
  static Future<List<Dish>> getDishesByCategory(String category) async {
    try {
      // Simple where query without orderBy to avoid composite index
      final snapshot = await _dishesRef
          .where('category', isEqualTo: category)
          .get();
      
      final dishes = snapshot.docs
          .map((doc) => Dish.fromFirestore(doc))
          .toList();
      
      // Sort locally by rating
      dishes.sort((a, b) => b.rating.compareTo(a.rating));
      return dishes;
    } catch (e) {
      print('Error getting dishes by category: $e');
      return [];
    }
  }
  
  /// Get dishes by cooker
  static Future<List<Dish>> getDishesByCooker(String cookerId) async {
    try {
      final snapshot = await _dishesRef
          .where('cookerId', isEqualTo: cookerId)
          .orderBy('rating', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => Dish.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting dishes by cooker: $e');
      return [];
    }
  }
  
  /// Search dishes by name (Arabic or English)
  static Future<List<Dish>> searchDishes(String query) async {
    try {
      // Get all dishes first (Firestore doesn't support full-text search natively)
      final snapshot = await _dishesRef.get();
      final allDishes = snapshot.docs
          .map((doc) => Dish.fromFirestore(doc))
          .toList();
      
      // Filter locally
      final lowerQuery = query.toLowerCase();
      return allDishes.where((dish) {
        return dish.name.toLowerCase().contains(lowerQuery) ||
               dish.nameAr.contains(query) ||
               dish.category.contains(query);
      }).toList();
    } catch (e) {
      print('Error searching dishes: $e');
      return [];
    }
  }
  
  /// Get all categories
  static Future<List<String>> getAllCategories() async {
    try {
      final snapshot = await _dishesRef.get();
      final categories = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .map((data) => data['category'] as String)
          .toSet()
          .toList();
      return categories;
    } catch (e) {
      print('Error getting categories: $e');
      return [];
    }
  }
  
  /// Stream dishes (real-time updates)
  static Stream<List<Dish>> streamDishes() {
    return _dishesRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Dish.fromFirestore(doc)).toList());
  }
}


/// Dish Model
class Dish {
  final String id;
  final String name;
  final String nameAr;
  final String description;
  final double price;
  final String category;
  final String image;
  final String cookerId;
  final String cookerName;
  final double rating;
  final int reviewCount;
  final int prepTime;
  final int servings;
  final bool isAvailable;
  final bool isPopular;
  final List<String> tags;
  
  Dish({
    required this.id,
    required this.name,
    required this.nameAr,
    required this.description,
    required this.price,
    required this.category,
    required this.image,
    required this.cookerId,
    required this.cookerName,
    required this.rating,
    required this.reviewCount,
    required this.prepTime,
    required this.servings,
    required this.isAvailable,
    required this.isPopular,
    required this.tags,
  });
  
  factory Dish.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Dish(
      id: doc.id,
      name: data['name'] ?? '',
      nameAr: data['nameAr'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      category: data['category'] ?? '',
      image: data['image'] ?? '',
      cookerId: data['cookerId'] ?? '',
      cookerName: data['cookerName'] ?? '',
      rating: (data['rating'] ?? 0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      prepTime: data['prepTime'] ?? 0,
      servings: data['servings'] ?? 0,
      isAvailable: data['isAvailable'] ?? true,
      isPopular: data['isPopular'] ?? false,
      tags: List<String>.from(data['tags'] ?? []),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'nameAr': nameAr,
      'description': description,
      'price': price,
      'category': category,
      'image': image,
      'cookerId': cookerId,
      'cookerName': cookerName,
      'rating': rating,
      'reviewCount': reviewCount,
      'prepTime': prepTime,
      'servings': servings,
      'isAvailable': isAvailable,
      'isPopular': isPopular,
      'tags': tags,
    };
  }
}
