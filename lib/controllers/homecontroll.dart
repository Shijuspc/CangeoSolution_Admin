import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:liquid_progress_indicator_v2/liquid_progress_indicator.dart';

class HomeController extends GetxController {
  var users = <Map<String, dynamic>>[].obs;
// List of users
  var selectedUsers = <String>[].obs; // List of selected user IDs
  var allSelected = false.obs; // Observable boolean for "Select All" checkbox
  RxList<String> fileIds = <String>[].obs;
  RxString selectedFileId = ''.obs;
  RxList<String> files = <String>[].obs;
  var bottomBarData = {}.obs;
  RxBool isLoading = false.obs; // Add loading state
  final RxDouble uploadProgress = 0.0.obs; // Track upload progress

  @override
  void onInit() {
    fetchFileIds();
    fetchUsers();
    super.onInit();
  }

  void fetchUsers() {
    FirebaseFirestore.instance
        .collection('users')
        .snapshots()
        .listen((snapshot) {
      users.assignAll(snapshot.docs.map((doc) {
        var data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? 'Unknown',
          'path': data['path'] ?? 'No Video',
        };
      }).toList());

      users.refresh(); // ✅ Ensure UI refreshes instantly
    });
  }

  void toggleUserSelection(String userId) {
    if (selectedUsers.contains(userId)) {
      selectedUsers.remove(userId);
    } else {
      selectedUsers.add(userId);
    }
    selectedUsers.refresh(); // ✅ Force UI update
  }

  void toggleSelectAll() {
    allSelected.value = !allSelected.value;
    if (allSelected.value) {
      selectedUsers.assignAll(users.map((user) => user['id'] as String));
    } else {
      selectedUsers.clear();
    }
    selectedUsers.refresh(); // ✅ Instant UI update
  }

  Future<void> fetchFileIds() async {
    try {
      var querySnapshot =
          await FirebaseFirestore.instance.collection('uploadfiles').get();
      fileIds.assignAll(querySnapshot.docs.map((doc) => doc.id).toList());

      fileIds.refresh(); // ✅ Instant UI update
      await _updateFilesInFirestore();
    } catch (e) {
      print("Error fetching file IDs: $e");
    }
  }

  Future<void> fetchFileData(String fileId) async {
    isLoading.value = true; // Show loading state
    files.clear();
    files.refresh(); // Force UI update

    try {
      var doc = await FirebaseFirestore.instance
          .collection('uploadfiles')
          .doc(fileId)
          .get();
      if (doc.exists) {
        var data = doc['files'];
        if (data is String) {
          files.assignAll([data]);
        } else if (data is List) {
          files.assignAll(List<String>.from(data));
        } else {
          files.assignAll([]);
        }
      }
    } catch (e) {
      print("Error fetching file data: $e");
    }

    isLoading.value = false; // Hide loading state
    files.refresh(); // ✅ Ensure UI refreshes instantly
  }

  Future<void> deleteFile(int index) async {
    String fileUrl = files[index];

    try {
      // Delete from Firebase Storage
      await FirebaseStorage.instance.refFromURL(fileUrl).delete();

      // Remove file URL from Firestore array
      files.removeAt(index);
      await _updateFilesInFirestore();
    } catch (e) {
      print("Error deleting file: $e");
    }
  }

  Future<void> deleteAllFiles() async {
    if (selectedFileId.value.isEmpty) return;

    try {
      // Fetch document
      var docRef = FirebaseFirestore.instance
          .collection('uploadfiles')
          .doc(selectedFileId.value);
      var doc = await docRef.get();

      if (doc.exists) {
        // Extract files array
        List<dynamic> fileUrls = doc['files'] ?? [];

        // Delete each file from Firebase Storage
        for (String fileUrl in fileUrls) {
          try {
            await FirebaseStorage.instance.refFromURL(fileUrl).delete();
          } catch (e) {
            print("Error deleting file from storage: $e");
          }
        }

        // Delete Firestore document
        await docRef.delete();

        // Clear local data
        selectedFileId.value = "";
        files.clear();
        fileIds.removeWhere((id) => id == doc.id);

        print("Successfully deleted all files and document.");
      }
    } catch (e) {
      print("Error deleting all files: $e");
    }
  }

  Future<void> replaceFile(int index, File newFile) async {
    if (index < 0 || index >= files.length) return;

    try {
      // Observable progress value
      RxDouble progress = 0.0.obs;

      // Show progress dialog
      Get.dialog(
        Obx(() => AlertDialog(
              backgroundColor: Colors.white,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 100,
                    width: 100,
                    child: LiquidCircularProgressIndicator(
                      value: progress.value, // Dynamic progress
                      valueColor: AlwaysStoppedAnimation(Colors.redAccent),
                      backgroundColor: Colors.white,
                      borderColor: Colors.redAccent,
                      borderWidth: 2.0,
                      direction: Axis.vertical,
                      center: Text(
                        "${(progress.value * 100).toStringAsFixed(1)}%",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color.fromARGB(255, 255, 255, 255)),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Text("Uploading file..."),
                ],
              ),
            )),
        barrierDismissible: false,
      );

      String oldFileUrl = files[index];

      String fileExtension = newFile.path.split('.').last;
      String newFileName =
          "${DateTime.now().millisecondsSinceEpoch}.$fileExtension";
      String newFilePath = "uploads/${selectedFileId.value}/$newFileName";

      Reference ref = FirebaseStorage.instance.ref().child(newFilePath);
      UploadTask uploadTask = ref.putFile(newFile);

      // Track upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        double percent = snapshot.bytesTransferred / snapshot.totalBytes;
        progress.value = percent; // Update UI progress
      });

      TaskSnapshot snapshot = await uploadTask;
      String newFileUrl = await snapshot.ref.getDownloadURL();

      // Replace the file URL in Firestore
      files[index] = newFileUrl;

      // Delete old file from Firebase Storage
      await FirebaseStorage.instance.refFromURL(oldFileUrl).delete();

      await _updateFilesInFirestore();

      // Close progress dialog
      Get.back();
      Get.snackbar(
        "Success",
        "Upload successful!",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        margin: EdgeInsets.only(bottom: 20, left: 20, right: 20),
      );
    } catch (e) {
      print("Error replacing file: $e");
      Get.back(); // Close progress dialog in case of error
    }
  }

  Future<void> _updateFilesInFirestore() async {
    await FirebaseFirestore.instance
        .collection('uploadfiles')
        .doc(selectedFileId.value)
        .update({'files': files});
  }

  // Save Bottom Bar Settings
  Future<void> saveBottomBarSettings(Map<String, dynamic> data) async {
    if (selectedFileId.value.isEmpty) return;
    await FirebaseFirestore.instance
        .collection('uploadfiles')
        .doc(selectedFileId.value)
        .update({'bottombar': data});
    bottomBarData.value = data;
  }
}

