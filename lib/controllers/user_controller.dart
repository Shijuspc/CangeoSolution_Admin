import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UserController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController nameController = TextEditingController();
  var users = <Map<String, dynamic>>[].obs;
  var expandedUserId = ''.obs;

  @override
  void onInit() {
    fetchUsers();
    super.onInit();
  }

  void addUser() async {
    String name = nameController.text.trim();
    if (name.isNotEmpty) {
      DocumentReference userRef = _firestore.collection('users').doc();
      await userRef.set({'name': name});
      nameController.clear();
      fetchUsers();
    }
  }

  void fetchUsers() {
    _firestore.collection('users').snapshots().listen((querySnapshot) {
      users.value = querySnapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        return {'id': doc.id, ...data};
      }).toList();
    });
  }

  void deleteUser(String userId) async {
    await _firestore.collection('users').doc(userId).delete();
    fetchUsers();
  }
}
