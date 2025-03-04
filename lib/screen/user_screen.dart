import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controllers/user_controller.dart';

class UserScreen extends StatelessWidget {
  final UserController controller = Get.put(UserController());
  final List<Color> gradientColors = [
    Colors.blue.withOpacity(0.7),
    Colors.redAccent.withOpacity(0.5),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SizedBox(
            height: 20,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 5, horizontal: 30),
                    margin: EdgeInsets.symmetric(
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: const Color.fromARGB(107, 0, 0, 0),
                            blurRadius: 5.0,
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
                      controller: controller.nameController,
                      decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Enter Name',
                          hintStyle: TextStyle(
                            fontSize: 20,
                            color: Colors.black26,
                            fontWeight: FontWeight.w600,
                          )),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.add_circle_outline_rounded,
                    size: 40,
                    color: Colors.redAccent,
                  ),
                  onPressed: controller.addUser,
                ),
              ],
            ),
          ),
          SizedBox(
            height: 20,
          ),
          Expanded(
            child: Obx(
              () => ListView.builder(
                itemCount: controller.users.length,
                itemBuilder: (context, index) {
                  var user = controller.users[index];
                  return Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 50,
                        ),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                              side: BorderSide(color: Colors.redAccent),
                              borderRadius: BorderRadius.circular(5)),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Text(
                                user['name'],
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.w600),
                              ),
                              SizedBox(
                                width: 60,
                              ),
                              StreamBuilder<DocumentSnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(user['id'])
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData ||
                                      !snapshot.data!.exists) {
                                    return Text('Active Time: 0 min');
                                  }
                                  var data = snapshot.data!.data()
                                      as Map<String, dynamic>?;
                                  var activeTime = data?['activeTime']
                                          as Map<String, dynamic>? ??
                                      {};
                                  String today = DateFormat('yyyy-MM-dd')
                                      .format(DateTime.now());
                                  int totalMinutes = int.tryParse(
                                          activeTime[today]?.toString() ??
                                              '0') ??
                                      0;
                                  int hours = totalMinutes ~/ 60;
                                  int minutes = totalMinutes % 60;
                                  String formattedTime = hours > 0
                                      ? "$hours hr $minutes min"
                                      : "$minutes min";

                                  return Text(
                                    'Active Time: $formattedTime',
                                  );
                                },
                              ),
                              Container(),
                              Container()
                            ],
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              Get.defaultDialog(
                                backgroundColor: Colors.white,
                                title: 'Confirm Delete',
                                middleText:
                                    'Are you sure you want to delete this user?',
                                confirm: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red),
                                  onPressed: () {
                                    controller.deleteUser(user['id']);
                                    Get.back();
                                  },
                                  child: Text(
                                    'Yes',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 16),
                                  ),
                                ),
                                cancel: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(30),
                                          side: BorderSide(
                                              color: Colors.red, width: 2))),
                                  onPressed: () => Get.back(),
                                  child: Text(
                                    'No',
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.black),
                                  ),
                                ),
                              );
                            },
                          ),
                          onTap: () {
                            controller.expandedUserId.value =
                                controller.expandedUserId.value == user['id']
                                    ? ''
                                    : user['id'];
                          },
                        ),
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      Obx(() {
                        if (controller.expandedUserId.value == user['id']) {
                          return StreamBuilder<DocumentSnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('users')
                                .doc(user['id'])
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData || !snapshot.data!.exists) {
                                return Container();
                              }
                              var data = snapshot.data!.data()
                                  as Map<String, dynamic>?;
                              var activeTime = data?['activeTime']
                                      as Map<String, dynamic>? ??
                                  {};
                              List<FlSpot> spots = [];
                              List<String> weekDays = [];
                              DateTime now = DateTime.now();

                              for (int i = 6; i >= 0; i--) {
                                String date = DateFormat('yyyy-MM-dd')
                                    .format(now.subtract(Duration(days: i)));
                                String shortDay = DateFormat('E')
                                    .format(now.subtract(Duration(days: i)));

                                // Convert minutes to hours
                                int totalMinutes = int.tryParse(
                                        activeTime[date]?.toString() ?? '0') ??
                                    0;
                                double hours = totalMinutes /
                                    60; // Convert minutes to decimal hours

                                spots.add(FlSpot((6 - i).toDouble(), hours));
                                weekDays.add(shortDay);
                              }

                              return Container(
                                height: 200,
                                padding: EdgeInsets.symmetric(
                                    horizontal: 50, vertical: 15),
                                child: LineChart(
                                  LineChartData(
                                    gridData: FlGridData(show: false),
                                    titlesData: FlTitlesData(
                                      topTitles: AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false),
                                      ),
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 80,
                                          getTitlesWidget: (value, meta) {
                                            int totalMinutes =
                                                (value * 60).toInt();
                                            int hours = totalMinutes ~/ 60;
                                            int minutes = totalMinutes % 60;
                                            return Container(
                                              margin: EdgeInsets.only(right: 0),
                                              child: Text('$hours h $minutes m',
                                                  style:
                                                      TextStyle(fontSize: 15)),
                                            );
                                          },
                                        ),
                                      ),
                                      rightTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 80,
                                          getTitlesWidget: (value, meta) {
                                            int totalMinutes =
                                                (value * 60).toInt();
                                            int hours = totalMinutes ~/ 60;
                                            int minutes = totalMinutes % 60;
                                            return Container(
                                              margin: EdgeInsets.only(left: 20),
                                              child: Text('$hours h $minutes m',
                                                  style:
                                                      TextStyle(fontSize: 15)),
                                            );
                                          },
                                        ),
                                      ),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget: (value, meta) {
                                            int index = value.toInt();
                                            if (index < 0 ||
                                                index >= weekDays.length)
                                              return Container();
                                            return Text(weekDays[index],
                                                style: TextStyle(fontSize: 20));
                                          },
                                          interval:
                                              1, // Ensure each weekday appears only once
                                        ),
                                      ),
                                    ),
                                    borderData: FlBorderData(show: false),
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: spots,
                                        isCurved: true,
                                        gradient: LinearGradient(colors: [
                                          Colors.red,
                                          Colors.purple
                                        ]),
                                        barWidth: 3,
                                        isStrokeCapRound: true,
                                        belowBarData: BarAreaData(
                                          show: true,
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.red.withOpacity(0.3),
                                              Colors.purple.withOpacity(0.3)
                                            ],
                                          ),
                                        ),
                                        dotData: FlDotData(
                                            show:
                                                true), // Show dots at each point
                                      ),
                                    ],
                                    lineTouchData: LineTouchData(
                                      touchTooltipData: LineTouchTooltipData(
                                        tooltipBgColor:
                                            Colors.black.withOpacity(0.7),
                                        getTooltipItems:
                                            (List<LineBarSpot> touchedSpots) {
                                          return touchedSpots.map((spot) {
                                            double totalHours = spot
                                                .y; // Now this represents hours
                                            int hours = totalHours.toInt();
                                            int minutes =
                                                ((totalHours - hours) * 60)
                                                    .toInt();

                                            return LineTooltipItem(
                                              '$hours h $minutes m', // Correctly formats hours and minutes
                                              TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 17),
                                            );
                                          }).toList();
                                        },
                                      ),
                                      touchCallback: (FlTouchEvent event,
                                          LineTouchResponse? touchResponse) {},
                                      handleBuiltInTouches: true,
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        }
                        return Container();
                      }),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
