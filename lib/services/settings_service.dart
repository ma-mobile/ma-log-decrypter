import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class RecentItem {
  RecentItem({
    required this.path,
    required this.type,
    required this.openedAt,
  });

  final String path;
  final RecentItemType type;
  final DateTime openedAt;

  Map<String, dynamic> toJson() => {
    'path': path,
    'type': type.name,
    'openedAt': openedAt.toIso8601String(),
  };

  factory RecentItem.fromJson(Map<String, dynamic> json) => RecentItem(
    path: json['path'] as String,
    type: RecentItemType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => RecentItemType.log,
    ),
    openedAt: DateTime.tryParse(json['openedAt'] as String) ?? DateTime.now(),
  );
}

enum RecentItemType { log, database }

class SettingsService {
  static const String _recentItemsKey = 'recent_items';
  static const String _themeModeKey = 'theme_mode';
  static const String _windowBoundsKey = 'window_bounds';
  static const int _maxRecentItems = 15;

  static Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  static Future<List<RecentItem>> loadRecentItems() async {
    final prefs = await _prefs;
    final jsonString = prefs.getString(_recentItemsKey);
    if (jsonString == null || jsonString.isEmpty) return [];
    try {
      final list = jsonDecode(jsonString) as List<dynamic>;
      return list
          .map((e) => RecentItem.fromJson(e as Map<String, dynamic>))
          .where((item) => item.path.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> addRecentItem(RecentItem item) async {
    final prefs = await _prefs;
    final items = await loadRecentItems();
    items.removeWhere((existing) => existing.path == item.path);
    items.insert(0, item);
    if (items.length > _maxRecentItems) {
      items.removeRange(_maxRecentItems, items.length);
    }
    await prefs.setString(_recentItemsKey, jsonEncode(items));
  }

  static Future<void> removeRecentItem(String path) async {
    final prefs = await _prefs;
    final items = await loadRecentItems();
    items.removeWhere((existing) => existing.path == path);
    await prefs.setString(_recentItemsKey, jsonEncode(items));
  }

  static Future<String?> loadThemeMode() async {
    final prefs = await _prefs;
    return prefs.getString(_themeModeKey);
  }

  static Future<void> saveThemeMode(String mode) async {
    final prefs = await _prefs;
    await prefs.setString(_themeModeKey, mode);
  }

  static Future<Map<String, dynamic>?> loadWindowBounds() async {
    final prefs = await _prefs;
    final jsonString = prefs.getString(_windowBoundsKey);
    if (jsonString == null || jsonString.isEmpty) return null;
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveWindowBounds(Map<String, dynamic> bounds) async {
    final prefs = await _prefs;
    await prefs.setString(_windowBoundsKey, jsonEncode(bounds));
  }
}
