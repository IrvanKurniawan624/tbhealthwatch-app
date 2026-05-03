// ============================================================================
// MODEL: PROFILE
// File ini mendefinisikan cetak biru (struktur data) untuk Profil Tenaga Medis.
// ============================================================================

class Profile {
  // Variabel dibuat 'final' karena data model di Flutter idealnya bersifat 
  // immutable (tidak bisa diubah secara sembarangan setelah dibuat).
  final String name;
  final String role;
  final String facilityName;
  final String facilityRole;
  final String assignmentLocation;
  final String email;
  final String phone;
  final String address;

  // Constructor utama untuk inisialisasi data
  Profile({
    required this.name,
    required this.role,
    required this.facilityName,
    required this.facilityRole,
    required this.assignmentLocation,
    required this.email,
    required this.phone,
    required this.address,
  });

  // --------------------------------------------------------------------------
  // ⚠️ PERSIAPAN UNTUK INTEGRASI API BACKEND NANTI
  // --------------------------------------------------------------------------

  // 1. fromJson: Mengubah format JSON (dari API) menjadi object Profile di Flutter.
  // Dilengkapi dengan '??' (fallback) agar aplikasi tidak crash jika ada data null dari server.
  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      name: json['name'] ?? '',
      role: json['role'] ?? '',
      facilityName: json['facilityName'] ?? '',
      facilityRole: json['facilityRole'] ?? '',
      assignmentLocation: json['assignmentLocation'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
    );
  }

  // 2. toJson: Mengubah object Profile menjadi JSON.
  // Sangat berguna nanti saat kamu menekan tombol "Simpan Perubahan" di Edit Profile
  // untuk mengirim data yang sudah di-update ke database server.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'role': role,
      'facilityName': facilityName,
      'facilityRole': facilityRole,
      'assignmentLocation': assignmentLocation,
      'email': email,
      'phone': phone,
      'address': address,
    };
  }
}