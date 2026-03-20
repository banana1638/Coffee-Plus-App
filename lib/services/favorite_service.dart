import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/favorite_model.dart';

class FavoriteService {
  static final FavoriteService _instance = FavoriteService._internal();
  factory FavoriteService() => _instance;

  FavoriteService._internal();

  static const String _storageKey = 'favorite_items';
  final ValueNotifier<List<FavoriteItem>> favoritesNotifier = ValueNotifier([]);

  Future<void> init() async {
    await loadFavorites();
  }

  Future<void> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final String? favoritesJson = prefs.getString(_storageKey);
    if (favoritesJson != null) {
      final List<dynamic> decoded = jsonDecode(favoritesJson);
      favoritesNotifier.value = decoded
          .map((item) => FavoriteItem.fromJson(item as Map<String, dynamic>))
          .toList();
    } else {
      favoritesNotifier.value = [];
    }
  }

  Future<void> saveFavorite(FavoriteItem item) async {
    final List<FavoriteItem> current = List.from(favoritesNotifier.value);
    
    // Check if exactly this combination already exists, if so, update remark and date
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
    current.removeWhere((f) => f.uniqueId == uniqueId);
    favoritesNotifier.value = current;
    await _persist();
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
