import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Service để quản lý trạng thái tính năng
class FeatureService {
  static const String apiUrl = 'YOUR_BACKEND_URL/features';

  // Lưu trữ local
  static Future<void> saveFeatureStatus(
    String featureId,
    bool isEnabled,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(featureId, isEnabled);

    // Gửi lên backend
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

  // Lấy trạng thái tính năng
  static Future<bool> getFeatureStatus(String featureId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(featureId) ?? true; // Mặc định bật
  }

  // Kiểm tra quyền truy cập tính năng
  static Future<bool> canAccessFeature(String featureId, String role) async {
    // Admin luôn có quyền truy cập
    if (role == 'admin') return true;

    // Các role khác phải kiểm tra trạng thái
    return await getFeatureStatus(featureId);
  }
}

// Model cho tính năng
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

// Admin Home với quản lý tính năng
class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  // Danh sách tất cả tính năng của hệ thống
  List<Feature> allFeatures = [
    // Viewer Features
    Feature(
      id: 'viewer_view_traffic',
      title: 'View Traffic Density (Viewer)',
      description: 'Allow viewers to see real-time traffic density',
      allowedRoles: ['viewer', 'police', 'admin'],
    ),

    // Police Features
    Feature(
      id: 'police_view_traffic',
      title: 'View Traffic Density (Police)',
      description: 'Allow police to monitor real-time traffic',
      allowedRoles: ['police', 'admin'],
    ),
    Feature(
      id: 'police_modify_lights',
      title: 'Modify Light Counter (Police)',
      description: 'Allow police to adjust traffic light timers',
      allowedRoles: ['police', 'admin'],
    ),
    Feature(
      id: 'police_receive_notification',
      title: 'Receive Notification (Police)',
      description: 'Allow police to receive alerts from admin',
      allowedRoles: ['police', 'admin'],
    ),

    // Admin Features (luôn bật)
    Feature(
      id: 'admin_stream_camera',
      title: 'Stream Camera (Admin)',
      description: 'View live camera footage',
      allowedRoles: ['admin'],
      isEnabled: true,
    ),
    Feature(
      id: 'admin_monitor_traffic',
      title: 'Monitor Traffic Density (Admin)',
      description: 'Monitor congestion levels',
      allowedRoles: ['admin'],
      isEnabled: true,
    ),
    Feature(
      id: 'admin_send_notification',
      title: 'Send Notification (Admin)',
      description: 'Alert police when needed',
      allowedRoles: ['admin'],
      isEnabled: true,
    ),
    Feature(
      id: 'admin_display_lights',
      title: 'Display Light Counter (Admin)',
      description: 'View current traffic light timer',
      allowedRoles: ['admin'],
      isEnabled: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadFeatureStatuses();
  }

  // Load trạng thái tính năng từ local storage
  Future<void> _loadFeatureStatuses() async {
    for (var feature in allFeatures) {
      final status = await FeatureService.getFeatureStatus(feature.id);
      setState(() {
        feature.isEnabled = status;
      });
    }
  }

  // Toggle tính năng
  Future<void> _toggleFeature(Feature feature) async {
    // Admin features không thể tắt
    if (feature.allowedRoles.length == 1 &&
        feature.allowedRoles.contains('admin')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Admin features cannot be disabled'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final newStatus = !feature.isEnabled;
    await FeatureService.saveFeatureStatus(feature.id, newStatus);

    setState(() {
      feature.isEnabled = newStatus;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${feature.title} ${newStatus ? "enabled" : "disabled"}'),
        backgroundColor: newStatus ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Nhóm features theo role
    final viewerFeatures = allFeatures
        .where((f) => f.id.startsWith('viewer_'))
        .toList();
    final policeFeatures = allFeatures
        .where((f) => f.id.startsWith('police_'))
        .toList();
    final adminFeatures = allFeatures
        .where((f) => f.id.startsWith('admin_'))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Feature Management'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.admin_panel_settings,
                    size: 32,
                    color: Colors.blue.shade700,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'System Features Control',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Text(
                'Enable or disable features for different user roles',
                style: TextStyle(color: Colors.grey.shade600),
              ),

              SizedBox(height: 30),

              // Viewer Features
              if (viewerFeatures.isNotEmpty) ...[
                _buildSectionHeader(
                  'Viewer Features',
                  Icons.visibility,
                  Colors.green,
                ),
                ...viewerFeatures.map((feature) => _buildFeatureCard(feature)),
                SizedBox(height: 20),
              ],

              // Police Features
              if (policeFeatures.isNotEmpty) ...[
                _buildSectionHeader(
                  'Police Features',
                  Icons.local_police,
                  Colors.blue,
                ),
                ...policeFeatures.map((feature) => _buildFeatureCard(feature)),
                SizedBox(height: 20),
              ],

              // Admin Features
              if (adminFeatures.isNotEmpty) ...[
                _buildSectionHeader(
                  'Admin Features',
                  Icons.admin_panel_settings,
                  Colors.orange,
                ),
                ...adminFeatures.map((feature) => _buildFeatureCard(feature)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(Feature feature) {
    final isAdminFeature =
        feature.allowedRoles.length == 1 &&
        feature.allowedRoles.contains('admin');

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: feature.isEnabled
              ? Colors.green.shade200
              : Colors.red.shade200,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: feature.isEnabled
                ? Colors.green.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            feature.isEnabled ? Icons.check_circle : Icons.cancel,
            color: feature.isEnabled ? Colors.green : Colors.grey,
            size: 28,
          ),
        ),
        title: Text(
          feature.title,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text(
              feature.description,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            if (isAdminFeature) ...[
              SizedBox(height: 4),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Always Enabled',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        trailing: Switch(
          value: feature.isEnabled,
          onChanged: isAdminFeature ? null : (value) => _toggleFeature(feature),
          activeColor: Colors.green,
        ),
      ),
    );
  }
}

// Widget để kiểm tra quyền truy cập tính năng trước khi hiển thị
class FeatureGate extends StatelessWidget {
  final String featureId;
  final String userRole;
  final Widget child;
  final Widget? fallback;

  const FeatureGate({
    Key? key,
    required this.featureId,
    required this.userRole,
    required this.child,
    this.fallback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: FeatureService.canAccessFeature(featureId, userRole),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData && snapshot.data == true) {
          return child;
        }

        return fallback ??
            Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'This feature is currently disabled',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Please contact your administrator',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
      },
    );
  }
}
