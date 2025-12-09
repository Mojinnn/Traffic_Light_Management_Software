// // ============================================
// // 2. POLICE HOME với Feature Gate
// // ============================================
// import 'package:first_flutter/services/future_service.dart';
// import 'package:first_flutter/views/pages/police/police_view.dart';
// import 'package:first_flutter/views/pages/police/police_modify.dart';
// import 'package:flutter/material.dart';

// class PoliceHome extends StatefulWidget {
//   const PoliceHome({super.key});

//   @override
//   State<PoliceHome> createState() => _PoliceHomeState();
// }

// class _PoliceHomeState extends State<PoliceHome> {
//   final FeatureService _featureService = FeatureService();
//   Map<String, bool> featureStatuses = {};

//   @override
//   void initState() {
//     super.initState();
//     _loadFeatures();

//     // Lắng nghe thay đổi từ Admin
//     _featureService.startListening(() {
//       _loadFeatures();
//     });
//   }

//   Future<void> _loadFeatures() async {
//     final viewTraffic = await _featureService.isFeatureEnabled(
//       'police_view_traffic',
//     );
//     final modifyLights = await _featureService.isFeatureEnabled(
//       'police_modify_lights',
//     );

//     setState(() {
//       featureStatuses = {
//         'police_view_traffic': viewTraffic,
//         'police_modify_lights': modifyLights,
//       };
//     });
//   }

//   void _navigateToFeature(
//     String featureId,
//     Widget page,
//     String featureName,
//   ) async {
//     final isEnabled = await _featureService.isFeatureEnabled(featureId);

//     if (!isEnabled) {
//       _showFeatureDisabledDialog(featureName);
//       return;
//     }

//     Navigator.push(context, MaterialPageRoute(builder: (context) => page));
//   }

//   void _showFeatureDisabledDialog(String featureName) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Row(
//           children: [
//             Icon(Icons.lock, color: Colors.orange),
//             SizedBox(width: 10),
//             Text('Feature Disabled'),
//           ],
//         ),
//         content: Text(
//           'The "$featureName" feature has been disabled by the administrator.',
//           style: TextStyle(fontSize: 16),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text('OK'),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       child: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Police Functions',
//               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//             ),
//             SizedBox(height: 20),

//             // View Traffic Density
//             if (featureStatuses['police_view_traffic'] ?? true)
//               GestureDetector(
//                 onTap: () => _navigateToFeature(
//                   'police_view_traffic',
//                   PoliceView(),
//                   'View Traffic Density',
//                 ),
//                 child: _buildFeatureCard(
//                   'View Traffic Density',
//                   'See real-time traffic density',
//                   Icons.traffic,
//                   featureStatuses['police_view_traffic'] ?? true,
//                 ),
//               ),

//             SizedBox(height: 15),

//             // Modify Light Counter
//             if (featureStatuses['police_modify_lights'] ?? true)
//               GestureDetector(
//                 onTap: () => _navigateToFeature(
//                   'police_modify_lights',
//                   PoliceModify(),
//                   'Modify Light Counter',
//                 ),
//                 child: _buildFeatureCard(
//                   'Modify Light Counter',
//                   'Adjust traffic light timers',
//                   Icons.settings,
//                   featureStatuses['police_modify_lights'] ?? true,
//                 ),
//               ),

