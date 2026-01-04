/// Cooker Service
/// ===============
/// Handles Firestore operations for cookers (cooks/chefs)
/// Get cooker profiles, their dishes, ratings

import 'package:cloud_firestore/cloud_firestore.dart';

class CookerService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final CollectionReference _cookersRef = _db.collection('cookers');
  
  /// Get all cookers
  static Future<List<Cooker>> getAllCookers() async {
    try {
      final snapshot = await _cookersRef
          .orderBy('rating', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => Cooker.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting cookers: $e');
      return [];
    }
  }
  
  /// Get cooker by ID
  static Future<Cooker?> getCookerById(String id) async {
    try {
      final doc = await _cookersRef.doc(id).get();
      if (doc.exists) {
        return Cooker.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting cooker: $e');
      return null;
    }
  }
  
  /// Get top rated cookers
  static Future<List<Cooker>> getTopCookers({int limit = 5}) async {
    try {
      // Simple query - just get by rating (no composite index needed)
      final snapshot = await _cookersRef
          .orderBy('rating', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) => Cooker.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting top cookers: $e');
      // Fallback: get all and sort locally
      try {
        final allSnapshot = await _cookersRef.limit(limit * 2).get();
        final cookers = allSnapshot.docs
            .map((doc) => Cooker.fromFirestore(doc))
            .toList();
        cookers.sort((a, b) => b.rating.compareTo(a.rating));
        return cookers.take(limit).toList();
      } catch (e2) {
        print('Fallback also failed: $e2');
        return [];
      }
    }
  }
  
  /// Get active cookers (accepting orders)
  static Future<List<Cooker>> getActiveCookers() async {
    try {
      final snapshot = await _cookersRef
          .where('isActive', isEqualTo: true)
          .orderBy('rating', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => Cooker.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting active cookers: $e');
      return [];
    }
  }
  
  /// Search cookers by name or specialty
  static Future<List<Cooker>> searchCookers(String query) async {
    try {
      final snapshot = await _cookersRef.get();
      final allCookers = snapshot.docs
          .map((doc) => Cooker.fromFirestore(doc))
          .toList();
      
      // Filter locally
      final lowerQuery = query.toLowerCase();
      return allCookers.where((cooker) {
        return cooker.name.toLowerCase().contains(lowerQuery) ||
               cooker.name.contains(query) ||
               cooker.specialty.contains(query) ||
               cooker.location.contains(query);
      }).toList();
    } catch (e) {
      print('Error searching cookers: $e');
      return [];
    }
  }
  
  /// Stream cookers (real-time updates)
  static Stream<List<Cooker>> streamCookers() {
    return _cookersRef
        .orderBy('rating', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Cooker.fromFirestore(doc)).toList());
  }
}


/// Cooker Model
class Cooker {
  final String id;
  final String name;
  final String bio;
  final String specialty;
  final double rating;
  final int reviewCount;
  final int dishCount;
  final String location;
  final String image;
  final bool isVerified;
  final bool isActive;
  final List<String> tags;
  final String phone;
  final double deliveryFee;
  final double minOrder;
  
  Cooker({
    required this.id,
    required this.name,
    required this.bio,
    required this.specialty,
    required this.rating,
    required this.reviewCount,
    required this.dishCount,
    required this.location,
    required this.image,
    required this.isVerified,
    required this.isActive,
    required this.tags,
    required this.phone,
    required this.deliveryFee,
    required this.minOrder,
  });
  
  factory Cooker.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Cooker(
      id: doc.id,
      name: data['name'] ?? '',
      bio: data['bio'] ?? '',
      specialty: data['specialty'] ?? '',
      rating: (data['rating'] ?? 0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      dishCount: data['dishCount'] ?? 0,
      location: data['location'] ?? '',
      image: data['image'] ?? '',
      isVerified: data['isVerified'] ?? false,
      isActive: data['isActive'] ?? true,
      tags: List<String>.from(data['tags'] ?? []),
      phone: data['phone'] ?? '',
      deliveryFee: (data['deliveryFee'] ?? 0).toDouble(),
      minOrder: (data['minOrder'] ?? 0).toDouble(),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'bio': bio,
      'specialty': specialty,
      'rating': rating,
      'reviewCount': reviewCount,
      'dishCount': dishCount,
      'location': location,
      'image': image,
      'isVerified': isVerified,
      'isActive': isActive,
      'tags': tags,
      'phone': phone,
      'deliveryFee': deliveryFee,
      'minOrder': minOrder,
    };
  }
}
