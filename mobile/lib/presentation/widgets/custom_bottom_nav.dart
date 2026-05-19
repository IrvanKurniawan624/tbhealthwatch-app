import 'package:flutter/material.dart';
import '../profile/profile_page.dart';
import '../monitoring/monitoring_page.dart';
import '../tracing/tracing_map_page.dart';
import '../surveillance/surveillance_page.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;

  const CustomBottomNav({super.key, required this.currentIndex});

  // Fungsi untuk menangani saat tab diklik
  void _onItemTapped(BuildContext context, int index) {
    // Kalau user klik tab yang sedang aktif, tidak perlu melakukan apa-apa
    if (index == currentIndex) return;

    // Ganti halaman dengan PushReplacement agar halamannya tidak menumpuk
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SurveillancePage()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const TracingMapPage()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MonitoringPage()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ProfilePage()),
        );
        break;
      default:
        // Menampilkan notifikasi sementara jika halaman belum dibuat
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Halaman untuk tab index: $index belum tersedia"),
          ),
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
      onTap: (index) =>
          _onItemTapped(context, index), // Panggil fungsi saat diklik
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.map_outlined),
          label: 'Surveillance',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_tree_outlined),
          label: 'Tracing',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.link), label: 'Monitoring'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}
