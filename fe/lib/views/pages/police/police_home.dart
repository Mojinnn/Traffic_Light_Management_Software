// import 'package:first_flutter/views/pages/police/police_modify.dart';
// import 'package:first_flutter/views/pages/police/police_view.dart';
// import 'package:first_flutter/views/widgets/container_widget.dart';
// import 'package:first_flutter/views/widgets/hero_widget.dart';
// import 'package:flutter/material.dart';

// class PoliceHome extends StatelessWidget {
//   const PoliceHome({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final List<Map<String, dynamic>> featureMap = [
//       {
//         "title": "View Traffic Density",
//         "desc": "See real-time traffic density",
//         "page": PoliceView(),
//       },
//       {
//         "title": "Modify Light Counter",
//         "desc": "Adjust traffic light timers",
//         "page": PoliceModify(),
//       },
//     ];

//     return SingleChildScrollView(
//       child: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             HeroWidget(title: 'Home', nextPage: null),

//             const SizedBox(height: 20),

//             //Section title
//             const Text(
//               'Police Functions',
//               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//             ),

//             const SizedBox(height: 10),

//             ...featureMap.map((feature) {
//               return GestureDetector(
//                 onTap: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (context) => feature["page"]),
//                   );
//                 },
//                 child: ContainerWidget(
//                   title: feature["title"]!,
//                   description: feature["desc"]!,
//                 ),
//               );
//             }),
//           ],
//         ),
//       ),
//     );
//   }
// }

// ============================================
// 2. POLICE HOME với Feature Gate
// ============================================
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

  @override
  void initState() {
    super.initState();
    _loadFeatures();

    // Lắng nghe thay đổi từ Admin
    _featureService.startListening(() {
      _loadFeatures();
    });
  }

  Future<void> _loadFeatures() async {
    final viewTraffic = await _featureService.isFeatureEnabled(
      'police_view_traffic',
    );
    final modifyLights = await _featureService.isFeatureEnabled(
      'police_modify_lights',
    );

    setState(() {
      featureStatuses = {
        'police_view_traffic': viewTraffic,
        'police_modify_lights': modifyLights,
      };
    });
  }

  void _navigateToFeature(
    String featureId,
    Widget page,
    String featureName,
  ) async {
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
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Police Functions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),

            // View Traffic Density
            if (featureStatuses['police_view_traffic'] ?? true)
              GestureDetector(
                onTap: () => _navigateToFeature(
                  'police_view_traffic',
                  PoliceView(),
                  'View Traffic Density',
                ),
                child: _buildFeatureCard(
                  'View Traffic Density',
                  'See real-time traffic density',
                  Icons.traffic,
                  featureStatuses['police_view_traffic'] ?? true,
                ),
              ),

            SizedBox(height: 15),

            // Modify Light Counter
            if (featureStatuses['police_modify_lights'] ?? true)
              GestureDetector(
                onTap: () => _navigateToFeature(
                  'police_modify_lights',
                  PoliceModify(),
                  'Modify Light Counter',
                ),
                child: _buildFeatureCard(
                  'Modify Light Counter',
                  'Adjust traffic light timers',
                  Icons.settings,
                  featureStatuses['police_modify_lights'] ?? true,
                ),
              ),

            // Thông báo nếu không có tính năng nào
            if ((featureStatuses['police_view_traffic'] == false) &&
                (featureStatuses['police_modify_lights'] == false))
              Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(Icons.lock, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'All features are disabled',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Contact your administrator',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    String title,
    String desc,
    IconData icon,
    bool isEnabled,
  ) {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEnabled ? Colors.blue.shade200 : Colors.grey.shade300,
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
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isEnabled ? Colors.blue.shade50 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: isEnabled ? Colors.blue : Colors.grey,
              size: 28,
            ),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  desc,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Icon(
            isEnabled ? Icons.arrow_forward_ios : Icons.lock,
            color: isEnabled ? Colors.grey : Colors.orange,
            size: 20,
          ),
        ],
      ),
    );
  }
}
