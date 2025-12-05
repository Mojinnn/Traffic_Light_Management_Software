import 'package:first_flutter/data/constants.dart';
import 'package:first_flutter/data/notifiers.dart';
import 'package:first_flutter/views/pages/police/police_home.dart';
// import 'package:first_flutter/views/pages/home_page.dart';
import 'package:first_flutter/views/pages/profile_page.dart';
import 'package:first_flutter/views/pages/settings_page.dart';
import 'package:first_flutter/views/widgets/navbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// List<Widget> pages = [HomePage(), ProfilePage()];

// class WidgetTree extends StatelessWidget {
//   const WidgetTree({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Traffic Controller'),
//         centerTitle: true,
//         actions: [
//           IconButton(
//             onPressed: () async {
//               isDarkModeNotifier.value = !isDarkModeNotifier.value;
//               final SharedPreferences prefs =
//                   await SharedPreferences.getInstance();
//               await prefs.setBool(
//                 KConstant.themeModeKey,
//                 isDarkModeNotifier.value,
//               );
//             },
//             icon: ValueListenableBuilder(
//               valueListenable: isDarkModeNotifier,
//               builder: (context, isDarkMode, child) {
//                 if (isDarkMode) {
//                   return Icon(Icons.light_mode);
//                 } else {
//                   return Icon(Icons.dark_mode);
//                 }
//               },
//             ),
//           ),
//           IconButton(
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) {
//                     return SettingsPage(title: 'Settings');
//                   },
//                 ),
//               );
//             },
//             icon: Icon(Icons.settings),
//           ),
//         ],
//       ),

//       body: ValueListenableBuilder(
//         valueListenable: selectedPageNotifier,
//         builder: (context, selectedPage, child) {
//           return pages.elementAt(selectedPage);
//         },
//       ),
//       bottomNavigationBar: NavbarWidget(),
//     );
//   }
// }

List<Widget> pages = [PoliceHome(), ProfilePage()];

class PoliceWidgetTree extends StatelessWidget {
  const PoliceWidgetTree({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Traffic Controller'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () async {
              isDarkModeNotifier.value = !isDarkModeNotifier.value;
              final SharedPreferences prefs =
                  await SharedPreferences.getInstance();
              await prefs.setBool(
                KConstant.themeModeKey,
                isDarkModeNotifier.value,
              );
            },
            icon: ValueListenableBuilder(
              valueListenable: isDarkModeNotifier,
              builder: (context, isDarkMode, child) {
                return Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode);
              },
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsPage(title: 'Settings'),
                ),
              );
            },
            icon: Icon(Icons.settings),
          ),
        ],
      ),

      body: ValueListenableBuilder(
        valueListenable: selectedPageNotifier,
        builder: (context, selectedPage, child) {
          return pages[selectedPage];
        },
      ),

      bottomNavigationBar: NavbarWidget(),
    );
  }
}
