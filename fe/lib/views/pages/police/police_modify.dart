// // import 'dart:async';
// // import 'dart:convert';
// // import 'package:flutter/material.dart';
// // import 'package:http/http.dart' as http;

// // class PoliceModify extends StatefulWidget {
// //   const PoliceModify({super.key});

// //   @override
// //   State<PoliceModify> createState() => _PoliceModifyState();
// // }

// // class _PoliceModifyState extends State<PoliceModify> {
// //   // API endpoints
// //   final String getStatusUrl = 'YOUR_BACKEND_URL/traffic-lights/status';
// //   final String controlUrl = 'YOUR_BACKEND_URL/traffic-lights/control';

// //   // Timer để cập nhật trạng thái
// //   Timer? statusTimer;
// //   bool isAutoMode = true;

// //   // Trạng thái 4 đèn giao thông
// //   List<TrafficLight> trafficLights = [
// //     TrafficLight(
// //       id: 1,
// //       name: 'North Light',
// //       direction: 'North',
// //       state: TrafficLightState.red,
// //     ),
// //     TrafficLight(
// //       id: 2,
// //       name: 'South Light',
// //       direction: 'South',
// //       state: TrafficLightState.red,
// //     ),
// //     TrafficLight(
// //       id: 3,
// //       name: 'East Light',
// //       direction: 'East',
// //       state: TrafficLightState.green,
// //     ),
// //     TrafficLight(
// //       id: 4,
// //       name: 'West Light',
// //       direction: 'West',
// //       state: TrafficLightState.green,
// //     ),
// //   ];

// //   @override
// //   void initState() {
// //     super.initState();
// //     startStatusUpdate();
// //   }

// //   @override
// //   void dispose() {
// //     statusTimer?.cancel();
// //     super.dispose();
// //   }

// //   // Bắt đầu cập nhật trạng thái
// //   void startStatusUpdate() {
// //     statusTimer = Timer.periodic(Duration(seconds: 1), (timer) async {
// //       await fetchTrafficLightStatus();
// //     });
// //   }

// //   // Lấy trạng thái đèn từ backend
// //   Future<void> fetchTrafficLightStatus() async {
// //     try {
// //       final response = await http.get(Uri.parse(getStatusUrl));

// //       if (response.statusCode == 200) {
// //         final data = jsonDecode(response.body);
// //         setState(() {
// //           isAutoMode = data['autoMode'] ?? true;

// //           for (var i = 0; i < trafficLights.length; i++) {
// //             final lightData = data['lights'][i];
// //             trafficLights[i].state = _getStateFromString(lightData['state']);
// //             trafficLights[i].remainingTime = lightData['remainingTime'] ?? 0;
// //           }
// //         });
// //       }
// //     } catch (e) {
// //       print('Error fetching status: $e');
// //       // Giả lập dữ liệu để test (xóa khi có backend)
// //       if (isAutoMode) {
// //         _simulateAutoMode();
// //       }
// //     }
// //   }

// //   // Chuyển đổi string thành enum
// //   TrafficLightState _getStateFromString(String state) {
// //     switch (state.toLowerCase()) {
// //       case 'red':
// //         return TrafficLightState.red;
// //       case 'yellow':
// //         return TrafficLightState.yellow;
// //       case 'green':
// //         return TrafficLightState.green;
// //       default:
// //         return TrafficLightState.red;
// //     }
// //   }

// //   // Giả lập chế độ tự động (xóa khi có backend)
// //   void _simulateAutoMode() {
// //     final now = DateTime.now().second;
// //     final cycle = now % 30;

