/// Review Service
/// ===============
/// Handles review/rating operations via Flask backend

import 'api_service.dart';
import 'api_config.dart';

class ReviewService {
  static String get _base => ApiConfig.baseUrl;

  /// Add a review for a dish
  static Future<ApiResponse> addDishReview({
    required String dishId,
    required int rating,
    String comment = '',
  }) async {
    return await ApiService.post(
      '$_base/reviews/dish/$dishId',
      body: {
        'rating': rating,
        'comment': comment,
      },
    );
  }

  /// Get reviews for a dish
  static Future<ApiResponse> getDishReviews(String dishId, {int page = 1, int perPage = 10}) async {
    return await ApiService.get(
      '$_base/reviews/dish/$dishId?page=$page&per_page=$perPage',
    );
  }

  /// Get all reviews by current user
  static Future<ApiResponse> getUserReviews() async {
    return await ApiService.get('$_base/reviews/user/me/dishes');
  }

  /// Delete a review
  static Future<ApiResponse> deleteReview(String reviewId) async {
    return await ApiService.delete('$_base/reviews/$reviewId');
  }
}

/// Review model
class Review {
  final String id;
  final int rating;
  final String comment;
  final DateTime? createdAt;
  final String userName;
  final String userImage;

  Review({
    required this.id,
    required this.rating,
    required this.comment,
    this.createdAt,
    required this.userName,
    required this.userImage,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] ?? '',
      rating: json['rating'] ?? 0,
      comment: json['comment'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      userName: json['userName'] ?? 'مستخدم',
      userImage: json['userImage'] ?? '',
    );
  }
}
