// import 'package:first_flutter/data/constants.dart';
// import 'package:first_flutter/views/pages/course_page.dart';
// import 'package:first_flutter/views/widgets/container_widget.dart';
// import 'package:first_flutter/views/widgets/hero_widget.dart';
// import 'package:flutter/material.dart';

// class HomePage extends StatelessWidget {
//   const HomePage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     List<String> generateList = [
//       KValue.keyConCept,
//       KValue.basicLayout,
//       KValue.cleanUI,
//       KValue.fixBug,
//     ];
//     return SingleChildScrollView(
//       child: Padding(
//         padding: const EdgeInsets.all(20.0),
//         child: Column(
//           children: [
//             HeroWidget(title: 'Home', nextPage: CoursePage(),),
//             ...List.generate(generateList.length, (index) {
//               return ContainerWidget(
//                 title: generateList.elementAt(index),
//                 description: 'This is a description',
//               );
//             }),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import '../../data/auth_service.dart';
import 'viewer/viewer_home.dart';
import 'police/police_home.dart';
import 'admin/admin_home.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;

    if (user == null) {
      return const Center(child: Text("Not logged in"));
    }

    switch (user.role) {
      case "viewer":
        return const ViewerHome();
      case "police":
        return const PoliceHome();
      case "admin":
        return const AdminHome();
      default:
        return const Center(child: Text("Unknown role"));
    }
  }
}
