import 'package:first_flutter/views/widgets/container_widget.dart';
import 'package:first_flutter/views/widgets/hero_widget.dart';
import 'package:flutter/material.dart';

class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

  @override
  Widget build(BuildContext context) {
    final Map<String, List<Map<String, String>>> featureMap = {
      // "Viewer Functions": [
      //   {"title": "Register", "desc": "Create a new account"},
      //   {"title": "Login", "desc": "Access the system"},
      //   {
      //     "title": "View Traffic Density",
      //     "desc": "See real-time traffic density",
      //   },
      //   {"title": "Logout", "desc": "Sign out from the system"},
      // ],
      // "Police Functions": [
      //   {"title": "Login", "desc": "Access police dashboard"},
      //   {"title": "View Traffic Density", "desc": "Monitor real-time traffic"},
      //   {"title": "Receive Notification", "desc": "Receive alerts from admin"},
      //   {
      //     "title": "Modify Light Counter",
      //     "desc": "Adjust traffic light timers",
      //   },
      //   {"title": "Logout", "desc": "Sign out"},
      // ],
      "Admin Functions": [
        {"title": "Stream Camera", "desc": "View live camera footage"},
        {
          "title": "Monitor Traffic Density",
          "desc": "Monitor congestion levels",
        },
        {"title": "Send Notification", "desc": "Alert police when needed"},
        {
          "title": "Display Light Counter Value",
          "desc": "View current traffic light timer",
        },
      ],
    };

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HeroWidget(title: 'Home', nextPage: null),

            ...featureMap.entries.map((section) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    section.key,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),

                  ...section.value.map((feature) {
                    return ContainerWidget(
                      title: feature["title"]!,
                      description: feature["desc"]!,
                    );
                  }),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
