// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:fl_chart/fl_chart.dart';
// import 'package:first_flutter/data/auth_service.dart';
// class PoliceView extends StatefulWidget {
//   const PoliceView({super.key});

//   @override
//   State<PoliceView> createState() => _PoliceViewState();
// }

// class _PoliceViewState extends State<PoliceView> {
//   // Video stream
//   String? currentImageUrl;
//   bool isStreaming = false;
//   Timer? streamTimer;

//   // Chart data - 4 hướng
//   List<VehicleDataPoint> dataPoints = [];
//   int maxDataPoints = 20; // Hiển thị tối đa 20 điểm
//   Timer? chartUpdateTimer;

//   // API endpoints
//   final String videoStreamUrl = 'YOUR_BACKEND_URL/stream/frame';
//   final String vehicleCountUrl = "${AuthService.baseUrl}/api/traffic-count/latest";

//   @override
//   void initState() {
//     super.initState();
//     startStreaming();
//     startChartUpdate();
//   }

//   @override
//   void dispose() {
//     stopStreaming();
//     stopChartUpdate();
//     super.dispose();
//   }

//   // Bắt đầu stream video
//   void startStreaming() {
//     setState(() {
//       isStreaming = true;
//     });

//     streamTimer = Timer.periodic(Duration(milliseconds: 100), (timer) async {
//       try {
//         final response = await http.get(Uri.parse(videoStreamUrl));

//         if (response.statusCode == 200) {
//           setState(() {
//             currentImageUrl = 'data:image/jpeg;base64,${response.body}';
//           });
//         }
//       } catch (e) {
//         print('Error fetching frame: $e');
//       }
//     });
//   }

//   // Dừng stream video
//   void stopStreaming() {
//     streamTimer?.cancel();
//     setState(() {
//       isStreaming = false;
//     });
//   }
// // --- Fetch dữ liệu từ backend ---
//   Future<void> _fetchLatestData() async {
//     try {
//       final response = await http.get(Uri.parse(vehicleCountUrl));
//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         final timestamp = DateTime.now();
//         setState(() {
//           dataPoints.add(
//             VehicleDataPoint(
//               time: timestamp,
//               north: data['north'] ?? 0,
//               south: data['south'] ?? 0,
//               east: data['east'] ?? 0,
//               west: data['west'] ?? 0,
//             ),
//           );
//           if (dataPoints.length > maxDataPoints) dataPoints.removeAt(0);
//         });
//       } else {
//         print('Failed to fetch vehicle count: ${response.statusCode}');
//       }
//     } catch (e) {
//       print('Error fetching vehicle count: $e');
//     }
//   }
//   // ------------------ VẼ BIỂU ĐỒ XE --------------//
//   // ------------------ Timer cập nhật chart --------------//
//   void startChartUpdate() {
//     chartUpdateTimer = Timer.periodic(Duration(seconds: 30), (timer) async {
//       await _fetchLatestData();
//     });
//   }
//   // Dừng cập nhật biểu đồ
//   void stopChartUpdate() {
//     chartUpdateTimer?.cancel();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Vehicle Monitoring'),
//         backgroundColor: Colors.blue.shade700,
//         actions: [
//           IconButton(
//             icon: Icon(isStreaming ? Icons.pause : Icons.play_arrow),
//             onPressed: () {
//               if (isStreaming) {
//                 stopStreaming();
//               } else {
//                 startStreaming();
//               }
//             },
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           // Video stream section
//           Expanded(
//             flex: 2,
//             child: Container(
//               margin: EdgeInsets.all(10),
//               decoration: BoxDecoration(
//                 color: Colors.black,
//                 borderRadius: BorderRadius.circular(10),
//                 border: Border.all(color: Colors.grey),
//               ),
//               child: ClipRRect(
//                 borderRadius: BorderRadius.circular(10),
//                 child: currentImageUrl != null
//                     ? Image.network(
//                         currentImageUrl!,
//                         fit: BoxFit.contain,
//                         errorBuilder: (context, error, stackTrace) {
//                           return Center(
//                             child: Column(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 Icon(Icons.error, color: Colors.red, size: 50),
//                                 SizedBox(height: 10),
//                                 Text(
//                                   'Không thể tải video',
//                                   style: TextStyle(color: Colors.white),
//                                 ),
//                               ],
//                             ),
//                           );
//                         },
//                         loadingBuilder: (context, child, loadingProgress) {
//                           if (loadingProgress == null) return child;
//                           return Center(child: CircularProgressIndicator());
//                         },
//                       )
//                     : Center(
//                         child: Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Icon(
//                               Icons.videocam_off,
//                               color: Colors.grey,
//                               size: 50,
//                             ),
//                             SizedBox(height: 10),
//                             Text(
//                               'Đang chờ video stream...',
//                               style: TextStyle(color: Colors.grey),
//                             ),
//                           ],
//                         ),
//                       ),
//               ),
//             ),
//           ),

