/// API Configuration
/// ==================
/// Central configuration for backend URLs and API settings

class ApiConfig {
  // Development
  static const String devBaseUrl = 'http://localhost:5000/api';
  
  // Production (update when deployed)
  static const String prodBaseUrl = 'https://your-api-domain.com/api';
  
  // Current environment
  static const bool isProduction = false;
  
  // Active base URL
  static String get baseUrl => isProduction ? prodBaseUrl : devBaseUrl;
  
  // API Endpoints
  static String get health => '$baseUrl/health';
  
  // Auth
  static String get authVerify => '$baseUrl/auth/verify';
  static String get authProfile => '$baseUrl/auth/profile';
  
  // Orders
  static String get orders => '$baseUrl/orders';
  static String orderById(String id) => '$baseUrl/orders/$id';
  static String cancelOrder(String id) => '$baseUrl/orders/$id/cancel';
  
  // Cart
  static String get cart => '$baseUrl/cart';
  static String get cartAdd => '$baseUrl/cart/add';
  static String get cartUpdate => '$baseUrl/cart/update';
  static String cartRemove(String dishId) => '$baseUrl/cart/remove/$dishId';
  static String get cartClear => '$baseUrl/cart/clear';
  
  // User
  static String get userProfile => '$baseUrl/users/profile';
  static String get userAddresses => '$baseUrl/users/addresses';
  static String deleteAddress(String id) => '$baseUrl/users/addresses/$id';
  static String get userFavorites => '$baseUrl/users/favorites';
  static String favoriteById(String dishId) => '$baseUrl/users/favorites/$dishId';
  
  // Timeout settings
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
