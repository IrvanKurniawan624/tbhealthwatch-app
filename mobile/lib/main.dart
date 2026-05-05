import 'package:flutter/material.dart';
import 'presentation/profile/profile_page.dart';

// ============================================================================
// FILE UTAMA (ENTRY POINT)
// Di sinilah aplikasi TB Health Watch pertama kali dijalankan.
// ============================================================================
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TB Health Watch',
      
      // Menghilangkan pita merah tulisan "DEBUG" di pojok kanan atas
      debugShowCheckedModeBanner: false, 
      
      // Mengatur tema global aplikasi (Warna utama, background, dll)
      theme: ThemeData(
        // Menggunakan colorScheme dengan warna biru khas desain Figma kalian
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0052CC), 
        ),
        scaffoldBackgroundColor: Colors.white,
        
        // Mengatur tema AppBar secara global agar kita tidak perlu 
        // menulis background putih berulang-ulang di setiap halaman
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black87),
        ),
        
        // Mengaktifkan desain komponen Material 3 yang lebih modern
        useMaterial3: true, 
      ),
      
      // Mengarahkan aplikasi untuk langsung membuka halaman Profile 
      // saat pertama kali dijalankan
      home: const ProfilePage(), 
    );
  }
}