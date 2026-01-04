/// Cache Manager
/// =============
/// Simple caching utility for offline support

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheManager {
  static const String _prefix = 'cache_';
  static const Duration _defaultTTL = Duration(hours: 24);

  /// Save data to cache
  static Future<bool> save(String key, dynamic data, {Duration? ttl}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'ttl': (ttl ?? _defaultTTL).inMilliseconds,
      };
      
      return await prefs.setString(
        '$_prefix$key',
        jsonEncode(cacheData),
      );
    } catch (e) {
      print('Error saving to cache: $e');
      return false;
    }
  }

  /// Get data from cache
  static Future<dynamic> get(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedStr = prefs.getString('$_prefix$key');
      
      if (cachedStr == null) return null;
      
      final cacheData = jsonDecode(cachedStr);
      final timestamp = cacheData['timestamp'] as int;
      final ttl = cacheData['ttl'] as int;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // Check if cache expired
      if (now - timestamp > ttl) {
        await remove(key);
        return null;
      }
      
      return cacheData['data'];
    } catch (e) {
      print('Error reading from cache: $e');
      return null;
    }
  }

  /// Remove data from cache
  static Future<bool> remove(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove('$_prefix$key');
    } catch (e) {
      print('Error removing from cache: $e');
      return false;
    }
  }

  /// Clear all cache
  static Future<bool> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith(_prefix));
      
      for (final key in keys) {
        await prefs.remove(key);
      }
      
      return true;
    } catch (e) {
      print('Error clearing cache: $e');
      return false;
    }
  }

  /// Check if cache exists and is valid
  static Future<bool> has(String key) async {
    final data = await get(key);
    return data != null;
  }

  /// Get or fetch (cache-aside pattern)
  static Future<T?> getOrFetch<T>(
    String key,
    Future<T> Function() fetchFn, {
    Duration? ttl,
  }) async {
    // Try cache first
    final cached = await get(key);
    if (cached != null) {
      return cached as T;
    }
    
    // Fetch from source
    try {
      final data = await fetchFn();
      await save(key, data, ttl: ttl);
      return data;
    } catch (e) {
      print('Error in getOrFetch: $e');
      return null;
    }
  }

  /// Cache keys
  static const String popularDishes = 'popular_dishes';
  static const String allDishes = 'all_dishes';
  static const String topCookers = 'top_cookers';
  static const String userProfile = 'user_profile';
  static const String cart = 'cart';
  static const String orderHistory = 'order_history';
  static const String favorites = 'favorites';
}
