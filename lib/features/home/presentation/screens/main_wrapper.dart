import 'package:flutter/material.dart';
import 'package:campusapp/features/home/presentation/screens/home_screen.dart';
import 'package:campusapp/features/events/presentation/screens/my_events_screen.dart';
import 'package:campusapp/features/leaderboard/presentation/screens/leaderboard_screen.dart';
import 'package:campusapp/features/profile/presentation/screens/profile_screen.dart';

class MainWrapper extends StatefulWidget {
  final String? userId;
  final String? userType;

  const MainWrapper({
    super.key,
    this.userId,
    this.userType,
  });

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();

    _screens = [
      HomeScreen(
        userId: widget.userId,   // ✅ CUMA HomeScreen yang pakai
        userType: widget.userType,
      ),
      const MyEventsScreen(),     // ✅ JANGAN kirim userId
      const LeaderboardScreen(),
      const ProfileScreen(),      // ✅ JANGAN kirim userId
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: 'Events',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard),
            label: 'Rank',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
      ),
    );
  }
}