// //     setState(() {
// //       if (cycle < 10) {
// //         // Bắc-Nam đỏ, Đông-Tây xanh
// //         trafficLights[0].state = TrafficLightState.red;
// //         trafficLights[1].state = TrafficLightState.red;
// //         trafficLights[2].state = TrafficLightState.green;
// //         trafficLights[3].state = TrafficLightState.green;
// //         trafficLights[0].remainingTime = 10 - cycle;
// //         trafficLights[1].remainingTime = 10 - cycle;
// //         trafficLights[2].remainingTime = 10 - cycle;
// //         trafficLights[3].remainingTime = 10 - cycle;
// //       } else if (cycle < 13) {
// //         // Đông-Tây vàng
// //         trafficLights[0].state = TrafficLightState.red;
// //         trafficLights[1].state = TrafficLightState.red;
// //         trafficLights[2].state = TrafficLightState.yellow;
// //         trafficLights[3].state = TrafficLightState.yellow;
// //         trafficLights[2].remainingTime = 13 - cycle;
// //         trafficLights[3].remainingTime = 13 - cycle;
// //       } else if (cycle < 23) {
// //         // Bắc-Nam xanh, Đông-Tây đỏ
// //         trafficLights[0].state = TrafficLightState.green;
// //         trafficLights[1].state = TrafficLightState.green;
// //         trafficLights[2].state = TrafficLightState.red;
// //         trafficLights[3].state = TrafficLightState.red;
// //         trafficLights[0].remainingTime = 23 - cycle;
// //         trafficLights[1].remainingTime = 23 - cycle;
// //         trafficLights[2].remainingTime = 23 - cycle;
// //         trafficLights[3].remainingTime = 23 - cycle;
// //       } else {
// //         // Bắc-Nam vàng
// //         trafficLights[0].state = TrafficLightState.yellow;
// //         trafficLights[1].state = TrafficLightState.yellow;
// //         trafficLights[2].state = TrafficLightState.red;
// //         trafficLights[3].state = TrafficLightState.red;
// //         trafficLights[0].remainingTime = 30 - cycle;
// //         trafficLights[1].remainingTime = 30 - cycle;
// //       }
// //     });
// //   }

// //   // Gửi lệnh điều khiển đến backend
// //   Future<void> sendControlCommand(
// //     String command, {
// //     int? lightId,
// //     String? state,
// //   }) async {
// //     try {
// //       final response = await http.post(
// //         Uri.parse(controlUrl),
// //         headers: {'Content-Type': 'application/json'},
// //         body: jsonEncode({
// //           'command': command,
// //           'lightId': lightId,
// //           'state': state,
// //         }),
// //       );

// //       if (response.statusCode == 200) {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(
// //             content: Text('Lệnh đã được gửi thành công!'),
// //             backgroundColor: Colors.green,
// //             duration: Duration(seconds: 1),
// //           ),
// //         );
// //         await fetchTrafficLightStatus();
// //       }
// //     } catch (e) {
// //       print('Error sending command: $e');
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(
// //           content: Text('Lỗi khi gửi lệnh: $e'),
// //           backgroundColor: Colors.red,
// //         ),
// //       );
// //     }
// //   }

// //   // Chuyển sang chế độ tự động
// //   void setAutoMode() async {
// //     setState(() {
// //       isAutoMode = true;
// //     });
// //     await sendControlCommand('auto');
// //   }

// //   // Chuyển sang chế độ thủ công
// //   void setManualMode() {
// //     setState(() {
// //       isAutoMode = false;
// //     });
// //     sendControlCommand('manual');
// //   }

// //   // Điều khiển một đèn cụ thể
// //   void controlSingleLight(int lightId, TrafficLightState state) {
// //     if (!isAutoMode) {
// //       sendControlCommand(
// //         'set',
// //         lightId: lightId,
// //         state: state.toString().split('.').last,
// //       );
// //     }
// //   }

// //   // Tắt hết đèn (Emergency)
// //   void emergencyStop() {
// //     setState(() {
// //       isAutoMode = false;
// //       for (var light in trafficLights) {
// //         light.state = TrafficLightState.red;
// //       }
// //     });
// //     sendControlCommand('emergency');
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: Text('Traffic Controller'),
// //         backgroundColor: Colors.blue.shade700,
// //       ),
// //       body: SingleChildScrollView(
// //         child: Column(
// //           children: [
// //             // Control Panel
// //             Container(
// //               padding: EdgeInsets.all(15),
// //               color: Colors.grey.shade100,
// //               child: Column(
// //                 children: [
// //                   Row(
// //                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
// //                     children: [
// //                       Expanded(
// //                         child: ElevatedButton.icon(
// //                           onPressed: setAutoMode,
// //                           icon: Icon(Icons.autorenew, size: 18),
// //                           label: Text('Auto'),
// //                           style: ElevatedButton.styleFrom(
// //                             backgroundColor: isAutoMode
// //                                 ? Colors.green
// //                                 : Colors.grey,
// //                             foregroundColor: Colors.white,
// //                             padding: EdgeInsets.symmetric(vertical: 12),
// //                           ),
// //                         ),
// //                       ),
// //                       SizedBox(width: 10),
// //                       Expanded(
// //                         child: ElevatedButton.icon(
// //                           onPressed: setManualMode,
// //                           icon: Icon(Icons.pan_tool, size: 18),
// //                           label: Text('Manual'),
// //                           style: ElevatedButton.styleFrom(
// //                             backgroundColor: !isAutoMode
// //                                 ? Colors.blue
// //                                 : Colors.grey,
// //                             foregroundColor: Colors.white,
// //                             padding: EdgeInsets.symmetric(vertical: 12),
// //                           ),
// //                         ),
// //                       ),
// //                       SizedBox(width: 10),
// //                       Expanded(
// //                         child: ElevatedButton.icon(
// //                           onPressed: emergencyStop,
// //                           icon: Icon(Icons.emergency, size: 18),
// //                           label: Text('Emergency'),
// //                           style: ElevatedButton.styleFrom(
// //                             backgroundColor: Colors.red,
// //                             foregroundColor: Colors.white,
// //                             padding: EdgeInsets.symmetric(vertical: 12),
// //                           ),
// //                         ),
// //                       ),
// //                     ],
// //                   ),
// //                   SizedBox(height: 10),
// //                   Container(
// //                     padding: EdgeInsets.all(10),
// //                     decoration: BoxDecoration(
// //                       color: isAutoMode
// //                           ? Colors.green.shade50
// //                           : Colors.blue.shade50,
// //                       borderRadius: BorderRadius.circular(8),
// //                       border: Border.all(
// //                         color: isAutoMode ? Colors.green : Colors.blue,
// //                         width: 2,
// //                       ),
// //                     ),
// //                     child: Row(
// //                       mainAxisAlignment: MainAxisAlignment.center,
// //                       children: [
// //                         Icon(
// //                           isAutoMode ? Icons.autorenew : Icons.pan_tool,
// //                           color: isAutoMode ? Colors.green : Colors.blue,
// //                         ),
// //                         SizedBox(width: 8),
// //                         Text(
// //                           'Mode: ${isAutoMode ? "AUTO" : "MANUAL"}',
// //                           style: TextStyle(
// //                             fontSize: 16,
// //                             fontWeight: FontWeight.bold,
// //                             color: isAutoMode
// //                                 ? Colors.green.shade700
// //                                 : Colors.blue.shade700,
// //                           ),
// //                         ),
// //                       ],
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             ),

