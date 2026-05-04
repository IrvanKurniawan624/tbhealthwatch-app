import 'package:flutter/material.dart';
import '../../data/models/profile_model.dart';

// ============================================================================
// 1. HALAMAN UTAMA (ROOT PAGE - STATEFUL)
// Halaman ini bertugas menyimpan "State" (Controller form) dan merakit komponen.
// ============================================================================
class EditProfilePage extends StatefulWidget {
  final Profile profile;

  const EditProfilePage({super.key, required this.profile});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  // --- Kumpulan Controller untuk Form ---
  late TextEditingController _nameController;
  late TextEditingController _roleController;
  late TextEditingController _locationController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;

  String? _selectedWilayah;
  // TODO: fetch from /api/regions once auth is wired
  final List<String> _wilayahList = [
    'Asemrowo', 'Benowo', 'Bubutan', 'Bulak', 'Dukuh Pakis',
    'Gayungan', 'Genteng', 'Gubeng', 'Gunung Anyar', 'Jambangan',
    'Karang Pilang', 'Kenjeran', 'Krembangan', 'Lakarsantri', 'Mulyorejo',
    'Pabean Cantian', 'Pakal', 'Rungkut', 'Sambikerep', 'Sawahan',
    'Semampir', 'Simokerto', 'Sukolilo', 'Sukomanunggal', 'Tambaksari',
    'Tandes', 'Tegalsari', 'Tenggilis Mejoyo', 'Wiyung', 'Wonocolo',
    'Wonokromo',
  ];

  @override
  void initState() {
    super.initState();
    // Mengisi form awal dengan data dari profile yang diklik
    _nameController = TextEditingController(text: widget.profile.name);
    _roleController = TextEditingController(text: widget.profile.role);
    _locationController = TextEditingController(text: "RSUD Dr. Soetomo, Surabaya");
    _emailController = TextEditingController(text: widget.profile.email);
    _phoneController = TextEditingController(text: widget.profile.phone);
    _addressController = TextEditingController(text: widget.profile.address.replaceAll('\n', ' '));
    
    _selectedWilayah = 'Gubeng';
  }

  @override
  void dispose() {
    // Wajib dibersihkan agar aplikasi tidak berat (memory leak)
    _nameController.dispose();
    _roleController.dispose();
    _locationController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // Fungsi untuk menyimpan data
  void _handleSave() {
    // ---------------------------------------------------------
    // ⚠️ TEMPAT MENYAMBUNGKAN KE BACKEND ASP.NET CORE NANTI
    // Di sini kamu bisa memanggil repository untuk update data.
    // ---------------------------------------------------------
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Perubahan berhasil disimpan!")),
    );
    Navigator.pop(context); // Kembali ke halaman profil
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const EditProfileAppBar(), // <-- Memanggil Header
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const AvatarEditSection(),
            const SizedBox(height: 24),
            
            // <-- Memanggil Form Utama, mengirimkan controller kepadanya
            MainInformationForm(
              nameController: _nameController,
              roleController: _roleController,
              locationController: _locationController,
              selectedWilayah: _selectedWilayah,
              wilayahList: _wilayahList,
              onWilayahChanged: (newValue) {
                setState(() {
                  _selectedWilayah = newValue;
                });
              },
            ),
            const SizedBox(height: 24),
            
            // <-- Memanggil Form Kontak
            ContactDetailForm(
              emailController: _emailController,
              phoneController: _phoneController,
              addressController: _addressController,
            ),
            const SizedBox(height: 24),
            
            const InfoBanner(),
            const SizedBox(height: 32),
            
            // <-- Memanggil Tombol Aksi
            ActionButtons(
              onSave: _handleSave,
              onCancel: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const EditProfileBottomNav(),
    );
  }
}

