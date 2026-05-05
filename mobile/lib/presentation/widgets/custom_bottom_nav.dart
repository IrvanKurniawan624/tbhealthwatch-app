import 'package:flutter/material.dart';
// TODO: Nanti import halaman-halaman lain di sini (Surveillance, Monitoring, Pasien)
// import '../pages/profile_page.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;

  const CustomBottomNav({
    super.key, 
    required this.currentIndex,
  });

  // Fungsi untuk menangani saat tab diklik
  void _onItemTapped(BuildContext context, int index) {
    // Kalau user klik tab yang sedang aktif, tidak perlu melakukan apa-apa
    if (index == currentIndex) return;

    // ----------------------------------------------------------------------
    // ⚠️ TEMPAT MENYAMBUNGKAN HALAMAN NANTI
    // Gunakan Navigator.pushReplacement agar halamannya ditimpa (tidak menumpuk)
    // ----------------------------------------------------------------------
    /*
    switch (index) {
      case 0:
        // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => SurveillancePage()));
        break;
      case 1:
        // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MonitoringPage()));
        break;
      case 2:
        // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => PasienPage()));
        break;
      case 3:
        // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ProfilePage()));
        break;
    }
    */

    // Untuk sementara, kita tampilkan notifikasi kecil saja jika halaman belum ada
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Pindah ke tab index: $index")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex, 
      selectedItemColor: const Color(0xFF0052CC),
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      onTap: (index) => _onItemTapped(context, index), // Panggil fungsi saat diklik
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: 'Surveillance'),
        BottomNavigationBarItem(icon: Icon(Icons.link), label: 'Monitoring'),
        BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Pasien'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}