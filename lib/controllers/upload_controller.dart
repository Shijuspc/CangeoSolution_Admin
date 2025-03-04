import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:liquid_progress_indicator_v2/liquid_progress_indicator.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:video_player/video_player.dart';

class UploadController extends GetxController {
  var selectedScreenIndex = 1.obs;
  RxList<Map<String, dynamic>> users = <Map<String, dynamic>>[].obs;
  RxList<String> selectedUsers = <String>[].obs;
  RxMap<int, File> selectedFiles = <int, File>{}.obs;
  var allSelected = false.obs;
  var isLoading = false.obs;
  RxList<String> usersWithUploads = <String>[].obs;
  RxList<String> filesList = <String>[].obs;
  RxInt fileCount = 0.obs;
  RxString popupTitle = ''.obs;
  RxString popupName = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchUsers();
  }

  final Map<String, Color> colorMap = {
    'Red': Colors.red,
    'Blue': Colors.blue,
    'Green': Colors.green,
    'Yellow': Colors.yellow,
    'Black': Colors.black,
    'White': Colors.white,
    'Grey': Colors.grey,
    'Purple': Colors.purple,
    'Orange': Colors.orange,
    'Pink': Colors.pink,
    'Brown': Colors.brown,
    'Cyan': Colors.cyan,
    'Teal': Colors.teal,
  };

  void fetchUsers() {
    FirebaseFirestore.instance
        .collection('users')
        .snapshots()
        .listen((snapshot) {
      users.assignAll(snapshot.docs.map((doc) {
        var data = doc.data();
        return {
          'id': doc.id,
          'name': data.containsKey('name')
              ? data['name']
              : 'Unknown', // Default name
          'title': data.containsKey('title')
              ? data['title']
              : 'No Title', // Default title
        };
      }).toList());
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

  Future<void> uploadPickFiles(int index) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'mp4', 'mov', 'avi', 'gif'],
    );

    if (result != null && result.files.isNotEmpty) {
      selectedFiles[index] = File(result.files.first.path!);
      selectedFiles.refresh();
    }
  }

  List<dynamic> getBottomBar(Map<String, dynamic> map) {
    return map['bottombar'] ?? [];
  }

  void showUserPopup(String userId) async {
    isLoading.value = true;

    try {
      var userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        var userData = userDoc.data();
        if (userData != null) {
          String title = userData['title'] ?? 'No Title';
          String name = userData['name'] ?? 'No Name';
          List<dynamic> files = userData['files'] ?? [];

          filesList.assignAll(files.map((file) => file.toString()).toList());
          fileCount.value = files.length;
          popupTitle.value = title;
          popupName.value = name;
        }
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to fetch user data");
    } finally {
      isLoading.value = false;
      Get.dialog(buildUserPopup(userId)); // ✅ Pass userId properly
    }
  }

  Future<void> replaceFile(int index, File newFile, String userId) async {
    if (index < 0 || index >= filesList.length) return;

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
                            color: Colors.white),
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

      String oldFileUrl = filesList[index]; // Get old file URL

      // Step 1: Upload New File
      String fileExtension = newFile.path.split('.').last;
      String newFileName =
          "${DateTime.now().millisecondsSinceEpoch}.$fileExtension";
      String newFilePath = "uploads/$newFileName";

      Reference ref = FirebaseStorage.instance.ref().child(newFilePath);
      UploadTask uploadTask = ref.putFile(newFile);

      // Track upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        double percent = snapshot.bytesTransferred / snapshot.totalBytes;
        progress.value = percent; // Update UI progress
      });

      TaskSnapshot snapshot = await uploadTask;
      String newFileUrl = await snapshot.ref.getDownloadURL();

      // Step 2: Replace Old File URL in Firestore for the Current User
      DocumentReference userDoc =
          FirebaseFirestore.instance.collection('users').doc(userId);
      var userSnapshot = await userDoc.get();

      if (!userSnapshot.exists) {
        throw "User document not found!";
      }

      List<String> userFiles = List<String>.from(userSnapshot['files'] ?? []);

      if (index < userFiles.length) {
        userFiles[index] = newFileUrl; // Replace old file with new one
      }

      await userDoc.update({'files': userFiles}); // Update Firestore

      // Step 3: Check if Old File is Still Used
      bool isFileStillUsed = false;

      var usersSnapshot =
          await FirebaseFirestore.instance.collection('users').get();

      for (var doc in usersSnapshot.docs) {
        List<String> files = List<String>.from(doc['files'] ?? []);
        if (files.contains(oldFileUrl)) {
          isFileStillUsed = true;
          break;
        }
      }

      // Step 4: Delete Old File from Storage if Unused
      if (!isFileStillUsed) {
        try {
          await FirebaseStorage.instance.refFromURL(oldFileUrl).delete();
        } catch (e) {
          print("Error deleting file: $e");
        }
      }

      // Update local file list
      filesList[index] = newFileUrl;

      // Close progress dialog
      Get.back();
    } catch (e) {
      print("Error replacing file: $e");
      Get.back(); // Close progress dialog in case of error
    }
  }

  Future<void> deleteFile(int index, String userId) async {
    try {
      // Get Firestore reference for the current user
      DocumentReference userDoc =
          FirebaseFirestore.instance.collection('users').doc(userId);

      // Fetch the user's current file list
      DocumentSnapshot userSnapshot = await userDoc.get();
      if (!userSnapshot.exists) return;

      List<String> userFiles = List<String>.from(userSnapshot['files'] ?? []);
      if (index < 0 || index >= userFiles.length) return;

      String fileUrlToDelete = userFiles[index];

      // Remove the file URL from the user's list
      userFiles.removeAt(index);

      // Update Firestore with the new file list
      await userDoc.update({'files': userFiles});

      // Check if any other user is still using this file
      QuerySnapshot allUsersSnapshot =
          await FirebaseFirestore.instance.collection('users').get();

      bool isFileUsedByOthers = allUsersSnapshot.docs.any((doc) {
        List<String> otherUserFiles = List<String>.from(doc['files'] ?? []);
        return otherUserFiles.contains(fileUrlToDelete);
      });

      // If no other user is using the file, delete it from Firebase Storage
      if (!isFileUsedByOthers) {
        await FirebaseStorage.instance.refFromURL(fileUrlToDelete).delete();
      }
      Get.back();
      Get.snackbar("Success", "File deleted successfully!",
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar("Error", "Failed to delete file: ${e.toString()}",
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> uploadData({
    required String title,
    required String bottomBarText,
    required double transparency,
    required Color bgColor,
    required Color textColor,
    required bool isBottomBarVisible,
  }) async {
    if (selectedFiles.isEmpty ||
        selectedUsers.isEmpty ||
        title.isEmpty ||
        bottomBarText.isEmpty) {
      Get.snackbar(
        "Error",
        "Please Select Files, Users and Enter Title, Bottom Bar Text .",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color.fromARGB(255, 240, 64, 52),
        colorText: Colors.white,
        margin: EdgeInsets.only(bottom: 20, left: 20, right: 20),
      );
      return;
    }

    try {
      RxDouble progress = 0.0.obs; // Observable progress value

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
                            color: Colors.black),
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

      Map<String, String> newFileUrls = {}; // Store newly uploaded file URLs

      // Step 1: Upload files to Firebase Storage
      for (var file in selectedFiles.values) {
        String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
        String fileExtension = file.path.split('.').last;
        String fileName = '$timestamp.$fileExtension';
        Reference ref =
            FirebaseStorage.instance.ref().child('uploads/$fileName');
        UploadTask uploadTask = ref.putFile(file);

        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          progress.value = snapshot.bytesTransferred / snapshot.totalBytes;
        });

        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();
        newFileUrls[fileName] = downloadUrl;
      }

      List<String> allOldFiles = []; // Collect all old files for cleanup later

      // Step 2: Assign new URLs to each user & track old files
      for (var userId in selectedUsers) {
        DocumentReference userDoc =
            FirebaseFirestore.instance.collection('users').doc(userId);
        List<String> existingFiles = [];

        var userSnapshot = await userDoc.get();
        if (userSnapshot.exists) {
          var userData = userSnapshot.data() as Map<String, dynamic>?;
          if (userData != null && userData.containsKey('files')) {
            existingFiles = List<String>.from(userData['files']);
          }
        }

        allOldFiles.addAll(existingFiles); // Collect old file URLs

        // Replace old files with new uploaded ones
        List<String> updatedFileUrls = newFileUrls.values.toList();

        // Convert colors to string names
        String bgColorName = colorMap.entries
            .firstWhere((entry) => entry.value == bgColor,
                orElse: () => MapEntry('Black', Colors.black))
            .key;
        String textColorName = colorMap.entries
            .firstWhere((entry) => entry.value == textColor,
                orElse: () => MapEntry('White', Colors.white))
            .key;

        await userDoc.set({
          'files': updatedFileUrls,
          'title': title,
          'bottombar': {
            'show': isBottomBarVisible,
            'bottomBarText': bottomBarText,
            'transparency': transparency,
            'bgColor': bgColorName, // Store color name
            'textColor': textColorName, // Store color name
          }
        }, SetOptions(merge: true));
      }

      // Step 3: Check if old files are still used before deleting
      Set<String> usedFiles = {}; // Store URLs still in use

      var usersSnapshot =
          await FirebaseFirestore.instance.collection('users').get();
      for (var userDoc in usersSnapshot.docs) {
        var userData = userDoc.data();
        if (userData.containsKey('files')) {
          usedFiles.addAll(List<String>.from(userData['files']));
        }
      }

      // Step 4: Delete unused files from Firebase Storage
      for (String oldFile in allOldFiles.toSet()) {
        if (!usedFiles.contains(oldFile)) {
          try {
            await FirebaseStorage.instance.refFromURL(oldFile).delete();
          } catch (e) {
            print("Error deleting file: $e");
          }
        }
      }

      Get.back();
      selectedFiles.clear();

      selectedUsers.clear();

      Get.snackbar("Success", "Upload successful!",
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.back();
      Get.snackbar("Error", "Upload failed: ${e.toString()}",
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> updateBottomBarStatus(String userId, bool isEnabled) async {
    try {
      // Reference to the user's Firestore document
      DocumentReference userDoc =
          FirebaseFirestore.instance.collection('users').doc(userId);

      // Update the 'bottombar.show' field
      await userDoc.set({
        'bottombar': {'show': isEnabled}
      }, SetOptions(merge: true));

      Get.snackbar("Success", "Bottom Bar updated successfully!",
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar("Error", "Failed to update Bottom Bar: ${e.toString()}",
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Widget buildUserPopup(String userId) {
    RxBool isEnabled = false.obs; // Observable to store bottom bar status

    // Fetch current bottom bar status from Firestore
    Future<void> fetchBottomBarStatus() async {
      try {
        DocumentSnapshot snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        if (snapshot.exists && snapshot.data() != null) {
          Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;
          if (data?['bottombar']?['show'] != null) {
            isEnabled.value = data!['bottombar']['show']; // Set initial value
          }
        }
      } catch (e) {
        print("Error fetching bottom bar status: $e");
      }
    }

    // Call function to fetch status when the dialog opens
    fetchBottomBarStatus();

    return Obx(() {
      return AlertDialog(
        backgroundColor: Colors.white,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Row(
              children: [
                Text(
                  "Name : ",
                  style: TextStyle(
                      fontSize: 20,
                      color: Colors.grey,
                      fontWeight: FontWeight.w400),
                ),
                Text(
                  popupName.value,
                  style: TextStyle(
                      fontSize: 20,
                      color: Colors.black,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  "Title : ",
                  style: TextStyle(
                      fontSize: 20,
                      color: Colors.grey,
                      fontWeight: FontWeight.w400),
                ),
                Text(
                  popupTitle.value,
                  style: TextStyle(
                      fontSize: 20,
                      color: Colors.black,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                constraints: BoxConstraints(
                    minHeight: 300, maxHeight: 450, minWidth: double.maxFinite),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.redAccent, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                        color: const Color.fromARGB(107, 0, 0, 0),
                        blurRadius: 5.0)
                  ],
                  borderRadius: BorderRadius.circular(5),
                  color: Colors.white,
                ),
                child: fileCount.value == 0
                    ? Center(child: Text("No Media Available"))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (fileCount.value == 1)
                            Expanded(
                                child: _buildMediaWithActions(
                                    filesList[0], 0, userId,
                                    isFullWidth: true)),
                          if (fileCount.value == 2)
                            Expanded(
                              child: Row(
                                children: [
                                  Expanded(
                                      child: _buildMediaWithActions(
                                          filesList[0], 0, userId)),
                                  SizedBox(width: 1),
                                  Expanded(
                                      child: _buildMediaWithActions(
                                          filesList[1], 1, userId)),
                                ],
                              ),
                            ),
                          if (fileCount.value == 3) ...[
                            Expanded(
                              child: Row(
                                children: [
                                  Expanded(
                                      child: _buildMediaWithActions(
                                          filesList[0], 0, userId)),
                                  SizedBox(width: 1),
                                  Expanded(
                                      child: _buildMediaWithActions(
                                          filesList[1], 1, userId)),
                                ],
                              ),
                            ),
                            SizedBox(height: 1),
                            Expanded(
                                child: _buildMediaWithActions(
                                    filesList[2], 2, userId,
                                    isFullWidth: true)),
                          ],
                          if (fileCount.value == 4) ...[
                            Expanded(
                              child: Row(
                                children: [
                                  Expanded(
                                      child: _buildMediaWithActions(
                                          filesList[0], 0, userId)),
                                  SizedBox(width: 1),
                                  Expanded(
                                      child: _buildMediaWithActions(
                                          filesList[1], 1, userId)),
                                ],
                              ),
                            ),
                            SizedBox(height: 1),
                            Expanded(
                              child: Row(
                                children: [
                                  Expanded(
                                      child: _buildMediaWithActions(
                                          filesList[2], 2, userId)),
                                  SizedBox(width: 1),
                                  Expanded(
                                      child: _buildMediaWithActions(
                                          filesList[3], 3, userId)),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
              ),
              SwitchListTile(
                activeColor: Colors.redAccent,
                title: Text(
                  "Enable Bottom Bar",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                value: isEnabled.value,
                onChanged: (value) {
                  isEnabled.value = value;
                  updateBottomBarStatus(userId, value);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text("Close",
                style: TextStyle(fontSize: 16, color: Colors.redAccent)),
          ),
        ],
      );
    });
  }
}

Widget _buildMediaWithActions(String fileUrl, int index, String userId,
    {bool isFullWidth = false}) {
  final UploadController controller = Get.find<UploadController>();
  return Stack(
    children: [
      Container(
        constraints: BoxConstraints(
          maxWidth: isFullWidth ? double.infinity : double.minPositive,
          minHeight: 100,
        ),
        child: MediaWidget(url: fileUrl),
      ),
      Positioned(
        top: 5,
        right: 5,
        child: Container(
          color: Colors.black54,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red, size: 30),
                onPressed: () async {
                  bool confirmDelete = await showDialog(
                    context: Get.overlayContext!,
                    builder: (context) => AlertDialog(
                      title: Text("Confirm Delete"),
                      content:
                          Text("Are you sure you want to delete this file?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text("Cancel",
                              style:
                                  TextStyle(fontSize: 16, color: Colors.black)),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text("Delete",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16)),
                        )
                      ],
                    ),
                  );

                  if (confirmDelete) {
                    await controller.deleteFile(index, userId);
                  }
                },
              ),
              IconButton(
                icon: Icon(Icons.cloud_upload_outlined,
                    color: Colors.blue, size: 30),
                onPressed: () async {
                  FilePickerResult? result =
                      await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['jpg', 'jpeg', 'png', 'mp4', 'mov'],
                  );

                  if (result != null) {
                    File file = File(result.files.single.path!);
                    await controller.replaceFile(index, file, userId);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

class MediaWidget extends StatelessWidget {
  final String url;
  MediaWidget({required this.url});

  @override
  Widget build(BuildContext context) {
    print("Video URL: $url");
    return url.contains('.mp4') || url.contains('.mkv')
        ? VideoPlayerScreen(
            videoUrl: url) // Each instance has its own controller
        : Image.network(
            url,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: LoadingAnimationWidget.inkDrop(
                  color: Colors.blue,
                  size: 50,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Icon(Icons.broken_image, size: 50, color: Colors.red);
            },
          );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerScreen({super.key, required this.videoUrl});

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        setState(() {
          _isInitialized = true;
        });
        _controller.setLooping(true);
      }).catchError((error) {
        print("Error initializing video: $error");
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _isInitialized
        ? Stack(
            alignment: Alignment.center,
            children: [
              AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              ),
              IconButton(
                icon: Icon(
                  _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 30,
                ),
                onPressed: () {
                  setState(() {
                    _controller.value.isPlaying
                        ? _controller.pause()
                        : _controller.play();
                  });
                },
              ),
            ],
          )
        : Center(
            child: LoadingAnimationWidget.inkDrop(
              color: Colors.blue,
              size: 50,
            ),
          );
  }
}

class BottomBarSettings extends StatefulWidget {
  final String userId;
  BottomBarSettings({required this.userId});

  @override
  _BottomBarSettingsState createState() => _BottomBarSettingsState();
}

class _BottomBarSettingsState extends State<BottomBarSettings> {
  TextEditingController _textController = TextEditingController();
  bool _isEnabled = false;
  Color _bgColor = Colors.black;
  Color _textColor = Colors.white;
  double _transparency = 50.0;

  final Map<String, Color> colorMap = {
    'Red': Colors.red,
    'Blue': Colors.blue,
    'Green': Colors.green,
    'Yellow': Colors.yellow,
    'Black': Colors.black,
    'White': Colors.white,
    'Grey': Colors.grey,
    'Purple': Colors.purple,
    'Orange': Colors.orange,
    'Pink': Colors.pink,
    'Brown': Colors.brown,
    'Cyan': Colors.cyan,
    'Teal': Colors.teal,
  };

  @override
  void initState() {
    super.initState();
    _loadBottomBarData(widget.userId);
  }

  @override
  void didUpdateWidget(covariant BottomBarSettings oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _loadBottomBarData(widget.userId);
    }
  }

  Future<void> _loadBottomBarData(String fileId) async {
    if (fileId.isEmpty || fileId == "none") return;

    DocumentSnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
        .instance
        .collection('uploadfiles')
        .doc(fileId)
        .get();

    if (snapshot.exists && snapshot.data() != null) {
      Map<String, dynamic> data = snapshot.data()!['bottombar'] ?? {};

      setState(() {
        _isEnabled = data['show'] ?? false;
        _textController.text = data['bottomBarText'] ?? '';
        _transparency = (data['transparency'] ?? 50).toDouble();
        _bgColor = getColorFromName(data['bgColor']) ?? Colors.black;
        _textColor = getColorFromName(data['textColor']) ?? Colors.white;
      });
    }
  }

  Future<void> _saveBottomBarData(String fileId) async {
    if (fileId.isEmpty || fileId == "none") return;

    await FirebaseFirestore.instance.collection('uploadfiles').doc(fileId).set({
      'bottombar': {
        'show': _isEnabled,
        'bottomBarText': _textController.text,
        'transparency': _transparency,
        'bgColor': getColorName(_bgColor),
        'textColor': getColorName(_textColor),
      }
    }, SetOptions(merge: true));

    Get.snackbar("Success", "Bottom Bar settings updated!",
        snackPosition: SnackPosition.BOTTOM);
  }

  Color? getColorFromName(String? colorName) {
    if (colorName == null) return null;
    return colorMap[colorName] ?? Colors.black;
  }

  String getColorName(Color color) {
    return colorMap.entries
        .firstWhere(
          (entry) => entry.value == color,
          orElse: () => MapEntry('black', Colors.black),
        )
        .key;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          border: Border.all(color: Colors.redAccent, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(107, 0, 0, 0),
              blurRadius: 5.0,
            )
          ],
          borderRadius: BorderRadius.circular(20),
          color: Colors.white),
      margin: EdgeInsets.all(20),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 25, right: 10, top: 20),
            child: SwitchListTile(
              activeColor: Colors.redAccent,
              title: Text(
                "Enable Bottom Bar",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              value: _isEnabled,
              onChanged: (value) {
                setState(() {
                  _isEnabled = value;
                });
              },
            ),
          ),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(10),
            child: Column(
              children: [
                AnimatedOpacity(
                  opacity: _isEnabled ? _transparency / 100 : 0.0,
                  duration: Duration(milliseconds: 300),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 5, horizontal: 30),
                    margin: EdgeInsets.symmetric(vertical: 10, horizontal: 25),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: _bgColor.withOpacity(_transparency / 100),
                    ),
                    child: TextField(
                      controller: _textController,
                      style: TextStyle(
                        color: _textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Enter text here',
                          hintStyle: TextStyle(
                            fontSize: 20,
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                          )),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Row(
                    children: [
                      Text(
                        'Transparency:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Expanded(
                        child: Slider(
                          thumbColor: Colors.redAccent,
                          activeColor: Colors.redAccent,
                          min: 0,
                          max: 100,
                          value: _transparency,
                          onChanged: (newValue) {
                            setState(() {
                              _transparency = newValue;
                            });
                          },
                        ),
                      ),
                      Text('${_transparency.toStringAsFixed(0)}%')
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Row(
                      children: [
                        Text(
                          "Background :",
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w500),
                        ),
                        SizedBox(
                          width: 20,
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Color.fromARGB(79, 0, 0, 0),
                                blurRadius: 5.0,
                              )
                            ],
                            border:
                                Border.all(color: Colors.redAccent, width: 1.5),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton2<Color>(
                              value: _bgColor,
                              items: colorMap.entries.map((entry) {
                                return DropdownMenuItem<Color>(
                                  value: entry.value,
                                  child: Text(
                                    entry.key,
                                    style: TextStyle(fontSize: 20),
                                  ),
                                );
                              }).toList(),
                              onChanged: (color) {
                                setState(() {
                                  _bgColor = color!;
                                });
                              },
                              buttonStyleData: ButtonStyleData(
                                padding: EdgeInsets.symmetric(horizontal: 5),
                                height: 30,
                                width: 150,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: Colors.white,
                                ),
                              ),
                              iconStyleData: IconStyleData(
                                icon: Icon(Icons.arrow_drop_down,
                                    color: Colors.redAccent),
                                iconSize: 35,
                              ),
                              dropdownStyleData: DropdownStyleData(
                                maxHeight: 200,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: Colors.white,
                                ),
                              ),
                              menuItemStyleData: MenuItemStyleData(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          "Text :",
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w500),
                        ),
                        SizedBox(
                          width: 20,
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Color.fromARGB(79, 0, 0, 0),
                                blurRadius: 5.0,
                              )
                            ],
                            border:
                                Border.all(color: Colors.redAccent, width: 1.5),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton2<Color>(
                              value: _textColor,
                              items: colorMap.entries.map((entry) {
                                return DropdownMenuItem<Color>(
                                  value: entry.value,
                                  child: Text(
                                    entry.key,
                                    style: TextStyle(fontSize: 20),
                                  ),
                                );
                              }).toList(),
                              onChanged: (color) {
                                setState(() {
                                  _textColor = color!;
                                });
                              },
                              buttonStyleData: ButtonStyleData(
                                padding: EdgeInsets.symmetric(horizontal: 5),
                                height: 30,
                                width: 150,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: Colors.white,
                                ),
                              ),
                              iconStyleData: IconStyleData(
                                icon: Icon(Icons.arrow_drop_down,
                                    color: Colors.redAccent),
                                iconSize: 35,
                              ),
                              dropdownStyleData: DropdownStyleData(
                                maxHeight: 200,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: Colors.white,
                                ),
                              ),
                              menuItemStyleData: MenuItemStyleData(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          SizedBox(
            width: 200,
            child: ElevatedButton(
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () => _saveBottomBarData(widget.userId),
              child: Text(
                "Save",
                style: TextStyle(color: Colors.white, fontSize: 22),
              ),
            ),
          ),
          SizedBox(height: 30),
        ],
      ),
    );
  }
}
