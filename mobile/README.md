# 🏥 TB Health Watch - Mobile App

Repositori ini berisi kode *frontend* (UI) untuk aplikasi mobile **TB Health Watch** yang dibangun menggunakan *framework* Flutter. 

## 🎯 Progress Pengerjaan - Minggu 1

Pada sprint/minggu pertama ini, pengerjaan difokuskan pada penyelesaian antarmuka pengguna (UI) untuk fitur manajemen profil, serta penyusunan arsitektur dasar aplikasi agar ramah untuk kerja tim (*Clean Code*).

### Fitur & Implementasi yang Telah Diselesaikan:
*   ✅ **Slicing UI Profile Page:** Menyelesaikan tampilan halaman profil tenaga medis sesuai dengan desain Figma.
*   ✅ **Slicing UI Edit Profile Page:** Menyelesaikan halaman formulir (*form*) interaktif untuk mengubah data profil.
*   ✅ **Component-Based UI (Clean Code):** Memecah kode UI yang panjang menjadi *widget-widget* kecil yang independen (seperti `AvatarSection`, `FacilityCard`, `CustomTextField`, dll) agar kode mudah dibaca, di-*review*, dan digunakan ulang (*reusable*) oleh anggota tim lain.
*   ✅ **Penerapan Repository Pattern:** Memisahkan lapisan data (*Data Layer*) dari antarmuka (*Presentation Layer*).
*   ✅ **Mock Data (Dummy):** Membuat `MockProfileRepository` untuk menyimulasikan pemanggilan data dengan jeda waktu. Hal ini memungkinkan UI bisa dites secara utuh dan dipresentasikan meskipun API *backend* belum selesai.
*   ✅ **Data Model Setup:** Membangun `Profile` model lengkap dengan fungsi `fromJson` dan `toJson` untuk persiapan *parsing* data.
*   ✅ **Global Theming:** Mengatur tema utama aplikasi di `main.dart` menggunakan Material 3 dan warna *primary* khusus (`#0052CC`) yang sesuai dengan *guideline* desain.

---

## 📂 Struktur Folder Utama
Arsitektur dalam folder `lib` dirancang sedemikian rupa agar aman dari konflik saat bekerja bersama-sama:
```text
lib/
 ┣ 📂 data/                      # Lapisan Data (Models & Repositories)
 ┃ ┣ 📂 models/
 ┃ ┃ ┗ 📄 profile_model.dart     # Struktur data & fungsi parsing JSON
 ┃ ┗ 📂 repositories/
 ┃   ┣ 📄 profile_repository.dart       # Kontrak/Interface data
 ┃   ┣ 📄 mock_profile_repository.dart  # Dummy data untuk testing UI
 ┃   ┗ 📄 api_profile_repository.dart   # Tempat menaruh logika HTTP Request ke Backend
 ┃
 ┣ 📂 presentation/              # Lapisan UI (Pages & Widgets)
 ┃ ┗ 📂 pages/
 ┃   ┣ 📄 profile_page.dart
 ┃   ┗ 📄 edit_profile_page.dart
 ┃
 ┗ 📄 main.dart                  # Entry point aplikasi & setting tema
