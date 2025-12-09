// import 'package:first_flutter/data/constants.dart';
// import 'package:first_flutter/data/notifiers.dart';
// import 'package:first_flutter/views/pages/welcome_page.dart';
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// void main() {
//   runApp(const MyApp());
// }

// // Material app (statefull)
// // Scaffold
// // App titile
// // Bottom Navigation bar

// // Statefull -> can refresh
// // Stateless -> can not refresh
// // Setstate -> to refresh ...

// class MyApp extends StatefulWidget {
//   const MyApp({super.key});

//   @override
//   State<MyApp> createState() => _MyAppState();
// }

// class _MyAppState extends State<MyApp> {
//   @override
//   void initState() {
//     initThemeMode();
//     super.initState();
//   }

//   void initThemeMode() async {
//     final SharedPreferences prefs = await SharedPreferences.getInstance();
//     final bool? repeat = prefs.getBool(KConstant.themeModeKey);
//     isDarkModeNotifier.value = repeat ?? false;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return ValueListenableBuilder(
//       valueListenable: isDarkModeNotifier,
//       builder: (context, isDarkMode, child) {
//         return MaterialApp(
//           // title: Text('Traffic Controller'),
//           debugShowCheckedModeBanner: false,
//           theme: ThemeData(
//             colorScheme: ColorScheme.fromSeed(
//               seedColor: Colors.teal,
//               brightness: isDarkMode ? Brightness.dark : Brightness.light,
//             ),
//           ),
//           home: WelcomePage(),
//         );
//       },
//     );
//   }
// }

// ============================================
// 1. MAIN.DART - Khởi tạo FeatureService
// ============================================
import 'package:first_flutter/data/constants.dart';
import 'package:first_flutter/data/notifiers.dart';
import 'package:first_flutter/services/future_service.dart';
import 'package:first_flutter/services/notify_service.dart';
import 'package:first_flutter/views/pages/welcome_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  // QUAN TRỌNG: Phải có dòng này để khởi tạo async trong main
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo FeatureService trước khi chạy app
  await FeatureService().initialize();
  NotifyService().startMockNotification();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    initThemeMode();
    super.initState();
  }

  void initThemeMode() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool? repeat = prefs.getBool(KConstant.themeModeKey);
    isDarkModeNotifier.value = repeat ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: isDarkModeNotifier,
      builder: (context, isDarkMode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.teal,
              brightness: isDarkMode ? Brightness.dark : Brightness.light,
            ),
          ),
          home: WelcomePage(),
        );
      },
    );
  }
}