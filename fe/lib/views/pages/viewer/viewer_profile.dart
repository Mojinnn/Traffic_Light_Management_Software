import 'package:first_flutter/data/notifiers.dart';
import 'package:first_flutter/data/auth_service.dart'; // dùng currentUser nếu có
import 'package:first_flutter/views/pages/viewer/viewer_change_pw.dart';
import 'package:first_flutter/views/pages/welcome_page.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Lấy thông tin user
    // Giả sử bạn lưu firstname + lastname trong AuthService.currentUser
    String fullName = "";
    if (AuthService.currentUser != null) {
      // Nếu bạn có lưu firstname và lastname trong currentUser
      fullName = "${AuthService.currentUser!.firstname} ${AuthService.currentUser!.lastname}";
    }

    return Column(
      children: [
        const SizedBox(height: 20),
        CircleAvatar(
          radius: 50.0,
          backgroundImage: const AssetImage('assets/images/avatar-an-danh-1.webp'),
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
        ListTile(
          title: const Text('Change Password'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) {
                  return ChangePassword();
                },
              ),
            );
          },
        ),
        const SizedBox(height: 10.0),
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
