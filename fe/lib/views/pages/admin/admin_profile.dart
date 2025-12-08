import 'package:first_flutter/data/notifiers.dart';
import 'package:first_flutter/views/pages/welcome_page.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 50.0,
          backgroundImage: AssetImage('assets/images/avatar-an-danh-1.webp'),
        ),
        ListTile(
          title: Text('Logout'),
          onTap: () {
            selectedPageNotifier.value = 0;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) {
                  return WelcomePage();
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
