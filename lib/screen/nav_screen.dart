import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'user_screen.dart';

class NavScreen extends StatefulWidget {
  const NavScreen({super.key});

  @override
  State<NavScreen> createState() => _NavScreenState();
}

class _NavScreenState extends State<NavScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    HomeScreen(),
    //UploadScreen(),
    UserScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 3, // Light shadow effect
        shadowColor: Colors.black26,
        centerTitle: true,
        title: const Text(
          "Cangeo Solution",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        elevation: 8, // Stronger shadow effect
        backgroundColor: Colors.white,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.redAccent, // Highlight selected item
        unselectedItemColor: Colors.black54,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed, // Ensures all items are visible
        selectedLabelStyle:
            TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        unselectedLabelStyle:
            TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          // BottomNavigationBarItem(
          //     icon: Icon(Icons.add_photo_alternate_outlined),
          //     label: 'File Upload'),
          BottomNavigationBarItem(
              icon: Icon(Icons.group_add_outlined), label: 'Users'),
        ],
      ),
    );
  }
}
