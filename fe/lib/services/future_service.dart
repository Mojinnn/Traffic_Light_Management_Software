import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class FeatureService {
  static const String apiUrl = 'http://localhost:8000/api/features';

  static final FeatureService _instance = FeatureService._internal();
  factory FeatureService() => _instance;
  FeatureService._internal();

  Map<String, bool> _cache = {};

  Future<void> initialize() async {
    try {
      final res = await http.get(Uri.parse(apiUrl));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final prefs = await SharedPreferences.getInstance();

        for (var f in data["features"]) {
          final id = f["featureId"];
          final enabled = f["isEnabled"];

          _cache[id] = enabled;
          await prefs.setBool(id, enabled);
        }
      }
    } catch (e) {
      await _loadLocal();
    }
  }

  Future<void> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    for (var k in prefs.getKeys()) {
      _cache[k] = prefs.getBool(k) ?? true;
    }
  }

  Future<bool> isFeatureEnabled(String featureId) async {
    if (_cache.containsKey(featureId)) {
      return _cache[featureId]!;
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(featureId) ?? true;
  }

  Future<void> update(String id, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(id, enabled);
    _cache[id] = enabled;

    try {
      await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"featureId": id, "isEnabled": enabled}),
      );
    } catch (_) {}
  }

  Future<bool> canAccess(String featureId, String role) async {
    if (role == "admin") return true;
    return await isFeatureEnabled(featureId);
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