// //             // Traffic Lights Display
// //             Container(
// //               padding: EdgeInsets.all(15),
// //               child: Column(
// //                 children: [
// //                   // Hàng 1: Đèn Bắc
// //                   SizedBox(
// //                     // height: 180,
// //                     child: Center(
// //                       child: SizedBox(
// //                         width: 150,
// //                         child: TrafficLightWidget(
// //                           light: trafficLights[0],
// //                           onControl: isAutoMode
// //                               ? null
// //                               : (state) => controlSingleLight(1, state),
// //                         ),
// //                       ),
// //                     ),
// //                   ),

// //                   SizedBox(height: 10),

// //                   // Hàng 2: Đèn Tây - Ngã tư - Đèn Đông
// //                   SizedBox(
// //                     // height: 180,
// //                     child: Row(
// //                       // crossAxisAlignment: CrossAxisAlignment.center,
// //                       crossAxisAlignment: CrossAxisAlignment.start,
// //                       children: [
// //                         Expanded(
// //                           child: TrafficLightWidget(
// //                             light: trafficLights[3],
// //                             onControl: isAutoMode
// //                                 ? null
// //                                 : (state) => controlSingleLight(4, state),
// //                           ),
// //                         ),
// //                         SizedBox(width: 10),
// //                         Expanded(
// //                           child: Container(
// //                             margin: EdgeInsets.symmetric(vertical: 10),
// //                             decoration: BoxDecoration(
// //                               color: Colors.grey.shade300,
// //                               borderRadius: BorderRadius.circular(10),
// //                             ),
// //                             child: Center(
// //                               child: Icon(
// //                                 Icons.add_road,
// //                                 size: 50,
// //                                 color: Colors.grey.shade600,
// //                               ),
// //                             ),
// //                           ),
// //                         ),
// //                         SizedBox(width: 10),
// //                         Expanded(
// //                           child: TrafficLightWidget(
// //                             light: trafficLights[2],
// //                             onControl: isAutoMode
// //                                 ? null
// //                                 : (state) => controlSingleLight(3, state),
// //                           ),
// //                         ),
// //                       ],
// //                     ),
// //                   ),

// //                   SizedBox(height: 10),

// //                   // Hàng 3: Đèn Nam
// //                   SizedBox(
// //                     // height: 180,
// //                     child: Center(
// //                       child: SizedBox(
// //                         width: 150,
// //                         child: TrafficLightWidget(
// //                           light: trafficLights[1],
// //                           onControl: isAutoMode
// //                               ? null
// //                               : (state) => controlSingleLight(2, state),
// //                         ),
// //                       ),
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }

