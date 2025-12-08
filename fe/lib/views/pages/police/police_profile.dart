import 'package:first_flutter/data/notifiers.dart';
import 'package:first_flutter/data/auth_service.dart';
import 'package:first_flutter/views/pages/welcome_page.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Lấy thông tin user
    String fullName = "";
    if (AuthService.currentUser != null) {
      fullName =
          "${AuthService.currentUser!.firstname ?? ""} ${AuthService.currentUser!.lastname ?? ""}".trim();
    }

    return Column(
      children: [
        const SizedBox(height: 20),
        CircleAvatar(
          radius: 50.0,
          backgroundImage:
              const AssetImage('assets/images/avatar-an-danh-1.webp'),
        ),
        const SizedBox(height: 10.0),
        // Tên đầy đủ hiển thị dưới ảnh đại diện
        Text(
          fullName.isNotEmpty ? fullName : "Guest",
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20.0),
        // Logout
        ListTile(
          title: const Text('Logout'),
          onTap: () {
            selectedPageNotifier.value = 0;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) {
                  return const WelcomePage();
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
