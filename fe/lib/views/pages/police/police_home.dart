import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:first_flutter/data/auth_service.dart';
import 'package:first_flutter/services/future_service.dart';
import 'package:first_flutter/views/pages/police/police_view.dart';
import 'package:first_flutter/views/pages/police/police_modify.dart';

class PoliceHome extends StatefulWidget {
  const PoliceHome({super.key});

  @override
  State<PoliceHome> createState() => _PoliceHomeState();
}

class _PoliceHomeState extends State<PoliceHome> {
  final FeatureService _featureService = FeatureService();

  Map<String, bool> featureStatuses = {};

  // Traffic light status
  List<TrafficLight> trafficLights = [
    TrafficLight(id: 1, name: 'North', state: TrafficLightState.red),
    TrafficLight(id: 2, name: 'South', state: TrafficLightState.red),
    TrafficLight(id: 3, name: 'East', state: TrafficLightState.green),
    TrafficLight(id: 4, name: 'West', state: TrafficLightState.green),
  ];

  // Timer config (fallback default)
  Map<String, Map<String, int>> timerConfig = {
    'North': {'red': 30, 'green': 27},
    'South': {'red': 30, 'green': 27},
    'East': {'red': 30, 'green': 27},
    'West': {'red': 30, 'green': 27},
  };

  Timer? statusTimer;
  String currentMode = 'AUTO';

  final String getStatusUrl = "${AuthService.baseUrl}/traffic-lights/status";

  @override
  void initState() {
    super.initState();
    _loadFeatures();
    _featureService.startListening(() {
      _loadFeatures();
    });
    startStatusUpdate();
  }

  @override
  void dispose() {
    statusTimer?.cancel();
    super.dispose();
  }

  void startStatusUpdate() {
    statusTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      await fetchTrafficLightStatus();
    });
  }

  Future<void> fetchTrafficLightStatus() async {
    try {
      final response = await http.get(Uri.parse(getStatusUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          currentMode = data['mode'] ?? 'AUTO';

          // Load timerConfig from backend (dict)
          if (data['timerConfig'] != null) {
            final config = Map<String, dynamic>.from(data['timerConfig']);
            for (final direction in ['North', 'South', 'East', 'West']) {
              final phases = config[direction];
              if (phases != null) {
                timerConfig[direction] = {
                  'red': (phases['red'] ?? timerConfig[direction]!['red'] ?? 30) as int,
                  'green': (phases['green'] ?? timerConfig[direction]!['green'] ?? 27) as int,
                };
              }
            }
          }

          // Update traffic lights status
          if (data['lights'] != null) {
            final lights = List<dynamic>.from(data['lights']);
            for (var i = 0; i < trafficLights.length && i < lights.length; i++) {
              final lightData = Map<String, dynamic>.from(lights[i]);
              trafficLights[i].state = _getStateFromString(lightData['state'] ?? 'red');
              trafficLights[i].remainingTime = (lightData['remainingTime'] ?? 0) as int;
            }
          }
        });
      } else {
        // Nếu lỗi, không simulate nữa (vì backend mới chạy countdown chuẩn)
        // chỉ log
        // ignore: avoid_print
        print("Status error: ${response.statusCode}");
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching status: $e');
    }
  }

  TrafficLightState _getStateFromString(String state) {
    switch (state.toLowerCase()) {
      case 'red':
        return TrafficLightState.red;
      case 'yellow':
        return TrafficLightState.yellow;
      case 'green':
        return TrafficLightState.green;
      default:
        return TrafficLightState.red;
    }
  }

  Future<void> _loadFeatures() async {
    final viewTraffic = await _featureService.isFeatureEnabled('police_view_traffic');
    final modifyLights = await _featureService.isFeatureEnabled('police_modify_lights');
    setState(() {
      featureStatuses = {
        'police_view_traffic': viewTraffic,
        'police_modify_lights': modifyLights,
      };
    });
  }

  void _navigateToFeature(String featureId, Widget page, String featureName) async {
    final isEnabled = await _featureService.isFeatureEnabled(featureId);
    if (!isEnabled) {
      _showFeatureDisabledDialog(featureName);
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  void _showFeatureDisabledDialog(String featureName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock, color: Colors.orange),
            SizedBox(width: 10),
            Text('Feature Disabled'),
          ],
        ),
        content: Text(
          'The "$featureName" feature has been disabled by the administrator.',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Police Dashboard'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Quick Actions',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),

              Row(
                children: [
                  if (featureStatuses['police_view_traffic'] ?? true)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _navigateToFeature(
                          'police_view_traffic',
                          const PoliceView(),
                          'View Traffic Stream',
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade200, width: 2),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.videocam, color: Colors.blue, size: 32),
                              const SizedBox(height: 8),
                              Text(
                                'View Stream',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(width: 10),
                  if (featureStatuses['police_modify_lights'] ?? true)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _navigateToFeature(
                          'police_modify_lights',
                          const PoliceModify(),
                          'Modify Settings',
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange.shade200, width: 2),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.settings, color: Colors.orange, size: 32),
                              const SizedBox(height: 8),
                              Text(
                                'Modify Settings',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 25),

              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: _getModeColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _getModeColor(), width: 2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_getModeIcon(), color: _getModeColor(), size: 24),
                    const SizedBox(width: 10),
                    Text(
                      'Current Mode: $currentMode',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _getModeColor(),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              const Text(
                'Traffic Lights Status',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),

              SizedBox(
                child: Center(
                  child: SizedBox(width: 150, child: _buildTrafficLight(trafficLights[0])),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildTrafficLight(trafficLights[3])),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Icon(Icons.add_road, size: 50, color: Colors.grey.shade600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: _buildTrafficLight(trafficLights[2])),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                child: Center(
                  child: SizedBox(width: 150, child: _buildTrafficLight(trafficLights[1])),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrafficLight(TrafficLight light) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(light.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            width: 60,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLight(Colors.red, light.state == TrafficLightState.red),
                const SizedBox(height: 6),
                _buildLight(Colors.yellow.shade700, light.state == TrafficLightState.yellow),
                const SizedBox(height: 6),
                _buildLight(Colors.green, light.state == TrafficLightState.green),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _getStateColor(light.state).withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              '${light.remainingTime}s',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _getStateColor(light.state),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLight(Color color, bool isActive) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? color : color.withOpacity(0.3),
        boxShadow: isActive
            ? [BoxShadow(color: color.withOpacity(0.6), blurRadius: 10, spreadRadius: 2)]
            : null,
      ),
    );
  }

  Color _getStateColor(TrafficLightState state) {
    switch (state) {
      case TrafficLightState.red:
        return Colors.red;
      case TrafficLightState.yellow:
        return Colors.orange;
      case TrafficLightState.green:
        return Colors.green;
    }
  }

  Color _getModeColor() {
    switch (currentMode) {
      case 'AUTO':
        return Colors.green;
      case 'MANUAL':
        return Colors.blue;
      case 'EMERGENCY':
        return Colors.red;
      case 'AI-BASED':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getModeIcon() {
    switch (currentMode) {
      case 'AUTO':
        return Icons.autorenew;
      case 'MANUAL':
        return Icons.pan_tool;
      case 'EMERGENCY':
        return Icons.emergency;
      case 'AI-BASED':
        return Icons.psychology;
      default:
        return Icons.help;
    }
  }
}

enum TrafficLightState { red, yellow, green }

class TrafficLight {
  final int id;
  final String name;
  TrafficLightState state;
  int remainingTime;

  TrafficLight({
    required this.id,
    required this.name,
    required this.state,
    this.remainingTime = 0,
  });
}
