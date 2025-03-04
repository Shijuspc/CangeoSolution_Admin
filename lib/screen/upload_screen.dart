import 'dart:io';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:video_player/video_player.dart';

import '../controllers/upload_controller.dart';

class UploadScreen extends StatefulWidget {
  UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final UploadController controller = Get.put(UploadController());

  // Bottom bar control
  bool _isBottomBarVisible = true;
  double _transparency = 50.0;
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  var selectedScreenIndex = 1.obs;
  Color _bgColor = Colors.black;
  Color _textColor = Colors.white;

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
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 20,
            ),
            // Display user list with checkboxes
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
                                      fontSize: 21,
                                      fontWeight: FontWeight.w600),
                                ), // ✅ Handle missing name

                                Row(
                                  children: [
                                    Text(
                                      user['title']?.toString() ?? 'No Title',
                                      style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w500),
                                    ),
                                    SizedBox(
                                      width: 0,
                                    ),
                                    TextButton(
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.all(0),
                                      ),
                                      onPressed: () =>
                                          controller.showUserPopup(user['id']),
                                      child: Text(
                                        "View",
                                        style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.redAccent),
                                      ),
                                    ),
                                  ],
                                ),
                                Container()
                              ],
                            ),
                            value:
                                controller.selectedUsers.contains(user['id']),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 5, horizontal: 30),
                margin: EdgeInsets.symmetric(
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.redAccent, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromARGB(107, 0, 0, 0),
                        blurRadius: 2,
                      )
                    ],
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white),
                child: TextFormField(
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                  controller: _titleController,
                  decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Enter Video Title',
                      hintStyle: TextStyle(
                        fontSize: 20,
                        color: Colors.black26,
                        fontWeight: FontWeight.w600,
                      )),
                ),
              ),
            ),
            SizedBox(
              height: 10,
            ),
            Text(
              "Screens",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(
              height: 10,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Center(
                  child: Obx(
                    () => ToggleButtons(
                      isSelected: List.generate(
                        4,
                        (index) =>
                            controller.selectedScreenIndex.value == index + 1,
                      ),
                      onPressed: (index) {
                        controller.selectedFiles.clear();
                        controller.selectedScreenIndex.value = index + 1;
                      },
                      children: List.generate(
                        4,
                        (index) {
                          bool isSelected =
                              controller.selectedScreenIndex.value == index + 1;
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Row(
                              children: [
                                Image.asset(
                                  "images/${isSelected ? '${index + 1}_red' : '${index + 1}_grey'}.png",
                                  width: 24,
                                  height: 24,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Display the selected screen
            Container(
                height: 450,
                margin: EdgeInsets.all(20),
                child: getSelectedScreen()),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              child: SwitchListTile(
                activeColor: Colors.redAccent,
                title: Text(
                  "Enable Bottom Bar",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                value: _isBottomBarVisible, // Use the same state variable
                onChanged: (value) {
                  setState(() {
                    _isBottomBarVisible = value;
                  });
                },
              ),
            ),

            // Bottom bar
            if (_isBottomBarVisible)
              Container(
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
                margin: EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  children: [
                    SizedBox(
                      height: 5,
                    ),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(10),
                      child: Column(
                        children: [
                          AnimatedOpacity(
                            opacity: _transparency / 100,
                            duration: Duration(milliseconds: 300),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  vertical: 5, horizontal: 30),
                              margin: EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 25),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color:
                                    _bgColor.withOpacity(_transparency / 100),
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
                          SizedBox(
                            height: 10,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    "Background :",
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w500),
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
                                      border: Border.all(
                                          color: Colors.redAccent, width: 1.5),
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
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 5),
                                          height: 30,
                                          width: 150,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(10),
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
                                            borderRadius:
                                                BorderRadius.circular(10),
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
                                        fontSize: 20,
                                        fontWeight: FontWeight.w500),
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
                                      border: Border.all(
                                          color: Colors.redAccent, width: 1.5),
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
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 5),
                                          height: 30,
                                          width: 150,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(10),
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
                                            borderRadius:
                                                BorderRadius.circular(10),
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
                          SizedBox(
                            height: 20,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(
              height: 20,
            ),
            SizedBox(
              width: 200,
              child: ElevatedButton(
                style:
                    ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                onPressed: () {
                  controller.uploadData(
                    isBottomBarVisible: _isBottomBarVisible,
                    bottomBarText: _textController.text,
                    transparency: _transparency,
                    bgColor: _bgColor,
                    textColor: _textColor,
                    title: _titleController.text,
                  );
                  _titleController.clear();
                },
                child: Text(
                  "Submit",
                  style: TextStyle(color: Colors.white, fontSize: 22),
                ),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget getSelectedScreen() {
    return Obx(() {
      switch (controller.selectedScreenIndex.value) {
        case 1:
          return screen1();
        case 2:
          return screen2();
        case 3:
          return screen3();
        case 4:
          return screen4();
        default:
          return Container();
      }
    });
  }

  Widget screen1() {
    return GestureDetector(
      onTap: () async {
        await controller.uploadPickFiles(1); // Each box allows only 1 file
      },
      child: fileSelectionBox(1),
    );
  }

  Widget screen2() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () async {
              await controller
                  .uploadPickFiles(2); // Each box allows only 1 file
            },
            child: fileSelectionBox(2),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () async {
              await controller
                  .uploadPickFiles(3); // Each box allows only 1 file
            },
            child: fileSelectionBox(3),
          ),
        ),
      ],
    );
  }

  Widget screen3() {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    await controller.uploadPickFiles(4);
                  },
                  child: fileSelectionBox(4),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    await controller.uploadPickFiles(5);
                  },
                  child: fileSelectionBox(5),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () async {
              await controller.uploadPickFiles(6);
            },
            child: fileSelectionBox(6),
          ),
        ),
      ],
    );
  }

  Widget screen4() {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    await controller.uploadPickFiles(7);
                  },
                  child: fileSelectionBox(7),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    await controller.uploadPickFiles(8);
                  },
                  child: fileSelectionBox(8),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    await controller.uploadPickFiles(9);
                  },
                  child: fileSelectionBox(9),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    await controller.uploadPickFiles(10);
                  },
                  child: fileSelectionBox(10),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget fileSelectionBox(int i) {
    return Obx(
      () => Container(
        margin: EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.redAccent, width: 2),
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
          boxShadow: [BoxShadow(blurRadius: 2, color: Colors.black12)],
        ),
        child: controller.selectedFiles.containsKey(i)
            ? _previewFile(controller.selectedFiles[i]!)
            : Center(
                child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_rounded,
                    size: 40,
                    color: Colors.redAccent,
                  ),
                  Text(
                    "Select Photo & Video ",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                ],
              )),
      ),
    );
  }

  // Preview Image or Video
  Widget _previewFile(File file) {
    String fileExtension = file.path.split('.').last.toLowerCase();

    if (['jpg', 'jpeg', 'png', "gif"].contains(fileExtension)) {
      return Image.file(file, fit: BoxFit.cover);
    } else if (['mp4', 'mkv', 'avi'].contains(fileExtension)) {
      return VideoPlayerWidget(file: file);
    } else {
      return const Text("Invalid File");
    }
  }
}

// Video Player Widget
class VideoPlayerWidget extends StatefulWidget {
  final File file;

  const VideoPlayerWidget({Key? key, required this.file}) : super(key: key);

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.file)
      ..initialize().then((_) {
        setState(() {}); // Refresh UI when video is loaded
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
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
        : const Center(child: CircularProgressIndicator());
  }
}