// ============================================================================
// 2. KOMPONEN: APP BAR / HEADER
// ============================================================================
class EditProfileAppBar extends StatelessWidget implements PreferredSizeWidget {
  const EditProfileAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: const BackButton(color: Colors.black),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/logo.png',
            height: 24,
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.health_and_safety, color: Colors.blue),
          ),
          const SizedBox(width: 8),
          const Text(
            "TB Health Watch",
            style: TextStyle(color: Color(0xFF0052CC), fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none, color: Colors.black87),
          onPressed: () {},
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// ============================================================================
// 3. KOMPONEN: AVATAR EDIT
// ============================================================================
class AvatarEditSection extends StatelessWidget {
  const AvatarEditSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Image.asset(
              'assets/images/logo.png',
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.monitor_heart, size: 50, color: Colors.red),
            ),
          ),
        ),
        Positioned(
          bottom: -5,
          right: -5,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Color(0xFF0052CC),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// 4. KOMPONEN: FORM INFORMASI UTAMA
// ============================================================================
class MainInformationForm extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController roleController;
  final TextEditingController locationController;
  final String? selectedWilayah;
  final List<String> wilayahList;
  final ValueChanged<String?> onWilayahChanged;

  const MainInformationForm({
    super.key,
    required this.nameController,
    required this.roleController,
    required this.locationController,
    required this.selectedWilayah,
    required this.wilayahList,
    required this.onWilayahChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.assignment_ind, color: Color(0xFF0052CC), size: 18),
              SizedBox(width: 8),
              Text("Informasi Utama", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0052CC))),
            ],
          ),
          const SizedBox(height: 16),
          CustomTextField(label: "NAMA LENGKAP", controller: nameController),
          const SizedBox(height: 12),
          CustomTextField(label: "PERAN/SPESIALISASI", controller: roleController),
          const SizedBox(height: 12),
          _buildDropdown(),
          const SizedBox(height: 12),
          CustomTextField(label: "LOKASI PENUGASAN", controller: locationController),
        ],
      ),
    );
  }

  Widget _buildDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("WILAYAH", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedWilayah,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black),
              onChanged: onWilayahChanged,
              items: wilayahList.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(value: value, child: Text(value));
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// 5. KOMPONEN: FORM DETAIL KONTAK
// ============================================================================
class ContactDetailForm extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController addressController;

  const ContactDetailForm({
    super.key,
    required this.emailController,
    required this.phoneController,
    required this.addressController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.contact_mail, color: Color(0xFF0052CC), size: 18),
              SizedBox(width: 8),
              Text("Detail Kontak", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0052CC))),
            ],
          ),
          const SizedBox(height: 16),
          CustomTextField(label: "EMAIL", controller: emailController),
          const SizedBox(height: 12),
          CustomTextField(label: "NOMOR TELEPON", controller: phoneController),
          const SizedBox(height: 12),
          CustomTextField(label: "ALAMAT", controller: addressController, maxLines: 2),
        ],
      ),
    );
  }
}

// ============================================================================
// 6. WIDGET BANTUAN: CUSTOM TEXT FIELD (Bisa Dipakai Berulang-ulang)
// ============================================================================
class CustomTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final int maxLines;

  const CustomTextField({
    super.key,
    required this.label,
    required this.controller,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[200],
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// 7. KOMPONEN: BANNER INFO (Kuning)
// ============================================================================
class InfoBanner extends StatelessWidget {
  const InfoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(Icons.info_outline, color: Color(0xFFD97706), size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "Pastikan unit wilayah dan pangkalan operasi sesuai dengan surat tugas terbaru Anda untuk akurasi pelaporan data pasien TBC.",
              style: TextStyle(fontSize: 12, color: Color(0xFFB45309), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 8. KOMPONEN: TOMBOL AKSI
// ============================================================================
class ActionButtons extends StatelessWidget {
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const ActionButtons({super.key, required this.onSave, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onSave,
            icon: const Icon(Icons.save, color: Colors.white, size: 18),
            label: const Text("Simpan Perubahan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0052CC),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: onCancel,
          child: const Text("Batalkan", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

// ============================================================================
// 9. KOMPONEN: BOTTOM NAVIGATION BAR
// ============================================================================
class EditProfileBottomNav extends StatelessWidget {
  const EditProfileBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: 3,
      selectedItemColor: const Color(0xFF0052CC),
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: 'Surveillance'),
        BottomNavigationBarItem(icon: Icon(Icons.link), label: 'Monitoring'),
        BottomNavigationBarItem(icon: Icon(Icons.link), label: 'Monitoring'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}
