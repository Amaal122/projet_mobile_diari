import '../models/chef_profile.dart';
import 'api_service.dart';
import 'api_config.dart';

/// Service for chef/cooker operations
class ChefService {
  static String get _baseUrl => ApiConfig.baseUrl;

  /// Register as a chef
  static Future<ApiResponse> registerAsChef({
    required String userId,
    required String name,
    String bio = '',
    String phone = '',
    List<String> specialties = const [],
    String location = '',
    String address = '',
    String profileImage = '',
  }) async {
    return await ApiService.post(
      '$_baseUrl/cookers/register',
      body: {
        'userId': userId,
        'name': name,
        'bio': bio,
        'phone': phone,
        'specialties': specialties,
        'location': location,
        'address': address,
        'profileImage': profileImage,
      },
    );
  }

  /// Get chef profile
  static Future<ApiResponse> getProfile(String userId) async {
    return await ApiService.get('$_baseUrl/cookers/profile?userId=$userId');
  }

  /// Update chef profile
  static Future<ApiResponse> updateProfile({
    required String userId,
    String? name,
    String? bio,
    String? phone,
    List<String>? specialties,
    String? location,
    String? address,
    String? profileImage,
    Map<String, dynamic>? workingHours,
    Map<String, dynamic>? deliverySettings,
  }) async {
    final data = <String, dynamic>{'userId': userId};
    
    if (name != null) data['name'] = name;
    if (bio != null) data['bio'] = bio;
    if (phone != null) data['phone'] = phone;
    if (specialties != null) data['specialties'] = specialties;
    if (location != null) data['location'] = location;
    if (address != null) data['address'] = address;
    if (profileImage != null) data['profileImage'] = profileImage;
    if (workingHours != null) data['workingHours'] = workingHours;
    if (deliverySettings != null) data['deliverySettings'] = deliverySettings;

    return await ApiService.put('$_baseUrl/cookers/profile', body: data);
  }

  /// Toggle chef availability
  static Future<ApiResponse> toggleAvailability({
    required String userId,
    required bool isActive,
  }) async {
    return await ApiService.put(
      '$_baseUrl/cookers/availability',
      body: {'userId': userId, 'isActive': isActive},
    );
  }

  /// Get chef statistics
  static Future<ApiResponse> getStats(String userId) async {
    return await ApiService.get('$_baseUrl/cookers/stats?userId=$userId');
  }

  /// Get chef's orders
  static Future<ApiResponse> getOrders({
    required String userId,
    String? status,
    int page = 1,
    int perPage = 20,
  }) async {
    String url = '$_baseUrl/cookers/orders?userId=$userId&page=$page&perPage=$perPage';
    if (status != null) {
      url += '&status=$status';
    }
    return await ApiService.get(url);
  }

  /// Accept an order
  static Future<ApiResponse> acceptOrder({
    required String userId,
    required String orderId,
  }) async {
    return await ApiService.put(
      '$_baseUrl/cookers/orders/$orderId/respond',
      body: {'userId': userId, 'action': 'accept'},
    );
  }

  /// Reject an order
  static Future<ApiResponse> rejectOrder({
    required String userId,
    required String orderId,
    String reason = '',
  }) async {
    return await ApiService.put(
      '$_baseUrl/cookers/orders/$orderId/respond',
      body: {'userId': userId, 'action': 'reject', 'reason': reason},
    );
  }

  /// Update order status
  static Future<ApiResponse> updateOrderStatus({
    required String userId,
    required String orderId,
    required String status, // preparing, ready, out_for_delivery, completed
  }) async {
    return await ApiService.put(
      '$_baseUrl/cookers/orders/$orderId/status',
      body: {'userId': userId, 'status': status},
    );
  }

  /// Parse chef profile from response
  static ChefProfile? parseProfile(ApiResponse response) {
    if (response.success && response.data != null && response.data['chef'] != null) {
      return ChefProfile.fromJson(response.data['chef']);
    }
    return null;
  }

  /// Parse chef stats from response
  static ChefStats? parseStats(ApiResponse response) {
    if (response.success && response.data != null && response.data['stats'] != null) {
      return ChefStats.fromJson(response.data['stats']);
    }
    return null;
  }
}
