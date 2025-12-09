import 'package:first_flutter/models/notify_model.dart';
import 'package:first_flutter/services/notify_service.dart';
import 'package:flutter/material.dart';

class PoliceNotify extends StatefulWidget {
  const PoliceNotify({super.key});

  @override
  State<PoliceNotify> createState() => _PoliceNotifyState();
}

class _PoliceNotifyState extends State<PoliceNotify> {
  final NotifyService notifyService = NotifyService();
  final List<NotifyModel> notifyList = [];

  @override
  void initState() {
    super.initState();
    // notifyService.startMockNotification(); // 👉 Backend giả
    // notifyService.stream.listen((notify) {
    //   setState(() {
    //     notifyList.insert(0, notify); // push lên đầu danh sách
    //   });
    // });
  }

  @override
  void dispose() {
    notifyService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notifications")),
      body: notifyList.isEmpty
          ? const Center(child: Text("No notifications yet"))
          : ListView.builder(
              itemCount: notifyList.length,
              itemBuilder: (context, index) {
                final item = notifyList[index];
                return Card(
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    leading: const Icon(Icons.notifications),
                    title: Text(item.title),
                    subtitle: Text(item.message),
                    trailing: Text(
                      "${item.timestamp.hour}:${item.timestamp.minute.toString().padLeft(2, "0")}",
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                );
              },
            ),
    );
  }
}