// // // Widget hiển thị một đèn giao thông
// // class TrafficLightWidget extends StatelessWidget {
// //   final TrafficLight light;
// //   final Function(TrafficLightState)? onControl;

// //   const TrafficLightWidget({Key? key, required this.light, this.onControl})
// //     : super(key: key);

// //   @override
// //   Widget build(BuildContext context) {
// //     return Container(
// //       padding: EdgeInsets.all(10),
// //       decoration: BoxDecoration(
// //         color: Colors.white,
// //         borderRadius: BorderRadius.circular(15),
// //         boxShadow: [
// //           BoxShadow(
// //             color: Colors.black.withOpacity(0.1),
// //             blurRadius: 8,
// //             offset: Offset(0, 3),
// //           ),
// //         ],
// //       ),
// //       child: Column(
// //         mainAxisSize: MainAxisSize.min,
// //         children: [
// //           // Tên đèn
// //           Text(
// //             light.name,
// //             style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
// //           ),
// //           SizedBox(height: 8),

// //           // Container đèn
// //           Container(
// //             width: 60,
// //             padding: EdgeInsets.symmetric(vertical: 8, horizontal: 15),
// //             decoration: BoxDecoration(
// //               color: Colors.grey.shade900,
// //               borderRadius: BorderRadius.circular(12),
// //             ),
// //             child: Column(
// //               mainAxisSize: MainAxisSize.min,
// //               children: [
// //                 // Đèn đỏ
// //                 _buildLight(Colors.red, light.state == TrafficLightState.red),
// //                 SizedBox(height: 6),
// //                 // Đèn vàng
// //                 _buildLight(
// //                   Colors.yellow.shade700,
// //                   light.state == TrafficLightState.yellow,
// //                 ),
// //                 SizedBox(height: 6),
// //                 // Đèn xanh
// //                 _buildLight(
// //                   Colors.green,
// //                   light.state == TrafficLightState.green,
// //                 ),
// //               ],
// //             ),
// //           ),

// //           // Thời gian còn lại
// //           SizedBox(height: 8),
// //           Container(
// //             padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
// //             decoration: BoxDecoration(
// //               color: _getStateColor().withOpacity(0.2),
// //               borderRadius: BorderRadius.circular(15),
// //             ),
// //             child: Text(
// //               '${light.remainingTime}s',
// //               style: TextStyle(
// //                 fontSize: 16,
// //                 fontWeight: FontWeight.bold,
// //                 color: _getStateColor(),
// //               ),
// //             ),
// //           ),

// //           // Nút điều khiển (chỉ hiện trong chế độ thủ công)
// //           if (onControl != null) ...[
// //             SizedBox(height: 8),
// //             Row(
// //               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
// //               children: [
// //                 _buildControlButton(
// //                   context,
// //                   Colors.red,
// //                   Icons.stop,
// //                   () => onControl!(TrafficLightState.red),
// //                 ),
// //                 _buildControlButton(
// //                   context,
// //                   Colors.yellow.shade700,
// //                   Icons.warning,
// //                   () => onControl!(TrafficLightState.yellow),
// //                 ),
// //                 _buildControlButton(
// //                   context,
// //                   Colors.green,
// //                   Icons.play_arrow,
// //                   () => onControl!(TrafficLightState.green),
// //                 ),
// //               ],
// //             ),
// //           ],
// //         ],
// //       ),
// //     );
// //   }

// //   Widget _buildLight(Color color, bool isActive) {
// //     return Container(
// //       width: 30,
// //       height: 30,
// //       decoration: BoxDecoration(
// //         shape: BoxShape.circle,
// //         color: isActive ? color : color.withOpacity(0.3),
// //         boxShadow: isActive
// //             ? [
// //                 BoxShadow(
// //                   color: color.withOpacity(0.6),
// //                   blurRadius: 10,
// //                   spreadRadius: 2,
// //                 ),
// //               ]
// //             : null,
// //       ),
// //     );
// //   }

// //   Widget _buildControlButton(
// //     BuildContext context,
// //     Color color,
// //     IconData icon,
// //     VoidCallback onPressed,
// //   ) {
// //     return InkWell(
// //       onTap: onPressed,
// //       borderRadius: BorderRadius.circular(6),
// //       child: Container(
// //         padding: EdgeInsets.all(6),
// //         decoration: BoxDecoration(
// //           color: color.withOpacity(0.2),
// //           borderRadius: BorderRadius.circular(6),
// //           border: Border.all(color: color, width: 1.5),
// //         ),
// //         child: Icon(icon, color: color, size: 16),
// //       ),
// //     );
// //   }

