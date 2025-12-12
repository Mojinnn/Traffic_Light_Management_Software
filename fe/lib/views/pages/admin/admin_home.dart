import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// ==========================
// BACKEND CONFIG
// ==========================
const String backendUrl = "http://localhost:8000/api/features";

// ==========================
// Feature Service — DÙNG BACKEND
// ==========================
class FeatureService {
  // Lấy danh sách feature từ backend
  static Future<Map<String, bool>> loadAllFeatures() async {
    final res = await http.get(Uri.parse(backendUrl));

    if (res.statusCode != 200) {
      throw Exception("Failed to load features");
    }

    final data = jsonDecode(res.body);

    Map<String, bool> result = {};
    for (var f in data["features"]) {
      result[f["featureId"]] = f["isEnabled"];
    }

    return result;
  }

  // Cập nhật feature (ADMIN)
  static Future<void> updateFeature(String id, bool enabled) async {
    await http.post(
      Uri.parse(backendUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "featureId": id,
        "isEnabled": enabled,
      }),
    );
  }
}

// ==========================
// Feature Model
// ==========================
class Feature {
  final String id;
  final String title;
  final String description;
  final List<String> allowedRoles;
  bool isEnabled;

  Feature({
    required this.id,
    required this.title,
    required this.description,
    required this.allowedRoles,
    this.isEnabled = true,
  });
}

// ==========================
// ADMIN HOME UI
// ==========================
class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  // ====================================
  // Danh sách Feature trong hệ thống
  // ====================================
  List<Feature> allFeatures = [
    // Viewer
    Feature(
      id: 'viewer_view_traffic',
      title: 'Viewer: View Traffic Density',
      description: 'Allow viewers to see real-time traffic',
      allowedRoles: ['viewer', 'police', 'admin'],
    ),

    // Police
    Feature(
      id: 'police_view_traffic',
      title: 'Police: View Traffic Density',
      description: 'Allow police to see traffic density',
      allowedRoles: ['police', 'admin'],
    ),
    Feature(
      id: 'police_modify_lights',
      title: 'Police: Modify Lights',
      description: 'Allow police to adjust traffic lights',
      allowedRoles: ['police', 'admin'],
    ),
    Feature(
      id: 'police_receive_notification',
      title: 'Police: Receive Notifications',
      description: 'Allow police to get alerts',
      allowedRoles: ['police', 'admin'],
    ),

    // Admin only
    Feature(
      id: 'admin_stream_camera',
      title: 'Admin: Stream Camera',
      description: 'View camera live stream',
      allowedRoles: ['admin'],
    ),
    Feature(
      id: 'admin_monitor_traffic',
      title: 'Admin: Monitor Traffic',
      description: 'Monitor congestion levels',
      allowedRoles: ['admin'],
    ),
    Feature(
      id: 'admin_send_notification',
      title: 'Admin: Send Notification',
      description: 'Send alerts to police',
      allowedRoles: ['admin'],
    ),
    Feature(
      id: 'admin_display_lights',
      title: 'Admin: Display Light Counter',
      description: 'View traffic light timers',
      allowedRoles: ['admin'],
    ),
  ];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBackend();
  }

  // ==========================
  // Load trạng thái từ backend
  // ==========================
  Future<void> _loadBackend() async {
    try {
      final backendData = await FeatureService.loadAllFeatures();

      setState(() {
        for (var f in allFeatures) {
          if (backendData.containsKey(f.id)) {
            f.isEnabled = backendData[f.id]!;
          }
        }
        isLoading = false;
      });
    } catch (e) {
      print("ERROR loading backend: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  // ==========================
  // Toggle tính năng
  // ==========================
  Future<void> _toggleFeature(Feature f) async {
    // Admin-only feature (không được tắt)
    if (f.allowedRoles.length == 1 && f.allowedRoles.contains("admin")) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Admin features cannot be disabled"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => f.isEnabled = !f.isEnabled);

    await FeatureService.updateFeature(f.id, f.isEnabled);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${f.title} updated"),
        backgroundColor: f.isEnabled ? Colors.green : Colors.red,
      ),
    );
  }

  // ==========================
  // UI
  // ==========================
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text("Feature Management")),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final viewerFeatures =
        allFeatures.where((f) => f.id.startsWith("viewer_")).toList();

    final policeFeatures =
        allFeatures.where((f) => f.id.startsWith("police_")).toList();

    final adminFeatures =
        allFeatures.where((f) => f.id.startsWith("admin_")).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Feature Management'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: _buildBody(viewerFeatures, policeFeatures, adminFeatures),
    );
  }

  // UI body
  Widget _buildBody(viewer, police, admin) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(),

          SizedBox(height: 30),

          _section("Viewer Features", Icons.visibility, Colors.green, viewer),
          SizedBox(height: 20),

          _section("Police Features", Icons.local_police, Colors.blue, police),
          SizedBox(height: 20),

          _section("Admin Features", Icons.admin_panel_settings, Colors.orange,
              admin),
        ],
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        Icon(Icons.admin_panel_settings,
            size: 32, color: Colors.blue.shade700),
        SizedBox(width: 10),
        Text(
          'System Features Control',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _section(
      String title, IconData icon, Color color, List<Feature> features) {
    if (features.isEmpty) return Container();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color),
            SizedBox(width: 8),
            Text(title,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color)),
          ],
        ),
        SizedBox(height: 10),
        ...features.map((f) => _featureCard(f)),
      ],
    );
  }

  Widget _featureCard(Feature f) {
    final isAdminFeature =
        f.allowedRoles.length == 1 && f.allowedRoles.contains("admin");

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: f.isEnabled ? Colors.green.shade200 : Colors.red.shade200,
          width: 2,
        ),
      ),
      child: ListTile(
        leading: Icon(
          f.isEnabled ? Icons.check_circle : Icons.cancel,
          color: f.isEnabled ? Colors.green : Colors.red,
          size: 32,
        ),
        title: Text(f.title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(f.description, style: TextStyle(fontSize: 12)),
        trailing: Switch(
          value: f.isEnabled,
          onChanged: isAdminFeature ? null : (_) => _toggleFeature(f),
        ),
      ),
    );
  }
}
