import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/favorite_model.dart';
import 'api_service.dart';

class FavoriteService {
  static final FavoriteService _instance = FavoriteService._internal();
  factory FavoriteService() => _instance;

  FavoriteService._internal();

  static const String _storageKey = 'favorite_items';
  final ValueNotifier<List<FavoriteItem>> favoritesNotifier = ValueNotifier([]);
  final ApiService _apiService = ApiService();

  Future<void> init() async {
    await loadFavorites();
  }

  Future<void> loadFavorites() async {
    // 1. Always load local first for immediate display
    final prefs = await SharedPreferences.getInstance();
    final String? favoritesJson = prefs.getString(_storageKey);
    List<FavoriteItem> localFavorites = [];
    if (favoritesJson != null) {
      final List<dynamic> decoded = jsonDecode(favoritesJson);
      localFavorites = decoded
          .map((item) => FavoriteItem.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    favoritesNotifier.value = localFavorites;

    // 2. If logged in, sync from backend (replaces local with server truth)
    if (_apiService.authStateNotifier.value) {
      try {
        final backendData = await _apiService.fetchFavorites();
        final backendFavorites = backendData
            .map((item) => FavoriteItem.fromJson(item))
            .toList();

        favoritesNotifier.value = backendFavorites;
        await _persist();
      } catch (e) {
        debugPrint("Error syncing favorites from backend: $e");
        // 后端失败时保留本地数据，不做额外更新
      }
    }
  }

  Future<void> saveFavorite(FavoriteItem item) async {
    final List<FavoriteItem> current = List.from(favoritesNotifier.value);

    // 1. If logged in, sync to backend first
    if (_apiService.authStateNotifier.value) {
      try {
        final result = await _apiService.addFavorite(
          productId: item.product.id,
          size: item.size,
          temp: item.temp,
          addons: item.addons,
          remark: item.remark,
        );
        // Create new item with backend ID
        item = FavoriteItem.fromJson(result);
      } catch (e) {
        debugPrint("Error saving favorite to backend: $e");
        // For now, continue to save locally even if backend fails
      }
    }

    // 2. Update local state
    final int index = current.indexWhere((f) => f.uniqueId == item.uniqueId);
    if (index != -1) {
      current[index] = item;
    } else {
      current.insert(0, item);
    }

    favoritesNotifier.value = current;
    await _persist();
  }

  Future<void> removeFavorite(String uniqueId) async {
    final List<FavoriteItem> current = List.from(favoritesNotifier.value);
    final int index = current.indexWhere((f) => f.uniqueId == uniqueId);

    if (index != -1) {
      final item = current[index];

      // 1. If logged in and has backend ID, remove from backend
      if (_apiService.authStateNotifier.value && item.id != null) {
        try {
          await _apiService.removeFavorite(item.id!);
        } catch (e) {
          debugPrint("Error removing favorite from backend: $e");
        }
      }

      // 2. Update local state
      current.removeAt(index);
      favoritesNotifier.value = current;
      await _persist();
    }
  }

  bool isFavorite(String uniqueId) {
    return favoritesNotifier.value.any((f) => f.uniqueId == uniqueId);
  }

  bool isProductFavorited(int productId) {
    return favoritesNotifier.value.any((f) => f.product.id == productId);
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(
      favoritesNotifier.value.map((f) => f.toJson()).toList(),
    );
    await prefs.setString(_storageKey, encoded);
  }

  // Clear all favorites
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    favoritesNotifier.value = [];
  }
}
