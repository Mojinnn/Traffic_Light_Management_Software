import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:first_flutter/data/auth_service.dart';

class PoliceModify extends StatefulWidget {
  const PoliceModify({super.key});

  @override
  State<PoliceModify> createState() => _PoliceModifyState();
}

class _PoliceModifyState extends State<PoliceModify> {
  final String controlUrl = "${AuthService.baseUrl}/traffic-lights/control";
  final String getConfigUrl = "${AuthService.baseUrl}/traffic-lights/config";

  String selectedMode = 'AUTO';
  String? editingTimer;

  // giữ giống cấu trúc bạn đang dùng
  Map<String, Map<String, int>> timerConfig = {
    'North': {'red': 30, 'green': 27},
    'South': {'red': 30, 'green': 27},
    'East': {'red': 30, 'green': 27},
    'West': {'red': 30, 'green': 27},
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

          hasChanges = false;
          editingTimer = null;
        });
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error loading config: $e');
    }
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
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
            const Text(
              'Are you sure you want to apply these changes?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            Text('Mode: $selectedMode', style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            if (selectedMode == 'MANUAL')
              const Text('TimerConfig will be applied immediately.'),
            if (selectedMode == 'AUTO')
              const Text('AUTO will reset to fixed timer: Red 30s, Yellow 3s, Green 27s.'),
            if (selectedMode == 'EMERGENCY')
              const Text('All lights will turn RED immediately.'),
            if (selectedMode == 'AI-BASED')
              const Text('AI-BASED is placeholder (currently same as AUTO fixed).'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _saveSettings();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _buildPayload() {
    // backend cho phép timerConfig optional, nhưng gửi luôn để tương thích mọi tình huống
    return {
      'mode': selectedMode,
      'timerConfig': {
        'North': timerConfig['North'],
        'South': timerConfig['South'],
        'East': timerConfig['East'],
        'West': timerConfig['West'],
      }
    };
  }

  Future<void> _saveSettings() async {
    try {
      final response = await http.post(
        Uri.parse(controlUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(_buildPayload()),
      );

      if (response.statusCode == 200) {
        setState(() {
          hasChanges = false;
          editingTimer = null;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: ${response.statusCode} - ${response.body}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
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
    final isManualMode = selectedMode == 'MANUAL';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modify Traffic Settings'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Mode',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),

              _buildModeCard(
                'AUTO',
                Icons.autorenew,
                Colors.green,
                'Reset to fixed: Red 30s, Yellow 3s, Green 27s',
              ),
              _buildModeCard(
                'MANUAL',
                Icons.pan_tool,
                Colors.blue,
                'Edit timer settings and apply immediately',
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
                'AI optimizes based on traffic (placeholder)',
              ),

              const SizedBox(height: 30),

              Row(
                children: [
                  const Text(
                    'Timer Settings (seconds)',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 10),
                  if (!isManualMode) Icon(Icons.lock, color: Colors.grey.shade400, size: 20),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                isManualMode
                    ? 'Tap on a timer to edit'
                    : 'Timer editing is only available in MANUAL mode',
                style: TextStyle(
                  fontSize: 14,
                  color: isManualMode ? Colors.grey.shade600 : Colors.red.shade400,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 15),

              ...timerConfig.keys.map((direction) => Column(
                    children: [
                      _buildDirectionHeader(direction),
                      const SizedBox(height: 8),
                      _buildTimerControl(direction, 'red', 'Red Phase'),
                      _buildTimerControl(direction, 'green', 'Green Phase'),
                      const SizedBox(height: 15),
                    ],
                  )),

              const SizedBox(height: 15),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: hasChanges ? _showConfirmationDialog : null,
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Apply Changes', style: TextStyle(fontSize: 16)),
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
          if (mode != 'MANUAL') {
            editingTimer = null; // lock edit UI when leaving MANUAL
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(15),
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 15),
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
                  const SizedBox(height: 4),
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

  Widget _buildDirectionHeader(String direction) {
    IconData icon;
    switch (direction) {
      case 'North':
        icon = Icons.north;
        break;
      case 'South':
        icon = Icons.south;
        break;
      case 'East':
        icon = Icons.east;
        break;
      case 'West':
        icon = Icons.west;
        break;
      default:
        icon = Icons.traffic;
    }

    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blue.shade700),
        const SizedBox(width: 8),
        Text(
          '$direction Direction',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildTimerControl(String direction, String phase, String label) {
    final timerId = '$direction-$phase';
    final isEditing = editingTimer == timerId;
    final isManualMode = selectedMode == 'MANUAL';

    return GestureDetector(
      onTap: isManualMode
          ? () {
              setState(() {
                editingTimer = timerId;
              });
            }
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isEditing ? Colors.blue.shade50 : (isManualMode ? Colors.white : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isEditing ? Colors.blue.shade400 : Colors.grey.shade300,
            width: isEditing ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            if (!isManualMode)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(Icons.lock, color: Colors.grey.shade400, size: 18),
              ),

            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: phase == 'red' ? Colors.red : Colors.green,
              ),
            ),
            const SizedBox(width: 10),

            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isManualMode ? Colors.black : Colors.grey.shade500,
                ),
              ),
            ),

            if (isManualMode && isEditing)
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        if (timerConfig[direction]![phase]! > 1) {
                          timerConfig[direction]![phase] = timerConfig[direction]![phase]! - 1;
                          hasChanges = true;
                        }
                      });
                    },
                    icon: const Icon(Icons.remove_circle, color: Colors.red, size: 24),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade300, width: 2),
                    ),
                    child: Text(
                      '${timerConfig[direction]![phase]}s',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        if (timerConfig[direction]![phase]! < 300) {
                          timerConfig[direction]![phase] = timerConfig[direction]![phase]! + 1;
                          hasChanges = true;
                        }
                      });
                    },
                    icon: const Icon(Icons.add_circle, color: Colors.green, size: 24),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isManualMode ? Colors.grey.shade100 : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${timerConfig[direction]![phase]}s',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isManualMode ? Colors.grey.shade700 : Colors.grey.shade400,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