//           // Chart section
//           Expanded(
//             flex: 3,
//             child: Container(
//               margin: EdgeInsets.all(10),
//               padding: EdgeInsets.all(15),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(10),
//                 border: Border.all(color: Colors.grey.shade300),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Header với legend
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         'Mật độ xe theo hướng',
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       Row(
//                         children: [
//                           _buildLegend('Bắc', Colors.red),
//                           SizedBox(width: 10),
//                           _buildLegend('Nam', Colors.blue),
//                           SizedBox(width: 10),
//                           _buildLegend('Đông', Colors.green),
//                           SizedBox(width: 10),
//                           _buildLegend('Tây', Colors.orange),
//                         ],
//                       ),
//                     ],
//                   ),
//                   SizedBox(height: 10),

//                   // Current counts
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                     children: [
//                       _buildCountCard(
//                         'Bắc',
//                         dataPoints.isEmpty ? 0 : dataPoints.last.north,
//                         Colors.red,
//                       ),
//                       _buildCountCard(
//                         'Nam',
//                         dataPoints.isEmpty ? 0 : dataPoints.last.south,
//                         Colors.blue,
//                       ),
//                       _buildCountCard(
//                         'Đông',
//                         dataPoints.isEmpty ? 0 : dataPoints.last.east,
//                         Colors.green,
//                       ),
//                       _buildCountCard(
//                         'Tây',
//                         dataPoints.isEmpty ? 0 : dataPoints.last.west,
//                         Colors.orange,
//                       ),
//                     ],
//                   ),
//                   SizedBox(height: 15),

//                   // Chart
//                   Expanded(
//                     child: dataPoints.isEmpty
//                         ? Center(
//                             child: Text(
//                               'Đang thu thập dữ liệu...',
//                               style: TextStyle(color: Colors.grey),
//                             ),
//                           )
//                         : LineChart(
//                             LineChartData(
//                               gridData: FlGridData(
//                                 show: true,
//                                 drawVerticalLine: true,
//                                 horizontalInterval: 2,
//                                 verticalInterval: 1,
//                                 getDrawingHorizontalLine: (value) {
//                                   return FlLine(
//                                     color: Colors.grey.shade300,
//                                     strokeWidth: 1,
//                                   );
//                                 },
//                                 getDrawingVerticalLine: (value) {
//                                   return FlLine(
//                                     color: Colors.grey.shade300,
//                                     strokeWidth: 1,
//                                   );
//                                 },
//                               ),
//                               titlesData: FlTitlesData(
//                                 show: true,
//                                 rightTitles: AxisTitles(
//                                   sideTitles: SideTitles(showTitles: false),
//                                 ),
//                                 topTitles: AxisTitles(
//                                   sideTitles: SideTitles(showTitles: false),
//                                 ),
//                                 bottomTitles: AxisTitles(
//                                   sideTitles: SideTitles(
//                                     showTitles: true,
//                                     reservedSize: 30,
//                                     interval: 5,
//                                     getTitlesWidget:
//                                         (double value, TitleMeta meta) {
//                                           if (value.toInt() >= 0 &&
//                                               value.toInt() <
//                                                   dataPoints.length) {
//                                             final time =
//                                                 dataPoints[value.toInt()].time;
//                                             return Padding(
//                                               padding: EdgeInsets.only(
//                                                 top: 8.0,
//                                               ),
//                                               child: Text(
//                                                 '${time.hour}:${time.minute.toString().padLeft(2, '0')}',
//                                                 style: TextStyle(
//                                                   color: Colors.grey.shade600,
//                                                   fontSize: 10,
//                                                 ),
//                                               ),
//                                             );
//                                           }
//                                           return Text('');
//                                         },
//                                   ),
//                                 ),
//                                 leftTitles: AxisTitles(
//                                   sideTitles: SideTitles(
//                                     showTitles: true,
//                                     interval: 2,
//                                     getTitlesWidget:
//                                         (double value, TitleMeta meta) {
//                                           return Text(
//                                             value.toInt().toString(),
//                                             style: TextStyle(
//                                               color: Colors.grey.shade600,
//                                               fontSize: 11,
//                                             ),
//                                           );
//                                         },
//                                     reservedSize: 35,
//                                   ),
//                                 ),
//                               ),
//                               borderData: FlBorderData(
//                                 show: true,
//                                 border: Border.all(
//                                   color: Colors.grey.shade300,
//                                   width: 1,
//                                 ),
//                               ),
//                               minX: 0,
//                               maxX: dataPoints.length.toDouble() - 1,
//                               minY: 0,
//                               maxY: _getMaxY(),
//                               lineBarsData: [
//                                 // Đường Bắc (Red)
//                                 _buildLineChartBarData(
//                                   dataPoints.asMap().entries.map((e) {
//                                     return FlSpot(
//                                       e.key.toDouble(),
//                                       e.value.north.toDouble(),
//                                     );
//                                   }).toList(),
//                                   Colors.red,
//                                 ),
//                                 // Đường Nam (Blue)
//                                 _buildLineChartBarData(
//                                   dataPoints.asMap().entries.map((e) {
//                                     return FlSpot(
//                                       e.key.toDouble(),
//                                       e.value.south.toDouble(),
//                                     );
//                                   }).toList(),
//                                   Colors.blue,
//                                 ),
//                                 // Đường Đông (Green)
//                                 _buildLineChartBarData(
//                                   dataPoints.asMap().entries.map((e) {
//                                     return FlSpot(
//                                       e.key.toDouble(),
//                                       e.value.east.toDouble(),
//                                     );
//                                   }).toList(),
//                                   Colors.green,
//                                 ),
//                                 // Đường Tây (Orange)
//                                 _buildLineChartBarData(
//                                   dataPoints.asMap().entries.map((e) {
//                                     return FlSpot(
//                                       e.key.toDouble(),
//                                       e.value.west.toDouble(),
//                                     );
//                                   }).toList(),
//                                   Colors.orange,
//                                 ),
//                               ],
//                             ),
//                           ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // Tạo LineChartBarData cho mỗi hướng
//   LineChartBarData _buildLineChartBarData(List<FlSpot> spots, Color color) {
//     return LineChartBarData(
//       spots: spots,
//       isCurved: true,
//       color: color,
//       barWidth: 3,
//       isStrokeCapRound: true,
//       dotData: FlDotData(
//         show: true,
//         getDotPainter: (spot, percent, barData, index) {
//           return FlDotCirclePainter(
//             radius: 3,
//             color: color,
//             strokeWidth: 1.5,
//             strokeColor: Colors.white,
//           );
//         },
//       ),
//       belowBarData: BarAreaData(show: false),
//     );
//   }

//   // Widget legend
//   Widget _buildLegend(String label, Color color) {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Container(
//           width: 12,
//           height: 12,
//           decoration: BoxDecoration(color: color, shape: BoxShape.circle),
//         ),
//         SizedBox(width: 4),
//         Text(
//           label,
//           style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
//         ),
//       ],
//     );
//   }

//   // Widget hiển thị số lượng xe hiện tại
//   Widget _buildCountCard(String direction, int count, Color color) {
//     return Container(
//       padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: color, width: 1),
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Text(
//             direction,
//             style: TextStyle(
//               fontSize: 10,
//               color: color,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           Text(
//             count.toString(),
//             style: TextStyle(
//               fontSize: 16,
//               color: color,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   double _getMaxY() {
//     if (dataPoints.isEmpty) return 20;

//     int maxCount = 0;
//     for (var point in dataPoints) {
//       if (point.north > maxCount) maxCount = point.north;
//       if (point.south > maxCount) maxCount = point.south;
//       if (point.east > maxCount) maxCount = point.east;
//       if (point.west > maxCount) maxCount = point.west;
//     }

//     return (maxCount + 5).toDouble();
//   }
// }

// // Model cho dữ liệu xe theo 4 hướng
// class VehicleDataPoint {
//   final DateTime time;
//   final int north;
//   final int south;
//   final int east;
//   final int west;

//   VehicleDataPoint({
//     required this.time,
//     required this.north,
//     required this.south,
//     required this.east,
//     required this.west,
//   });
// } 


import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:first_flutter/data/auth_service.dart';

// ⭐ THÊM IMPORT CHO WEB
import 'package:flutter/foundation.dart' show kIsWeb;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;

class PoliceView extends StatefulWidget {
  const PoliceView({super.key});

  @override
  State<PoliceView> createState() => _PoliceViewState();
}

class _PoliceViewState extends State<PoliceView> {
  // ========================================
  // ⭐ CẤU HÌNH STREAM (GIỐNG CODE 2)
  // ========================================
// ================= CLOUD FLARE BASE =================
static const String baseUrl ='https://involvement-shapes-radiation-netscape.trycloudflare.com';

  final String esp32Ip = '10.10.59.238';
  
// ================= STREAM =================
  final String streamViewType = 'police-stream-iframe';
  final String videoStreamUrl = '$baseUrl/detect';

  bool isStreaming = false;
  
  // Chart data - 4 hướng
  List<VehicleDataPoint> dataPoints = [];
  int maxDataPoints = 20;
  Timer? chartUpdateTimer;

  // API endpoints
  // ================= VEHICLE COUNT =================
final String vehicleCountUrl = '$baseUrl/lanes';

  @override
  void initState() {
    super.initState();

    if (kIsWeb) {
      _registerStreamIframe();
      isStreaming = true;
    }

    startChartUpdate();
    _fetchLatestData(); // gọi 1 phát để có dữ liệu ngay
  }

  @override
  void dispose() {
    stopChartUpdate();
    super.dispose();
  }

  // ========================================
  // ⭐ ĐĂNG KÝ IFRAME CHO STREAM
  // ========================================
  void _registerStreamIframe() {
  ui_web.platformViewRegistry.registerViewFactory(
    streamViewType,
    (int viewId) {
      final iframe = html.IFrameElement()
        ..src = videoStreamUrl
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%';

      return iframe;
    },
  );
}

  // --- Fetch dữ liệu từ backend ---
  Future<void> _fetchLatestData() async {
    try {
      final response = await http.get(Uri.parse(vehicleCountUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final timestamp = DateTime.now();
        setState(() {
          dataPoints.add(
            VehicleDataPoint(
              time: timestamp,
              north: data['north'] ?? 0,
              south: data['south'] ?? 0,
              east: data['east'] ?? 0,
              west: data['west'] ?? 0,
            ),
          );
          if (dataPoints.length > maxDataPoints) dataPoints.removeAt(0);
        });
      } else {
        print('Failed to fetch vehicle count: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching vehicle count: $e');
    }
  }

  // ------------------ Timer cập nhật chart --------------//
  // void startChartUpdate() {
  //   chartUpdateTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
  //     await _fetchLatestData();
  //   });
  // }

  // void stopChartUpdate() {
  //   chartUpdateTimer?.cancel();
  // }
void startChartUpdate() {
  chartUpdateTimer =
      Timer.periodic(const Duration(seconds: 2), (_) {
    _fetchLatestData();
  });
}

  // ========================================
  // ⭐ Toggle STREAM (Web)
  // ========================================
  void _toggleStreaming() {
    if (!kIsWeb) return;

    setState(() {
      isStreaming = !isStreaming;
      // iframe stream không “pause” thật sự như video,
      // nên cách đơn giản là: pause => hiển thị overlay, play => hiển thị lại iframe
    });
  }

  void _refreshStream() {
    if (!kIsWeb) return;
    setState(() {
      _registerStreamIframe(); // đăng ký lại
      isStreaming = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Monitoring'),
        backgroundColor: Colors.blue.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Stream',
            onPressed: _refreshStream,
          ),
          IconButton(
            icon: Icon(isStreaming ? Icons.pause : Icons.play_arrow),
            tooltip: isStreaming ? 'Pause (overlay)' : 'Play',
            onPressed: _toggleStreaming,
          ),
        ],
      ),
      body: Column(
        children: [
          // ========================================
          // ⭐ STREAM SECTION (GIỐNG CODE 2)
          // ========================================
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.shade700, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: kIsWeb
                    ? Stack(
                        children: [
                          // iframe stream
                          HtmlElementView(viewType: streamViewType),

                          // LIVE badge
                          Positioned(
                            top: 10,
                            left: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: isStreaming ? Colors.green : Colors.grey,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isStreaming ? 'LIVE' : 'PAUSED',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // POLICE badge
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade700.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.local_police, color: Colors.white, size: 14),
                                  SizedBox(width: 6),
                                  Text(
                                    'POLICE',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // overlay khi pause
                          if (!isStreaming)
                            Container(
                              color: Colors.black.withOpacity(0.65),
                              child: const Center(
                                child: Text(
                                  'Stream đang tạm dừng',
                                  style: TextStyle(color: Colors.white, fontSize: 16),
                                ),
                              ),
                            ),
                        ],
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.computer, color: Colors.grey, size: 50),
                            const SizedBox(height: 10),
                            const Text('Stream chỉ khả dụng trên Web',
                                style: TextStyle(color: Colors.grey)),
                            const SizedBox(height: 5),
                            Text(
                              'Chạy: flutter run -d chrome',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ),

          // ========================================
          // CHART SECTION (GIỮ NGUYÊN TỪ CODE 1)
          // ========================================
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Mật độ xe theo hướng',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          _buildLegend('Bắc', Colors.red),
                          const SizedBox(width: 10),
                          _buildLegend('Nam', Colors.blue),
                          const SizedBox(width: 10),
                          _buildLegend('Đông', Colors.green),
                          const SizedBox(width: 10),
                          _buildLegend('Tây', Colors.orange),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildCountCard('Bắc', dataPoints.isEmpty ? 0 : dataPoints.last.north, Colors.red),
                      _buildCountCard('Nam', dataPoints.isEmpty ? 0 : dataPoints.last.south, Colors.blue),
                      _buildCountCard('Đông', dataPoints.isEmpty ? 0 : dataPoints.last.east, Colors.green),
                      _buildCountCard('Tây', dataPoints.isEmpty ? 0 : dataPoints.last.west, Colors.orange),
                    ],
                  ),
                  const SizedBox(height: 15),

                  Expanded(
                    child: dataPoints.isEmpty
                        ? const Center(
                            child: Text('Đang thu thập dữ liệu...', style: TextStyle(color: Colors.grey)),
                          )
                        : LineChart(
                            LineChartData(
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: true,
                                horizontalInterval: 2,
                                verticalInterval: 1,
                                getDrawingHorizontalLine: (value) => FlLine(
                                  color: Colors.grey.shade300,
                                  strokeWidth: 1,
                                ),
                                getDrawingVerticalLine: (value) => FlLine(
                                  color: Colors.grey.shade300,
                                  strokeWidth: 1,
                                ),
                              ),
                              titlesData: FlTitlesData(
                                show: true,
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 30,
                                    interval: 5,
                                    getTitlesWidget: (double value, TitleMeta meta) {
                                      final idx = value.toInt();
                                      if (idx >= 0 && idx < dataPoints.length) {
                                        final time = dataPoints[idx].time;
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 8.0),
                                          child: Text(
                                            '${time.hour}:${time.minute.toString().padLeft(2, '0')}',
                                            style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                                          ),
                                        );
                                      }
                                      return const Text('');
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    interval: 2,
                                    reservedSize: 35,
                                    getTitlesWidget: (double value, TitleMeta meta) => Text(
                                      value.toInt().toString(),
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                                    ),
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(
                                show: true,
                                border: Border.all(color: Colors.grey.shade300, width: 1),
                              ),
                              minX: 0,
                              maxX: dataPoints.length.toDouble() - 1,
                              minY: 0,
                              maxY: _getMaxY(),
                              lineBarsData: [
                                _buildLineChartBarData(
                                  dataPoints.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.north.toDouble())).toList(),
                                  Colors.red,
                                ),
                                _buildLineChartBarData(
                                  dataPoints.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.south.toDouble())).toList(),
                                  Colors.blue,
                                ),
                                _buildLineChartBarData(
                                  dataPoints.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.east.toDouble())).toList(),
                                  Colors.green,
                                ),
                                _buildLineChartBarData(
                                  dataPoints.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.west.toDouble())).toList(),
                                  Colors.orange,
                                ),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  LineChartBarData _buildLineChartBarData(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
          radius: 3,
          color: color,
          strokeWidth: 1.5,
          strokeColor: Colors.white,
        ),
      ),
      belowBarData: BarAreaData(show: false),
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
      ],
    );
  }

  Widget _buildCountCard(String direction, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(direction, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
          Text(count.toString(), style: TextStyle(fontSize: 16, color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  double _getMaxY() {
    if (dataPoints.isEmpty) return 20;

    int maxCount = 0;
    for (var point in dataPoints) {
      if (point.north > maxCount) maxCount = point.north;
      if (point.south > maxCount) maxCount = point.south;
      if (point.east > maxCount) maxCount = point.east;
      if (point.west > maxCount) maxCount = point.west;
    }
    return (maxCount + 5).toDouble();
  }
}

class VehicleDataPoint {
  final DateTime time;
  final int north;
  final int south;
  final int east;
  final int west;

  VehicleDataPoint({
    required this.time,
    required this.north,
    required this.south,
    required this.east,
    required this.west,
  });
}
