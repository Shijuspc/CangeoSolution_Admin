import 'package:get/get.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    navigateToHome();
  }

  void navigateToHome() async {
    await Future.delayed(Duration(seconds: 3));
    Get.offNamed('/nav');
  }
}
