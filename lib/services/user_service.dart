/// User Service
/// =============
/// Handles user profile, addresses, favorites with Flask backend

import 'api_service.dart';
import 'api_config.dart';

class UserService {
  /// Get user profile
  static Future<ApiResponse> getProfile() async {
    return await ApiService.get(ApiConfig.userProfile);
  }
  
  /// Update user profile
  static Future<ApiResponse> updateProfile({
    String? name,
    String? phone,
    String? photoUrl,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (phone != null) body['phone'] = phone;
    if (photoUrl != null) body['photoUrl'] = photoUrl;
    
    return await ApiService.put(ApiConfig.userProfile, body: body);
  }
  
  // ==================== Addresses ====================
  
  /// Get all addresses
  static Future<ApiResponse> getAddresses() async {
    return await ApiService.get(ApiConfig.userAddresses);
  }
  
  /// Add new address
  static Future<ApiResponse> addAddress({
    required String address,
    String? label,
    String? city,
    bool isDefault = false,
  }) async {
    return await ApiService.post(
      ApiConfig.userAddresses,
      body: {
        'address': address,
        'label': label ?? 'المنزل',
        'city': city ?? '',
        'isDefault': isDefault,
      },
    );
  }
  
  /// Delete address
  static Future<ApiResponse> deleteAddress(String addressId) async {
    return await ApiService.delete(ApiConfig.deleteAddress(addressId));
  }
  
  // ==================== Favorites ====================
  
  /// Get all favorites
  static Future<ApiResponse> getFavorites() async {
    return await ApiService.get(ApiConfig.userFavorites);
  }
  
  /// Add to favorites
  static Future<ApiResponse> addFavorite({
    required String dishId,
    String? dishName,
    String? dishImage,
  }) async {
    return await ApiService.post(
      ApiConfig.favoriteById(dishId),
      body: {
        'dishName': dishName ?? '',
        'dishImage': dishImage ?? '',
      },
    );
  }
  
  /// Remove from favorites
  static Future<ApiResponse> removeFavorite(String dishId) async {
    return await ApiService.delete(ApiConfig.favoriteById(dishId));
  }
}


/// User Profile model
class UserProfile {
  final String uid;
  final String email;
  final String name;
  final String phone;
  final String? photoUrl;
  final List<Address> addresses;
  final List<FavoriteItem> favorites;
  
  UserProfile({
    required this.uid,
    required this.email,
    required this.name,
    required this.phone,
    this.photoUrl,
    required this.addresses,
    required this.favorites,
  });
  
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      photoUrl: json['photoUrl'],
      addresses: (json['addresses'] as List?)
          ?.map((addr) => Address.fromJson(addr))
          .toList() ?? [],
      favorites: (json['favorites'] as List?)
          ?.map((fav) => FavoriteItem.fromJson(fav))
          .toList() ?? [],
    );
  }
}


class Address {
  final String id;
  final String label;
  final String address;
  final String city;
  final bool isDefault;
  
  Address({
    required this.id,
    required this.label,
    required this.address,
    required this.city,
    required this.isDefault,
  });
  
  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'] ?? '',
      label: json['label'] ?? 'المنزل',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      isDefault: json['isDefault'] ?? false,
    );
  }
}


class FavoriteItem {
  final String dishId;
  final String dishName;
  final String dishImage;
  
  FavoriteItem({
    required this.dishId,
    required this.dishName,
    required this.dishImage,
  });
  
  factory FavoriteItem.fromJson(Map<String, dynamic> json) {
    return FavoriteItem(
      dishId: json['dishId'] ?? '',
      dishName: json['dishName'] ?? '',
      dishImage: json['dishImage'] ?? '',
    );
  }
}
