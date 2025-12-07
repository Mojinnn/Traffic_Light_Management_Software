import 'package:first_flutter/views/pages/police/police_modify.dart';
import 'package:first_flutter/views/pages/police/police_view.dart';
import 'package:first_flutter/views/widgets/container_widget.dart';
import 'package:first_flutter/views/widgets/hero_widget.dart';
import 'package:flutter/material.dart';

class PoliceHome extends StatelessWidget {
  const PoliceHome({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> featureMap = [
      {
        "title": "View Traffic Density",
        "desc": "See real-time traffic density",
        "page": PoliceView(),
      },
      {
        "title": "Modify Light Counter",
        "desc": "Adjust traffic light timers",
        "page": PoliceModify(),
      },
    ];

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HeroWidget(title: 'Home', nextPage: null),

            const SizedBox(height: 20),

            //Section title
            const Text(
              'Police Functions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            ...featureMap.map((feature) {
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => feature["page"]),
                  );
                },
                child: ContainerWidget(
                  title: feature["title"]!,
                  description: feature["desc"]!,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;

// class PoliceHome extends StatefulWidget {
//   const PoliceHome({super.key});

//   @override
//   State<PoliceHome> createState() => _PoliceHomeState();
// }

// class _PoliceHomeState extends State<PoliceHome> {
//   // API endpoints
//   final String getStatusUrl = 'YOUR_BACKEND_URL/traffic-lights/status';
//   final String controlUrl = 'YOUR_BACKEND_URL/traffic-lights/control';

//   // Timer để cập nhật trạng thái
//   Timer? statusTimer;
//   bool isAutoMode = true;

//   // Trạng thái 4 đèn giao thông
//   List<TrafficLight> trafficLights = [
//     TrafficLight(
//       id: 1,
//       name: 'Đèn Bắc',
//       direction: 'North',
//       state: TrafficLightState.red,
//     ),
//     TrafficLight(
//       id: 2,
//       name: 'Đèn Nam',
//       direction: 'South',
//       state: TrafficLightState.red,
//     ),
//     TrafficLight(
//       id: 3,
//       name: 'Đèn Đông',
//       direction: 'East',
//       state: TrafficLightState.green,
//     ),
//     TrafficLight(
//       id: 4,
//       name: 'Đèn Tây',
//       direction: 'West',
//       state: TrafficLightState.green,
//     ),
//   ];

//   @override
//   void initState() {
//     super.initState();
//     startStatusUpdate();
//   }

//   @override
//   void dispose() {
//     statusTimer?.cancel();
//     super.dispose();
//   }

//   // Bắt đầu cập nhật trạng thái
//   void startStatusUpdate() {
//     statusTimer = Timer.periodic(Duration(seconds: 1), (timer) async {
//       await fetchTrafficLightStatus();
//     });
//   }

//   // Lấy trạng thái đèn từ backend
//   Future<void> fetchTrafficLightStatus() async {
//     try {
//       final response = await http.get(Uri.parse(getStatusUrl));

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         setState(() {
//           isAutoMode = data['autoMode'] ?? true;

//           for (var i = 0; i < trafficLights.length; i++) {
//             final lightData = data['lights'][i];
//             trafficLights[i].state = _getStateFromString(lightData['state']);
//             trafficLights[i].remainingTime = lightData['remainingTime'] ?? 0;
//           }
//         });
//       }
//     } catch (e) {
//       print('Error fetching status: $e');
//       // Giả lập dữ liệu để test (xóa khi có backend)
//       if (isAutoMode) {
//         _simulateAutoMode();
//       }
//     }
//   }

//   // Chuyển đổi string thành enum
//   TrafficLightState _getStateFromString(String state) {
//     switch (state.toLowerCase()) {
//       case 'red':
//         return TrafficLightState.red;
//       case 'yellow':
//         return TrafficLightState.yellow;
//       case 'green':
//         return TrafficLightState.green;
//       default:
//         return TrafficLightState.red;
//     }
//   }

//   // Giả lập chế độ tự động (xóa khi có backend)
//   void _simulateAutoMode() {
//     final now = DateTime.now().second;
//     final cycle = now % 30;

//     setState(() {
//       if (cycle < 10) {
//         // Bắc-Nam đỏ, Đông-Tây xanh
//         trafficLights[0].state = TrafficLightState.red;
//         trafficLights[1].state = TrafficLightState.red;
//         trafficLights[2].state = TrafficLightState.green;
//         trafficLights[3].state = TrafficLightState.green;
//         trafficLights[0].remainingTime = 10 - cycle;
//         trafficLights[1].remainingTime = 10 - cycle;
//         trafficLights[2].remainingTime = 10 - cycle;
//         trafficLights[3].remainingTime = 10 - cycle;
//       } else if (cycle < 13) {
//         // Đông-Tây vàng
//         trafficLights[0].state = TrafficLightState.red;
//         trafficLights[1].state = TrafficLightState.red;
//         trafficLights[2].state = TrafficLightState.yellow;
//         trafficLights[3].state = TrafficLightState.yellow;
//         trafficLights[2].remainingTime = 13 - cycle;
//         trafficLights[3].remainingTime = 13 - cycle;
//       } else if (cycle < 23) {
//         // Bắc-Nam xanh, Đông-Tây đỏ
//         trafficLights[0].state = TrafficLightState.green;
//         trafficLights[1].state = TrafficLightState.green;
//         trafficLights[2].state = TrafficLightState.red;
//         trafficLights[3].state = TrafficLightState.red;
//         trafficLights[0].remainingTime = 23 - cycle;
//         trafficLights[1].remainingTime = 23 - cycle;
//         trafficLights[2].remainingTime = 23 - cycle;
//         trafficLights[3].remainingTime = 23 - cycle;
//       } else {
//         // Bắc-Nam vàng
//         trafficLights[0].state = TrafficLightState.yellow;
//         trafficLights[1].state = TrafficLightState.yellow;
//         trafficLights[2].state = TrafficLightState.red;
//         trafficLights[3].state = TrafficLightState.red;
//         trafficLights[0].remainingTime = 30 - cycle;
//         trafficLights[1].remainingTime = 30 - cycle;
//       }
//     });
//   }

//   // Gửi lệnh điều khiển đến backend
//   Future<void> sendControlCommand(
//     String command, {
//     int? lightId,
//     String? state,
//   }) async {
//     try {
//       final response = await http.post(
//         Uri.parse(controlUrl),
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode({
//           'command': command,
//           'lightId': lightId,
//           'state': state,
//         }),
//       );

//       if (response.statusCode == 200) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Lệnh đã được gửi thành công!'),
//             backgroundColor: Colors.green,
//             duration: Duration(seconds: 1),
//           ),
//         );
//         await fetchTrafficLightStatus();
//       }
//     } catch (e) {
//       print('Error sending command: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Lỗi khi gửi lệnh: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }

//   // Chuyển sang chế độ tự động
//   void setAutoMode() async {
//     setState(() {
//       isAutoMode = true;
//     });
//     await sendControlCommand('auto');
//   }

//   // Chuyển sang chế độ thủ công
//   void setManualMode() {
//     setState(() {
//       isAutoMode = false;
//     });
//     sendControlCommand('manual');
//   }

//   // Điều khiển một đèn cụ thể
//   void controlSingleLight(int lightId, TrafficLightState state) {
//     if (!isAutoMode) {
//       sendControlCommand(
//         'set',
//         lightId: lightId,
//         state: state.toString().split('.').last,
//       );
//     }
//   }

//   // Tắt hết đèn (Emergency)
//   void emergencyStop() {
//     setState(() {
//       isAutoMode = false;
//       for (var light in trafficLights) {
//         light.state = TrafficLightState.red;
//       }
//     });
//     sendControlCommand('emergency');
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Column(
//         children: [
//           // Control Panel
//           Container(
//             padding: EdgeInsets.all(15),
//             color: Colors.grey.shade100,
//             child: Column(
//               children: [
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                   children: [
//                     Expanded(
//                       child: ElevatedButton.icon(
//                         onPressed: setAutoMode,
//                         icon: Icon(Icons.autorenew),
//                         label: Text('Tự động'),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: isAutoMode
//                               ? Colors.green
//                               : Colors.grey,
//                           foregroundColor: Colors.white,
//                           padding: EdgeInsets.symmetric(vertical: 12),
//                         ),
//                       ),
//                     ),
//                     SizedBox(width: 10),
//                     Expanded(
//                       child: ElevatedButton.icon(
//                         onPressed: setManualMode,
//                         icon: Icon(Icons.pan_tool),
//                         label: Text('Thủ công'),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: !isAutoMode
//                               ? Colors.blue
//                               : Colors.grey,
//                           foregroundColor: Colors.white,
//                           padding: EdgeInsets.symmetric(vertical: 12),
//                         ),
//                       ),
//                     ),
//                     SizedBox(width: 10),
//                     Expanded(
//                       child: ElevatedButton.icon(
//                         onPressed: emergencyStop,
//                         icon: Icon(Icons.emergency),
//                         label: Text('Khẩn cấp'),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.red,
//                           foregroundColor: Colors.white,
//                           padding: EdgeInsets.symmetric(vertical: 12),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 SizedBox(height: 10),
//                 Container(
//                   padding: EdgeInsets.all(10),
//                   decoration: BoxDecoration(
//                     color: isAutoMode
//                         ? Colors.green.shade50
//                         : Colors.blue.shade50,
//                     borderRadius: BorderRadius.circular(8),
//                     border: Border.all(
//                       color: isAutoMode ? Colors.green : Colors.blue,
//                       width: 2,
//                     ),
//                   ),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Icon(
//                         isAutoMode ? Icons.autorenew : Icons.pan_tool,
//                         color: isAutoMode ? Colors.green : Colors.blue,
//                       ),
//                       SizedBox(width: 8),
//                       Text(
//                         'Chế độ: ${isAutoMode ? "TỰ ĐỘNG" : "THỦ CÔNG"}',
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                           color: isAutoMode
//                               ? Colors.green.shade700
//                               : Colors.blue.shade700,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           // Traffic Lights Display
//           Expanded(
//             child: Container(
//               padding: EdgeInsets.all(10),
//               child: Column(
//                 children: [
//                   // Hàng 1: Đèn Bắc
//                   Expanded(
//                     child: Row(
//                       children: [
//                         Spacer(),
//                         Expanded(
//                           flex: 2,
//                           child: TrafficLightWidget(
//                             light: trafficLights[0],
//                             onControl: isAutoMode
//                                 ? null
//                                 : (state) => controlSingleLight(1, state),
//                           ),
//                         ),
//                         Spacer(),
//                       ],
//                     ),
//                   ),

//                   // Hàng 2: Đèn Đông và Tây
//                   Expanded(
//                     child: Row(
//                       children: [
//                         Expanded(
//                           child: TrafficLightWidget(
//                             light: trafficLights[3],
//                             onControl: isAutoMode
//                                 ? null
//                                 : (state) => controlSingleLight(4, state),
//                           ),
//                         ),
//                         Expanded(
//                           child: Container(
//                             margin: EdgeInsets.all(10),
//                             decoration: BoxDecoration(
//                               color: Colors.grey.shade300,
//                               borderRadius: BorderRadius.circular(10),
//                             ),
//                             child: Center(
//                               child: Icon(
//                                 Icons.add_road,
//                                 size: 50,
//                                 color: Colors.grey.shade600,
//                               ),
//                             ),
//                           ),
//                         ),
//                         Expanded(
//                           child: TrafficLightWidget(
//                             light: trafficLights[2],
//                             onControl: isAutoMode
//                                 ? null
//                                 : (state) => controlSingleLight(3, state),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),

//                   // Hàng 3: Đèn Nam
//                   Expanded(
//                     child: Row(
//                       children: [
//                         Spacer(),
//                         Expanded(
//                           flex: 2,
//                           child: TrafficLightWidget(
//                             light: trafficLights[1],
//                             onControl: isAutoMode
//                                 ? null
//                                 : (state) => controlSingleLight(2, state),
//                           ),
//                         ),
//                         Spacer(),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // Widget hiển thị một đèn giao thông
// class TrafficLightWidget extends StatelessWidget {
//   final TrafficLight light;
//   final Function(TrafficLightState)? onControl;

//   const TrafficLightWidget({Key? key, required this.light, this.onControl})
//     : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: EdgeInsets.all(8),
//       padding: EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(15),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 10,
//             offset: Offset(0, 5),
//           ),
//         ],
//       ),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           // Tên đèn
//           Text(
//             light.name,
//             style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//           ),
//           SizedBox(height: 10),

//           // Container đèn
//           Container(
//             padding: EdgeInsets.all(10),
//             decoration: BoxDecoration(
//               color: Colors.grey.shade900,
//               borderRadius: BorderRadius.circular(15),
//             ),
//             child: Column(
//               children: [
//                 // Đèn đỏ
//                 _buildLight(Colors.red, light.state == TrafficLightState.red),
//                 SizedBox(height: 8),
//                 // Đèn vàng
//                 _buildLight(
//                   Colors.yellow,
//                   light.state == TrafficLightState.yellow,
//                 ),
//                 SizedBox(height: 8),
//                 // Đèn xanh
//                 _buildLight(
//                   Colors.green,
//                   light.state == TrafficLightState.green,
//                 ),
//               ],
//             ),
//           ),

//           // Thời gian còn lại
//           SizedBox(height: 10),
//           Container(
//             padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//             decoration: BoxDecoration(
//               color: _getStateColor().withOpacity(0.2),
//               borderRadius: BorderRadius.circular(20),
//             ),
//             child: Text(
//               '${light.remainingTime}s',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: _getStateColor(),
//               ),
//             ),
//           ),

//           // Nút điều khiển (chỉ hiện trong chế độ thủ công)
//           if (onControl != null) ...[
//             SizedBox(height: 10),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//                 _buildControlButton(
//                   context,
//                   Colors.red,
//                   Icons.stop,
//                   () => onControl!(TrafficLightState.red),
//                 ),
//                 _buildControlButton(
//                   context,
//                   Colors.yellow,
//                   Icons.warning,
//                   () => onControl!(TrafficLightState.yellow),
//                 ),
//                 _buildControlButton(
//                   context,
//                   Colors.green,
//                   Icons.play_arrow,
//                   () => onControl!(TrafficLightState.green),
//                 ),
//               ],
//             ),
//           ],
//         ],
//       ),
//     );
//   }

//   Widget _buildLight(Color color, bool isActive) {
//     return Container(
//       width: 40,
//       height: 40,
//       decoration: BoxDecoration(
//         shape: BoxShape.circle,
//         color: isActive ? color : color.withOpacity(0.2),
//         boxShadow: isActive
//             ? [
//                 BoxShadow(
//                   color: color.withOpacity(0.5),
//                   blurRadius: 15,
//                   spreadRadius: 3,
//                 ),
//               ]
//             : null,
//       ),
//     );
//   }

//   Widget _buildControlButton(
//     BuildContext context,
//     Color color,
//     IconData icon,
//     VoidCallback onPressed,
//   ) {
//     return InkWell(
//       onTap: onPressed,
//       child: Container(
//         padding: EdgeInsets.all(8),
//         decoration: BoxDecoration(
//           color: color.withOpacity(0.2),
//           borderRadius: BorderRadius.circular(8),
//           border: Border.all(color: color, width: 2),
//         ),
//         child: Icon(icon, color: color, size: 20),
//       ),
//     );
//   }

//   Color _getStateColor() {
//     switch (light.state) {
//       case TrafficLightState.red:
//         return Colors.red;
//       case TrafficLightState.yellow:
//         return Colors.orange;
//       case TrafficLightState.green:
//         return Colors.green;
//     }
//   }
// }

// // Enum cho trạng thái đèn
// enum TrafficLightState { red, yellow, green }

// // Model cho đèn giao thông
// class TrafficLight {
//   final int id;
//   final String name;
//   final String direction;
//   TrafficLightState state;
//   int remainingTime;

//   TrafficLight({
//     required this.id,
//     required this.name,
//     required this.direction,
//     required this.state,
//     this.remainingTime = 0,
//   });
// }