// //   Color _getStateColor() {
// //     switch (light.state) {
// //       case TrafficLightState.red:
// //         return Colors.red;
// //       case TrafficLightState.yellow:
// //         return Colors.orange;
// //       case TrafficLightState.green:
// //         return Colors.green;
// //     }
// //   }
// // }

// // // Enum cho trạng thái đèn
// // enum TrafficLightState { red, yellow, green }

// // // Model cho đèn giao thông
// // class TrafficLight {
// //   final int id;
// //   final String name;
// //   final String direction;
// //   TrafficLightState state;
// //   int remainingTime;

// //   TrafficLight({
// //     required this.id,
// //     required this.name,
// //     required this.direction,
// //     required this.state,
// //     this.remainingTime = 0,
// //   });
// // }

// ============================================
// 3. POLICE_MODIFY.DART - Chỉnh mode + timer + xác nhận
// ============================================
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PoliceModify extends StatefulWidget {
  const PoliceModify({super.key});

  @override
  State<PoliceModify> createState() => _PoliceModifyState();
}

class _PoliceModifyState extends State<PoliceModify> {
  final String controlUrl = 'YOUR_BACKEND_URL/traffic-lights/control';
  final String getConfigUrl = 'YOUR_BACKEND_URL/traffic-lights/config';

  String selectedMode = 'AUTO';

  Map<String, int> timerValues = {
    'North Red': 30,
    'North Green': 25,
    'South Red': 30,
    'South Green': 25,
    'East Red': 30,
    'East Green': 25,
    'West Red': 30,
    'West Green': 25,
  };

  bool hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentConfig();
  }

  Future<void> _loadCurrentConfig() async {
    try {
      final response = await http.get(Uri.parse(getConfigUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          selectedMode = data['mode'] ?? 'AUTO';
          if (data['timers'] != null) {
            timerValues = Map<String, int>.from(data['timers']);
          }
        });
      }
    } catch (e) {
      print('Error loading config: $e');
    }
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 10),
            Text('Confirm Changes'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to apply these changes?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 15),
            Text('Mode: $selectedMode', style: TextStyle(fontSize: 14)),
            SizedBox(height: 8),
            Text('This will affect the traffic light system immediately.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _saveSettings();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveSettings() async {
    try {
      final response = await http.post(
        Uri.parse(controlUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mode': selectedMode, 'timers': timerValues}),
      );

      if (response.statusCode == 200) {
        setState(() {
          hasChanges = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Settings saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving settings: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Modify Traffic Settings'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Mode',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 15),

              _buildModeCard(
                'AUTO',
                Icons.autorenew,
                Colors.green,
                'Automatic cycle based on timer',
              ),
              _buildModeCard(
                'MANUAL',
                Icons.pan_tool,
                Colors.blue,
                'Manual control via dashboard',
              ),
              _buildModeCard(
                'EMERGENCY',
                Icons.emergency,
                Colors.red,
                'All lights turn red',
              ),
              _buildModeCard(
                'AI-BASED',
                Icons.psychology,
                Colors.purple,
                'AI optimizes based on traffic',
              ),

              SizedBox(height: 30),

              Text(
                'Timer Settings (seconds)',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 15),

              ...timerValues.keys.map((key) => _buildTimerControl(key)),

              SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: hasChanges ? _showConfirmationDialog : null,
                  icon: Icon(Icons.check_circle),
                  label: Text('Apply Changes', style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasChanges ? Colors.green : Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeCard(String mode, IconData icon, Color color, String desc) {
    final isSelected = selectedMode == mode;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedMode = mode;
          hasChanges = true;
        });
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 3 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mode,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? color : Colors.black,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    desc,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: color, size: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerControl(String label) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'Duration for this phase',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    if (timerValues[label]! > 5) {
                      timerValues[label] = timerValues[label]! - 5;
                      hasChanges = true;
                    }
                  });
                },
                icon: Icon(Icons.remove_circle, color: Colors.red),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${timerValues[label]}s',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    if (timerValues[label]! < 120) {
                      timerValues[label] = timerValues[label]! + 5;
                      hasChanges = true;
                    }
                  });
                },
                icon: Icon(Icons.add_circle, color: Colors.green),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
