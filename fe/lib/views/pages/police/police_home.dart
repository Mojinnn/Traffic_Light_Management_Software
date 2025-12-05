import 'package:first_flutter/views/widgets/container_widget.dart';
import 'package:first_flutter/views/widgets/hero_widget.dart';
import 'package:flutter/material.dart';

class PoliceHome extends StatelessWidget {
  const PoliceHome({super.key});

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
      "Police Functions": [
        {"title": "Receive Notification", "desc": "Receive alerts from admin"},
        {
          "title": "Modify Light Counter",
          "desc": "Adjust traffic light timers",
        },
      ],
      // "Admin Functions": [
      //   {"title": "Login", "desc": "Admin authentication"},
      //   {"title": "Stream Camera", "desc": "View live camera footage"},
      //   {
      //     "title": "Monitor Traffic Density",
      //     "desc": "Monitor congestion levels",
      //   },
      //   {"title": "Send Notification", "desc": "Alert police when needed"},
      //   {
      //     "title": "Display Light Counter Value",
      //     "desc": "View current traffic light timer",
      //   },
      //   {"title": "Verify Login", "desc": "Verify user authentication"},
      //   {"title": "Logout", "desc": "Sign out"},
      // ],
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
