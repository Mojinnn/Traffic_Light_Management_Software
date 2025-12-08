import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class FeatureService {
  static const String apiUrl = 'YOUR_BACKEND_URL/features';

  // Singleton pattern
  static final FeatureService _instance = FeatureService._internal();
  factory FeatureService() => _instance;
  FeatureService._internal();

  Map<String, bool> _featureCache = {};

  // Load tất cả features từ backend khi app khởi động
  Future<void> initialize() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();

        for (var feature in data['features']) {
          final featureId = feature['featureId'];
          final isEnabled = feature['isEnabled'];
          _featureCache[featureId] = isEnabled;
          await prefs.setBool(featureId, isEnabled);
        }
      }
    } catch (e) {
      print('Error initializing features: $e');
      await _loadFromLocal();
    }
  }

  // Load từ local storage
  Future<void> _loadFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (var key in keys) {
      _featureCache[key] = prefs.getBool(key) ?? true;
    }
  }

  // Kiểm tra tính năng có được bật không
  Future<bool> isFeatureEnabled(String featureId) async {
    // Check cache trước
    if (_featureCache.containsKey(featureId)) {
      return _featureCache[featureId]!;
    }

    // Nếu không có trong cache, load từ local
    final prefs = await SharedPreferences.getInstance();
    final status = prefs.getBool(featureId) ?? true;
    _featureCache[featureId] = status;
    return status;
  }

  // Admin cập nhật trạng thái tính năng
  Future<void> updateFeatureStatus(String featureId, bool isEnabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(featureId, isEnabled);
    _featureCache[featureId] = isEnabled;

    try {
      await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'featureId': featureId, 'isEnabled': isEnabled}),
      );
    } catch (e) {
      print('Error updating feature: $e');
    }
  }

  // Lắng nghe thay đổi từ backend (polling hoặc websocket)
  void startListening(Function() onUpdate) {
    // Option 1: Polling mỗi 10 giây
    Stream.periodic(Duration(seconds: 10)).listen((_) async {
      await initialize();
      onUpdate();
    });
  }
}