//             // Thông báo nếu không có tính năng nào
//             if ((featureStatuses['police_view_traffic'] == false) &&
//                 (featureStatuses['police_modify_lights'] == false))
//               Center(
//                 child: Padding(
//                   padding: EdgeInsets.all(40),
//                   child: Column(
//                     children: [
//                       Icon(Icons.lock, size: 64, color: Colors.grey),
//                       SizedBox(height: 16),
//                       Text(
//                         'All features are disabled',
//                         style: TextStyle(
//                           fontSize: 18,
//                           color: Colors.grey,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       SizedBox(height: 8),
//                       Text(
//                         'Contact your administrator',
//                         style: TextStyle(color: Colors.grey),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildFeatureCard(
//     String title,
//     String desc,
//     IconData icon,
//     bool isEnabled,
//   ) {
//     return Container(
//       padding: EdgeInsets.all(15),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(
//           color: isEnabled ? Colors.blue.shade200 : Colors.grey.shade300,
//           width: 2,
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 8,
//             offset: Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Container(
//             padding: EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: isEnabled ? Colors.blue.shade50 : Colors.grey.shade100,
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: Icon(
//               icon,
//               color: isEnabled ? Colors.blue : Colors.grey,
//               size: 28,
//             ),
//           ),
//           SizedBox(width: 15),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   title,
//                   style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                 ),
//                 SizedBox(height: 4),
//                 Text(
//                   desc,
//                   style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
//                 ),
//               ],
//             ),
//           ),
//           Icon(
//             isEnabled ? Icons.arrow_forward_ios : Icons.lock,
//             color: isEnabled ? Colors.grey : Colors.orange,
//             size: 20,
//           ),
//         ],
//       ),
//     );
//   }
// }

// ============================================
// 1. POLICE_HOME.DART - Menu + Đèn giao thông với countdown
// ============================================
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:first_flutter/services/future_service.dart';
import 'package:first_flutter/views/pages/police/police_view.dart';
import 'package:first_flutter/views/pages/police/police_modify.dart';
import 'package:flutter/material.dart';

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
  
  Timer? statusTimer;
  String currentMode = 'AUTO';
  final String getStatusUrl = 'YOUR_BACKEND_URL/traffic-lights/status';

  @override
  void initState() {
    super.initState();
    _loadFeatures();
    startStatusUpdate();
    
    _featureService.startListening(() {
      _loadFeatures();
    });
  }

  @override
  void dispose() {
    statusTimer?.cancel();
    super.dispose();
  }

  void startStatusUpdate() {
    statusTimer = Timer.periodic(Duration(seconds: 1), (timer) async {
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
          for (var i = 0; i < trafficLights.length; i++) {
            final lightData = data['lights'][i];
            trafficLights[i].state = _getStateFromString(lightData['state']);
            trafficLights[i].remainingTime = lightData['remainingTime'] ?? 0;
          }
        });
      }
    } catch (e) {
      _simulateAutoMode();
    }
  }

  TrafficLightState _getStateFromString(String state) {
    switch (state.toLowerCase()) {
      case 'red': return TrafficLightState.red;
      case 'yellow': return TrafficLightState.yellow;
      case 'green': return TrafficLightState.green;
      default: return TrafficLightState.red;
    }
  }

  void _simulateAutoMode() {
    final now = DateTime.now().second;
    final cycle = now % 30;
    
    setState(() {
      if (cycle < 10) {
        trafficLights[0].state = TrafficLightState.red;
        trafficLights[1].state = TrafficLightState.red;
        trafficLights[2].state = TrafficLightState.green;
        trafficLights[3].state = TrafficLightState.green;
        for (var i = 0; i < 4; i++) trafficLights[i].remainingTime = 10 - cycle;
      } else if (cycle < 13) {
        trafficLights[0].state = TrafficLightState.red;
        trafficLights[1].state = TrafficLightState.red;
        trafficLights[2].state = TrafficLightState.yellow;
        trafficLights[3].state = TrafficLightState.yellow;
        trafficLights[2].remainingTime = 13 - cycle;
        trafficLights[3].remainingTime = 13 - cycle;
      } else if (cycle < 23) {
        trafficLights[0].state = TrafficLightState.green;
        trafficLights[1].state = TrafficLightState.green;
        trafficLights[2].state = TrafficLightState.red;
        trafficLights[3].state = TrafficLightState.red;
        for (var i = 0; i < 4; i++) trafficLights[i].remainingTime = 23 - cycle;
      } else {
        trafficLights[0].state = TrafficLightState.yellow;
        trafficLights[1].state = TrafficLightState.yellow;
        trafficLights[2].state = TrafficLightState.red;
        trafficLights[3].state = TrafficLightState.red;
        trafficLights[0].remainingTime = 30 - cycle;
        trafficLights[1].remainingTime = 30 - cycle;
      }
    });
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
        title: Row(
          children: [
            Icon(Icons.lock, color: Colors.orange),
            SizedBox(width: 10),
            Text('Feature Disabled'),
          ],
        ),
        content: Text(
          'The "$featureName" feature has been disabled by the administrator.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Police Dashboard'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quick Actions Section
              Text(
                'Quick Actions',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 15),
              
              Row(
                children: [
                  // View Traffic Button
                  if (featureStatuses['police_view_traffic'] ?? true)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _navigateToFeature(
                          'police_view_traffic',
                          PoliceView(),
                          'View Traffic Stream',
                        ),
                        child: Container(
                          padding: EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade200, width: 2),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.videocam, color: Colors.blue, size: 32),
                              SizedBox(height: 8),
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
                  
                  SizedBox(width: 10),
                  
                  // Modify Settings Button
                  if (featureStatuses['police_modify_lights'] ?? true)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _navigateToFeature(
                          'police_modify_lights',
                          PoliceModify(),
                          'Modify Settings',
                        ),
                        child: Container(
                          padding: EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange.shade200, width: 2),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.settings, color: Colors.orange, size: 32),
                              SizedBox(height: 8),
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
              
              SizedBox(height: 25),
              
              // Current Mode Display
              Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: _getModeColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _getModeColor(), width: 2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_getModeIcon(), color: _getModeColor(), size: 24),
                    SizedBox(width: 10),
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
              
              SizedBox(height: 20),
              
              Text(
                'Traffic Lights Status',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 15),
              
              // Traffic Lights Display
              SizedBox(
                child: Center(
                  child: SizedBox(
                    width: 150,
                    child: _buildTrafficLight(trafficLights[0]),
                  ),
                ),
              ),
              
              SizedBox(height: 10),
              
              SizedBox(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildTrafficLight(trafficLights[3])),
                    SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        margin: EdgeInsets.symmetric(vertical: 10),
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
                    SizedBox(width: 10),
                    Expanded(child: _buildTrafficLight(trafficLights[2])),
                  ],
                ),
              ),
              
              SizedBox(height: 10),
              
              SizedBox(
                child: Center(
                  child: SizedBox(
                    width: 150,
                    child: _buildTrafficLight(trafficLights[1]),
                  ),
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
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(light.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Container(
            width: 60,
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 15),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLight(Colors.red, light.state == TrafficLightState.red),
                SizedBox(height: 6),
                _buildLight(Colors.yellow.shade700, light.state == TrafficLightState.yellow),
                SizedBox(height: 6),
                _buildLight(Colors.green, light.state == TrafficLightState.green),
              ],
            ),
          ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
      case TrafficLightState.red: return Colors.red;
      case TrafficLightState.yellow: return Colors.orange;
      case TrafficLightState.green: return Colors.green;
    }
  }

  Color _getModeColor() {
    switch (currentMode) {
      case 'AUTO': return Colors.green;
      case 'MANUAL': return Colors.blue;
      case 'EMERGENCY': return Colors.red;
      case 'AI-BASED': return Colors.purple;
      default: return Colors.grey;
    }
  }

  IconData _getModeIcon() {
    switch (currentMode) {
      case 'AUTO': return Icons.autorenew;
      case 'MANUAL': return Icons.pan_tool;
      case 'EMERGENCY': return Icons.emergency;
      case 'AI-BASED': return Icons.psychology;
      default: return Icons.help;
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

