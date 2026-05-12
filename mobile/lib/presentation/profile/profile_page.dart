import 'package:flutter/material.dart';
import 'edit_profile_page.dart';
import '../../core/api_client.dart';
import '../../data/models/profile_model.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/repositories/api_profile_repository.dart';
import '../auth/login_page.dart';
import '../widgets/custom_bottom_nav.dart';
import '../widgets/custom_app_bar.dart';

// ============================================================================
// 1. HALAMAN UTAMA (ROOT PAGE)
// Di sinilah tempat kita merakit semua potongan UI menjadi satu halaman utuh.
// ============================================================================
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _repository = ApiProfileRepository(ApiClient());
  late Future<Profile> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _repository.getProfileData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // MENGGUNAKAN GLOBAL APP BAR (Tanpa Tombol Back)
      appBar: const CustomAppBar(), 
      body: FutureBuilder<Profile>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (snapshot.hasData) {
            final profile = snapshot.data!;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // --- Merakit komponen-komponen UI di sini ---
                  AvatarSection(profile: profile, repository: _repository),
                  const SizedBox(height: 24),
                  FacilityCard(profile: profile),
                  const SizedBox(height: 24),
                  ContactCard(profile: profile),
                  const SizedBox(height: 24),
                  const LogoutButton(),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
      // MENGGUNAKAN GLOBAL BOTTOM NAV DI SINI
      bottomNavigationBar: const CustomBottomNav(currentIndex: 3),
    );
  }
}

// ============================================================================
// 2. KOMPONEN: AVATAR & INFO SINGKAT
// Berisi foto profil, badge "Verified", nama, peran, dan tombol Edit Profile.
// ============================================================================
class AvatarSection extends StatelessWidget {
  final Profile profile;
  final IProfileRepository? repository;

  const AvatarSection({super.key, required this.profile, this.repository});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.teal[700],
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.person, size: 60, color: Colors.white),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            "VERIFIED MEDICAL PERSONNEL",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0052CC),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          profile.name,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0052CC),
          ),
        ),
        Text(
          profile.role,
          style: TextStyle(color: Colors.grey[600]),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditProfilePage(profile: profile, repository: repository),
              ),
            );
          },
          icon: const Icon(Icons.edit, size: 16),
          label: const Text(
            "Edit Profile",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0052CC),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// 3. KOMPONEN: KARTU FASILITAS KESEHATAN (Warna Biru)
// ============================================================================
class FacilityCard extends StatelessWidget {
  final Profile profile;

  const FacilityCard({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0052CC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            profile.facilityName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            profile.facilityRole,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "LOKASI PENUGASAN",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        profile.assignmentLocation,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 4. KOMPONEN: KARTU KONTAK (Warna Putih)
// ============================================================================
class ContactCard extends StatelessWidget {
  final Profile profile;

  const ContactCard({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Contact Details",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          _ContactItem(icon: Icons.email, label: "EMAIL", value: profile.email),
          const Divider(height: 24),
          _ContactItem(icon: Icons.phone, label: "NO. TELEPON", value: profile.phone),
          const Divider(height: 24),
          _ContactItem(icon: Icons.work, label: "ALAMAT", value: profile.address),
        ],
      ),
    );
  }
}

// Sub-komponen khusus untuk mem-build isi kontak (hanya dipakai di ContactCard)
class _ContactItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ContactItem({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF0052CC), size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// 5. KOMPONEN: TOMBOL LOGOUT
// ============================================================================
class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          try {
            await ApiClient().post('/auth/logout');
          } catch (_) {}
          await ApiClient.clearTokens();
          if (context.mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginPage()),
              (_) => false,
            );
          }
        },
        icon: const Icon(Icons.logout, color: Colors.red),
        label: const Text(
          "Keluar",
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red[50],
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
