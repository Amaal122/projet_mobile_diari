/// API Service
/// ============
/// Handles HTTP requests to Flask backend with Firebase token authentication

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class ApiService {
  static String? _authToken;
  
  /// Set the Firebase ID token for authenticated requests
  static void setAuthToken(String token) {
    _authToken = token;
  }
  
  /// Clear auth token (on logout)
  static void clearAuthToken() {
    _authToken = null;
  }
  
  /// Get headers with optional auth token
  static Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
    };
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }
  
  /// GET request
  static Future<ApiResponse> get(String url) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      ).timeout(ApiConfig.connectionTimeout);
      
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }
  
  /// POST request
  static Future<ApiResponse> post(String url, {Map<String, dynamic>? body}) async {
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(ApiConfig.connectionTimeout);
      
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }
  
  /// PUT request
  static Future<ApiResponse> put(String url, {Map<String, dynamic>? body}) async {
    try {
      final response = await http.put(
        Uri.parse(url),
        headers: _headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(ApiConfig.connectionTimeout);
      
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }
  
  /// DELETE request
  static Future<ApiResponse> delete(String url) async {
    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: _headers,
      ).timeout(ApiConfig.connectionTimeout);
      
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }
  
  /// Handle HTTP response
  static ApiResponse _handleResponse(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse(success: true, data: data);
      } else {
        return ApiResponse(
          success: false,
          error: data['error'] ?? 'Request failed',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        error: 'Failed to parse response',
        statusCode: response.statusCode,
      );
    }
  }
  
  // ==================== Health Check ====================
  
  static Future<bool> checkHealth() async {
    final response = await get(ApiConfig.health);
    return response.success;
  }
}


/// API Response wrapper
class ApiResponse {
  final bool success;
  final dynamic data;
  final String? error;
  final int? statusCode;
  
  ApiResponse({
    required this.success,
    this.data,
    this.error,
    this.statusCode,
  });
  
  @override
  String toString() {
    if (success) {
      return 'ApiResponse(success: true, data: $data)';
    } else {
      return 'ApiResponse(success: false, error: $error, statusCode: $statusCode)';
    }
  }
}
