import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'screen/nav_screen.dart';
import 'screen/splash_screen.dart';
import 'screen/user_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.redAccent, // Change to your desired color
            elevation: 3,
            shadowColor: Colors.black26,
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
            iconTheme: IconThemeData(color: Colors.white), // Icons color
          ),
          scaffoldBackgroundColor: Colors.white),
      initialRoute: '/splash',
      getPages: [
        GetPage(name: '/splash', page: () => SplashScreen()),
        //GetPage(name: '/home', page: () => HomeScreen()),
        GetPage(name: '/nav', page: () => NavScreen()),
        GetPage(name: '/user', page: () => UserScreen()),
      ],
    );
  }
}
