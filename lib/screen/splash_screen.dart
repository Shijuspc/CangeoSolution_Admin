import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/splash_controller.dart';

class SplashScreen extends StatelessWidget {
  final SplashController controller = Get.put(SplashController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 250, child: Image.asset("images/logo.png"))
            // Icon(Icons.flash_on, size: 100, color: Colors.white),
            // SizedBox(height: 20),
            // Text(
            //   "Cangeo Solution",
            //   style: TextStyle(
            //       fontSize: 24,
            //       color: Colors.white,
            //       fontWeight: FontWeight.bold),
            // ),
          ],
        ),
      ),
    );
  }
}
