import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:video_player/video_player.dart';

import '../controllers/homecontroll.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HomeController controller = Get.put(HomeController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
          child: Column(children: [
        SizedBox(
          height: 30,
        ),
        Obx(() {
          if (controller.users.isEmpty) {
            return Center(
              child: LoadingAnimationWidget.inkDrop(
                color: Colors.redAccent,
                size: 50,
              ),
            );
          }

          return Container(
            constraints: BoxConstraints(minHeight: 100, maxHeight: 400),
            margin: EdgeInsets.symmetric(horizontal: 30),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Color.fromARGB(79, 0, 0, 0),
                  blurRadius: 3.0,
                )
              ],
              border: Border.all(color: Colors.redAccent, width: 2),
            ),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Select All checkbox logic
                  Row(
                    children: [
                      Checkbox(
                        activeColor: Colors.redAccent,
                        value: controller.allSelected.value,
                        onChanged: (bool? value) =>
                            controller.toggleSelectAll(),
                      ),
                      const Text(
                        'Select All',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  // Displaying individual user checkboxes
                  ...controller.users.map((user) {
                    return Obx(() {
                      return CheckboxListTile(
                        activeColor: Colors.redAccent,
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              user['name'] ?? 'No Name',
                              style: TextStyle(
                                  fontSize: 21, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              user['path'] ?? 'No Video',
                              style: TextStyle(
                                  fontSize: 21, fontWeight: FontWeight.w600),
                            ),
                            Container()
                          ],
                        ),
                        value: controller.selectedUsers.contains(user['id']),
                        onChanged: (bool? selected) =>
                            controller.toggleUserSelection(user['id']),
                      );
                    });
                  }).toList(),
                ],
              ),
            ),
          );
        }),
        SizedBox(
          height: 20,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Obx(() {
              // Ensure selectedFileId has a valid value
              String selectedValue = controller.selectedFileId.value;
              if (!controller.fileIds.contains(selectedValue) &&
                  selectedValue != "none" &&
                  selectedValue != "No Video") {
                selectedValue = "none";
              }

              return Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromARGB(79, 0, 0, 0),
                      blurRadius: 5.0,
                    )
                  ],
                  border: Border.all(color: Colors.redAccent, width: 1.5),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton2<String>(
                    isExpanded: true,
                    hint: Text(
                      "Select File",
                      style: TextStyle(fontSize: 16, color: Colors.redAccent),
                    ),
                    items: [
                      DropdownMenuItem<String>(
                        value: "none",
                        child: Text(
                          "None",
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      ...controller.fileIds.asMap().entries.map((entry) {
                        int index = entry.key + 1;
                        String fileId = entry.value;
                        return DropdownMenuItem<String>(
                          value: fileId,
                          child: Text(
                            "Video $index",
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        );
                      }).toList(),
                      DropdownMenuItem<String>(
                        value: "No Video",
                        child: Text(
                          "No Video",
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                    value: selectedValue, // ✅ Safe fallback if invalid
                    onChanged: (newValue) {
                      controller.selectedFileId.value = newValue!;
                      if (newValue == "none" || newValue == "No Video") {
                        controller.files.clear();
                      } else {
                        controller.fetchFileData(newValue);
                      }
                    },
                    buttonStyleData: ButtonStyleData(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      height: 35,
                      width: 300,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: Colors.white,
                      ),
                    ),
                    iconStyleData: IconStyleData(
                      icon:
                          Icon(Icons.arrow_drop_down, color: Colors.redAccent),
                      iconSize: 35,
                    ),
                    dropdownStyleData: DropdownStyleData(
                      maxHeight: 300,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: Colors.white,
                      ),
                    ),
                    menuItemStyleData: MenuItemStyleData(
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                ),
              );
            }),

            SizedBox(
              width: 10,
            ),

            // Container(
            //   padding: EdgeInsets.symmetric(horizontal: 1, vertical: 1),
            //   decoration: BoxDecoration(
            //       color: Colors.white,
            //       borderRadius: BorderRadius.circular(10),
            //       border: Border.all(color: Colors.redAccent, width: 1.5),
            //       boxShadow: [
            //         BoxShadow(
            //           color: const Color.fromARGB(79, 0, 0, 0),
            //           blurRadius: 5.0,
            //         )
            //       ]),
            //   child: IconButton(
            //     onPressed: () {
            //       Get.defaultDialog(
            //         contentPadding:
            //             EdgeInsets.symmetric(horizontal: 60, vertical: 20),
            //         backgroundColor: Colors.white,
            //         title: "Confirm Deletion",
            //         middleText: "Are you sure you want to delete all files?",
            //         textConfirm: "Yes",
            //         textCancel: "No",
            //         confirmTextColor: Colors.white,
            //         buttonColor: Colors.red,
            //         onConfirm: () async {
            //           await controller.deleteAllFiles();
            //           Get.back(); // Close dialog
            //         },
            //         onCancel: () {
            //           Get.back(); // Close dialog
            //         },
            //       );
            //     },
            //     icon: Icon(
            //       Icons.delete,
            //       color: Colors.red,
            //       size: 35,
            //     ),
            //   ),
            // )
          ],
        ),
        SizedBox(
          height: 10,
        ),
        Obx(() {
          if (controller.isLoading.value)
            Positioned.fill(
              child: Container(
                color: Colors.white.withOpacity(0.8),
                child: Center(
                  child: LoadingAnimationWidget.inkDrop(
                    color: Colors.redAccent,
                    size: 50,
                  ),
                ),
              ),
            );
          int count = controller.files.length;

          return Container(
            constraints: BoxConstraints(
                minHeight: 300, maxHeight: 600), // Set max height

            decoration: BoxDecoration(
                border: Border.all(color: Colors.redAccent, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromARGB(107, 0, 0, 0),
                    blurRadius: 5.0,
                  )
                ],
                borderRadius: BorderRadius.circular(30),
                color: Colors.white),
            margin: EdgeInsets.all(20),

            child: count == 0
                ? Center(
                    child: Text(
                    "No Media Available",
                    style: TextStyle(fontSize: 20),
                  ))
                : Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(20))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (count == 1)
                          Expanded(
                            child: _buildMediaWithActions(
                                context, controller.files[0], 0,
                                isFullWidth: true),
                          ),
                        if (count == 2)
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                    child: _buildMediaWithActions(
                                        context, controller.files[0], 0)),
                                SizedBox(width: 10),
                                Expanded(
                                    child: _buildMediaWithActions(
                                        context, controller.files[1], 1)),
                              ],
                            ),
                          ),
                        if (count == 3) ...[
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    children: [
                                      Expanded(
                                        child: _buildMediaWithActions(
                                            context, controller.files[0], 0,
                                            isFullWidth: true),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    children: [
                                      Expanded(
                                          child: _buildMediaWithActions(
                                              context, controller.files[1], 1)),
                                      SizedBox(width: 10),
                                      Expanded(
                                          child: _buildMediaWithActions(
                                              context, controller.files[2], 2)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (count == 4) ...[
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                    child: _buildMediaWithActions(
                                        context, controller.files[0], 0)),
                                SizedBox(width: 10),
                                Expanded(
                                    child: _buildMediaWithActions(
                                        context, controller.files[1], 1)),
                              ],
                            ),
                          ),
                          SizedBox(height: 10),
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                    child: _buildMediaWithActions(
                                        context, controller.files[2], 2)),
                                SizedBox(width: 10),
                                Expanded(
                                    child: _buildMediaWithActions(
                                        context, controller.files[3], 3)),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
          );
        }),
        SizedBox(
          width: 200,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              if (controller.selectedFileId.value == "none") {
                Get.snackbar(
                  "Info",
                  "No file selected!",
                  snackPosition: SnackPosition.BOTTOM,
                  margin: EdgeInsets.only(bottom: 20, left: 20, right: 20),
                );
                print("No file selected");
                return;
              }

              if (controller.selectedUsers.isEmpty) {
                Get.snackbar(
                  "Info",
                  "No users selected!",
                  snackPosition: SnackPosition.BOTTOM,
                  margin: EdgeInsets.only(bottom: 20, left: 20, right: 20),
                );
                print("No users selected");
                return;
              }

              try {
                for (String userId in controller.selectedUsers) {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .update({'path': controller.selectedFileId.value});
                }
                print("Users updated successfully");
              } catch (e) {
                print("Error updating users: $e");
              }
            },
            child: Text(
              "Submit",
              style: TextStyle(color: Colors.white, fontSize: 22),
            ),
          ),
        ),
        Obx(() => BottomBarSettings(fileId: controller.selectedFileId.value)),
      ])),
    );
  }
}

