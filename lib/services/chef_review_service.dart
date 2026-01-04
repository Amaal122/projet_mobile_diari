/// Enhanced Review Service
/// ========================
/// Handles reviews and ratings for chefs using Firestore
/// Includes chef rating submission, stats, and streaming

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ChefReviewService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Submit a review for a chef after order
  static Future<ChefReviewResult> submitReview({
    required String orderId,
    required String chefId,
    required String customerId,
    required String customerName,
    required double rating,
    String comment = '',
  }) async {
    try {
      // Check if already reviewed
      final existing = await _db.collection('chef_reviews')
          .where('orderId', isEqualTo: orderId)
          .limit(1)
          .get();
      
      if (existing.docs.isNotEmpty) {
        return ChefReviewResult(success: false, error: 'تم تقييم هذا الطلب مسبقاً');
      }

      // Create review
      final reviewData = {
        'orderId': orderId,
        'chefId': chefId,
        'customerId': customerId,
        'customerName': customerName,
        'rating': rating,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
        'isVisible': true,
      };

      final reviewRef = await _db.collection('chef_reviews').add(reviewData);

      // Update order as rated
      await _db.collection('orders').doc(orderId).update({
        'isRated': true,
        'rating': rating,
      });

      // Update chef's average rating
      await _updateChefRating(chefId);

      return ChefReviewResult(success: true, reviewId: reviewRef.id);
    } catch (e) {
      debugPrint('Error submitting review: $e');
      return ChefReviewResult(success: false, error: 'حدث خطأ أثناء إرسال التقييم');
    }
  }

  /// Update chef's average rating
  static Future<void> _updateChefRating(String chefId) async {
    try {
      final reviews = await _db.collection('chef_reviews')
          .where('chefId', isEqualTo: chefId)
          .where('isVisible', isEqualTo: true)
          .get();

      if (reviews.docs.isEmpty) return;

      double totalRating = 0;
      for (final doc in reviews.docs) {
        totalRating += (doc.data()['rating'] ?? 0).toDouble();
      }

      final avgRating = totalRating / reviews.docs.length;

      await _db.collection('cookers').doc(chefId).update({
        'rating': double.parse(avgRating.toStringAsFixed(1)),
        'reviewsCount': reviews.docs.length,
      });
    } catch (e) {
      debugPrint('Error updating chef rating: $e');
    }
  }

  /// Get reviews for a chef
  static Future<List<ChefReview>> getChefReviews({
    required String chefId,
    int limit = 20,
  }) async {
    try {
      final snapshot = await _db.collection('chef_reviews')
          .where('chefId', isEqualTo: chefId)
          .where('isVisible', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => ChefReview.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting chef reviews: $e');
      return [];
    }
  }

  /// Stream reviews for a chef
  static Stream<List<ChefReview>> streamChefReviews(String chefId) {
    return _db.collection('chef_reviews')
        .where('chefId', isEqualTo: chefId)
        .where('isVisible', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => ChefReview.fromFirestore(doc)).toList());
  }

  /// Get chef rating stats
  static Future<ChefRatingStats> getChefRatingStats(String chefId) async {
    try {
      final snapshot = await _db.collection('chef_reviews')
          .where('chefId', isEqualTo: chefId)
          .where('isVisible', isEqualTo: true)
          .get();

      if (snapshot.docs.isEmpty) {
        return ChefRatingStats.empty();
      }

      final ratingCounts = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
      double totalRating = 0;

      for (final doc in snapshot.docs) {
        final rating = (doc.data()['rating'] ?? 0).toDouble();
        totalRating += rating;
        final rounded = rating.round().clamp(1, 5);
        ratingCounts[rounded] = (ratingCounts[rounded] ?? 0) + 1;
      }

      return ChefRatingStats(
        averageRating: totalRating / snapshot.docs.length,
        totalReviews: snapshot.docs.length,
        ratingCounts: ratingCounts,
      );
    } catch (e) {
      debugPrint('Error getting rating stats: $e');
      return ChefRatingStats.empty();
    }
  }
}

/// Review result
class ChefReviewResult {
  final bool success;
  final String? reviewId;
  final String? error;

  ChefReviewResult({required this.success, this.reviewId, this.error});
}

/// Chef Review model
class ChefReview {
  final String id;
  final String orderId;
  final String chefId;
  final String customerId;
  final String customerName;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final bool isVisible;

  ChefReview({
    required this.id,
    required this.orderId,
    required this.chefId,
    required this.customerId,
    required this.customerName,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.isVisible = true,
  });

  factory ChefReview.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChefReview(
      id: doc.id,
      orderId: data['orderId'] ?? '',
      chefId: data['chefId'] ?? '',
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? 'عميل',
      rating: (data['rating'] ?? 0).toDouble(),
      comment: data['comment'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isVisible: data['isVisible'] ?? true,
    );
  }

  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    
    if (diff.inDays > 30) {
      return 'منذ ${(diff.inDays / 30).floor()} شهر';
    } else if (diff.inDays > 0) {
      return 'منذ ${diff.inDays} يوم';
    } else if (diff.inHours > 0) {
      return 'منذ ${diff.inHours} ساعة';
    } else if (diff.inMinutes > 0) {
      return 'منذ ${diff.inMinutes} دقيقة';
    } else {
      return 'الآن';
    }
  }
}

/// Chef Rating statistics
class ChefRatingStats {
  final double averageRating;
  final int totalReviews;
  final Map<int, int> ratingCounts;

  ChefRatingStats({
    required this.averageRating,
    required this.totalReviews,
    required this.ratingCounts,
  });

  factory ChefRatingStats.empty() {
    return ChefRatingStats(
      averageRating: 0,
      totalReviews: 0,
      ratingCounts: {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
    );
  }

  double getPercentage(int stars) {
    if (totalReviews == 0) return 0;
    return ((ratingCounts[stars] ?? 0) / totalReviews) * 100;
  }
}
