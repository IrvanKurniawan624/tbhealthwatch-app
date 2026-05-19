import 'package:flutter/material.dart';
import '../profile/profile_page.dart';
import '../monitoring/monitoring_page.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;

  const CustomBottomNav({super.key, required this.currentIndex});

  void _onItemTapped(BuildContext context, int index) {
    if (index == currentIndex) return;

    switch (index) {
      case 2:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MonitoringPage()));
        break;
      case 3:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProfilePage()));
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Halaman untuk tab index: $index belum tersedia")),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      selectedItemColor: const Color(0xFF0052CC),
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      onTap: (index) => _onItemTapped(context, index),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: 'Surveillance'),
        BottomNavigationBarItem(icon: Icon(Icons.account_tree_outlined), label: 'Tracing'),
        BottomNavigationBarItem(icon: Icon(Icons.link), label: 'Monitoring'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}