// Function to build a media widget with delete & upload buttons
Widget _buildMediaWithActions(BuildContext context, String url, int index,
    {bool isFullWidth = false}) {
  final HomeController controller = Get.find<HomeController>();

  return Stack(
    children: [
      Container(
        width: isFullWidth ? double.infinity : double.maxFinite,
        height: isFullWidth ? double.infinity : double.maxFinite,
        child: MediaWidget(url: url),
      ),
      Positioned(
        top: 5,
        right: 5,
        child: Container(
          // Wrap Row in a Container

          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Container(
              //   decoration: BoxDecoration(
              //     borderRadius: BorderRadius.circular(10),
              //     color: Colors.black54,
              //   ),
              //   padding: EdgeInsets.all(3),
              //   child: IconButton(
              //     icon: Icon(
              //       Icons.delete,
              //       color: Colors.red,
              //       size: 30,
              //     ),
              //     onPressed: () async {
              //       bool confirmDelete = await showDialog(
              //         context: context,
              //         builder: (context) => AlertDialog(
              //           title: Text("Confirm Delete"),
              //           content:
              //               Text("Are you sure you want to delete this file?"),
              //           actions: [
              //             TextButton(
              //                 onPressed: () => Navigator.pop(context, false),
              //                 child: Text(
              //                   "Cancel",
              //                   style: TextStyle(
              //                       fontSize: 16, color: Colors.black),
              //                 )),
              //             TextButton(
              //                 onPressed: () => Navigator.pop(context, true),
              //                 child: Text(
              //                   "Delete",
              //                   style: TextStyle(
              //                       color: Colors.white, fontSize: 16),
              //                 ))
              //           ],
              //         ),
              //       );
              //       if (confirmDelete) {
              //         await controller.deleteFile(index);
              //       }
              //     },
              //   ),
              // ),
              // SizedBox(
              //   width: 10,
              // ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.black54,
                ),
                padding: EdgeInsets.all(3),
                child: IconButton(
                  icon: Icon(
                    Icons.cloud_upload_outlined,
                    color: Colors.white,
                    size: 40,
                  ),
                  onPressed: () async {
                    FilePickerResult? result =
                        await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: [
                        'jpg',
                        'jpeg',
                        'png',
                        'mp4',
                        'gif',
                        'mkv',
                      ],
                    );

                    if (result != null) {
                      File file = File(result.files.single.path!);
                      await controller.replaceFile(index, file);
                    }
                  },
                ),
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
            fit: BoxFit.fill,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: LoadingAnimationWidget.inkDrop(
                  color: Colors.redAccent,
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
              // Positioned(
              //   bottom: 20,
              //   child: FloatingActionButton(
              //     onPressed: () {
              //       setState(() {
              //         _controller.value.isPlaying
              //             ? _controller.pause()
              //             : _controller.play();
              //       });
              //     },
              //     child: Icon(_controller.value.isPlaying
              //         ? Icons.pause
              //         : Icons.play_arrow),
              //   ),
              // ),
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
              color: Colors.redAccent,
              size: 50,
            ),
          );
  }
}

class BottomBarSettings extends StatefulWidget {
  final String fileId;
  BottomBarSettings({required this.fileId});

  @override
  _BottomBarSettingsState createState() => _BottomBarSettingsState();
}

class _BottomBarSettingsState extends State<BottomBarSettings> {
  final HomeController controller = Get.find<HomeController>();

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
    _loadBottomBarData(widget.fileId);
  }

  @override
  void didUpdateWidget(covariant BottomBarSettings oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fileId != widget.fileId) {
      _loadBottomBarData(widget.fileId);
    }
  }

  Future<void> _loadBottomBarData(String fileId) async {
    if (fileId.isEmpty || fileId == "none" || fileId == "No Video") return;

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
    if (fileId.isEmpty || fileId == "none" || fileId == "No Video") return;

    await FirebaseFirestore.instance.collection('uploadfiles').doc(fileId).set({
      'bottombar': {
        'show': _isEnabled,
        'bottomBarText': _textController.text,
        'transparency': _transparency,
        'bgColor': getColorName(_bgColor),
        'textColor': getColorName(_textColor),
      }
    }, SetOptions(merge: true));

    Get.snackbar(
      "Success",
      "Bottom Bar settings updated!",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      margin: EdgeInsets.only(bottom: 20, left: 20, right: 20),
    );
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
                            color: const Color.fromARGB(255, 164, 155, 155),
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
              onPressed: () => _saveBottomBarData(widget.fileId),
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