// class MediaWidget extends StatefulWidget {
//   final String url;
//   MediaWidget({required this.url});

//   @override
//   _MediaWidgetState createState() => _MediaWidgetState();
// }

// class _MediaWidgetState extends State<MediaWidget> {
//   VideoPlayerController? _controller;
//   bool _isInitialized = false;
//   bool _showControls = true;
//   Timer? _hideTimer;

//   @override
//   void initState() {
//     super.initState();
//     if (widget.url.contains('.mp4')) {
//       _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
//         ..initialize().then((_) {
//           setState(() => _isInitialized = true);
//           _controller?.setLooping(true);
//           _startHideTimer();
//         }).catchError((error) {
//           print("Error initializing video: $error");
//         });
//     }
//   }

//   void _startHideTimer() {
//     _hideTimer?.cancel();
//     _hideTimer = Timer(Duration(seconds: 3), () {
//       setState(() {
//         _showControls = false;
//       });
//     });
//   }

//   @override
//   void dispose() {
//     _controller?.dispose();
//     _hideTimer?.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: () {
//         setState(() => _showControls = !_showControls);
//         if (_showControls) _startHideTimer();
//       },
//       child: widget.url.contains('.mp4')
//           ? _isInitialized
//               ? AspectRatio(
//                   aspectRatio:
//                       _controller!.value.aspectRatio, // Auto-adjust video
//                   child: Stack(
//                     alignment: Alignment.center,
//                     children: [
//                       VideoPlayerWidget(_controller!),
//                       if (_showControls)
//                         Positioned(
//                           bottom: 10,
//                           child: FloatingActionButton(
//                             onPressed: () {
//                               setState(() {
//                                 _controller!.value.isPlaying
//                                     ? _controller!.pause()
//                                     : _controller!.play();
//                               });
//                               _startHideTimer();
//                             },
//                             child: Icon(
//                               _controller!.value.isPlaying
//                                   ? Icons.pause
//                                   : Icons.play_arrow,
//                             ),
//                           ),
//                         ),
//                     ],
//                   ),
//                 )
//               : Center(child: CircularProgressIndicator())
//           : Image.network(
//               widget.url,
//               fit: BoxFit.cover,
//               loadingBuilder: (context, child, loadingProgress) =>
//                   loadingProgress == null
//                       ? child
//                       : Center(child: CircularProgressIndicator()),
//               errorBuilder: (context, error, stackTrace) =>
//                   Icon(Icons.broken_image, size: 50, color: Colors.red),
//             ),
//     );
//   }
// }
